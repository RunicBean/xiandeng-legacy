package controller

import (
	"net/http"

	"xiandeng.net.cn/server/db"
	"xiandeng.net.cn/server/internal/app"
	"xiandeng.net.cn/server/internal/code"
	"xiandeng.net.cn/server/internal/services"
	"xiandeng.net.cn/server/tasks/server"
)

type PaymentController struct {
	*Controller
	paymentService services.PaymentGeneralService
}

func NewPaymentController(
	controller *Controller,
	paymentService services.PaymentGeneralService,
	taskClient server.TaskClient,
	repo db.Repository) *PaymentController {
	return &PaymentController{
		Controller:     controller,
		paymentService: paymentService,
	}
}

type BodyRevokePayment struct {
	OrderId           int64 `json:"order_id" form:"order_id"`
	RetainEntitlement bool  `json:"retain_entitlement" form:"retain_entitlement"`
}

func (c *PaymentController) RevokePayment() app.HandlerFunc {
	return func(ctx app.Context) {
		var body BodyRevokePayment
		if err := ctx.ShouldBind(&body); err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		err := c.paymentService.RevokePayment(ctx.RequestContext(), int(body.OrderId), body.RetainEntitlement)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessCreateJSON("ok")
	}
}
