package controller

import (
	gs "github.com/swaggo/gin-swagger"
	"xiandeng.net.cn/server/internal/app"

	sf "github.com/swaggo/files"
)

func SwaggerControl() app.HandlerFunc {
	return func(ctx app.Context) {
		gs.WrapHandler(sf.Handler)(ctx.GinContext())
	}
}
