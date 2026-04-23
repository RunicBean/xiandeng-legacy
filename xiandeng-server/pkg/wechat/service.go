package wechat

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"xiandeng.net.cn/server/db"
	"xiandeng.net.cn/server/pkg/config"
)

type AccessTokenResponse struct {
	AccessToken    string `json:"access_token"`
	ExpiresIn      int    `json:"expires_in"`
	RefreshToken   string `json:"refresh_token"`
	OpenID         string `json:"openid"`
	UnionID        string `json:"unionid"`
	IsSnapshotUser int    `json:"is_snapshotuser"`
	Scope          string `json:"scope"`
}

type wechatService struct {
	appId     string
	appSecret string
}

type WechatService interface {
	GetAppId() string
	CodeExchange(code string) (accessToken *AccessTokenResponse, err error)
	GetUserInfo(accessToken string, openId string) (*WxUserInfo, error)
	GetUserInfoWithCode(code string) (*WxUserInfo, error)
}

var _ WechatService = (*wechatService)(nil)

func NewWxService(conf *config.Config) WechatService {
	return &wechatService{
		appId:     conf.Auth.WxAppID,
		appSecret: conf.Auth.WxAppSecret,
	}
}

type WxServiceManager struct {
	wxSvcMap map[string]WechatService
}

func (m *WxServiceManager) GetWechatService(orgName string) WechatService {
	if svc, ok := m.wxSvcMap[orgName]; ok {
		return svc
	}
	return m.wxSvcMap["default"]
}

func NewWxServiceManager(repo db.Repository, conf *config.Config) *WxServiceManager {
	mgr := &WxServiceManager{
		wxSvcMap: make(map[string]WechatService),
	}
	creds, err := repo.NewQueries().ListOrgWxCredentials(context.Background())
	if err != nil {
		panic(fmt.Errorf("微信服务初始化失败: %v", err))
	}
	for _, cred := range creds {
		if cred.Wxappid == nil || cred.Wxappsecret == nil {
			//panic(fmt.Errorf("微信服务初始化失败: 机构 %s 的微信凭证缺失", cred.ID.String()))

			mgr.wxSvcMap[cred.Uri] = &wechatService{
				appId:     conf.Auth.WxAppID,
				appSecret: conf.Auth.WxAppSecret,
			}
		} else {
			mgr.wxSvcMap[cred.Uri] = &wechatService{
				appId:     *cred.Wxappid,
				appSecret: *cred.Wxappsecret,
			}
		}

	}
	mgr.wxSvcMap["default"] = NewWxService(conf)
	return mgr
}

func (ws *wechatService) GetAppId() string {
	return ws.appId
}

func (ws *wechatService) CodeExchange(code string) (accessToken *AccessTokenResponse, err error) {
	codeUrl := "https://api.weixin.qq.com/sns/oauth2/access_token?appid=%s&secret=%s&code=%s&grant_type=authorization_code"
	codeUrl = fmt.Sprintf(
		codeUrl,
		ws.appId,
		ws.appSecret,
		code,
	)
	resp, err := http.Get(codeUrl)
	if err != nil {
		return nil, err
	}

	var tokenResponse AccessTokenResponse
	body, _ := io.ReadAll(resp.Body)
	err = json.Unmarshal(body, &tokenResponse)
	if err != nil {
		return nil, err
	}
	return &tokenResponse, nil
}

type WxUserInfo struct {
	OpenID       string `json:"openid"`
	NickName     string `json:"nickname"`
	HeadImageUrl string `json:"headimgurl"`
	// Privilege    string `json:"privilege"`
	UnionID string `json:"unionid"`
}

func (ws *wechatService) GetUserInfo(accessToken string, openId string) (*WxUserInfo, error) {
	userInfoUrl := "https://api.weixin.qq.com/sns/userinfo?access_token=%s&openid=%s"
	userInfoUrl = fmt.Sprintf(userInfoUrl, accessToken, openId)
	resp, err := http.Get(userInfoUrl)
	if err != nil {
		return nil, fmt.Errorf("微信 GetUserInfo API访问失败: %v", err)
	}
	var userInfo WxUserInfo
	body, _ := io.ReadAll(resp.Body)
	err = json.Unmarshal(body, &userInfo)
	if err != nil {
		return nil, fmt.Errorf("微信 GetUserInfo API返回JSON结构解析错误: %v", err)
	}
	return &userInfo, nil
}

func (ws *wechatService) GetUserInfoWithCode(code string) (*WxUserInfo, error) {
	at, err := ws.CodeExchange(code)
	if err != nil {
		return nil, err
	}

	wxUser, err := ws.GetUserInfo(at.AccessToken, at.OpenID)
	if err != nil {
		return nil, err
	}
	return wxUser, nil
}
