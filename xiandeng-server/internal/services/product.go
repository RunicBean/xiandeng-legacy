package services

import (
	"xiandeng.net.cn/server/db"
	"xiandeng.net.cn/server/pkg/config"
	"xiandeng.net.cn/server/pkg/log"
)

type ProductService interface {
}

type productService struct {
	*Service
}

func NewProductService(conf *config.Config, logger *log.Logger, repo db.Repository) ProductService {
	return &productService{
		Service: NewService(conf, logger, repo),
	}
}
