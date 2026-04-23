package wechatlogin

import "fmt"

type LoginHandler interface {
	InitiateLogin() string
}

type Stage int64

const (
	Login Stage = iota
	Signup
)

func (s Stage) String() string {
	switch s {
	case Login:
		return "login"
	case Signup:
		return "signup"
	default:
		panic("Invalid Stage Value. Login/Signup available.")
	}
}

type loginHandler struct {
	appId       string
	redirectUrl string
	state       string
}

func (h *loginHandler) InitiateLogin() string {
	accessUrl := "https://open.weixin.qq.com/connect/oauth2/authorize?appid=%s&redirect_uri=%s&response_type=code&scope=snsapi_userinfo&state=%s#wechat_redirect"
	return fmt.Sprintf(accessUrl, h.appId, h.redirectUrl, h.state)
}

var _ LoginHandler = (*loginHandler)(nil)

func NewLoginHandler(appId string, state string, redirectUrl string, sessionId string, stage string) LoginHandler {
	redirectUrl += "?session_id=%s&stage=%s"
	redirectUrl = fmt.Sprintf(redirectUrl, sessionId, stage)
	return &loginHandler{
		appId:       appId,
		state:       state,
		redirectUrl: redirectUrl,
	}
}
