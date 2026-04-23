package main

import (
	"xiandeng.net.cn/server/cmd/task/wire"
	"xiandeng.net.cn/server/pkg/config"
	"xiandeng.net.cn/server/pkg/env"
	"xiandeng.net.cn/server/pkg/flags"
	"xiandeng.net.cn/server/pkg/log"
)

// func WrapHandler(f func(context.Context, *asynq.Task, *tasks.Dep) error, dep *tasks.Dep) func(ctx context.Context, t *asynq.Task) error {
// 	return func(ctx context.Context, t *asynq.Task) error {
// 		return f(ctx, t, dep)
// 	}
// }

func main() {
	fm := flags.NewFlagManager()
	env.SetEnv(fm.Env)
	conf := config.LoadConfConfig(fm)

	logger := log.NewLog(conf.Logger, env.Active().IsPro())
	logger.SetServerType("task")
	logger.Info("Starting service...")

	s, clearup, err := wire.NewWire(conf, logger)
	if err != nil {
		panic(err)
	}
	defer clearup()
	panic(s.Start())
}
