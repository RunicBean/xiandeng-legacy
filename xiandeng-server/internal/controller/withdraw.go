package controller

import (
	"fmt"
	"net/http"

	"github.com/go-playground/validator/v10"
	"github.com/google/uuid"
	"github.com/shopspring/decimal"
	"xiandeng.net.cn/server/db/models"
	"xiandeng.net.cn/server/internal/app"
	"xiandeng.net.cn/server/internal/code"
	"xiandeng.net.cn/server/internal/services"
)

type WithdrawController struct {
	*Controller
	withdrawService services.WithdrawService
	validate        *validator.Validate
}

func NewWithdrawController(
	controller *Controller,
	service services.WithdrawService,
	validate *validator.Validate) *WithdrawController {
	return &WithdrawController{
		Controller:      controller,
		withdrawService: service,
		validate:        validate,
	}
}

type CreateBankWithdrawMethodBody struct {
	CurrentUser   *bool   `json:"current_user" form:"current_user" validate:"required_without=UserId"`
	UserId        *string `json:"user_id" form:"user_id" validate:"required_without=CurrentUser"`
	BankName      string  `json:"bank_name" form:"bank_name"`
	AccountNumber string  `json:"account_number" form:"account_number" validate:"card-number"`
	AccountName   string  `json:"account_name" form:"account_name"`
}

func (c *WithdrawController) CreateBankWithdrawMethod() app.HandlerFunc {
	return func(ctx app.Context) {

		var body CreateBankWithdrawMethodBody
		err := ctx.ShouldBind(&body)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		validateErr := c.validate.Struct(body)
		if validateErr != nil {
			ctx.AbortWithBadRequest(validateErr)
			return
		}
		var userId uuid.UUID
		if body.CurrentUser != nil && *body.CurrentUser {
			userId = ctx.User().ID
		} else if body.UserId != nil {
			userId, err = uuid.Parse(*body.UserId)
			if err != nil {
				ctx.AbortWithBadRequest(fmt.Errorf("userid parsing error: %v", err.Error()))
				return
			}
		} else {
			ctx.AbortWithBadRequest(fmt.Errorf("current user or user id is required"))
			return
		}

		wmid, err := c.withdrawService.CreateBankWithdrawMethod(ctx.RequestContext(), userId, body.BankName, body.AccountNumber, body.AccountName)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessCreateJSON(wmid)
	}
}

type ListBankWithdrawMethodsQuery struct {
	CurrentUser *bool   `json:"current_user" form:"current_user" validate:"required_without=UserId"`
	UserId      *string `json:"user_id" form:"user_id" validate:"required_without=CurrentUser"`
}

func (c *WithdrawController) ListBankWithdrawMethods() app.HandlerFunc {
	return func(ctx app.Context) {
		var query ListBankWithdrawMethodsQuery
		err := ctx.ShouldBindQuery(&query)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		validateErr := c.validate.Struct(query)
		if validateErr != nil {
			ctx.AbortWithBadRequest(validateErr)
			return
		}
		var userId uuid.UUID
		if query.CurrentUser != nil && *query.CurrentUser {
			userId = ctx.User().ID
		} else if query.UserId != nil {
			userId, err = uuid.Parse(*query.UserId)
			if err != nil {
				ctx.AbortWithBadRequest(fmt.Errorf("userid parsing error: %v", err.Error()))
				return
			}
		} else {
			ctx.AbortWithBadRequest(fmt.Errorf("current user or user id is required"))
			return
		}

		methods, err := c.withdrawService.ListBankWithdrawMethods(ctx.RequestContext(), userId)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(methods)
	}
}

func (c *WithdrawController) DeleteWithdrawMethod() app.HandlerFunc {
	return func(ctx app.Context) {
		withdrawMethodId, err := uuid.Parse(ctx.Param("withdraw_method_id"))
		if err != nil {
			ctx.AbortWithBadRequest(fmt.Errorf("withdraw method id parsing error: %v", err.Error()))
			return
		}
		err = c.withdrawService.DeleteWithdrawMethod(ctx.RequestContext(), withdrawMethodId)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON("deleted")
	}
}

type UpdateBankWithdrawMethodBody struct {
	AccountName   string `json:"account_name" form:"account_name"`
	AccountNumber string `json:"account_number" form:"account_number" validate:"card-number"`
	BankName      string `json:"bank_name" form:"bank_name"`
}

func (c *WithdrawController) UpdateBankWithdrawMethod() app.HandlerFunc {
	return func(ctx app.Context) {
		withdrawMethodIdStr := ctx.Param("withdraw_method_id")
		withdrawMethodId, err := uuid.Parse(withdrawMethodIdStr)
		if err != nil {
			ctx.AbortWithBadRequest(fmt.Errorf("withdraw method id parsing error: %v", err.Error()))
			return
		}
		var body UpdateBankWithdrawMethodBody
		err = ctx.ShouldBind(&body)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		validateErr := c.validate.Struct(body)
		if validateErr != nil {
			ctx.AbortWithBadRequest(validateErr)
			return
		}
		err = c.withdrawService.UpdateWithdrawMethod(ctx.RequestContext(), withdrawMethodId, body.AccountName, body.AccountNumber, body.BankName)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON("updated")
	}
}

type CreateWithdrawBody struct {
	CurrentUser      bool                `json:"current_user" form:"current_user" validate:"required_without=UserId AccountId"`
	AccountId        uuid.UUID           `json:"account_id" form:"account_id" validate:"required_without=CurrentUser,uuid"`
	UserId           uuid.UUID           `json:"user_id" form:"user_id" validate:"required_without=CurrentUser,uuid"`
	WithdrawMethodId uuid.NullUUID       `json:"withdraw_method_id" form:"withdraw_method_id" validate:"required"`
	WithdrawType     models.Withdrawtype `json:"withdraw_type" form:"withdraw_type" validate:"required"`
	Amount           decimal.Decimal     `json:"amount" form:"amount" validate:"required"`
}

func (c *WithdrawController) CreateWithdraw() app.HandlerFunc {
	return func(ctx app.Context) {
		var body CreateWithdrawBody
		err := ctx.ShouldBind(&body)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		validateErr := c.validate.Struct(body)
		if validateErr != nil {
			ctx.AbortWithBadRequest(validateErr)
			return
		}
		var userId uuid.UUID
		var acctId uuid.UUID
		if body.CurrentUser {
			userId = ctx.User().ID
			acctId = ctx.Account().ID
		} else {
			userId = body.UserId
			acctId = body.AccountId
		}
		wid, err := c.withdrawService.CreateWithdraw(ctx.RequestContext(), userId, acctId, body.Amount, body.WithdrawMethodId, body.WithdrawType)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessCreateJSON(wid)
	}
}

type ListWithdrawQuery struct {
	CurrentUser    *bool                `json:"current_user" form:"current_user" validate:"required_without=UserId"`
	UserId         *string              `json:"user_id" form:"user_id" validate:"required_without=CurrentUser"`
	AccountId      *string              `json:"account_id" form:"account_id" validate:"required_without=CurrentUser"`
	WithdrawType   *models.Withdrawtype `json:"withdraw_type" form:"withdraw_type"`
	Status         *string              `json:"status" form:"status"`
	CreatedAtStart *string              `json:"created_at_start" form:"created_at_start"`
	CreatedAtEnd   *string              `json:"created_at_end" form:"created_at_end"`
	AmountLow      *decimal.Decimal     `json:"amount_low" form:"amount_low"`
	AmountHigh     *decimal.Decimal     `json:"amount_high" form:"amount_high"`
}

func (c *WithdrawController) ListWithdraw() app.HandlerFunc {
	return func(ctx app.Context) {
		var query ListWithdrawQuery
		err := ctx.ShouldBindQuery(&query)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		validateErr := c.validate.Struct(query)
		if validateErr != nil {
			ctx.AbortWithBadRequest(validateErr)
			return
		}
		var AccountId string
		var UserId string
		if *query.CurrentUser {
			AccountId = ctx.Account().ID.String()
			UserId = ctx.User().ID.String()
		} else {
			AccountId = *query.AccountId
			UserId = *query.UserId
		}

		var dbParams = models.ListWithdrawParams{
			Accountid:      &AccountId,
			Userid:         &UserId,
			Withdrawtype:   query.WithdrawType,
			Status:         query.Status,
			Createdatstart: query.CreatedAtStart,
			Createdatend:   query.CreatedAtEnd,
			Amountlow:      query.AmountLow,
			Amounthigh:     query.AmountHigh,
		}
		// if query.WithdrawType != nil {
		// 	dbParams.Withdrawtype = string(*query.WithdrawType)
		// } else {
		// 	dbParams.Withdrawtype = ""
		// }

		// if query.Status != nil {
		// 	dbParams.Status = *query.Status
		// } else {
		// 	dbParams.Status = ""
		// }

		// if query.CreatedAtStart != nil {
		// 	dbParams.Createdatstart = *query.CreatedAtStart
		// } else {
		// 	dbParams.Createdatstart = ""
		// }

		// if query.CreatedAtEnd != nil {
		// 	dbParams.Createdatend = *query.CreatedAtEnd
		// } else {
		// 	dbParams.Createdatend = ""
		// }
		// dbParams.Amountlow = query.AmountLow

		withdraws, err := c.withdrawService.ListWithdraw(ctx.RequestContext(), dbParams)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(withdraws)
	}
}
