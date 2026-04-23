package services

import (
	"context"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
	"xiandeng.net.cn/server/db"
	"xiandeng.net.cn/server/db/models"
	"xiandeng.net.cn/server/pkg/config"
	"xiandeng.net.cn/server/pkg/log"
)

type AdjustmentService interface {
	InsertAdjustment(
		ctx context.Context,
		accountId uuid.UUID,
		amount decimal.Decimal,
		balanceType models.Accountbalancetype,
		notes string,
		operateUserId uuid.UUID,
	) error
	ListAdjustmentRecords(ctx context.Context) ([]models.ListAdjustmentRecordsRow, error)
}

type adjustmentService struct {
	*Service
}

func NewAdjustmentService(conf *config.Config, logger *log.Logger, repo db.Repository) AdjustmentService {
	return &adjustmentService{
		Service: NewService(conf, logger, repo),
	}
}

func (s *adjustmentService) InsertAdjustment(
	ctx context.Context,
	accountId uuid.UUID,
	amount decimal.Decimal,
	balanceType models.Accountbalancetype,
	notes string,
	operateUserId uuid.UUID,
) error {
	err := s.repo.NewQueries().InsertAdjustment(ctx, models.InsertAdjustmentParams{
		Accountid:     accountId,
		Amount:        amount,
		Balancetype:   balanceType,
		Notes:         notes,
		Operateuserid: uuid.NullUUID{UUID: operateUserId, Valid: true},
	})
	if err != nil {
		return err
	}
	return nil
}

func (s *adjustmentService) ListAdjustmentRecords(ctx context.Context) ([]models.ListAdjustmentRecordsRow, error) {
	records, err := s.repo.NewQueries().ListAdjustmentRecords(ctx)
	if err != nil {
		return nil, err
	}
	return records, nil
}
