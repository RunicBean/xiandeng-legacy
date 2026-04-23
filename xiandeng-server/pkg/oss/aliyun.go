package oss

import (
	"io"
	"log"
	"time"

	aliyun_oss "github.com/aliyun/aliyun-oss-go-sdk/oss"
	"xiandeng.net.cn/server/constants"
)

type AliyunOSSClient struct {
	client *aliyun_oss.Client
	bucket string
}

func (c *AliyunOSSClient) ListBuckets() {

}

func (c *AliyunOSSClient) ListObjects(bucket string, prefix *string) ([]string, error) {
	b, _ := c.client.Bucket(bucket)
	var err error
	var res aliyun_oss.ListObjectsResult
	if prefix == nil {
		res, err = b.ListObjects()
	} else {
		res, err = b.ListObjects(aliyun_oss.Prefix(*prefix))
	}

	if err != nil {
		return nil, err
	}
	objKeys := []string{}
	for _, obj := range res.Objects {
		objKeys = append(objKeys, obj.Key)
	}
	return objKeys, nil
}

func (c *AliyunOSSClient) ListObjectSignedUrls(bucket string, prefix *string) ([]SignedURL, error) {
	b, _ := c.client.Bucket(bucket)
	var err error
	var res aliyun_oss.ListObjectsResult
	if prefix == nil {
		res, err = b.ListObjects()
	} else {
		res, err = b.ListObjects(aliyun_oss.Prefix(*prefix))
	}
	if err != nil {
		return nil, err
	}

	objKeys := []SignedURL{}
	for _, obj := range res.Objects {
		expires := time.Now().Add(constants.OSS_SIGNED_URL_EXPIRE_MINUTES * time.Minute)
		signedURL, err := b.SignURL(obj.Key, aliyun_oss.HTTPGet, expires.Unix())
		if err != nil {
			return nil, err
		}
		objKeys = append(objKeys, SignedURL{
			URL:  signedURL,
			Name: obj.Key,
		})
	}
	return objKeys, nil
}

func (c *AliyunOSSClient) GetObjectSignedUrl(bucket string, remotePath string) (string, time.Time, error) {
	b, _ := c.client.Bucket(bucket)
	expires := time.Now().Add(constants.OSS_SIGNED_URL_EXPIRE_MINUTES * time.Minute)
	signedURL, err := b.SignURL(remotePath, aliyun_oss.HTTPGet, expires.Unix())
	return signedURL, expires, err
}

func (c *AliyunOSSClient) ListDefaultBucketObjects(prefix *string) ([]string, error) {
	return c.ListObjects(c.bucket, prefix)
}

func (c *AliyunOSSClient) ListDefaultBucketObjectSignedUrls(prefix *string) ([]SignedURL, error) {
	return c.ListObjectSignedUrls(c.bucket, prefix)
}

func (c *AliyunOSSClient) GetDefaultBucketObjectSignedUrl(remotePath string) (string, time.Time, error) {
	return c.GetObjectSignedUrl(c.bucket, remotePath)
}

func (c *AliyunOSSClient) PutFile(bucket string, localPath string, remotePath string) error {
	b, err := c.client.Bucket(bucket)
	if err != nil {
		return err
	}
	err = b.PutObjectFromFile(remotePath, localPath)
	return err
}

func (c *AliyunOSSClient) PutBuffer(bucket string, buffer io.Reader, remotePath string) error {
	b, err := c.client.Bucket(bucket)
	if err != nil {
		return err
	}
	err = b.PutObject(remotePath, buffer)
	return err
}

func (c *AliyunOSSClient) PutDefaultBucketBuffer(buffer io.Reader, remotePath string) error {
	b, err := c.client.Bucket(c.bucket)
	if err != nil {
		return err
	}
	err = b.PutObject(remotePath, buffer)
	return err
}

func NewAliyunOSSClient(config OssConfig) (oc *AliyunOSSClient) {
	oc = &AliyunOSSClient{
		bucket: config.Bucket,
	}
	client, err := aliyun_oss.New(config.Endpoint, config.AccessKeyId, config.AccessKeySecret)
	oc.client = client
	if err != nil {
		log.Fatalf("Aliyun OSS Client Error: %s", err)
	}
	return
}
