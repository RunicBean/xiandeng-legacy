package controller

import (
	"errors"
	"fmt"
	"net/http"

	"github.com/google/uuid"
	"go.uber.org/zap/zapcore"
	"xiandeng.net.cn/server/db/models"
	"xiandeng.net.cn/server/internal/app"
	"xiandeng.net.cn/server/internal/code"
	"xiandeng.net.cn/server/internal/services"
	"xiandeng.net.cn/server/pkg/log"
)

type AccountController struct {
	*Controller
	accountService services.AccountService
}

func NewAccountController(controller *Controller, service services.AccountService) *AccountController {
	return &AccountController{
		Controller:     controller,
		accountService: service,
	}
}

type QueryStudentExists struct {
	Code               string `json:"code" form:"code"`
	StudentAccountName string `json:"student_account_name" form:"student_account_name"`
}

func (q QueryStudentExists) MarshalLogObject(enc zapcore.ObjectEncoder) error {
	enc.AddString("code", q.Code)
	enc.AddString("student_account_name", q.StudentAccountName)
	return nil
}

func (c *AccountController) StudentExists() app.HandlerFunc {
	return func(ctx app.Context) {
		var query QueryStudentExists
		err := ctx.ShouldBindQuery(&query)
		if err != nil {
			ctx.AbortWithBadRequest(err, query)
			return
		}
		if query.StudentAccountName == "" || query.Code == "" {
			ctx.AbortWithBadRequest(fmt.Errorf("code or student_account_name missing"), query)
			return
		}
		exist, err := c.accountService.StudentExists(ctx.RequestContext(), query.Code, query.StudentAccountName)
		if err != nil {
			ctx.AbortWithStatusJSON(
				http.StatusInternalServerError,
				code.ServerInternalErr,
				"accountService.StudentExists",
				err,
				query,
			)
			return
		}
		ctx.SuccessJSON(exist)
	}
}

func (c *AccountController) GetAccount() app.HandlerFunc {
	return func(ctx app.Context) {
		acctId := ctx.Param("account_id")
		acct, err := c.accountService.GetAccount(ctx.RequestContext(), uuid.MustParse(acctId))
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.RecordNotFound, fmt.Sprintf("account_id: %s", acctId), err)
			return
		}
		ctx.SuccessJSON(acct)
	}
}

func (c *AccountController) GetAccountSignupData() app.HandlerFunc {
	return func(ctx app.Context) {
		acctId := ctx.Param("account_id")
		acct, err := c.accountService.GetAccountWithPendingFranchiseOrder(ctx.RequestContext(), uuid.MustParse(acctId))
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.RecordNotFound, fmt.Sprintf("account_id: %s", acctId), err)
			return
		}
		var ret map[string]string = map[string]string{
			"account_name":     *acct.Accountname,
			"account_type":     string(acct.Type.Entitytype),
			"account_status":   string(acct.Status.Accountstatus),
			"upstream_account": acct.Upstreamaccount.UUID.String(),
			"pending_fee":      acct.Pendingfee.Decimal.String(),
			"original_type":    string(acct.Originaltype.Entitytype),
			"target_type":      string(acct.Targettype.Entitytype),
		}
		ctx.SuccessJSON(ret)
	}
}

type BodyUpdateAgentTargettype struct {
	CurrentUser *bool   `json:"current_user" form:"current_user"`
	AccountId   *string `json:"account_id" form:"account_id"`
	TargetType  string  `json:"target_type" form:"target_type"`
}

func (body BodyUpdateAgentTargettype) MarshalLogObject(enc zapcore.ObjectEncoder) error {
	enc.AddBool("current_user", *body.CurrentUser)
	if body.AccountId == nil {
		enc.AddString("account_id", "NULL")
	} else {
		enc.AddString("account_id", *body.AccountId)
	}
	enc.AddString("target_type", body.TargetType)
	return nil
}

func (c *AccountController) UpdateAgentTargettype() app.HandlerFunc {
	return func(ctx app.Context) {
		var body BodyUpdateAgentTargettype
		err := ctx.ShouldBind(&body)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		if body.CurrentUser == nil && body.AccountId == nil {
			ctx.AbortWithBadRequest(errors.New("current_user or account_id is required"))
			return
		}
		if body.CurrentUser != nil && *body.CurrentUser {
			accountId := ctx.Account().ID.String()
			body.AccountId = &accountId
		}
		err = c.accountService.UpdateAgentTargettype(ctx.RequestContext(), uuid.MustParse(*body.AccountId), models.Entitytype(body.TargetType))
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err, body)
			return
		}
		ctx.SuccessCreateJSON("ok")
	}
}

func (c *AccountController) ListMyAgents() app.HandlerFunc {
	return func(ctx app.Context) {
		// acctId := ctx.Param("account_id")

		rows, err := c.accountService.ListMyAgents(ctx.RequestContext(), ctx.Account().ID)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.RecordNotFound, err.Error(), err, log.SimpleMapParam{"account_id": ctx.Account().ID.String()})
			return
		}

		ctx.SuccessJSON(models.ListMyDirectAgentsRowsToMaps(rows))
	}
}

type QuerySearchAgents struct {
	AccountNameLike *string `json:"account_name_like" form:"account_name_like"`
}

func (query QuerySearchAgents) MarshalLogObject(enc zapcore.ObjectEncoder) error {
	if query.AccountNameLike == nil {
		enc.AddString("account_name_like", "NULL")
		return nil
	}
	enc.AddString("account_name_like", *query.AccountNameLike)
	return nil
}

func (c *AccountController) SearchAgents() app.HandlerFunc {
	return func(ctx app.Context) {
		var query QuerySearchAgents
		err := ctx.ShouldBindQuery(&query)
		if err != nil {
			ctx.AbortWithBadRequest(err, query)
			return
		}
		if query.AccountNameLike != nil {
			accountName := "%" + *query.AccountNameLike + "%"
			query.AccountNameLike = &accountName
		}
		accts, err := c.accountService.SearchAgents(ctx.RequestContext(), query.AccountNameLike)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.RecordNotFound, "accountService.SearchAgents issue", err, query)
			return
		}
		var ret []map[string]interface{}
		for _, acct := range accts {
			ret = append(ret, acct.ToMap())
		}
		ctx.SuccessJSON(ret)
	}
}

type QuerySearchAgentsWithAttributes struct {
	AccountNameLike *string `json:"account_name_like" form:"account_name_like"`
	PhoneLike       *string `json:"phone_like" form:"phone_like"`
	EmailLike       *string `json:"email_like" form:"email_like"`
}

func (query QuerySearchAgentsWithAttributes) MarshalLogObject(enc zapcore.ObjectEncoder) error {
	if query.AccountNameLike == nil {
		enc.AddString("account_name_like", "NULL")
	} else {
		enc.AddString("account_name_like", *query.AccountNameLike)
	}
	if query.PhoneLike == nil {
		enc.AddString("phone_like", "NULL")
	} else {
		enc.AddString("phone_like", *query.PhoneLike)
	}

	if query.EmailLike == nil {
		enc.AddString("email_like", "NULL")
	} else {
		enc.AddString("email_like", *query.EmailLike)
	}
	return nil
}

func (c *AccountController) SearchAgentsWithAttributes() app.HandlerFunc {
	return func(ctx app.Context) {
		var query QuerySearchAgentsWithAttributes
		err := ctx.ShouldBindQuery(&query)
		if err != nil {
			ctx.AbortWithBadRequest(err, query)
			return
		}
		accts, err := c.accountService.SearchAgentsWithAttributes(ctx.RequestContext(), query.AccountNameLike, query.PhoneLike, query.EmailLike)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.RecordNotFound, err.Error(), err, query)
			return
		}
		ctx.SuccessJSON(models.SearchAgentsWithAttributesRowsToMaps(accts))
	}
}

// @Router /account/pending-agents/foid/{foid} [get]
func (c *AccountController) PendingAgentsByFranchiseOrderId() app.HandlerFunc {
	return func(ctx app.Context) {
		foid := ctx.Param("foid")
		franchiseOrderId, err := uuid.Parse(foid)
		if err != nil {
			ctx.AbortWithBadRequest(err, log.SimpleParam(foid))
			return
		}
		data, err := c.accountService.PendingAgentsByFranchiseOrderId(ctx.RequestContext(), franchiseOrderId)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err, log.SimpleMapParam{"franchise_order_id": foid})
			return
		}
		ctx.SuccessJSON(data)
	}
}

func (c *AccountController) AssignAgentAward() app.HandlerFunc {
	return func(ctx app.Context) {
		acctId := ctx.Param("account_id")
		err := c.accountService.AssignAgentAward(ctx.RequestContext(), uuid.MustParse(acctId))
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err, log.SimpleMapParam{"account_id": acctId})
			return
		}
		ctx.SuccessCreateJSON("ok")
	}
}

type QueryListPartitionAgents struct {
	Partition string `json:"partition" form:"partition"`
}

func (query QueryListPartitionAgents) MarshalLogObject(enc zapcore.ObjectEncoder) error {
	enc.AddString("partition", query.Partition)
	return nil
}

func (c *AccountController) ListPartitionAgents() app.HandlerFunc {
	return func(ctx app.Context) {
		var query QueryListPartitionAgents
		err := ctx.ShouldBindQuery(&query)
		if err != nil {
			ctx.AbortWithBadRequest(err, query)
			return
		}
		partition := models.Accountpartition(query.Partition)
		// acctId := uuid.MustParse("4754da6c-7984-48fe-bb1a-fa8e8b0ed10b")
		acctId := ctx.Account().ID
		data, err := c.accountService.ListPartitionAgents(ctx.RequestContext(), acctId, partition)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err, query)
			return
		}
		ctx.SuccessJSON(data)
	}
}

type BodyUpdateAgentPartition struct {
	AccountId string `json:"account_id" form:"account_id"`
	Partition string `json:"partition" form:"partition"`
}

func (body BodyUpdateAgentPartition) MarshalLogObject(enc zapcore.ObjectEncoder) error {
	enc.AddString("account_id", body.AccountId)
	enc.AddString("partition", body.Partition)
	return nil
}

func (c *AccountController) UpdateAgentPartition() app.HandlerFunc {
	return func(ctx app.Context) {
		var body BodyUpdateAgentPartition
		err := ctx.ShouldBind(&body)
		if err != nil {
			ctx.AbortWithBadRequest(err, body)
			return
		}
		if err := c.accountService.UpdateAgentPartition(ctx.RequestContext(), uuid.MustParse(body.AccountId), models.Accountpartition(body.Partition)); err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err, body)
			return
		}
		ctx.SuccessCreateJSON("ok")
	}
}

func (c *AccountController) UpdateAgentByHQ() app.HandlerFunc {
	return func(ctx app.Context) {
		var body models.UpdateAccountParams
		err := ctx.ShouldBind(&body)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		err = c.accountService.UpdateAgentByHQ(ctx.RequestContext(), body)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessCreateJSON("ok")
	}
}

func (c *AccountController) CalculateSumPv() app.HandlerFunc {
	return func(ctx app.Context) {
		data, err := c.accountService.CalculateSumPv(ctx.RequestContext(), ctx.Account().ID)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err, log.SimpleMapParam{"account_id": ctx.Account().ID.String()})
			return
		}
		ctx.SuccessJSON(data)
	}
}

type QuerySevenLevelSubAgents struct {
	CurrentUser *bool   `json:"current_user" form:"current_user"`
	AccountId   *string `json:"account_id" form:"account_id"`
	Partition   string  `json:"partition" form:"partition"`
}

func (query QuerySevenLevelSubAgents) MarshalLogObject(enc zapcore.ObjectEncoder) error {
	if query.CurrentUser == nil {
		enc.AddString("current_user", "NULL")
	} else {
		enc.AddBool("current_user", *query.CurrentUser)
	}

	if query.AccountId == nil {
		enc.AddString("account_id", "NULL")
	} else {
		enc.AddString("account_id", *query.AccountId)
	}

	enc.AddString("partition", query.Partition)
	return nil
}

func (c *AccountController) SevenLevelSubAgents() app.HandlerFunc {
	return func(ctx app.Context) {
		var query QuerySevenLevelSubAgents
		err := ctx.ShouldBindQuery(&query)
		if err != nil {
			ctx.AbortWithBadRequest(err, query)
			return
		}
		var acctId string
		if query.CurrentUser != nil && *query.CurrentUser {
			acctId = ctx.Account().ID.String()
		} else if query.AccountId != nil {
			acctId = *query.AccountId
		} else {
			ctx.AbortWithBadRequest(errors.New("account_id is required"), query)
			return
		}
		data, err := c.accountService.SevenLevelSubAgents(ctx.RequestContext(), uuid.MustParse(acctId), models.Accountpartition(query.Partition))
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err, log.SimpleMapParam{"account_id": acctId, "partition": query.Partition})
			return
		}
		ctx.SuccessJSON(data)
	}
}

type QueryListSubAgentDetails struct {
	CurrentUser       *bool   `json:"current_user" form:"current_user"`
	CurrentAccountId  *string `json:"current_account_id" form:"current_account_id"`
	SubAgentAccountId string  `json:"sub_agent_account_id" form:"sub_agent_account_id"`
}

func (query QueryListSubAgentDetails) MarshalLogObject(enc zapcore.ObjectEncoder) error {
	if query.CurrentUser == nil {
		enc.AddString("current_user", "NULL")
	} else {
		enc.AddBool("current_user", *query.CurrentUser)
	}

	if query.CurrentAccountId == nil {
		enc.AddString("current_account_id", "NULL")
	} else {
		enc.AddString("current_account_id", *query.CurrentAccountId)
	}

	enc.AddString("sub_agent_account_id", query.SubAgentAccountId)
	return nil
}

func (c *AccountController) ListSubAgentDetails() app.HandlerFunc {
	return func(ctx app.Context) {
		var query QueryListSubAgentDetails
		err := ctx.ShouldBindQuery(&query)
		if err != nil {
			ctx.AbortWithBadRequest(err, query)
			return
		}
		var currentAccountId uuid.UUID
		if query.CurrentUser != nil && *query.CurrentUser {
			currentAccountId = ctx.Account().ID
		} else if query.CurrentAccountId != nil {
			currentAccountId = uuid.MustParse(*query.CurrentAccountId)
		} else {
			ctx.AbortWithBadRequest(errors.New("current_account_id is required"), query)
			return
		}
		data, err := c.accountService.ListSubAgentDetails(ctx.RequestContext(), currentAccountId, uuid.MustParse(query.SubAgentAccountId))
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err, query)
			return
		}
		ctx.SuccessJSON(data)
	}
}

func (c *AccountController) ListCheckNameResults() app.HandlerFunc {
	return func(ctx app.Context) {
		accountName, ok := ctx.GetQuery("account_name")
		if !ok {
			ctx.AbortWithBadRequest(errors.New("account_name is required"))
			return
		}
		data, err := c.accountService.ListNameCheckResults(ctx.RequestContext(), accountName)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err, log.SimpleMapParam{"account_name": accountName})
			return
		}
		ctx.SuccessJSON(data)
	}
}

type BodyAgentToStudent struct {
	UserId       string  `json:"user_id" form:"user_id"`
	AccountName  string  `json:"account_name" form:"account_name"`
	Relationship *string `json:"relationship" form:"relationship"`
}

func (body BodyAgentToStudent) MarshalLogObject(enc zapcore.ObjectEncoder) error {
	enc.AddString("user_id", body.UserId)
	enc.AddString("account_name", body.AccountName)
	if body.Relationship != nil {
		enc.AddString("relationship", *body.Relationship)
	}
	return nil
}

func (c *AccountController) AgentToStudent() app.HandlerFunc {
	return func(ctx app.Context) {
		var body BodyAgentToStudent
		err := ctx.ShouldBind(&body)
		if err != nil {
			ctx.AbortWithBadRequest(err, body)
			return
		}
		err = c.accountService.AgentToStudent(ctx.RequestContext(), uuid.MustParse(body.UserId), body.AccountName, body.Relationship)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err, body)
			return
		}
		ctx.SuccessCreateJSON("ok")
	}
}

type BodyStudentToAgent struct {
	UserId      string `json:"user_id" form:"user_id"`
	AccountName string `json:"account_name" form:"account_name"`
	EntityName  string `json:"entity_name" form:"entity_name"`
}

func (body BodyStudentToAgent) MarshalLogObject(enc zapcore.ObjectEncoder) error {
	enc.AddString("user_id", body.UserId)
	enc.AddString("account_name", body.AccountName)
	enc.AddString("entity_name", body.EntityName)
	return nil
}

func (c *AccountController) StudentToAgent() app.HandlerFunc {
	return func(ctx app.Context) {
		var body BodyStudentToAgent
		err := ctx.ShouldBind(&body)
		if err != nil {
			ctx.AbortWithBadRequest(err, body)
			return
		}
		err = c.accountService.StudentToAgent(ctx.RequestContext(), uuid.MustParse(body.UserId), body.AccountName, models.Entitytype(body.EntityName))
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err, body)
			return
		}
		ctx.SuccessCreateJSON("ok")
	}
}

type BodyStudentJoinAgent struct {
	UserId    string `json:"user_id" form:"user_id"`
	AccountId string `json:"account_id" form:"account_id"`
	RoleId    string `json:"role_id" form:"role_id"`
}

func (body BodyStudentJoinAgent) MarshalLogObject(enc zapcore.ObjectEncoder) error {
	enc.AddString("user_id", body.UserId)
	enc.AddString("account_id", body.AccountId)
	enc.AddString("role_id", body.RoleId)
	return nil
}

func (c *AccountController) StudentJoinAgent() app.HandlerFunc {
	return func(ctx app.Context) {
		var body BodyStudentJoinAgent
		err := ctx.ShouldBind(&body)
		if err != nil {
			ctx.AbortWithBadRequest(err, body)
			return
		}
		err = c.accountService.StudentJoinAgent(ctx.RequestContext(), uuid.MustParse(body.AccountId), body.RoleId, body.UserId)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err, body)
			return
		}
		ctx.SuccessCreateJSON("ok")
	}
}
