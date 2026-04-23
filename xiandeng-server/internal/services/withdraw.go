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
)

type WithdrawService interface {
	CreateBankWithdrawMethod(
		ctx context.Context,
		userId uuid.UUID,
		bankName string,
		accountNumber string,
		accountName string,
	) (uuid.UUID, error)
	ListBankWithdrawMethods(ctx context.Context, userId uuid.UUID) ([]models.Userwithdrawmethod, error)
	DeleteWithdrawMethod(ctx context.Context, withdrawMethodId uuid.UUID) error
	UpdateWithdrawMethod(ctx context.Context, withdrawMethodId uuid.UUID, accountName string, accountNumber string, bank string) error
	CreateWithdraw(ctx context.Context, userId uuid.UUID, accountId uuid.UUID, amount decimal.Decimal, withdrawMethodId uuid.NullUUID, withdrawType models.Withdrawtype) (any, error)
	ListWithdraw(ctx context.Context, params models.ListWithdrawParams) ([]models.ListWithdrawRow, error)
}

type withdrawService struct {
	*Service
}

func NewWithdrawService(conf *config.Config, logger *log.Logger, repo db.Repository) WithdrawService {
	return &withdrawService{
		Service: NewService(conf, logger, repo),
	}
}

func (s *withdrawService) CreateBankWithdrawMethod(
	ctx context.Context,
	userId uuid.UUID,
	bankName string,
	accountNumber string,
	accountName string,
) (uuid.UUID, error) {
	return s.repo.NewQueries().CreateWithdrawMethod(ctx, models.CreateWithdrawMethodParams{
		Userid:         userId,
		Withdrawmethod: "bank",
		Bank:           &bankName,
		Accountname:    &accountName,
		Accountnumber:  &accountNumber,
	})
}

func (s *withdrawService) ListBankWithdrawMethods(ctx context.Context, userId uuid.UUID) ([]models.Userwithdrawmethod, error) {
	wds, err := s.repo.NewQueries().ListWithdrawMethods(ctx, models.ListWithdrawMethodsParams{
		Userid:         userId,
		Withdrawmethod: "bank",
	})
	if err != nil {
		return nil, err
	}
	return wds, nil
}

func (s *withdrawService) DeleteWithdrawMethod(ctx context.Context, withdrawMethodId uuid.UUID) error {
	err := s.repo.NewQueries().DeleteWithdrawMethod(ctx, withdrawMethodId)
	if err != nil {
		return fmt.Errorf("DeleteWithdrawMethod: %v", err.Error())
	}
	return nil
}

func (s *withdrawService) UpdateWithdrawMethod(ctx context.Context, withdrawMethodId uuid.UUID, accountName string, accountNumber string, bank string) error {
	err := s.repo.NewQueries().UpdateBankWithdrawMethod(ctx, models.UpdateBankWithdrawMethodParams{
		ID:            withdrawMethodId,
		Accountname:   &accountName,
		Accountnumber: &accountNumber,
		Bank:          &bank,
	})
	if err != nil {
		return fmt.Errorf("UpdateWithdrawMethod: %v", err.Error())
	}
	return nil
}

func (s *withdrawService) CreateWithdraw(ctx context.Context, userId uuid.UUID, accountId uuid.UUID, amount decimal.Decimal, withdrawMethodId uuid.NullUUID, withdrawType models.Withdrawtype) (any, error) {

	wid, err := s.repo.NewQueries().CreateWithdraw(ctx, models.CreateWithdrawParams{
		Accountid:            uuid.NullUUID{UUID: accountId, Valid: true},
		Lastoperateuserid:    uuid.NullUUID{UUID: userId, Valid: true},
		Amount:               decimal.NewNullDecimal(amount),
		Type:                 withdrawType,
		Userwithdrawmethodid: withdrawMethodId,
	})
	return wid, err
}

func (s *withdrawService) ListWithdraw(ctx context.Context, params models.ListWithdrawParams) ([]models.ListWithdrawRow, error) {
	return s.repo.NewQueries().ListWithdraw(ctx, params)
}
