package oss

import (
	"io"
	"log"
	"time"

	"xiandeng.net.cn/server/pkg/config"
)

type SignedURL struct {
	URL  string `json:"url"`
	Name string `json:"name"`
}

type OSSClient interface {
	ListBuckets()
	ListObjects(bucket string, prefix *string) ([]string, error)
	ListDefaultBucketObjects(prefix *string) ([]string, error)
	ListObjectSignedUrls(bucket string, prefix *string) ([]SignedURL, error)
	ListDefaultBucketObjectSignedUrls(prefix *string) ([]SignedURL, error)
	GetObjectSignedUrl(bucket string, remotePath string) (string, time.Time, error)
	GetDefaultBucketObjectSignedUrl(remotePath string) (string, time.Time, error)
	PutBuffer(bucket string, buffer io.Reader, remotePath string) error
	PutFile(bucket string, localPath string, remotePath string) error
	PutDefaultBucketBuffer(buffer io.Reader, remotePath string) error
}

func NewOSSClient(conf *config.Config) OSSClient {
	var oc OSSClient
	switch conf.OSS.Product {
	case "aliyun":
		oc = NewAliyunOSSClient(OssConfig{
			Bucket:          conf.OSS.Bucket,
			Endpoint:        conf.OSS.Endpoint,
			AccessKeyId:     conf.OSS.AccessKeyId,
			AccessKeySecret: conf.OSS.AccessKeySecret,
		})
	case "noop":
		oc = &NoopOSSClient{}
	default:
		log.Fatalf("OSS Product Type undefined.")
	}
	return oc
}
