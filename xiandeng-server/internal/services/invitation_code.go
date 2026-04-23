package services

import (
	"context"
	"fmt"
	"xiandeng.net.cn/server/pkg/utils/model_util"

	"xiandeng.net.cn/server/constants"
	"xiandeng.net.cn/server/pkg/log"

	"github.com/google/uuid"
	"xiandeng.net.cn/server/db"
	"xiandeng.net.cn/server/db/models"
	"xiandeng.net.cn/server/pkg/config"
	"xiandeng.net.cn/server/pkg/utils/string_util"
	"xiandeng.net.cn/server/services/cache"
)

type InvitationCodeService interface {
	GenerateCode(ctx context.Context, _type models.NullEntitytype, accountId string, userId string) string
	GetInvitationDataFromCache(iCode string) (_type string, accountId string, err error)
	GetInvitationDataFromDB(ctx context.Context, iCode string) (code models.Invitationcode, err error)
	ListCodes(ctx context.Context, userId uuid.UUID) ([]models.ListInvitationCodesByUserIdRow, error)
	CompleteInvitationCodes(ctx context.Context, userId uuid.UUID) error
}

type invitationCodeService struct {
	*Service
	cache cache.GlobalCache
}

func NewInvitationCodeService(conf *config.Config, logger *log.Logger, repo db.Repository, c cache.GlobalCache) InvitationCodeService {
	return &invitationCodeService{
		Service: NewService(conf, logger, repo),
		cache:   c,
	}
}

var _ InvitationCodeService = (*invitationCodeService)(nil)

func (s *invitationCodeService) GenerateCode(ctx context.Context, _type models.NullEntitytype, accountId string, userId string) string {
	rs := string_util.RandomString(constants.INVITATION_CODE_LENGTH)
	acctId, _ := uuid.Parse(accountId)
	uid, _ := uuid.Parse(userId)
	err := s.repo.GenerateCode(ctx, acctId, uid, _type, rs, constants.INVITATION_CODE_EXPIRES_IN)
	if err != nil {
		panic(err)
	}
	return rs
}

func (s *invitationCodeService) ListCodes(ctx context.Context, userId uuid.UUID) ([]models.ListInvitationCodesByUserIdRow, error) {
	codes, err := s.repo.NewQueries().ListInvitationCodesByUserId(ctx, model_util.UUIDToNullUUID(userId))
	return codes, err
}

func (s *invitationCodeService) GetInvitationDataFromDB(ctx context.Context, iCode string) (code models.Invitationcode, err error) {
	code, err = s.repo.NewQueries().GetInvitationData(ctx, iCode)
	if err != nil {
		return models.Invitationcode{}, err
	}
	return code, nil
}

func (s *invitationCodeService) GetInvitationDataFromCache(iCode string) (_type string, accountId string, err error) {
	c, err := s.cache.GetInvitationCache(cache.InvitationCode(iCode), true)
	if err != nil {
		return "", "", err
	}
	return c.AccountId, c.Type, nil
}

func (s *invitationCodeService) CompleteInvitationCodes(ctx context.Context, userId uuid.UUID) error {
	_, err := s.repo.NewQueries().CompleteInvitationCodes(ctx, userId)
	if err != nil {
		return fmt.Errorf("failed to complete invitation codes: %v", err)
	}
	return nil
}
