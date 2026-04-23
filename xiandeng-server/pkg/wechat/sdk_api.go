package wechat

import (
	"github.com/silenceper/wechat/v2"
	"github.com/silenceper/wechat/v2/cache"
	"github.com/silenceper/wechat/v2/officialaccount"
	offConfig "github.com/silenceper/wechat/v2/officialaccount/config"
	"xiandeng.net.cn/server/pkg/config"
)

func NewOfficialAccount(conf *config.Config) *officialaccount.OfficialAccount {
	wc := wechat.NewWechat()
	memory := cache.NewMemory()
	cfg := &offConfig.Config{
		AppID:     conf.Auth.WxAppID,
		AppSecret: conf.Auth.WxAppSecret,
		Token:     "mytesttoken",
		Cache:     memory,
	}
	return wc.GetOfficialAccount(cfg)
}
