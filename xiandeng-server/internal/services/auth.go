package services

import (
	"context"
	"fmt"
	"net/url"

	"github.com/google/uuid"
	"xiandeng.net.cn/server/constants"

	"github.com/shopspring/decimal"
	"xiandeng.net.cn/server/db"
	"xiandeng.net.cn/server/db/models"
	"xiandeng.net.cn/server/internal/code"
	"xiandeng.net.cn/server/pkg/config"
	"xiandeng.net.cn/server/pkg/log"
	"xiandeng.net.cn/server/pkg/wechat"
)

type AuthService interface {
	GetUserByPhone(ctx context.Context, phone string) (models.User, error)
	CheckPhoneAvailable(ctx context.Context, phone string) (bool, error)
	GenerateWechatOauthUrl(sessionId string, stage string, inplaceRedirect bool, requireRole *string, orgId *string, wxAppId string) string
	GetUserByOpenid(ctx context.Context, openid *string) (models.User, error)
	//CreateUser(ctx context.Context, userInput models2.UserBasicInfo, arg models.InitCreateUserParams) (entityType models.Entitytype, userId string, accountId string, err error)
	CheckEntitlementAvailable(ctx context.Context, params models.CheckEntitlementAvailableParams) (bool, error)
	CheckAgentStatus(
		ctx context.Context,
		acct models.Account) *code.Code
	RegisterUser(ctx context.Context, params models.RegisterUserParams) (models.RegisterUserRow, error)
	GetAgentAccountIdByUserId(ctx context.Context, userId uuid.UUID) (uuid.UUID, error)
	GetStudentAccountIdByUserId(ctx context.Context, userId uuid.UUID) (uuid.UUID, error)
	GetAccountByUserId(ctx context.Context, userId uuid.UUID, requireRole constants.RequireRole) (models.Account, error)
	CheckBelongsToOrg(ctx context.Context, orgName string, accountId uuid.UUID) (bool, error)
	GetRoleOfUser(ctx context.Context, userId uuid.UUID, accountId uuid.UUID) (models.GetRoleOfUserRow, error)
	DemoAccount(ctx context.Context, wechatOpenID string) (*models.Account, *models.User, error)
}

type authService struct {
	*Service
	wxSvcMgr *wechat.WxServiceManager
}

func NewAuthService(conf *config.Config, logger *log.Logger, repo db.Repository, wxSvcMgr *wechat.WxServiceManager) AuthService {
	return &authService{
		Service:  NewService(conf, logger, repo),
		wxSvcMgr: wxSvcMgr,
	}
}

func (s *authService) CheckPhoneAvailable(ctx context.Context, phone string) (bool, error) {
	_, err := s.repo.NewQueries().GetUserByPhone(ctx, phone)
	if err == nil {
		return false, nil
	} else {
		if err.Error() == "no rows in result set" {
			return true, nil
		} else {
			s.logger.ErrorTraceback("failed to get user by phone", err, log.SimpleMapParam{"phone": phone})
			return false, err
		}
	}

}

func (s *authService) GetUserByPhone(ctx context.Context, phone string) (models.User, error) {
	return s.repo.NewQueries().GetUserByPhone(ctx, phone)
}

func (s *authService) GenerateWechatOauthUrl(sessionId string, stage string, inplaceRedirect bool, requireRole *string, orgName *string, wxAppId string) string {
	state := "mystatecustomized"
	redirect_url := "https://%s/server/api/v1/wechat_auth?session_id=%s&stage=%s&inplace_redirect=%t"
	redirect_url = fmt.Sprintf(
		redirect_url,
		s.conf.Server.WebDomain,
		sessionId,
		stage,
		inplaceRedirect)
	if requireRole != nil {
		enc := url.Values{}
		enc.Add("require_role", *requireRole)
		redirect_url += "&" + enc.Encode()
	}
	if orgName != nil {
		enc := url.Values{}
		enc.Add("org_name", *orgName)
		redirect_url += "&" + enc.Encode()
	}
	s.logger.Info(fmt.Sprintf("current wechat app id: %s", wxAppId))
	accessUrl := "https://open.weixin.qq.com/connect/oauth2/authorize?appid=%s&redirect_uri=%s&response_type=code&scope=snsapi_userinfo&state=%s#wechat_redirect"

	return fmt.Sprintf(accessUrl, wxAppId, url.QueryEscape(redirect_url), state)
}

func (s *authService) GetUserByOpenid(ctx context.Context, openid *string) (models.User, error) {
	return s.repo.NewQueries().GetUserByOpenid(ctx, openid)
}

//func (s *authService) CreateUser(ctx context.Context, userInput models2.UserBasicInfo, arg models.InitCreateUserParams) (entityType models.Entitytype, userId string, accountId string, err error) {
//	return s.repo.CreateUser(ctx, userInput, arg)
//}

func (s *authService) RegisterUser(ctx context.Context, params models.RegisterUserParams) (models.RegisterUserRow, error) {
	row, err := s.repo.NewQueries().RegisterUser(ctx, params)
	if err != nil {
		s.logger.ErrorTraceback("failed to register user", err, params)
		return models.RegisterUserRow{}, err
	}
	return row, nil
}

func (s *authService) CheckEntitlementAvailable(ctx context.Context, params models.CheckEntitlementAvailableParams) (bool, error) {
	return s.repo.NewQueries().CheckEntitlementAvailable(ctx, params)
}

func (s *authService) GetAgentAccountIdByUserId(ctx context.Context, userId uuid.UUID) (uuid.UUID, error) {
	acctId, err := s.repo.NewQueries().GetAgentAccountIdByUserId(ctx, userId)
	if err != nil {
		s.logger.ErrorTraceback("failed to get agent account id", err, log.SimpleMapParam{"user_id": userId.String()})
		return acctId, err
	} else {
		return acctId, nil
	}
}

func (s *authService) GetStudentAccountIdByUserId(ctx context.Context, userId uuid.UUID) (uuid.UUID, error) {
	acctId, err := s.repo.NewQueries().GetStudentAccountIdByUserId(ctx, userId)
	if err != nil {
		s.logger.ErrorTraceback("failed to get student account id", err, log.SimpleMapParam{"user_id": userId.String()})
		return acctId, err
	} else {
		return acctId, nil
	}
}

func (s *authService) GetAccountByUserId(ctx context.Context, userId uuid.UUID, requireRole constants.RequireRole) (models.Account, error) {
	var err error
	var acctId uuid.UUID
	switch requireRole {
	case constants.RequireRoleStudent:
		acctId, err = s.GetStudentAccountIdByUserId(ctx, userId)
	case constants.RequireRoleAgent:
		acctId, err = s.GetAgentAccountIdByUserId(ctx, userId)
	default:
		return models.Account{}, fmt.Errorf("requireRole: %s, err: %x", requireRole, code.RoleTypeNotExist)
	}
	if err != nil {
		return models.Account{}, fmt.Errorf("authService.GetAccountByUserId: %x", err)
	}
	return s.repo.NewQueries().GetAccount(ctx, acctId)
}

func (s *authService) CheckAgentStatus(
	ctx context.Context,
	acct models.Account) *code.Code {

	//if userRow.Type.Entitytype != models.EntitytypeHQAGENT &&
	//	userRow.Type.Entitytype != models.EntitytypeLV1AGENT &&
	//	userRow.Type.Entitytype != models.EntitytypeLV2AGENT {
	//	return nil
	//}

	if acct.Status.Accountstatus == models.AccountstatusINIT {
		return &code.AgentLoginInit
	}
	if acct.Status.Accountstatus == models.AccountstatusCLOSED {
		return &code.AgentClosed
	}

	//acctId, err := s.repo.NewQueries().GetAgentAccountIdByUserId(ctx, userRow.ID)
	//if err != nil {
	//	s.logger.ErrorTraceback("failed to get agent account id", err, log.SimpleMapParam{"user_id": userRow.ID.String()})
	//	return nil
	//}
	pendingAccount, err := s.repo.NewQueries().GetAccountWithPendingFranchiseOrder(ctx, acct.ID)
	if err != nil {
		return &code.DBQueriesExecErr
	}

	var agentCode *code.Code
	if pendingAccount.Pendingfee.Decimal == decimal.New(0, 0) || !pendingAccount.Pendingfee.Valid {
		agentCode = nil
	} else if pendingAccount.Originaltype.Valid {
		agentCode = &code.AgentLoginUpgrading
	}

	if agentCode != nil {
		return agentCode
	}

	upAcct, err := s.repo.NewQueries().GetAccount(ctx, acct.Upstreamaccount.UUID)
	if err != nil {
		return nil
	}
	if upAcct.Type.Entitytype == models.EntitytypeHEADQUARTER {
		return nil
	}

	if !acct.Partition.Valid {
		agentCode = &code.AgentUpstreamPartition
	}
	return agentCode
}

func (s *authService) CheckBelongsToOrg(ctx context.Context, orgName string, accountId uuid.UUID) (bool, error) {
	tx, qtx, err := s.repo.StartTransaction(ctx)
	if err != nil {
		return false, err
	}
	defer tx.Rollback(ctx)
	acct, err := qtx.GetAccount(ctx, accountId)
	if err != nil {
		return false, err
	}
	if orgName == "default" {
		return !acct.Orgid.Valid, nil
	} else {
		orgmeta, err := qtx.GetOrgMetadata(ctx, orgName)
		if err != nil {
			return false, err
		}
		return orgmeta.ID == acct.Orgid.UUID, nil
	}

}

func (s *authService) GetRoleOfUser(ctx context.Context, userId uuid.UUID, accountId uuid.UUID) (models.GetRoleOfUserRow, error) {
	role, err := s.repo.NewQueries().GetRoleOfUser(ctx, models.GetRoleOfUserParams{
		Accountid: accountId,
		Userid:    userId,
	})
	return role, err
}

// DemoAccount returns the account and user of the demo account with the given openid
// If no demoaccount found, error will be nil, and account and user will be nil
func (s *authService) DemoAccount(ctx context.Context, wechatOpenID string) (*models.Account, *models.User, error) {
	demoAcct, err := s.repo.NewQueries().GetDemoAccount(ctx, &wechatOpenID)
	fmt.Println(wechatOpenID)
	fmt.Println(demoAcct.UUID.String())
	fmt.Println(err)
	if err != nil || !demoAcct.Valid {
		return nil, nil, nil
	}
	s.logger.Info("got demo account id: ")
	s.logger.Info(demoAcct.UUID.String())
	acct, err := s.repo.NewQueries().GetAccount(ctx, demoAcct.UUID)
	if err != nil {
		s.logger.ErrorTraceback("failed to get account", err)
		return nil, nil, err
	}
	user, err := s.repo.NewQueries().GetStudentUserByAccountID(ctx, demoAcct.UUID)
	if err != nil {
		s.logger.ErrorTraceback("failed to get student user id", err)
	}
	s.logger.Info(fmt.Sprintf("got student user id: %s", user.ID.String()))
	return &acct, &user, nil
}
