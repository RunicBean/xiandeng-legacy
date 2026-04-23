package services

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
	"xiandeng.net.cn/server/db"
	"xiandeng.net.cn/server/db/models"
	"xiandeng.net.cn/server/pkg/config"
	"xiandeng.net.cn/server/pkg/log"
	"xiandeng.net.cn/server/tasks/server"
)

type OrderService interface {
	ConfirmOfflineOrderSucceeded(ctx context.Context, orderId int64, paymentMethod string, revokePay bool, forceSettle bool) (any, error)
	PaySuccess(ctx context.Context, orderId int64) (string, error)
	GenerateSimpleOrderWithPaymentMethod(ctx context.Context, productId uuid.UUID, studentId uuid.UUID, couponExists bool, couponCode int64, paymentMethod string) (*models.GenerateSimpleOrderWithPaymentMethodRow, error)
	SimpleDeclineOrder(ctx context.Context, orderId int64) error
	UpdateOrderActualPrice(ctx context.Context, orderId int64, actualPrice decimal.Decimal) error
}

type orderService struct {
	*Service
	tc server.TaskClient
}

func NewOrderService(conf *config.Config, logger *log.Logger, repo db.Repository, tc server.TaskClient) OrderService {
	return &orderService{
		Service: NewService(conf, logger, repo),
		tc:      tc,
	}
}

func (s *orderService) ConfirmOfflineOrderSucceeded(ctx context.Context, orderId int64, paymentMethod string, revokePay bool, forceSettle bool) (any, error) {
	tx, qtx, err := s.repo.StartTransaction(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)
	_, err = qtx.UpdateOrder(ctx, models.UpdateOrderParams{
		Paymentmethoddoupdate: true,
		Paymentmethod:         paymentMethod,
		Orderid:               orderId,
	})
	if err != nil {
		return nil, err
	}
	result, err := qtx.PaySuccess(ctx, models.PaySuccessParams{
		Orderid:     orderId,
		Forcesettle: forceSettle,
	})
	if err != nil {
		return nil, fmt.Errorf("pay success for order %d: %s", orderId, err.Error())
	}
	if result != "success" {
		return nil, fmt.Errorf("pay success for order %d: %s", orderId, result)
	}
	if revokePay {
		result, err := qtx.RevokePay(ctx, models.RevokePayParams{
			Orderid:           orderId,
			Retainentitlement: true,
		})
		if err != nil {
			return nil, fmt.Errorf("revoke pay for order %d: %s", orderId, err.Error())
		}
		if result.(string) != "success" {
			return nil, fmt.Errorf("revoke pay for order %d: %s", orderId, result)
		}
	}
	err = tx.Commit(ctx)
	if err != nil {
		return nil, err
	}
	return result, nil
}

func (s *orderService) PaySuccess(ctx context.Context, orderId int64) (string, error) {
	return s.repo.NewQueries().PaySuccess(ctx, models.PaySuccessParams{
		Orderid:     orderId,
		Forcesettle: false,
	})
}

func (s *orderService) GenerateSimpleOrderWithPaymentMethod(ctx context.Context, productId uuid.UUID, studentId uuid.UUID, couponExists bool, couponCode int64, paymentMethod string) (*models.GenerateSimpleOrderWithPaymentMethodRow, error) {
	return s.repo.NewQueries().GenerateSimpleOrderWithPaymentMethod(ctx, models.GenerateSimpleOrderWithPaymentMethodParams{
		Productid:     productId,
		Studentid:     studentId,
		Couponexists:  couponExists,
		Couponcode:    couponCode,
		Paymentmethod: paymentMethod,
	})
}

func (s *orderService) SimpleDeclineOrder(ctx context.Context, orderId int64) error {
	_, err := s.repo.NewQueries().SimpleDeclineOrder(ctx, orderId)
	return err
}

func (s *orderService) UpdateOrderActualPrice(ctx context.Context, orderId int64, actualPrice decimal.Decimal) error {
	tx, qtx, err := s.repo.StartTransaction(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)
	_, err = qtx.UpdateOrderPrice(ctx, models.UpdateOrderPriceParams{
		ID:    orderId,
		Price: decimal.NewNullDecimal(actualPrice),
	})
	if err != nil {
		return err
	}
	_, err = qtx.UpdateOrderProductPrice(ctx, models.UpdateOrderProductPriceParams{
		Orderid:     &orderId,
		Actualprice: decimal.NewNullDecimal(actualPrice),
	})
	if err != nil {
		return err
	}
	return tx.Commit(ctx)
}
