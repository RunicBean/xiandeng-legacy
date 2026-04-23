package models

import (
	"go.uber.org/zap/zapcore"
)

func (p CreateAccountParams) MarshalLogObject(enc zapcore.ObjectEncoder) error {
	enc.AddString("account_type", string(p.Type.Entitytype))
	enc.AddString("up_account", p.Upstreamaccount.UUID.String())
	enc.AddString("account_name", *p.Accountname)
	return nil
}

func (p ListOrderCouponParams) MarshalLogObject(enc zapcore.ObjectEncoder) error {
	enc.AddString("agent_id", p.Agentid)
	enc.AddString("product_id", p.Productid)
	enc.AddString("student_id", p.Studentid)
	enc.AddBool("valid", p.Valid)
	return nil
}

func (p RegisterUserParams) MarshalLogObject(enc zapcore.ObjectEncoder) error {

	if p.InvitationCode != nil {
		enc.AddString("invitation_code", *p.InvitationCode)
	}
	if p.ExistAccountID != nil {
		enc.AddString("exist_account_id", p.ExistAccountID.String())
	}
	enc.AddString("u_phone", p.UPhone)
	enc.AddString("nick_name", p.NickName)
	enc.AddString("open_id", p.OpenID)
	if p.AccountName != nil {
		enc.AddString("account_name", *p.AccountName)
	}
	enc.AddString("u_password", "***")
	if p.URelationship != nil {
		enc.AddString("relationship", *p.URelationship)
	}
	if p.UEmail != nil {
		enc.AddString("email", *p.UEmail)
	}
	if p.AvatarUrl != nil {
		enc.AddString("avatar_url", *p.AvatarUrl)
	}
	//enc.AddString("avatar_url", string_util.ConvertStringPtr(p.AvatarUrl))
	enc.AddString("u_source", p.USource)
	if p.InviteUserid != nil {
		enc.AddString("invite_userid", *p.InviteUserid)
	}
	//enc.AddString("invite_userid", string_util.ConvertStringPtr(p.InviteUserid))
	return nil
}
