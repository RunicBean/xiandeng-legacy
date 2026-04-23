package controller

import (
	"fmt"
	"net/http"
	"strconv"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
	"github.com/xuri/excelize/v2"
	"xiandeng.net.cn/server/db"
	"xiandeng.net.cn/server/db/models"
	"xiandeng.net.cn/server/internal/app"
	"xiandeng.net.cn/server/internal/code"
	timeutil "xiandeng.net.cn/server/pkg/utils/time_util"
)

type WalletController struct {
	*Controller
	repo db.Repository
}

func NewWalletController(controller *Controller, repo db.Repository) *WalletController {
	return &WalletController{
		Controller: controller,
		repo:       repo,
	}
}

func (c *WalletController) GetBalance() app.HandlerFunc {
	return func(ctx app.Context) {
		b, err := c.repo.NewQueries().GetBalance(ctx.RequestContext(), ctx.Account().ID)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(b)
	}
}

type BalanceActivitySearchQuery struct {
	CreatedAtStart  *string  `json:"createdat_start" form:"createdat_start"`
	CreatedAtEnd    *string  `json:"createdat_end" form:"createdat_end"`
	Source          *string  `json:"source" form:"source"`
	PriceRangeStart *float64 `json:"price_range_start" form:"price_range_start"`
	PriceRangeEnd   *float64 `json:"price_range_end" form:"price_range_end"`
	ProductList     []string `json:"product_list" form:"product_list"`
	ID              *string  `json:"id" form:"id"`
}

func TransformParams(params BalanceActivitySearchQuery) (*models.ListBalanceActivityDetailsParams, error) {
	searchBalanceActivityParams := models.ListBalanceActivityDetailsParams{}
	if params.CreatedAtStart != nil && *params.CreatedAtStart != "" {
		searchBalanceActivityParams.Createdatstart = params.CreatedAtStart
	}
	if params.CreatedAtEnd != nil && *params.CreatedAtEnd != "" {
		searchBalanceActivityParams.Createdatend = params.CreatedAtEnd
	}
	if params.Source != nil && *params.Source != "" {
		searchBalanceActivityParams.Source = params.Source
	}
	if params.PriceRangeStart != nil {
		searchBalanceActivityParams.Pricerangestart = decimal.NewNullDecimal(decimal.NewFromFloat(*params.PriceRangeStart))
	}
	if params.PriceRangeEnd != nil {
		searchBalanceActivityParams.Pricerangeend = decimal.NewNullDecimal(decimal.NewFromFloat(*params.PriceRangeEnd))
	}
	if params.ProductList != nil && len(params.ProductList) > 0 {
		searchBalanceActivityParams.Productlist = params.ProductList
	}
	if params.ID != nil && *params.ID != "" {
		i, err := strconv.Atoi(*params.ID)
		if err != nil {
			return nil, err
		}
		ip := int64(i)
		searchBalanceActivityParams.ID = &ip
	}
	return &searchBalanceActivityParams, nil
}

// ListBalanceActivityDetails
// @summary ListBalanceActivityDetails
// @description ListBalanceActivityDetails
// @Tags Wallet
// @Accept application/json
// @Produce application/json
// @Param body query BalanceActivitySearchQuery true "BalanceActivitySearchQuery"
// @Router /wallet/balanceactivity/list [post]
func (c *WalletController) ListBalanceActivityDetails() app.HandlerFunc {
	return func(ctx app.Context) {
		params := BalanceActivitySearchQuery{}
		if err := ctx.ShouldBind(&params); err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		searchBalanceActivityParams, err := TransformParams(params)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		data, err := c.repo.NewQueries().ListBalanceActivityDetails(ctx.RequestContext(), *searchBalanceActivityParams)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(data)
	}
}

func (c *WalletController) ExportBalanceActivityDetails() app.HandlerFunc {
	return func(ctx app.Context) {
		params := BalanceActivitySearchQuery{}
		if err := ctx.ShouldBind(&params); err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		searchBalanceActivityParams, err := TransformParams(params)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		data, err := c.repo.NewQueries().ListBalanceActivityDetails(ctx.RequestContext(), *searchBalanceActivityParams)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		fi := excelize.NewFile()
		headers := []string{"ChildAccountname", "CreatedAt", "ProductName", "Amount", "BalanceAfter", "Source", "OrderId", "ChildAccountType"}
		fi.SetSheetRow("Sheet1", "A1", &headers)
		for idx, detail := range data {
			var detailData = []interface{}{
				timeutil.TimeInShanghai(detail.Createdat.Time).Format("2006-01-02 15:04:05"),
				*detail.Source,
				detail.Amount.Decimal.InexactFloat64(),
				detail.Balanceafter.Decimal.InexactFloat64(),
				detail.Balancetype,
				detail.Category,
				detail.Salesprovider,
				detail.Relatedorder,
			}
			err := fi.SetSheetRow("Sheet1", "A"+strconv.Itoa(idx+2), &detailData)
			if err != nil {
				ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
				return
			}
		}
		err = ctx.SuccessExcel(fi, fmt.Sprintf("balance_activity_%s.xlsx", timeutil.NowInShanghai().Format("20060102_150405")))

		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
	}
}

func (c *WalletController) ListMyBalanceActivityDetails() app.HandlerFunc {
	return func(ctx app.Context) {
		params := BalanceActivitySearchQuery{}
		if err := ctx.ShouldBind(&params); err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		searchBalanceActivityParams, err := TransformParams(params)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		searchBalanceActivityParams.Accountid = &ctx.Account().ID
		data, err := c.repo.NewQueries().ListBalanceActivityDetails(ctx.RequestContext(), *searchBalanceActivityParams)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(data)
	}
}

func (c *WalletController) ExportMyBalanceActivityDetails() app.HandlerFunc {
	return func(ctx app.Context) {
		params := BalanceActivitySearchQuery{}
		if err := ctx.ShouldBind(&params); err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		searchBalanceActivityParams, err := TransformParams(params)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		searchBalanceActivityParams.Accountid = &ctx.Account().ID
		data, err := c.repo.NewQueries().ListBalanceActivityDetails(ctx.RequestContext(), *searchBalanceActivityParams)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		fi := excelize.NewFile()
		headers := []string{
			"CreatedAt",
			"Source",
			"Amount",
			"BalanceAfter",
			"BalanceType",
			"Category",
			"SalesProvider",
			"RelatedOrder",
		}
		fi.SetSheetRow("Sheet1", "A1", &headers)
		for idx, detail := range data {
			var detailData = []interface{}{
				timeutil.TimeInShanghai(detail.Createdat.Time).Format("2006-01-02 15:04:05"),
				*detail.Source,
				detail.Amount.Decimal.InexactFloat64(),
				detail.Balanceafter.Decimal.InexactFloat64(),
				detail.Balancetype,
				detail.Category,
				detail.Salesprovider,
				detail.Relatedorder,
			}
			err := fi.SetSheetRow("Sheet1", "A"+strconv.Itoa(idx+2), &detailData)
			if err != nil {
				ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
				return
			}
		}
		err = ctx.SuccessExcel(fi, fmt.Sprintf("balance_activity_%s.xlsx", timeutil.NowInShanghai().Format("20060102_150405")))

		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
	}
}

type WithdrawStat struct {
	Sum               decimal.Decimal `json:"sum"`
	NoPendingWithdraw bool            `json:"no_pending"`
	RequestExist      bool            `json:"request_exist"`
}

func (c *WalletController) GetOngoingWithdrawAmount() app.HandlerFunc {
	return func(ctx app.Context) {
		var returns = map[models.Withdrawtype]WithdrawStat{
			models.WithdrawtypeBalance: {
				Sum:               decimal.NewFromInt(0),
				NoPendingWithdraw: true,
				RequestExist:      false,
			},
			models.WithdrawtypePartition: {
				Sum:               decimal.NewFromInt(0),
				NoPendingWithdraw: true,
				RequestExist:      false,
			},
			models.WithdrawtypeTriple: {
				Sum:               decimal.NewFromInt(0),
				NoPendingWithdraw: true,
				RequestExist:      false,
			},
		}
		withdraws, err := c.repo.NewQueries().GetOngoingWithdraws(ctx.RequestContext(), uuid.NullUUID{Valid: true, UUID: ctx.Account().ID})
		// if strings.Contains(err.Error(), "no rows in result set") {
		// 	ctx.SuccessJSON(initRet)
		// 	return
		// }
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		for _, w := range withdraws {
			thisW := returns[w.Type]
			thisW.NoPendingWithdraw = false
			if *w.Status == "REQUESTED" {
				thisW.RequestExist = true
			}
			thisW.Sum = thisW.Sum.Add(w.Amount.Decimal)
			returns[w.Type] = thisW
		}
		ctx.SuccessJSON(returns)
	}
}

func (c *WalletController) ListTripleAwardDetails() app.HandlerFunc {
	return func(ctx app.Context) {
		data, err := c.repo.NewQueries().ListTripleAwardDetails(ctx.RequestContext(), ctx.Account().ID)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(data)
	}
}

func (c *WalletController) ListTripleUnlockDetails() app.HandlerFunc {
	return func(ctx app.Context) {
		sourceId := ctx.Param("source_id")
		data, err := c.repo.NewQueries().ListTripleUnlockDetails(ctx.RequestContext(), uuid.MustParse(sourceId))
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(data)
	}
}
