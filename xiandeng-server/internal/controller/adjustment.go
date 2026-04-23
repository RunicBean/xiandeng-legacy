package controller

import (
	"net/http"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
	"go.uber.org/zap/zapcore"
	"xiandeng.net.cn/server/db/models"
	"xiandeng.net.cn/server/internal/app"
	"xiandeng.net.cn/server/internal/code"
	"xiandeng.net.cn/server/internal/services"
)

type AdjustmentController struct {
	*Controller
	adjustmentService services.AdjustmentService
}

func NewAdjustmentController(controller *Controller, service services.AdjustmentService) *AdjustmentController {
	return &AdjustmentController{
		Controller:        controller,
		adjustmentService: service,
	}
}

type InsertAdjustmentRequest struct {
	AccountId   uuid.UUID                 `json:"account_id" binding:"required"`
	Amount      decimal.Decimal           `json:"amount" binding:"required"`
	BalanceType models.Accountbalancetype `json:"balance_type" binding:"required"`
	Notes       string                    `json:"notes" binding:"required"`
}

func (req InsertAdjustmentRequest) MarshalLogObject(enc zapcore.ObjectEncoder) error {
	enc.AddString("account_id", req.AccountId.String())
	enc.AddString("amount", req.Amount.String())
	enc.AddString("balance_type", string(req.BalanceType))
	enc.AddString("notes", req.Notes)
	return nil
}

// InsertAdjustment
// @summary InsertAdjustment
// @description InsertAdjustment
// @Tags Adjustment
// @Accept application/json
// @Produce application/json
// @Param body body InsertAdjustmentRequest true "InsertAdjustmentRequest"
// @Router /adjustment/insert [post]
func (c *AdjustmentController) InsertAdjustment() app.HandlerFunc {
	return func(ctx app.Context) {
		var req InsertAdjustmentRequest
		if err := ctx.ShouldBind(&req); err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}

		// 获取当前操作用户ID
		operateUserId := ctx.User().ID

		err := c.adjustmentService.InsertAdjustment(
			ctx.RequestContext(),
			req.AccountId,
			req.Amount,
			req.BalanceType,
			req.Notes,
			operateUserId,
		)
		if err != nil {
			ctx.AbortWithStatusJSON(
				http.StatusInternalServerError,
				code.ServerInternalErr,
				"adjustmentService.InsertAdjustment",
				err,
				req,
			)
			return
		}

		ctx.SuccessJSON(map[string]string{
			"message": "Adjustment inserted successfully",
		})
	}
}

// ListAdjustmentRecords
// @summary ListAdjustmentRecords
// @description ListAdjustmentRecords
// @Tags Adjustment
// @Accept application/json
// @Produce application/json
// @Router /adjustment/list [get]
func (c *AdjustmentController) ListAdjustmentRecords() app.HandlerFunc {
	return func(ctx app.Context) {
		records, err := c.adjustmentService.ListAdjustmentRecords(ctx.RequestContext())
		if err != nil {
			ctx.AbortWithStatusJSON(
				http.StatusInternalServerError,
				code.ServerInternalErr,
				"adjustmentService.ListAdjustmentRecords",
				err,
				nil,
			)
			return
		}

		ctx.SuccessJSON(records)
	}
}
