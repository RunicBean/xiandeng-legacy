package main

import (
	"strings"
	db_migrate "xiandeng.net.cn/server/db/migration"
	"xiandeng.net.cn/server/pkg/config"
	"xiandeng.net.cn/server/pkg/env"
	"xiandeng.net.cn/server/pkg/flags"
	"xiandeng.net.cn/server/pkg/log"
)

func main() {
	fm := flags.NewFlagManager()
	env.SetEnv(fm.Env)
	conf := config.LoadConfConfig(fm)
	logger := log.NewLog(conf.Logger, env.Active().IsPro())
	// DB Migration
	m := db_migrate.NewMigrate(conf)
	err := m.Up()
	if err != nil {
		logger.Error(err.Error())
	}
	if err != nil && !strings.Contains(err.Error(), "no change") {
		panic(err)
	}
}
