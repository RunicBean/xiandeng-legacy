package main

import (
	"go.uber.org/zap/zapcore"
	"xiandeng.net.cn/server/cmd/server/wire"
	"xiandeng.net.cn/server/pkg/config"
	"xiandeng.net.cn/server/pkg/env"
	"xiandeng.net.cn/server/pkg/flags"
	"xiandeng.net.cn/server/pkg/log"
)

type ABC struct {
	Name string
}

func (abc ABC) MarshalLogObject(enc zapcore.ObjectEncoder) error {
	enc.AddString("name", abc.Name)
	return nil
}

// @title 研伴后台接口文档
// @version 1.0
// @description 所有/v1/api下面的接口
// @termsOfService http://xiandeng.net.cn

// @tag.name 公众号
// @tag.description 公众号相关接口
// @tag.docs.url http://xiandeng.net.cn
// @contact.name Yancy Huang
// @contact.url http://xiandeng.net.cn
// @contact.email yhsunwest@gmail.com

// @externalDocs.url https://github.com/swaggo/swag/blob/master/README_zh-CN.md
// @license.name Apache 2.0
// @license.url http://www.apache.org/licenses/LICENSE-2.0.html

// @host https://yc-http-test.ai-toolsets.com
func main() {
	fm := flags.NewFlagManager()
	env.SetEnv(fm.Env)
	conf := config.LoadConfConfig(fm)

	logger := log.NewLog(conf.Logger, env.Active().IsPro())
	logger.SetServerType("server")
	// logger.ErrorTraceback("test", errors.New("test error"))
	// logger.ErrorTraceback("test", errors.New("test error"), ABC{Name: "1"})
	logger.Info("Starting service...")

	// DB Migration
	// m := db_migrate.NewMigrate(conf)
	// err := m.Up()
	// if err != nil && strings.Contains(err.Error(), "no change") {
	// 	logger.Info(err.Error())
	// }
	// if err != nil && !strings.Contains(err.Error(), "no change") {
	// 	panic(err)
	// }
	// logger.Info("DB Migration Done")

	s, clearup, err := wire.NewWire(conf, logger)
	defer clearup()
	if err != nil {
		panic(err)
	}
	//if err != nil {
	//	log.Fatalf("app server start error: %v", err)
	//}
	if err = s.Run(); err != nil {
		panic(err)
	}
}
