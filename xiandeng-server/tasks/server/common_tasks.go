package server

import (
	"context"
	"log"
	"time"

	"github.com/gin-gonic/gin"
	"xiandeng.net.cn/server/db/models"
)

func ImageResize(srcUrl string) (string, error) {
	time.Sleep(5 * time.Second)
	log.Printf("Resizing image: src=%s", srcUrl)
	return "image resize ok", nil
}

func EmailDelivery(ctx context.Context, arg string) (string, error) {
	// ... use ctx ...
	c, ok := ctx.(*gin.Context)
	u := c.MustGet("__user__").(*models.User)
	log.Print(ok)
	log.Print(u.ID.String())
	return "ok", nil
}
