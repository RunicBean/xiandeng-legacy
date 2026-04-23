package services

import (
	"context"

	"github.com/google/uuid"
	"xiandeng.net.cn/server/db"
	"xiandeng.net.cn/server/db/models"
	"xiandeng.net.cn/server/pkg/config"
	"xiandeng.net.cn/server/pkg/log"
)

type DeliveryService interface {
	ListDelivery(ctx context.Context, accountId string, status string) ([]models.ListDeliveryRow, error)
	ConfirmDelivery(ctx context.Context, deliveryId uuid.UUID) (any, error)
}

type deliveryService struct {
	*Service
}

func NewDeliveryService(conf *config.Config, logger *log.Logger, repo db.Repository) DeliveryService {
	return &deliveryService{
		Service: NewService(conf, logger, repo),
	}
}

func (s *deliveryService) ListDelivery(ctx context.Context, accountId string, status string) ([]models.ListDeliveryRow, error) {
	return s.repo.NewQueries().ListDelivery(ctx, models.ListDeliveryParams{
		Deliveryaccount: uuid.NullUUID{UUID: uuid.MustParse(accountId), Valid: true},
		Status:          &status,
	})
}

func (s *deliveryService) ConfirmDelivery(ctx context.Context, deliveryId uuid.UUID) (any, error) {
	return s.repo.NewQueries().ConfirmDelivery(ctx, deliveryId)

}
