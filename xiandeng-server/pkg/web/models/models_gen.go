package models

import "go.uber.org/zap/zapcore"

type InvitationCode struct {
	AccountID  string      `json:"accountId"`
	Code       string      `json:"code"`
	UserID     string      `json:"userId"`
	CreateType AccountType `json:"createType"`
	ExpiresAt  string      `json:"expiresAt"`
}

type Mutation struct {
}

type Product struct {
	ID            string  `json:"id"`
	Type          *string `json:"type,omitempty"`
	ProductName   *string `json:"productName,omitempty"`
	FinalPrice    *string `json:"finalPrice,omitempty"`
	HqAgentPrice  *string `json:"hqAgentPrice,omitempty"`
	Lv1AgentPrice *string `json:"lv1AgentPrice,omitempty"`
	Lv2AgentPrice *string `json:"lv2AgentPrice,omitempty"`
	PublishStatus *bool   `json:"publishStatus,omitempty"`
	Description   *string `json:"description,omitempty"`
}

const (
	BASIC_INFO_ROLE_STUDENT  = "student"
	BASIC_INFO_ROLE_GUARDIAN = "guardian"
)

type UserBasicInfo struct {
	Phone               string  `json:"phone"`
	Password            string  `json:"password"`
	Email               *string `json:"email,omitempty"`
	RefCode             *string `json:"refCode,omitempty"`
	Province            *string `json:"province,omitempty"`
	City                *string `json:"city,omitempty"`
	Role                *string `json:"role,omitempty"`
	GardStudentName     *string `json:"gardStudentName,omitempty"`
	GardRelationship    *string `json:"gardRelationship,omitempty"`
	InvitationAccountId *string `json:"invitationAccountId,omitempty"`
	AgentName           *string `json:"agentName,omitempty"`
	ExistAccountId      *string `json:"existAccountId,omitempty"`
	InviteUserId        *string `json:"inviteUserId,omitempty"`
	InviteAgentRoleId   *string `json:"inviteAgentRoleId,omitempty"`
}

func (u *UserBasicInfo) MarshalLogObject(enc zapcore.ObjectEncoder) error {
	enc.AddString("phone", u.Phone)
	enc.AddString("password", "******")
	if u.Email != nil {
		enc.AddString("email", *u.Email)
	}
	if u.RefCode != nil {
		enc.AddString("refCode", *u.RefCode)
	}
	if u.Province != nil {
		enc.AddString("province", *u.Province)
	}
	if u.City != nil {
		enc.AddString("city", *u.City)
	}
	if u.Role != nil {
		enc.AddString("role", *u.Role)
	}
	if u.GardStudentName != nil {
		enc.AddString("gardStudentName", *u.GardStudentName)
	}
	if u.GardRelationship != nil {
		enc.AddString("gardRelationship", *u.GardRelationship)
	}
	if u.InvitationAccountId != nil {
		enc.AddString("invitationAccountId", *u.InvitationAccountId)
	}
	if u.AgentName != nil {
		enc.AddString("agentName", *u.AgentName)
	}
	if u.ExistAccountId != nil {
		enc.AddString("existAccountId", *u.ExistAccountId)
	}
	if u.InviteUserId != nil {
		enc.AddString("inviteUserId", *u.InviteUserId)
	}
	if u.InviteAgentRoleId != nil {
		enc.AddString("inviteAgentRoleId", *u.InviteAgentRoleId)
	}
	return nil
}

// `WechatAuthStatus` is a subscription of current status of wechat authentication
type WechatAuthStatus struct {
	Token   string          `json:"token"`
	State   WechatAuthState `json:"state"`
	Message *string         `json:"message,omitempty"`
}

type AccountType string

const (
	AccountTypeStudent     AccountType = "STUDENT"
	AccountTypeHqAgent     AccountType = "HQ_AGENT"
	AccountTypeLv1Agent    AccountType = "LV1_AGENT"
	AccountTypeLv2Agent    AccountType = "LV2_AGENT"
	AccountTypeHeadQuarter AccountType = "HEAD_QUARTER"
)

var AllAccountType = []AccountType{
	AccountTypeStudent,
	AccountTypeHqAgent,
	AccountTypeLv1Agent,
	AccountTypeLv2Agent,
	AccountTypeHeadQuarter,
}

func (e AccountType) IsValid() bool {
	switch e {
	case AccountTypeStudent, AccountTypeLv1Agent, AccountTypeLv2Agent, AccountTypeHeadQuarter, AccountTypeHqAgent:
		return true
	}
	return false
}

func (e AccountType) String() string {
	return string(e)
}

type WechatAuthState string

const (
	WechatAuthStateInit        WechatAuthState = "INIT"
	WechatAuthStateCodeScanned WechatAuthState = "CODE_SCANNED"
	WechatAuthStateAuthorized  WechatAuthState = "AUTHORIZED"
	WechatAuthStateSuccess     WechatAuthState = "SUCCESS"
	WechatAuthStateFailed      WechatAuthState = "FAILED"
	WechatAuthStateExpired     WechatAuthState = "EXPIRED"
)

var AllWechatAuthState = []WechatAuthState{
	WechatAuthStateInit,
	WechatAuthStateCodeScanned,
	WechatAuthStateAuthorized,
	WechatAuthStateSuccess,
	WechatAuthStateFailed,
}

func (e WechatAuthState) IsValid() bool {
	switch e {
	case WechatAuthStateInit, WechatAuthStateCodeScanned, WechatAuthStateAuthorized, WechatAuthStateSuccess, WechatAuthStateFailed:
		return true
	}
	return false
}

func (e WechatAuthState) String() string {
	return string(e)
}
