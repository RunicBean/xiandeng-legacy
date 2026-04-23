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

type AccountService interface {
	StudentExists(ctx context.Context, invCode string, studentAccountName string) (bool, error)
	GetAccount(ctx context.Context, accountId uuid.UUID) (models.Account, error)
	GetAccountWithPendingFranchiseOrder(ctx context.Context, accountId uuid.UUID) (models.GetAccountWithPendingFranchiseOrderRow, error)
	UpdateAgentTargettype(ctx context.Context, accountId uuid.UUID, targettype models.Entitytype) error
	ListMyAgents(ctx context.Context, accountId uuid.UUID) ([]models.ListMyDirectAgentsRow, error)
	SearchAgents(ctx context.Context, accountNameLike *string) ([]models.SearchAgentsWithPendingFranchiseOrderRow, error)
	SearchAgentsWithAttributes(ctx context.Context, accountNameLike *string, phoneLike *string, emailLike *string) ([]models.SearchAgentsWithAttributesRow, error)
	PendingAgentsByFranchiseOrderId(ctx context.Context, franchiseOrderId uuid.UUID) ([]models.UpstreamAgentPendingAccountsRow, error)
	AssignAgentAward(ctx context.Context, accountId uuid.UUID) error
	ListPartitionAgents(ctx context.Context, accountId uuid.UUID, partition models.Accountpartition) ([]models.ListPartitionAgentsRow, error)
	UpdateAgentPartition(ctx context.Context, accountId uuid.UUID, partition models.Accountpartition) error
	CalculateSumPv(ctx context.Context, accountId uuid.UUID) (map[models.Accountpartition]decimal.Decimal, error)
	SevenLevelSubAgents(ctx context.Context, accountId uuid.UUID, partition models.Accountpartition) ([]models.SevenLevelSubAgentsRow, error)
	ListSubAgentDetails(ctx context.Context, currentAccountId uuid.UUID, subAgentAccountId uuid.UUID) ([]models.ListSubAgentDetailsRow, error)
	ListNameCheckResults(ctx context.Context, accountName string) ([]models.ListNameCheckResultsRow, error)
	StudentToAgent(ctx context.Context, userId uuid.UUID, accountName string, entityType models.Entitytype) error
	AgentToStudent(ctx context.Context, userId uuid.UUID, accountName string, relationShip *string) error
	StudentJoinAgent(ctx context.Context, accountid uuid.UUID, roleId string, userid string) error
	UpdateAgentByHQ(ctx context.Context, params models.UpdateAccountParams) error
}

type accountService struct {
	*Service
}

func NewAccountService(conf *config.Config, logger *log.Logger, repo db.Repository) AccountService {
	return &accountService{
		Service: NewService(conf, logger, repo),
	}
}

func (s *accountService) StudentExists(ctx context.Context, invCode string, studentAccountName string) (bool, error) {
	exists, err := s.repo.NewQueries().CheckDownstreamStudentExists(ctx, models.CheckDownstreamStudentExistsParams{
		Code:        invCode,
		Accountname: &studentAccountName,
	})
	if err != nil {
		return false, fmt.Errorf("service StudentExists: %v", err.Error())
	}
	return exists, nil
}

func (s *accountService) GetAccount(ctx context.Context, accountId uuid.UUID) (models.Account, error) {
	return s.repo.NewQueries().GetAccount(ctx, accountId)
}

func (s *accountService) GetAccountWithPendingFranchiseOrder(ctx context.Context, accountId uuid.UUID) (models.GetAccountWithPendingFranchiseOrderRow, error) {
	return s.repo.NewQueries().GetAccountWithPendingFranchiseOrder(ctx, accountId)
}

func (s *accountService) UpdateAgentTargettype(ctx context.Context, accountId uuid.UUID, targettype models.Entitytype) error {
	return s.repo.NewQueries().UpdateAgentTargettype(ctx, models.UpdateAgentTargettypeParams{
		Accountid:  accountId,
		Targettype: targettype,
	})
}

func (s *accountService) ListMyAgents(ctx context.Context, accountId uuid.UUID) ([]models.ListMyDirectAgentsRow, error) {
	return s.repo.NewQueries().ListMyDirectAgents(ctx, uuid.NullUUID{Valid: true, UUID: accountId})
}

func (s *accountService) SearchAgents(ctx context.Context, accountNameLike *string) ([]models.SearchAgentsWithPendingFranchiseOrderRow, error) {
	return s.repo.NewQueries().SearchAgentsWithPendingFranchiseOrder(ctx, accountNameLike)
}

func (s *accountService) SearchAgentsWithAttributes(ctx context.Context, accountNameLike *string, phoneLike *string, emailLike *string) ([]models.SearchAgentsWithAttributesRow, error) {
	phone := ""
	if phoneLike != nil {
		phone = "%" + *phoneLike + "%"
	}
	email := ""
	if emailLike != nil {
		email = "%" + *emailLike + "%"
	}
	if accountNameLike != nil {
		accountName := "%" + *accountNameLike + "%"
		accountNameLike = &accountName
	}
	return s.repo.NewQueries().SearchAgentsWithAttributes(ctx, models.SearchAgentsWithAttributesParams{
		Accountname: accountNameLike,
		Phone:       phone,
		Email:       email,
	})
}

func (s *accountService) AssignAgentAward(ctx context.Context, accountId uuid.UUID) error {
	return s.repo.NewQueries().AssignAward(ctx, accountId)
}

func (s *accountService) ListPartitionAgents(ctx context.Context, accountId uuid.UUID, partition models.Accountpartition) ([]models.ListPartitionAgentsRow, error) {
	return s.repo.NewQueries().ListPartitionAgents(ctx, accountId, partition)
}

func (s *accountService) UpdateAgentPartition(ctx context.Context, accountId uuid.UUID, partition models.Accountpartition) error {
	return s.repo.NewQueries().UpdateAccount(ctx, models.UpdateAccountParams{
		ID:        accountId,
		Partition: &partition,
	})
}

func (s *accountService) UpdateAgentByHQ(ctx context.Context, params models.UpdateAccountParams) error {
	if params.Status != nil {
		fmt.Println("status: ", *params.Status)
	}
	fmt.Println("account", params.ID.String())

	tx, qtx, err := s.repo.StartTransaction(ctx)
	defer tx.Rollback(ctx)
	if err != nil {
		return fmt.Errorf("start transaction: %x", err)
	}

	// Update account table
	err = qtx.UpdateAccount(ctx, params)
	if err != nil {
		return err
	}

	// Update agent attributes if demo fields are provided
	if params.DemoFlag != nil || params.DemoAccount != nil {
		agentAttrParams := models.UpdateAgentAttributeParams{
			Accountid:   params.ID,
			DemoFlag:    params.DemoFlag,
			DemoAccount: params.DemoAccount,
		}
		err = qtx.UpdateAgentAttribute(ctx, agentAttrParams)
		if err != nil {
			return err
		}
	}

	return tx.Commit(ctx)
}

func (s *accountService) CalculateSumPv(ctx context.Context, accountId uuid.UUID) (map[models.Accountpartition]decimal.Decimal, error) {
	var ret = make(map[models.Accountpartition]decimal.Decimal)
	data, err := s.repo.NewQueries().CalculateSumPv(ctx, accountId)
	if err != nil {
		return nil, fmt.Errorf("service CalculateSumPv: %v", err.Error())
	}
	for _, sum := range data {
		ret[sum.Partition] = sum.Sum
	}
	_, ok := ret[models.AccountpartitionL]
	if !ok {
		ret[models.AccountpartitionL] = decimal.Zero
	}
	_, ok = ret[models.AccountpartitionR]
	if !ok {
		ret[models.AccountpartitionR] = decimal.Zero
	}
	return ret, nil
}

func (s *accountService) PendingAgentsByFranchiseOrderId(ctx context.Context, franchiseOrderId uuid.UUID) ([]models.UpstreamAgentPendingAccountsRow, error) {
	return s.repo.NewQueries().UpstreamAgentPendingAccounts(ctx, franchiseOrderId)
}

func (s *accountService) SevenLevelSubAgents(ctx context.Context, accountId uuid.UUID, partition models.Accountpartition) ([]models.SevenLevelSubAgentsRow, error) {
	return s.repo.NewQueries().SevenLevelSubAgents(ctx, models.SevenLevelSubAgentsParams{
		Paccountid: accountId,
		Ppartition: partition,
	})
}

func (s *accountService) ListSubAgentDetails(ctx context.Context, currentAccountId uuid.UUID, subAgentAccountId uuid.UUID) ([]models.ListSubAgentDetailsRow, error) {
	return s.repo.NewQueries().ListSubAgentDetails(ctx, models.ListSubAgentDetailsParams{
		ID:   currentAccountId,
		ID_2: subAgentAccountId,
	})
}

func (s *accountService) ListNameCheckResults(ctx context.Context, accountName string) ([]models.ListNameCheckResultsRow, error) {
	return s.repo.NewQueries().ListNameCheckResults(ctx, &accountName)
}

func (s *accountService) StudentToAgent(ctx context.Context, userId uuid.UUID, accountName string, entityType models.Entitytype) error {
	return s.repo.NewQueries().StudentToAgent(ctx, models.StudentToAgentParams{
		Userid:      userId,
		Accountname: accountName,
		Entitytype:  entityType,
	})
}

func (s *accountService) AgentToStudent(ctx context.Context, userId uuid.UUID, accountName string, relationShip *string) error {
	return s.repo.NewQueries().AgentToStudent(ctx, models.AgentToStudentParams{
		Userid:       userId,
		Accountname:  accountName,
		Relationship: relationShip,
	})
}

func (s *accountService) StudentJoinAgent(ctx context.Context, accountid uuid.UUID, roleId string, userid string) error {
	return s.repo.NewQueries().StudentJoinAgent(ctx, models.StudentJoinAgentParams{
		Accountid: accountid,
		RoleId:    roleId,
		Userid:    userid,
	})
}
