//go:build wireinject
// +build wireinject

package wire

import (
	"github.com/google/wire"
	"xiandeng.net.cn/server/db"
	"xiandeng.net.cn/server/pkg/config"
	"xiandeng.net.cn/server/pkg/log"
	"xiandeng.net.cn/server/tasks/server"
)

var repositorySet = wire.NewSet(
	db.NewDBTX,
	db.NewRepository,
)

func NewWire(*config.Config, *log.Logger) (server.TaskServer, func(), error) {
	panic(wire.Build(
		repositorySet,
		server.NewTaskServer,
	))
}
