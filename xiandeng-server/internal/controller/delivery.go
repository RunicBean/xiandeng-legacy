package controller

import (
	"fmt"
	"net/http"

	"github.com/google/uuid"
	"xiandeng.net.cn/server/internal/app"
	"xiandeng.net.cn/server/internal/code"
	"xiandeng.net.cn/server/internal/services"
	"xiandeng.net.cn/server/pkg/log"
)

type DeliveryController struct {
	*Controller
	deliveryService services.DeliveryService
}

func NewDeliveryController(controller *Controller, deliveryService services.DeliveryService) *DeliveryController {
	return &DeliveryController{
		Controller:      controller,
		deliveryService: deliveryService,
	}
}

func (c *DeliveryController) ListDelivery() app.HandlerFunc {
	return func(ctx app.Context) {
		accountId := ctx.Account().ID.String()
		status, ok := ctx.GetQuery("status")
		if !ok {
			ctx.AbortWithBadRequest(fmt.Errorf("status is required"))
			return
		}
		deliveries, err := c.deliveryService.ListDelivery(ctx.RequestContext(), accountId, status)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err, log.SimpleMapParam{"account_id": accountId, "status": status})
			return
		}
		ctx.SuccessJSON(deliveries)
	}
}

type BodyConfirmDelivery struct {
	DeliveryId uuid.UUID `json:"delivery_id" form:"delivery_id"`
}

func (c *DeliveryController) ConfirmDelivery() app.HandlerFunc {
	return func(ctx app.Context) {
		var body BodyConfirmDelivery
		err := ctx.ShouldBind(&body)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		_, err = c.deliveryService.ConfirmDelivery(ctx.RequestContext(), body.DeliveryId)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err, log.SimpleMapParam{"delivery_id": body.DeliveryId.String()})
			return
		}
		ctx.SuccessJSON("")
	}
}
