package services

import (
	"context"
	"xiandeng.net.cn/server/db"
	"xiandeng.net.cn/server/db/models"
	"xiandeng.net.cn/server/pkg/config"
	"xiandeng.net.cn/server/pkg/log"
)

type CouponService interface {
	CreateCoupon(ctx context.Context, args models.CreateOrderCouponWithDbProcedureParams) (interface{}, error)
}

type couponService struct {
	*Service
}

func NewCouponService(conf *config.Config, logger *log.Logger, repo db.Repository) CouponService {
	return &couponService{
		Service: NewService(conf, logger, repo),
	}
}

func (s *couponService) CreateCoupon(ctx context.Context, args models.CreateOrderCouponWithDbProcedureParams) (interface{}, error) {
	return s.repo.NewQueries().CreateOrderCouponWithDbProcedure(ctx, args)
}
