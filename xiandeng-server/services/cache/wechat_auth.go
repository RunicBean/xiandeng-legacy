package cache

import (
	"fmt"
	"github.com/patrickmn/go-cache"
	model "xiandeng.net.cn/server/pkg/web/models"
)

type UserAuthInfo struct {
	BasicInfo          model.UserBasicInfo
	OpenId             string
	Status             model.WechatAuthState
	Message            *string
	RefCode            *string
	WxAuthRedirectUrl  string
	IsFromWechatClient bool
	Channel            chan WechatAuthNotifyChannel
}

type WechatAuthNotifyChannel struct {
	Status  model.WechatAuthState
	Message *string
}

func (ac *appCache) InitUserAuthInfoCache(sessionID string, basicInfo model.UserBasicInfo, wxUrl string, isFromWechatClient bool) {
	fmt.Printf("Setup cache for session: %s\n", sessionID)
	ac.cache.Set(
		"wxb:"+sessionID,
		&UserAuthInfo{
			BasicInfo:          basicInfo,
			OpenId:             "",
			Status:             model.WechatAuthStateInit,
			RefCode:            basicInfo.RefCode,
			WxAuthRedirectUrl:  wxUrl,
			IsFromWechatClient: isFromWechatClient,
			Channel:            make(chan WechatAuthNotifyChannel, 3),
		},
		cache.DefaultExpiration,
	)
}

func (ac *appCache) CacheWechatAuthStatus(sessionID string, status model.WechatAuthState, message *string) {
	st, found := ac.cache.Get("wxb:" + sessionID)
	if found {
		// Update Cache only
		st.(*UserAuthInfo).Status = status
		st.(*UserAuthInfo).Channel <- WechatAuthNotifyChannel{
			Status:  status,
			Message: message,
		}
	} else {
		fmt.Printf("Unable to locate cache for session: %s\n", sessionID)
		panic("Auth has not been init yet.")
	}

}

func (ac *appCache) GetWechatAuthStatusChannel(sessionID string) (*UserAuthInfo, chan WechatAuthNotifyChannel) {
	ui, found := ac.cache.Get("wxb:" + sessionID)
	if !found {
		return nil, nil
	}
	return ui.(*UserAuthInfo), ui.(*UserAuthInfo).Channel
}

func (ac *appCache) ClearUserAuthInfoCache(sessionID string) {
	ac.cache.Delete("wxb:" + sessionID)
}
