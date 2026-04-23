package controller

import (
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/jackc/pgx/v5/pgtype"
	"xiandeng.net.cn/server/db"
	"xiandeng.net.cn/server/db/models"
	"xiandeng.net.cn/server/internal/app"
	"xiandeng.net.cn/server/internal/code"
	"xiandeng.net.cn/server/internal/services"
	"xiandeng.net.cn/server/pkg/env"
	"xiandeng.net.cn/server/pkg/payment"
	"xiandeng.net.cn/server/pkg/wechatpay"
	//"xiandeng.net.cn/server/services/payment"
)

type WechatpayController struct {
	*Controller
	wechatpayService services.WechatpayService
	paymentService   services.PaymentGeneralService
	repo             db.Repository
}

func NewWechatpayController(
	controller *Controller,
	service services.WechatpayService,
	paymentService services.PaymentGeneralService,
	repo db.Repository) *WechatpayController {
	return &WechatpayController{
		Controller:       controller,
		wechatpayService: service,
		paymentService:   paymentService,
		repo:             repo,
	}
}

type BodyCreatePayment struct {
	OrderNumber int64 `json:"order_number" form:"order_number"`
}

type ResponseCreatePayment struct {
	Intent payment.Intent       `json:"intent"`
	Sign   wechatpay.SignResult `json:"sign"`
}

// CreateWechatpayPrepay 创建微信预订单
// @Summary 创建微信prepay
// @Description 创建微信prepay
// @Tags 支付
// @Param BodyCreatePayment body BodyCreatePayment true "请求体"
// @Success 201 {object} controller.ResponseJsonResult{data=ResponseCreatePayment}
// @Produce application/json
// @Security ApiKeyAuth
// @Router /wechatpay/prepay/create [post]
func (wc *WechatpayController) CreateWechatpayPrepay() app.HandlerFunc {
	return func(ctx app.Context) {
		var body BodyCreatePayment
		err := ctx.ShouldBind(&body)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		u := ctx.User()
		intent, signRes, err := wc.wechatpayService.CreateWechatPrepay(ctx.RequestContext(), u.ID.String(), body.OrderNumber)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.PaymentSignError, err.Error(), err)
			return
		}
		ctx.SuccessCreateJSON(ResponseCreatePayment{
			Intent: *intent,
			Sign:   *signRes,
		})
	}
}

type QueryGetPaymentByOrderId struct {
	OrderId int `json:"order_id" form:"order_id"`
}

// GetPaymentByOrderId 根据订单号获取微信交易
// @Summary 根据订单获取微信交易
// @Description 根据订单获取微信交易
// @Tags 支付
// @Param QueryGetPaymentByOrderId query QueryGetPaymentByOrderId true "请求体"
// @Success 200 {object} controller.ResponseJsonResult
// @Produce application/json
// @Security ApiKeyAuth
// @Router /payment [get]
func (wc *WechatpayController) GetPaymentByOrderId() app.HandlerFunc {
	return func(ctx app.Context) {
		var query QueryGetPaymentByOrderId
		err := ctx.ShouldBindQuery(&query)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		txn, err := wc.wechatpayService.GetPaymentByOrderId(ctx.RequestContext(), int64(query.OrderId))
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.ServerInternalErr, fmt.Sprintf("get payment: %v", err.Error()), err)
			return
		}
		ctx.SuccessJSON(txn)
	}
}

type BodyConfirmOfflinePaymentSucceeded struct {
	OrderId       int64  `json:"order_id" form:"order_id"`
	PaymentMethod string `json:"payment_method" form:"payment_method"`
	RevokePay     bool   `json:"revoke_pay" form:"revoke_pay"`
	ForceSettle   bool   `json:"force_settle" form:"force_settle"`
}

// ConfirmOrderSucceeded 根据订单号确认微信交易是否成功
// @Summary 根据订单号确认微信交易是否成功
// @Description 根据订单获取微信交易，并判断是否已成功，成功就会call stored procedure: pay_success
// @Tags 支付
// @Param QueryGetPaymentByOrderId body QueryGetPaymentByOrderId true "请求体"
// @Success 200 {object} controller.ResponseJsonResult
// @Produce application/json
// @Security ApiKeyAuth
// @Router /wechatpay/order/confirm [post]
func (wc *WechatpayController) ConfirmOrderSucceeded() app.HandlerFunc {
	return func(ctx app.Context) {
		var body QueryGetPaymentByOrderId
		err := ctx.ShouldBind(&body)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		if env.Active().IsDev() {
			ctx.SuccessJSON(wechatpay.TradeStateSuccess)
			return
		}
		txn, err := wc.wechatpayService.GetPaymentByOrderId(ctx.RequestContext(), int64(body.OrderId))
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.ServerInternalErr, fmt.Sprintf("get payment: %v", err.Error()), err)
			return
		}
		switch *txn.TradeState {
		case wechatpay.TradeStateSuccess:

			result, err := wc.repo.NewQueries().PaySuccess(ctx.RequestContext(), models.PaySuccessParams{
				Orderid:     int64(body.OrderId),
				Forcesettle: false,
			})
			if err != nil {
				ctx.AbortWithBadRequest(fmt.Errorf("PaySuccess failed: %v, result: %s", err.Error(), result))
				return
			}
			ctx.SuccessJSON(txn.TradeState)
			return
		case wechatpay.TradeStateNotpay:
			ctx.SuccessJSON(wechatpay.TradeStateNotpay)
			return
		case wechatpay.TradeStateClosed:
			// 关单
			err := wc.wechatpayService.ClosePayment(ctx.RequestContext(), int64(body.OrderId))
			if err != nil {
				ctx.AbortWithBadRequest(fmt.Errorf("ClosePayment failed: %v", err.Error()))
				return
			}
			ctx.SuccessJSON(txn.TradeState)
			return
		case wechatpay.TradeStateRefund:
			ctx.SuccessJSON(txn.TradeState)
			return
		default:
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.PaymentCommonError, fmt.Sprintf("invalid txn status: %s", *txn.TradeState), fmt.Errorf("invalid txn status: %s", *txn.TradeState))
			return
		}
	}
}

type BodyClosePayment struct {
	OrderId int64 `json:"order_id" form:"order_id"`
}

// ClosePayment 关闭订单
// @Summary 关闭订单
// @Description 关闭订单
// @Tags 支付
// @Param BodyClosePayment body BodyClosePayment true "请求体"
// @Success 200 {object} controller.ResponseJsonResult
// @Produce application/json
// @Security ApiKeyAuth
// @Router /wechatpay/payment/close [post]
func (wc *WechatpayController) ClosePayment() app.HandlerFunc {
	return func(ctx app.Context) {
		var body BodyClosePayment
		err := ctx.ShouldBind(&body)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		err = wc.wechatpayService.ClosePayment(ctx.RequestContext(), body.OrderId)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
		}
		ctx.SuccessJSON("ok")
	}
}

type BodySign struct {
	TimeStamp string `json:"timestamp" form:"timestamp"`
	PrepayID  string `json:"prepay_id" form:"prepay_id"`
}

// Sign 预订单签名
// @Summary 预订单签名
// @Description 预订单签名
// @Tags 支付
// @Param BodySign body BodySign true "请求体"
// @Success 200 {object} controller.ResponseJsonResult{data=wechatpay.SignResult}
// @Accept application/json
// @Produce application/json
// @Security ApiKeyAuth
// @Router /wechatpay/prepay/sign [post]
func (wc *WechatpayController) Sign() app.HandlerFunc {
	return func(ctx app.Context) {
		var body BodySign
		err := ctx.ShouldBind(&body)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		signResult, err := wc.wechatpayService.Sign(body.PrepayID)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.ServerInternalErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(signResult)
	}
}

func (wc *WechatpayController) WechatNotifyHandle() app.HandlerFunc {
	return func(ctx app.Context) {
		var p wechatpay.NotifyPayload
		err := ctx.ShouldBind(&p)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		d, err := wc.wechatpayService.VerifyAndDecrypt(p)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.PaymentVerifyFailed, err.Error(), err)
			return
		}
		orderId, err := strconv.Atoi(*d.OutTradeNo)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.PaymentCommonError, err.Error(), err)
			return
		}
		var latestOrderStatus string

		switch *d.TradeState {
		case wechatpay.TradeStateSuccess:
			latestOrderStatus = wechatpay.OrderStatusSuccess
			payTime, err := time.Parse("2006-01-02T15:04:05", *d.SuccessTime)
			if err != nil {
				ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.ServerInternalErr, fmt.Sprintf("time parse: %v", err.Error()), err)
				return
			}

			_, err = wc.repo.NewQueries().UpdateOrderAsPayed(ctx.RequestContext(), models.UpdateOrderAsPayedParams{
				ID: int64(orderId),
				Payat: pgtype.Timestamp{
					Time:  payTime,
					Valid: true,
				},
			})
			ctx.SuccessJSON(latestOrderStatus)
			return
		case wechatpay.TradeStateNotpay:
			// 关单
			latestOrderStatus = wechatpay.OrderStatusPending
		case wechatpay.TradeStateClosed:
			latestOrderStatus = wechatpay.OrderStatusFailed
		case wechatpay.TradeStateRefund:
			latestOrderStatus = wechatpay.OrderStatusRefund
		default:
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.PaymentCommonError, fmt.Sprintf("invalid txn status: %s", *d.TradeState), fmt.Errorf("invalid txn status: %s", *d.TradeState))
			return
		}

		_, err = wc.repo.NewQueries().UpdateOrderStatus(ctx.RequestContext(), models.UpdateOrderStatusParams{
			ID:     int64(orderId),
			Status: &latestOrderStatus,
		})
		if err != nil {
			fmt.Printf("order status update error: %v\n", err)
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.RecordUpdateError, err.Error(), err)
			return
		}
		ctx.SuccessJSON("ok")
	}
}

func (wc *WechatpayController) WechatNotifyTemp() app.HandlerFunc {
	return func(ctx app.Context) {
		ctx.SuccessJSON("ok")
	}
}
