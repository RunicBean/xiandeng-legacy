package cache

import (
	"github.com/patrickmn/go-cache"
	"sync"
	"time"
	"xiandeng.net.cn/server/pkg/web/models"
)

type GlobalCache interface {
	InitUserAuthInfoCache(sessionID string, basicInfo models.UserBasicInfo, wxUrl string, isFromWechatClient bool)
	CacheWechatAuthStatus(sessionID string, status models.WechatAuthState, message *string)
	GetWechatAuthStatusChannel(sessionID string) (*UserAuthInfo, chan WechatAuthNotifyChannel)
	ClearUserAuthInfoCache(sessionID string)

	SetInvitationCache(iCode InvitationCode, iCache InvitationCache)
	GetInvitationCache(iCode InvitationCode, delete bool) (InvitationCache, error)
}

type appCache struct {
	cache *cache.Cache
}

var _ GlobalCache = (*appCache)(nil)

var (
	once sync.Once
	c    *appCache
)

func GetAppCache() GlobalCache {
	once.Do(func() {
		c = &appCache{
			cache: cache.New(30*time.Minute, 5*time.Minute),
		}
	})
	return c
}
