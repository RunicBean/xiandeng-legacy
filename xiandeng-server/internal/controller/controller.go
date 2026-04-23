package controller

import (
	"xiandeng.net.cn/server/pkg/config"
	"xiandeng.net.cn/server/pkg/log"
)

type Controller struct {
	logger *log.Logger
	conf   *config.Config
}

func NewController(logger *log.Logger, conf *config.Config) *Controller {
	return &Controller{
		logger: logger,
		conf:   conf,
	}
}
