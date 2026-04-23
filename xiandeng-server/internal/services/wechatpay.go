package services

import (
	"context"
	"fmt"
	"github.com/google/uuid"
	"github.com/shopspring/decimal"
	"github.com/wechatpay-apiv3/wechatpay-go/core"
	"github.com/wechatpay-apiv3/wechatpay-go/services/payments"
	"xiandeng.net.cn/server/db"
	"xiandeng.net.cn/server/db/models"
	"xiandeng.net.cn/server/pkg/config"
	"xiandeng.net.cn/server/pkg/log"
	"xiandeng.net.cn/server/pkg/payment"
	"xiandeng.net.cn/server/pkg/wechatpay"
)

type WechatpayService interface {
	CreateWechatPrepay(ctx context.Context, userId string, orderNumber int64) (*payment.Intent, *wechatpay.SignResult, error)
	GetPaymentByOrderId(ctx context.Context, orderId int64) (*payments.Transaction, error)
	ClosePayment(ctx context.Context, orderId int64) error
	Sign(prepayId string) (*wechatpay.SignResult, error)
	VerifyAndDecrypt(notifyPayload wechatpay.NotifyPayload) (*payments.Transaction, error)
}

type wechatpayService struct {
	*Service
	engine *wechatpay.WechatPayEngine
}

func NewWechatpayService(conf *config.Config, logger *log.Logger, repo db.Repository, engine *wechatpay.WechatPayEngine) WechatpayService {
	return &wechatpayService{
		Service: NewService(conf, logger, repo),
		engine:  engine,
	}
}

func (s *wechatpayService) CreateWechatPrepay(ctx context.Context, userId string, orderNumber int64) (*payment.Intent, *wechatpay.SignResult, error) {

	queries := s.repo.NewQueries()
	dbuser, err := queries.GetUser(ctx, uuid.MustParse(userId))
	if err != nil {
		return nil, nil, fmt.Errorf("parsePayerId: %x", err)
	}

	order, err := queries.GetOrder(ctx, orderNumber)
	if err != nil {
		return nil, nil, fmt.Errorf("cannot get order: %x", err)
	}
	// orderNumber, totalAmountDec, err := e.CreateOrder(db, ctx, params)

	// 拿到商品总价
	payingAmount := order.Price.Decimal.Mul(decimal.NewFromInt(100))
	payingAmtInt64 := core.Int64(payingAmount.BigInt().Int64())

	notifyUrl := fmt.Sprintf("https://%s/server/api/v1/wechatpay/webhook", s.conf.Server.WebDomain)
	intent, err := s.engine.CreatePayment(ctx, order.ID, *payingAmtInt64, *dbuser.Wechatopenid, payment.PaymentCreateParams{
		Payer: payment.Payer{
			Type: "",
			Id:   userId,
		},
		NotifyUrl:   notifyUrl,
		Description: "先登服务",
		OrderNumber: orderNumber,
	})

	if err != nil {
		return nil, nil, err
	}
	sign, err := s.engine.Sign(intent.PrePayID)
	return intent, sign, err
}

func (s *wechatpayService) ClosePayment(ctx context.Context, orderId int64) error {
	tx, qtx, err := s.repo.StartTransaction(ctx)
	defer tx.Rollback(ctx)
	if err != nil {
		return fmt.Errorf("start transaction: %x", err)
	}
	_, err = qtx.UpdateOrderStatus(ctx, models.UpdateOrderStatusParams{
		ID:     orderId,
		Status: &wechatpay.OrderStatusFailed,
	})
	if err != nil {
		return fmt.Errorf("update order status: %x", err)
	}
	err = s.engine.ClosePayment(ctx, orderId)
	if err != nil {
		return fmt.Errorf("close payment: %x", err)
	}
	err = tx.Commit(ctx)
	if err != nil {
		return err
	}
	return nil
}

func (s *wechatpayService) GetPaymentByOrderId(ctx context.Context, orderId int64) (*payments.Transaction, error) {
	return s.engine.GetPaymentByOrderId(ctx, orderId)
}

func (s *wechatpayService) Sign(prepayId string) (*wechatpay.SignResult, error) {
	return s.engine.Sign(prepayId)
}

func (s *wechatpayService) VerifyAndDecrypt(notifyPayload wechatpay.NotifyPayload) (*payments.Transaction, error) {
	return s.engine.VerifyAndDecrypt(notifyPayload)
}
