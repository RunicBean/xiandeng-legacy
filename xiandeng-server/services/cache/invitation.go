package cache

import (
	"time"

	errcode "xiandeng.net.cn/server/errors"
)

type InvitationCode string

type InvitationCache struct {
	AccountId string
	Type      string
}

func (ac *appCache) SetInvitationCache(iCode InvitationCode, iCache InvitationCache) {
	ac.cache.Set(string(iCode), iCache, 24*time.Hour)
}

func (ac *appCache) GetInvitationCache(iCode InvitationCode, delete bool) (InvitationCache, error) {
	iCache, found := ac.cache.Get(string(iCode))
	if !found {
		return InvitationCache{}, errcode.InvitationCacheNotFound
	}
	if delete {
		defer ac.cache.Delete(string(iCode))
	}
	return iCache.(InvitationCache), nil
}
