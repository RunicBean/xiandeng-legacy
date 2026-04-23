package resource

import (
	"time"

	"xiandeng.net.cn/server/pkg/config"
	"xiandeng.net.cn/server/pkg/oss"
)

var (
	termsOverallSignedUrl        string
	termsOverallSignedUrlExpires time.Time
)

type Resource interface {
	GetTermsOverallSignedUrl(key string) string
}

type resource struct {
	oc   oss.OSSClient
	conf *config.Config
}

var _ Resource = (*resource)(nil)

func NewResource(conf *config.Config, oc oss.OSSClient) Resource {
	return &resource{
		oc:   oc,
		conf: conf,
	}
}

func (r *resource) GetTermsOverallSignedUrl(key string) string {
	if termsOverallSignedUrl == "" || time.Now().After(termsOverallSignedUrlExpires) {
		termsOverallSignedUrl, termsOverallSignedUrlExpires, _ = r.oc.GetDefaultBucketObjectSignedUrl(key)
	}
	return termsOverallSignedUrl
}
