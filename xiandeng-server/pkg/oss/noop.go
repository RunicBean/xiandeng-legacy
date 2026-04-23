package oss

import (
	"fmt"
	"io"
	"time"
)

type NoopOSSClient struct{}

var _ OSSClient = (*NoopOSSClient)(nil)

func (c *NoopOSSClient) ListBuckets() {}

func (c *NoopOSSClient) ListObjects(bucket string, prefix *string) ([]string, error) {
	return nil, fmt.Errorf("noop oss client")
}

func (c *NoopOSSClient) ListDefaultBucketObjects(prefix *string) ([]string, error) {
	return nil, fmt.Errorf("noop oss client")
}

func (c *NoopOSSClient) ListObjectSignedUrls(bucket string, prefix *string) ([]SignedURL, error) {
	return nil, fmt.Errorf("noop oss client")
}

func (c *NoopOSSClient) ListDefaultBucketObjectSignedUrls(prefix *string) ([]SignedURL, error) {
	return nil, fmt.Errorf("noop oss client")
}

func (c *NoopOSSClient) GetObjectSignedUrl(bucket string, remotePath string) (string, time.Time, error) {
	return "", time.Time{}, fmt.Errorf("noop oss client")
}

func (c *NoopOSSClient) GetDefaultBucketObjectSignedUrl(remotePath string) (string, time.Time, error) {
	return "", time.Time{}, fmt.Errorf("noop oss client")
}

func (c *NoopOSSClient) PutBuffer(bucket string, buffer io.Reader, remotePath string) error {
	return fmt.Errorf("noop oss client")
}

func (c *NoopOSSClient) PutFile(bucket string, localPath string, remotePath string) error {
	return fmt.Errorf("noop oss client")
}

func (c *NoopOSSClient) PutDefaultBucketBuffer(buffer io.Reader, remotePath string) error {
	return fmt.Errorf("noop oss client")
}

