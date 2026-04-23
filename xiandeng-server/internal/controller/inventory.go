package controller

import (
	"fmt"
	"net/http"
	"strconv"

	"github.com/go-playground/validator/v10"
	"github.com/google/uuid"
	"xiandeng.net.cn/server/db/models"
	"xiandeng.net.cn/server/internal/app"
	"xiandeng.net.cn/server/internal/code"
	"xiandeng.net.cn/server/internal/services"
	"xiandeng.net.cn/server/pkg/log"
)

type InventoryController struct {
	*Controller
	service  services.InventoryService
	validate *validator.Validate
}

func NewInventoryController(controller *Controller, service services.InventoryService, validate *validator.Validate) *InventoryController {
	return &InventoryController{
		Controller: controller,
		service:    service,
		validate:   validate,
	}
}

type BodyCreateInventoryOrder struct {
	ProductID string `json:"product_id" form:"product_id"`
	Quantity  int32  `json:"quantity" form:"quantity"`
	OrderType string `json:"order_type" form:"order_type"`
	// productId uuid.UUID,
	// quantity int32,
	// _type models.Inventoryordertype,
	// status models.Inventoryorderstatus,
}

func (c *InventoryController) CreateInventoryOrder() app.HandlerFunc {
	return func(ctx app.Context) {
		var body BodyCreateInventoryOrder
		if err := ctx.ShouldBind(&body); err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		ioId, err := c.service.CreateInventoryOrder(ctx.RequestContext(), ctx.Account().ID, uuid.MustParse(body.ProductID), body.Quantity, models.Inventoryordertype(body.OrderType), models.Inventoryorderstatus("pending"))
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err, log.SimpleMapParam{
				"account_id": ctx.Account().ID.String(),
				"product_id": body.ProductID,
				"quantity":   strconv.Itoa(int(body.Quantity)),
				"order_type": body.OrderType,
			})
			return
		}
		ctx.SuccessCreateJSON(ioId)
	}
}

type QueryGetMaximumQuantity struct {
	CurrentUser *bool      `json:"current_user" form:"current_user" validate:"required_without=AccountId"`
	AccountId   *uuid.UUID `json:"account_id" form:"account_id" validate:"required_without=CurrentUser"`
	ProductID   string     `json:"product_id" form:"product_id"`
}

func (c *InventoryController) GetMaximumQuantity() app.HandlerFunc {
	return func(ctx app.Context) {
		var query QueryGetMaximumQuantity
		if err := ctx.ShouldBindQuery(&query); err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}

		err := c.validate.Struct(query)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		var accountId uuid.UUID
		if query.CurrentUser != nil && *query.CurrentUser {
			accountId = ctx.Account().ID
		} else {
			accountId = *query.AccountId
		}

		quantity, err := c.service.GetMaximumQuantity(ctx.RequestContext(), accountId, uuid.MustParse(query.ProductID))
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(quantity)
	}
}

type QueryListInventory struct {
	AccountID   *uuid.UUID `json:"account_id" form:"account_id" validate:"required_without=CurrentUser"`
	CurrentUser *bool      `json:"current_user" form:"current_user" validate:"required_without=AccountId"`
}

func (c *InventoryController) ListInventory() app.HandlerFunc {
	return func(ctx app.Context) {
		var query QueryListInventory
		if err := ctx.ShouldBind(&query); err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		err := c.validate.Struct(query)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		if query.CurrentUser != nil && *query.CurrentUser {
			query.AccountID = &ctx.Account().ID
		}
		list, err := c.service.ListInventory(ctx.RequestContext(), *query.AccountID)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(list)
	}
}

func (c *InventoryController) ConfirmInventoryOrder() app.HandlerFunc {
	return func(ctx app.Context) {
		ioId := ctx.Param("io_id")
		err := c.service.ConfirmInventoryOrder(ctx.RequestContext(), ioId)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON("ok")
	}
}

func (c *InventoryController) UpdateInventoryOrderPaymentMethod() app.HandlerFunc {
	return func(ctx app.Context) {
		var body struct {
			PaymentMethod string `json:"payment_method" form:"payment_method"`
		}
		if err := ctx.ShouldBind(&body); err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		err := c.service.UpdateInventoryOrderPaymentMethod(ctx.RequestContext(), ctx.Param("io_id"), body.PaymentMethod)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON("updated")
	}
}

type QueryAccountId struct {
	AccountID   *uuid.UUID `json:"account_id" form:"account_id" validate:"required_without=CurrentUser"`
	CurrentUser *bool      `json:"current_user" form:"current_user" validate:"required_without=AccountId"`
}

func (c *InventoryController) InventoryCourseOrders() app.HandlerFunc {
	return func(ctx app.Context) {
		var query QueryAccountId
		if err := ctx.ShouldBindQuery(&query); err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		err := c.validate.Struct(query)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		if query.CurrentUser != nil && *query.CurrentUser {
			query.AccountID = &ctx.Account().ID
		}
		list, err := c.service.InventoryCourseOrders(ctx.RequestContext(), *query.AccountID)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(list)
	}
}

func (c *InventoryController) GetInventoryActivities() app.HandlerFunc {
	return func(ctx app.Context) {
		var query QueryAccountId
		if err := ctx.ShouldBindQuery(&query); err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		err := c.validate.Struct(query)
		if err != nil {
			ctx.AbortWithBadRequest(err)
		}
		if query.CurrentUser != nil && *query.CurrentUser {
			query.AccountID = &ctx.Account().ID
		}
		list, err := c.service.GetInventoryActivities(ctx.RequestContext(), *query.AccountID)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(list)
	}
}

func (c *InventoryController) ListInventoriesForHQ() app.HandlerFunc {
	return func(ctx app.Context) {
		list, err := c.service.ListInventoriesForHQ(ctx.RequestContext())
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(list)
	}
}

type BodyUpdateInventoryOrderStatus struct {
	Status models.Inventoryorderstatus `json:"status" form:"status"`
}

func (c *InventoryController) UpdateInventoryOrderStatus() app.HandlerFunc {
	return func(ctx app.Context) {
		ioId := ctx.Param("io_id")
		var body BodyUpdateInventoryOrderStatus
		err := ctx.ShouldBind(&body)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		err = c.service.UpdateInventoryOrderStatus(ctx.RequestContext(), ioId, body.Status)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(fmt.Sprintf("updated: %s", ioId))
	}
}
