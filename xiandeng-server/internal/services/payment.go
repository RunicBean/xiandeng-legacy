package services

import (
	"context"
	"fmt"
	"regexp"
	"strconv"
	"strings"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
	"xiandeng.net.cn/server/db"
	"xiandeng.net.cn/server/db/models"
	"xiandeng.net.cn/server/pkg/config"
	"xiandeng.net.cn/server/pkg/log"
	"xiandeng.net.cn/server/pkg/payment"
)

type PaymentGeneralService interface {
	GenerateSimpleOrder(ctx context.Context, params payment.OrderCreateParams) (*int, *decimal.Decimal, error)
	RevokePayment(ctx context.Context, orderId int, retainEntitlement bool) error
}

type paymentGeneralService struct {
	*Service
}

func NewPaymentGeneralService(conf *config.Config, logger *log.Logger, repo db.Repository) PaymentGeneralService {
	return &paymentGeneralService{
		Service: NewService(conf, logger, repo),
	}
}

func (s *paymentGeneralService) GenerateSimpleOrder(ctx context.Context, params payment.OrderCreateParams) (*int, *decimal.Decimal, error) {
	// 目前只考虑单商品购买
	if len(params.Products) != 1 {
		return nil, nil, fmt.Errorf("unimplemented multiple products")
	}

	var theProduct = params.Products[0]

	var generalCouponCodeNum int64
	var generalCouponExists bool
	if params.GeneralCoupon == "" {
		generalCouponCodeNum = 0
		generalCouponExists = false
	} else {
		d, err := strconv.Atoi(params.GeneralCoupon)
		if err != nil {
			return nil, nil, fmt.Errorf("couponcode %s is not valid number", params.GeneralCoupon)
		}
		generalCouponCodeNum = int64(d)
		generalCouponExists = true
	}

	ret, err := s.repo.NewQueries().GenerateSimpleOrder(ctx, models.GenerateSimpleOrderParams{
		Productid:    uuid.MustParse(theProduct.Id),
		Studentid:    uuid.MustParse(params.StudentId),
		Couponcode:   generalCouponCodeNum,
		Couponexists: generalCouponExists,
	})
	if err != nil {
		return nil, nil, fmt.Errorf("GenerateSimpleOrder: %v", err)
	}
	c := regexp.MustCompile(`\((.*?),(.*?),(.*?)\)`)
	subStr := c.FindAllStringSubmatch(*ret, 3)
	if errStr := subStr[0][3]; strings.ReplaceAll(errStr, `"`, "") != "" {
		return nil, nil, fmt.Errorf(errStr)
	}
	fmt.Printf("generate order result: %v", subStr)

	orderNumber, err := strconv.Atoi(subStr[0][1])
	if err != nil {
		return nil, nil, fmt.Errorf("ordernumber return value invalid: %v", subStr[0][1])
	}
	fmt.Printf("创建订单：%d", orderNumber)
	actualPrice := subStr[0][2]
	totalAmountDec, err := decimal.NewFromString(actualPrice)
	if err != nil {
		return nil, nil, fmt.Errorf("actualprice return value invalid: %v", subStr[0][2])
	}
	return &orderNumber, &totalAmountDec, nil
}

func (s *paymentGeneralService) RevokePayment(ctx context.Context, orderId int, retainEntitlement bool) error {
	_, err := s.repo.NewQueries().RevokePay(ctx, models.RevokePayParams{
		Orderid:           int64(orderId),
		Retainentitlement: retainEntitlement,
	})
	return err
}
