package services

import (
	"fmt"
	"io"
	"time"

	"xiandeng.net.cn/server/constants"
	"xiandeng.net.cn/server/pkg/config"
	"xiandeng.net.cn/server/pkg/oss"
)

type FileSystemService interface {
	UploadOrderProof(orderId string, fileName io.Reader, ext string) error
	ListOrderProof(orderId string) ([]oss.SignedURL, error)
}

type fileSystemService struct {
	conf *config.Config
	oc   oss.OSSClient
}

var _ FileSystemService = (*fileSystemService)(nil)

func NewFileSystemService(conf *config.Config, oc oss.OSSClient) FileSystemService {
	return &fileSystemService{
		conf: conf,
		oc:   oc,
	}
}

func (fs *fileSystemService) UploadOrderProof(orderId string, fileBuf io.Reader, ext string) error {
	return fs.oc.PutDefaultBucketBuffer(fileBuf, fmt.Sprintf("%s/%s/%s.%s", constants.ORDER_PROOF_DIRECTORY, orderId, time.Now().Format("2006-01-02_15:04:05.000000000"), ext))
}

func (fs *fileSystemService) ListOrderProof(orderId string) ([]oss.SignedURL, error) {
	prefix := fmt.Sprintf("%s/%s", constants.ORDER_PROOF_DIRECTORY, orderId)
	return fs.oc.ListDefaultBucketObjectSignedUrls(&prefix)
}
