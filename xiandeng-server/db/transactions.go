package db

import (
	"context"
	"time"
	"xiandeng.net.cn/server/pkg/utils/model_util"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
	"xiandeng.net.cn/server/db/models"
	timeutil "xiandeng.net.cn/server/pkg/utils/time_util"
)

// CreateUser create three tables,
// Account: Business Account data
// User: account related User
// Attribute: AgentAttribute & StudentAttribute, extend info of Account
//func (r *repository) CreateUser(
//	ctx context.Context,
//	userInput models2.UserBasicInfo,
//	arg models.InitCreateUserParams) (entityType models.Entitytype, userId string, accountId string, err error) {
//
//	tx, qtx, err := r.StartTransaction(ctx)
//	if err != nil {
//		return "", "", "", err
//	}
//	defer tx.Rollback(ctx)
//
//	// 判断是否为家长
//	var isGuardian bool = *userInput.Role == models2.BASIC_INFO_ROLE_GUARDIAN
//
//	// 分阶段，第一阶段，是否需要创建account
//	var acctId uuid.UUID
//	var acctInfo models.Account
//	toCreateAccount := true
//	if userInput.InvitationAccountId != nil && *userInput.InvitationAccountId != "" {
//		acctId = uuid.MustParse(*userInput.InvitationAccountId)
//		acctInfo, err = qtx.GetAccount(ctx, acctId)
//		if err != nil {
//			return "", "", "", err
//		}
//		toCreateAccount = false
//	}
//
//	if toCreateAccount {
//		createAcctParams := models.CreateAccountParams{}
//		// Get refcode accountid
//		if *userInput.RefCode == "Youknowwh@t" {
//			createAcctParams.Type = models.NullEntitytype{
//				Entitytype: models.EntitytypeHEADQUARTER,
//				Valid:      true,
//			}
//		} else if userInput.RefCode != nil {
//			ic, err := qtx.GetInvitationData(ctx, *userInput.RefCode)
//			if err != nil {
//				return "", "", "", fmt.Errorf("invitation retrieving error: %x", err)
//			}
//			arg.Referaluserid = ic.Userid
//			createAcctParams.Upstreamaccount = ic.Accountid
//			createAcctParams.Type = ic.Createtype
//		} else {
//			createAcctParams.Type = models.NullEntitytype{
//				Entitytype: models.EntitytypeSTUDENT,
//				Valid:      true,
//			}
//		}
//
//		// 如果是学生类型，则将学生姓名填入account name
//		if createAcctParams.Type.Entitytype == models.EntitytypeSTUDENT {
//			if userInput.GardStudentName != nil && *userInput.GardStudentName != "" {
//				createAcctParams.Accountname = userInput.GardStudentName
//			}
//		} else {
//			createAcctParams.Accountname = userInput.AgentName
//		}
//
//		acctInfo, err = qtx.CreateAccount(ctx, createAcctParams)
//		if err != nil {
//			r.logger.ErrorTraceback("account creation error", err, createAcctParams)
//			return "", "", "", fmt.Errorf("account creation error: %v", err)
//		}
//		acctId = acctInfo.ID
//	}
//
//	// 家长流程
//	if isGuardian {
//		uidStrP, err := CreateAsGuardian(ctx, qtx, userInput, arg, acctId)
//		if err != nil {
//			return "", "", "", err
//		}
//		return acctInfo.Type.Entitytype, *uidStrP, acctId.String(), tx.Commit(ctx)
//	}
//
//	r.logger.Info(fmt.Sprintf("AccountId: %s, EntityType: %s", acctId.String(), acctInfo.Type.Entitytype))
//	// Start creating Attribute record
//	switch acctInfo.Type.Entitytype {
//	case models.EntitytypeHQAGENT:
//		r.logger.Info("Create AgentAttr...")
//		err = qtx.CreateAgentAttr(ctx, models.CreateAgentAttrParams{
//			Accountid: acctId,
//			Province:  nil,
//			City:      nil,
//		})
//	case models.EntitytypeLV1AGENT:
//		r.logger.Info("Create AgentAttr...")
//		err = qtx.CreateAgentAttr(ctx, models.CreateAgentAttrParams{
//			Accountid: acctId,
//			Province:  nil,
//			City:      nil,
//		})
//	case models.EntitytypeLV2AGENT:
//		r.logger.Info("Create AgentAttr...")
//		err = qtx.CreateAgentAttr(ctx, models.CreateAgentAttrParams{
//			Accountid: acctId,
//			Province:  nil,
//			City:      nil,
//		})
//	case models.EntitytypeSTUDENT:
//		r.logger.Info("Create StudentAttr...")
//		err = qtx.InitCreateStudentAttr(ctx, acctId)
//	}
//	if err != nil {
//		return "", "", "", err
//	}
//
//	// Start creating User record
//	arg.Accountid = utils.UUIDToNullUUID(acctId)
//	uid, err := qtx.InitCreateUser(ctx, arg)
//	if err != nil {
//		return "", "", "", err
//	}
//	uidStr := uid.String()
//	return acctInfo.Type.Entitytype, uidStr, acctId.String(), tx.Commit(ctx)
//}
//
//func CreateAsGuardian(
//	ctx context.Context,
//	qtx *models.Queries,
//	userInput models2.UserBasicInfo,
//	arg models.InitCreateUserParams,
//	acctId uuid.UUID,
//) (*string, error) {
//	arg.Accountid = utils.UUIDToNullUUID(acctId)
//	uid, err := qtx.InitCreateUser(ctx, arg)
//	if err != nil {
//		return nil, err
//	}
//	uidStr := uid.String()
//	err = qtx.CreateGuardian(ctx, models.CreateGuardianParams{
//		Guardianid:   uid,
//		Studentid:    utils.UUIDToNullUUID(acctId),
//		Relationship: userInput.GardRelationship,
//	})
//	if err != nil {
//		return nil, err
//	}
//	return &uidStr, nil
//}

//
//// InviteUserToAccount create user under account
//func InviteUserToAccount(
//	ctx context.Context,
//	db *pgxpool.Pool,
//	arg models.InitCreateUserParams,
//	accountId string,
//	refCode *string) (*string, error) {
//
//	queries := models.New(db)
//	tx, err := db.Begin(ctx)
//	if err != nil {
//		return nil, err
//	}
//	defer tx.Rollback(ctx)
//	qtx := queries.WithTx(tx)
//
//	// Start creating User record
//	arg.Accountid = utils.UUIDToNullUUID(uuid.MustParse(accountId))
//	uid, err := qtx.InitCreateUser(ctx, arg)
//	if err != nil {
//		return nil, err
//	}
//	uidStr := uid.String()
//	return &uidStr, tx.Commit(ctx)
//}

func (r *repository) StartTransaction(ctx context.Context) (pgx.Tx, *models.Queries, error) {
	db := r.db.(*pgxpool.Pool)
	queries := models.New(db)
	tx, err := db.Begin(ctx)
	if err != nil {
		return nil, nil, err
	}
	qtx := queries.WithTx(tx)
	return tx, qtx, nil
}

func (r *repository) GenerateCode(
	ctx context.Context,
	accountId uuid.UUID,
	userId uuid.UUID,
	createType models.NullEntitytype,
	code string,
	duration time.Duration,
) error {
	tx, qtx, err := r.StartTransaction(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)
	_, err = qtx.DeleteInvitationCode(ctx, models.DeleteInvitationCodeParams{
		Accountid:  model_util.UUIDToNullUUID(accountId),
		Userid:     model_util.UUIDToNullUUID(userId),
		Createtype: createType,
	})
	if err != nil {
		return err
	}

	expiresAt := pgtype.Timestamp{}
	expiresAt.Scan(timeutil.NowInShanghai().Add(duration))
	_, err = qtx.CreateInvitationCode(ctx, models.CreateInvitationCodeParams{
		Code:       code,
		Accountid:  model_util.UUIDToNullUUID(accountId),
		Userid:     model_util.UUIDToNullUUID(userId),
		Createtype: createType,
		Expiresat:  expiresAt,
	})
	if err != nil {
		return err
	}

	return tx.Commit(ctx)
}
