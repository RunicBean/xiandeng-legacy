package services

import (
	"xiandeng.net.cn/server/db"
	"xiandeng.net.cn/server/pkg/config"
	"xiandeng.net.cn/server/pkg/log"
)

type Service struct {
	conf   *config.Config
	logger *log.Logger
	repo   db.Repository
}

func NewService(conf *config.Config, logger *log.Logger, repo db.Repository) *Service {
	return &Service{
		conf:   conf,
		logger: logger,
		repo:   repo,
	}
}
