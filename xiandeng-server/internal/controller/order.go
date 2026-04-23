package controller

import (
	"fmt"
	"net/http"
	"slices"
	"strconv"

	"github.com/go-playground/validator/v10"
	"github.com/google/uuid"
	"github.com/shopspring/decimal"
	"xiandeng.net.cn/server/db"
	"xiandeng.net.cn/server/db/models"
	"xiandeng.net.cn/server/internal/app"
	"xiandeng.net.cn/server/internal/code"
	"xiandeng.net.cn/server/internal/services"
	"xiandeng.net.cn/server/pkg/log"
	"xiandeng.net.cn/server/pkg/payment"
	"xiandeng.net.cn/server/tasks/server"
)

type OrderController struct {
	*Controller
	orderService   services.OrderService
	paymentService services.PaymentGeneralService
	taskClient     server.TaskClient
	repo           db.Repository
	validate       *validator.Validate
}

func NewOrderController(
	controller *Controller,
	service services.OrderService,
	paymentService services.PaymentGeneralService,
	taskClient server.TaskClient,
	repo db.Repository,
	validate *validator.Validate) *OrderController {
	return &OrderController{
		Controller:     controller,
		orderService:   service,
		taskClient:     taskClient,
		paymentService: paymentService,
		repo:           repo,
		validate:       validate,
	}
}

type BodyCreateOrder struct {
	Products          []payment.ProductParams `json:"product_coupon_pairs" form:"product_coupon_pairs"`
	GeneralCouponCode string                  `json:"general_coupon_code" form:"general_coupon_code"`
}

func (c *OrderController) CreateOrder() app.HandlerFunc {
	return func(ctx app.Context) {
		var body BodyCreateOrder
		err := ctx.ShouldBind(&body)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		orderNumber, _, err := c.paymentService.GenerateSimpleOrder(ctx.RequestContext(), payment.OrderCreateParams{
			StudentId:     ctx.Account().ID.String(),
			Products:      body.Products,
			GeneralCoupon: body.GeneralCouponCode,
		})

		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.PaymentCreateError, err.Error(), err)
			return
		}
		ctx.SuccessCreateJSON(orderNumber)
	}
}

func (c *OrderController) ConfirmOfflineOrderSucceeded() app.HandlerFunc {
	return func(ctx app.Context) {
		var body BodyConfirmOfflinePaymentSucceeded
		err := ctx.ShouldBind(&body)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		result, err := c.orderService.ConfirmOfflineOrderSucceeded(ctx.RequestContext(), body.OrderId, body.PaymentMethod, body.RevokePay, body.ForceSettle)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.ServerInternalErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(result)
	}
}

type BodyDeclineOrder struct {
	OrderId int64 `json:"order_id" form:"order_id"`
}

func (c *OrderController) DeclineOrder() app.HandlerFunc {
	return func(ctx app.Context) {
		var body BodyDeclineOrder
		err := ctx.ShouldBind(&body)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		_, err = c.repo.NewQueries().DeclineOrder(ctx.RequestContext(), body.OrderId)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.ServerInternalErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON("ok")
	}
}

func (c *OrderController) SimpleDeclineOrder() app.HandlerFunc {
	return func(ctx app.Context) {
		var body BodyDeclineOrder
		err := ctx.ShouldBind(&body)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		err = c.orderService.SimpleDeclineOrder(ctx.RequestContext(), body.OrderId)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.ServerInternalErr, err.Error(), err)
		}
		ctx.SuccessCreateJSON("ok")
	}
}

type BodyUpdateOrderPrice struct {
	OrderId     int64  `json:"order_id" form:"order_id"`
	ActualPrice string `json:"actual_price" form:"actual_price"`
}

func (c *OrderController) UpdateOrderPrice() app.HandlerFunc {
	return func(ctx app.Context) {
		var body BodyUpdateOrderPrice
		err := ctx.ShouldBind(&body)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		actualPrice, err := decimal.NewFromString(body.ActualPrice)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		err = c.orderService.UpdateOrderActualPrice(ctx.RequestContext(), body.OrderId, actualPrice)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.ServerInternalErr, err.Error(), err)
			return
		}
		ctx.SuccessCreateJSON("ok")
	}
}

// ListOrders 列出订单
// @Summary 列出订单
// @Description 列出订单
// @Tags 商品
// @Success 200 {object} controller.ResponseJsonResult
// @Produce application/json
// @Security ApiKeyAuth
// @Router /order/list [get]
func (c *OrderController) ListOrders() app.HandlerFunc {
	return func(ctx app.Context) {
		orders, err := c.repo.NewQueries().ListOrders(ctx.RequestContext())
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.RecordNotFound, err.Error(), err)
			return
		}
		ctx.SuccessJSON(orders)
	}
}

type BodySearchOrders struct {
	StudentName     *string  `json:"student_name" form:"student_name"`
	AgentName       *string  `json:"agent_name" form:"agent_name"`
	ProductName     *string  `json:"product_name" form:"product_name"`
	UpdateatStart   *string  `json:"updateat_start" form:"updateat_start"`
	UpdateatEnd     *string  `json:"updateat_end" form:"updateat_end"`
	PriceRangeStart *float32 `json:"price_range_start" form:"price_range_start"`
	PriceRangeEnd   *float32 `json:"price_range_end" form:"price_range_end"`
	PaymentMethod   *string  `json:"payment_method" form:"payment_method"`
	StatusList      []string `json:"status_list" form:"status_list"`
}

// SearchOrders 搜索订单
// @Summary 列出订单
// @Description 搜索订单
// @Tags 商品
// @Param BodySearchOrders body BodySearchOrders true "1"
// @Success 200 {object} controller.ResponseJsonResult
// @Produce application/json
// @Security ApiKeyAuth
// @Router /order/search [post]
func (c *OrderController) SearchOrders() app.HandlerFunc {
	return func(ctx app.Context) {
		var body BodySearchOrders
		err := ctx.ShouldBind(&body)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}

		searchOrderParams := models.SearchOrdersParams{}

		if body.PaymentMethod != nil && *body.PaymentMethod != "" {
			searchOrderParams.Paymentmethod = body.PaymentMethod
		}

		if body.UpdateatStart != nil && *body.UpdateatStart != "" {
			searchOrderParams.Updateatstart = body.UpdateatStart
		}

		if body.UpdateatEnd != nil && *body.UpdateatEnd != "" {
			searchOrderParams.Updateatend = body.UpdateatEnd
		}

		if body.StudentName != nil && *body.StudentName != "" {
			a := "%" + *body.StudentName + "%"
			searchOrderParams.Studentname = &a
		}

		if body.AgentName != nil && *body.AgentName != "" {
			a := "%" + *body.AgentName + "%"
			searchOrderParams.Agentname = &a
		}

		if body.ProductName != nil && *body.ProductName != "" {
			a := "%" + *body.ProductName + "%"
			searchOrderParams.Productnamepattern = &a
		}
		if body.PriceRangeStart != nil && *body.PriceRangeStart != 0 {
			searchOrderParams.Pricerangestart = decimal.NewNullDecimal(decimal.NewFromFloat32(*body.PriceRangeStart))
		}
		if body.PriceRangeEnd != nil && *body.PriceRangeEnd != 0 {
			searchOrderParams.Pricerangeend = decimal.NewNullDecimal(decimal.NewFromFloat32(*body.PriceRangeEnd))
		}
		if body.StatusList != nil && len(body.StatusList) > 0 {
			searchOrderParams.StatusList = body.StatusList
		}

		orders, err := c.repo.NewQueries().SearchOrders(ctx.RequestContext(), searchOrderParams)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(orders)
	}
}

type BodyUpdateOrder struct {
	PaymentMethodDoUpdate   bool    `json:"payment_method_do_update" form:"payment_method_do_update"`
	PaymentMethod           *string `json:"payment_method" form:"payment_method"`
	PaymentMethodUpdateNull bool    `json:"payment_method_update_null" form:"payment_method_update_null"`
	StatusDoUpdate          bool    `json:"status_do_update" form:"status_do_update"`
	Status                  *string `json:"status" form:"status"`
	UpdatedAtToNow          bool    `json:"updatedat_to_now" form:"updatedat_to_now"`
	OrderId                 int64   `json:"order_id" form:"order_id"`
}

func (c *OrderController) UpdateOrder() app.HandlerFunc {
	return func(ctx app.Context) {
		var body BodyUpdateOrder
		err := ctx.ShouldBind(&body)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		// 处理参数
		if body.PaymentMethod == nil {
			body.PaymentMethodDoUpdate = false
			s := ""
			body.PaymentMethod = &s
		}
		if body.Status == nil {
			body.StatusDoUpdate = false
			s := ""
			body.Status = &s
		}
		_, err = c.repo.NewQueries().UpdateOrder(ctx.RequestContext(), models.UpdateOrderParams{
			Paymentmethoddoupdate:   body.PaymentMethodDoUpdate,
			Paymentmethod:           *body.PaymentMethod,
			Paymentmethodupdatenull: body.PaymentMethodUpdateNull,
			Statusdoupdate:          body.StatusDoUpdate,
			Status:                  *body.Status,
			Updatedattonow:          body.UpdatedAtToNow,
			Orderid:                 body.OrderId,
		})
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessCreateJSON("ok")
	}
}

func (c *OrderController) ListPaymentMethods() app.HandlerFunc {
	return func(ctx app.Context) {
		pms, err := c.repo.NewQueries().ListPaymentMethods(ctx.RequestContext())
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		ctx.SuccessJSON(pms)
	}
}

// @Route /order/liuliustatements [get]
func (c *OrderController) ListLiuliustatementByOrderId() app.HandlerFunc {
	return func(ctx app.Context) {
		var body struct {
			OrderId int64 `json:"order_id" form:"order_id"`
		}
		err := ctx.ShouldBindQuery(&body)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		liuliustatement, err := c.repo.NewQueries().ListLiuliustatementByOrderId(ctx.RequestContext(), &body.OrderId)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		ctx.SuccessJSON(liuliustatement)
	}
}

type BodyPaySuccess struct {
	OrderId int64 `json:"order_id" form:"order_id"`
}

func (c *OrderController) PaySuccess() app.HandlerFunc {
	return func(ctx app.Context) {
		var body BodyPaySuccess
		err := ctx.ShouldBind(&body)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		orderStatus, err := c.orderService.PaySuccess(ctx.RequestContext(), body.OrderId)
		if err != nil {
			ctx.LogWarn("pay success failed", err, log.SimpleMapParam{"order_id": strconv.Itoa(int(body.OrderId))})
			ctx.Abort(http.StatusInternalServerError, code.OrderUpdateError, fmt.Sprintf("order_id: %d, error: %s", body.OrderId, err.Error()))
			return
		}
		ctx.SuccessJSON(orderStatus)
	}
}

type BodyGenerateSimpleOrderWithPaymentMethod struct {
	CurrentUser   *bool      `json:"current_user" form:"current_user" validate:"required_without=StudentId"`
	StudentId     *uuid.UUID `json:"student_id" form:"student_id" validate:"required_without=CurrentUser"`
	ProductId     uuid.UUID  `json:"product_id" form:"product_id"`
	PaymentMethod string     `json:"payment_method" form:"payment_method"`
}

func (c *OrderController) GenerateSimpleOrderWithPaymentMethod() app.HandlerFunc {
	return func(ctx app.Context) {
		var body BodyGenerateSimpleOrderWithPaymentMethod
		err := ctx.ShouldBind(&body)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		err = c.validate.Struct(body)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		if body.CurrentUser != nil && *body.CurrentUser {
			acctId, err := c.repo.NewQueries().GetStudentAccountIdByUserId(ctx.RequestContext(), ctx.User().ID)
			if err != nil {
				ctx.AbortWithBadRequest(err, log.SimpleMapParam{"user_id": ctx.User().ID.String()})
				return
			}
			body.StudentId = &acctId
		}
		data, err := c.orderService.GenerateSimpleOrderWithPaymentMethod(
			ctx.RequestContext(),
			body.ProductId,
			*body.StudentId,
			false,
			0,
			body.PaymentMethod,
		)
		if err != nil {
			ctx.AbortWithBadRequest(err, log.SimpleMapParam{
				"student_id":     body.StudentId.String(),
				"product_id":     body.ProductId.String(),
				"payment_method": body.PaymentMethod,
			})
			return
		}
		ctx.SuccessCreateJSON(data)
	}
}

func (c *OrderController) ListRestrictedOrders() app.HandlerFunc {
	return func(ctx app.Context) {
		acct := ctx.Account()
		orders, err := c.repo.NewQueries().ListRestrictedOrders(ctx.RequestContext(), acct.ID)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		var tags []string
		for _, order := range orders {
			if order.Tags == nil {
				continue
			}
			for _, tag := range order.Tags.([]interface{}) {
				if !slices.Contains(tags, tag.(string)) {
					tags = append(tags, tag.(string))
				}
			}
		}
		ctx.SuccessJSON(map[string]any{
			"meta": map[string]any{
				"tags": tags,
			},
			"orders": orders,
		})
	}
}

func (c *OrderController) ListRestrictedOrdersByReferral() app.HandlerFunc {
	return func(ctx app.Context) {
		acct := ctx.Account()
		user := ctx.User()
		orders, err := c.repo.NewQueries().ListRestrictedOrdersByReferral(ctx.RequestContext(), models.ListRestrictedOrdersByReferralParams{
			Accountid:      acct.ID,
			Referraluserid: user.ID,
		})
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		var tags []string
		for _, order := range orders {
			if order.Tags == nil {
				continue
			}
			for _, tag := range order.Tags.([]interface{}) {
				if !slices.Contains(tags, tag.(string)) {
					tags = append(tags, tag.(string))
				}
			}
		}
		ctx.SuccessJSON(map[string]any{
			"meta": map[string]any{
				"tags": tags,
			},
			"orders": orders,
		})
	}
}

func (c *OrderController) InsertOrderTags() app.HandlerFunc {
	return func(ctx app.Context) {
		var body struct {
			OrderId []int64  `json:"order_ids" form:"order_ids"`
			Tags    []string `json:"tags" form:"tags"`
		}
		err := ctx.ShouldBind(&body)
		if err != nil || len(body.OrderId) == 0 || len(body.Tags) == 0 {
			ctx.AbortWithBadRequest(err)
			return
		}
		var inserts = make([]models.InsertOrderTagsParams, 0)
		for _, orderId := range body.OrderId {
			for _, tag := range body.Tags {
				inserts = append(inserts, models.InsertOrderTagsParams{Orderid: orderId, Tag: tag})
			}
		}
		cnt, err := c.repo.NewQueries().InsertOrderTags(ctx.RequestContext(), inserts)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		ctx.SuccessJSON(cnt)
	}
}

func (c *OrderController) DeleteOrderTags() app.HandlerFunc {
	return func(ctx app.Context) {
		//orderId := ctx.Param("orderid")
		var body struct {
			OrderIds []int64 `json:"order_ids" form:"order_ids"`
		}
		err := ctx.ShouldBind(&body)
		if err != nil || len(body.OrderIds) == 0 {
			ctx.AbortWithBadRequest(err)
			return
		}
		err = c.repo.NewQueries().RemoveTagsForOrder(ctx.RequestContext(), body.OrderIds)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		ctx.SuccessJSON("ok")
	}
}
