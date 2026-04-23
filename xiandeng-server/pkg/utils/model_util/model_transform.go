package model_util

import (
	"time"
	"xiandeng.net.cn/server/pkg/utils"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
	"xiandeng.net.cn/server/db/models"
	model "xiandeng.net.cn/server/pkg/web/models"
	"xiandeng.net.cn/server/services/scraper"
)

func AccountTypeGqlToDB(t model.AccountType) models.NullEntitytype {
	dbT := models.NullEntitytype{}
	dbT.Scan(t.String())
	return dbT
}

func AccountTypeDBToGql(dbt models.NullEntitytype) model.AccountType {
	t := model.AccountType(dbt.Entitytype)
	return t
}

func InvitationCodeDBToGql(dbi models.Invitationcode) (i model.InvitationCode) {
	return model.InvitationCode{
		AccountID:  NullUUIDToString(dbi.Accountid),
		Code:       dbi.Code,
		UserID:     NullUUIDToString(dbi.Userid),
		CreateType: model.AccountType(dbi.Createtype.Entitytype),
		ExpiresAt:  dbi.Expiresat.Time.Format(time.RFC3339),
	}
}
func InvitationCodesDBToGql(dbl []models.ListInvitationCodesByUserIdRow) (l []model.InvitationCode) {
	// l = []*model.InvitationCode{}
	for _, r := range dbl {
		l = append(l, model.InvitationCode{
			AccountID:  NullUUIDToString(r.Accountid),
			Code:       r.Code,
			UserID:     "",
			CreateType: model.AccountType(r.Createtype.Entitytype),
			ExpiresAt:  r.Expiresat.Time.Format(time.RFC3339),
		})
	}
	return l
}

func ProductDBToGql(dbr models.Product) (r *model.Product, err error) {
	finalPrice := decimal.Decimal(dbr.Finalprice).String()
	return &model.Product{
		ID:            dbr.ID.String(),
		Type:          dbr.Type,
		ProductName:   &dbr.Productname,
		FinalPrice:    &finalPrice,
		PublishStatus: &dbr.Publishstatus,
		Description:   &dbr.Description,
	}, nil
}

func UUIDToNullUUID(i uuid.UUID) uuid.NullUUID {
	return uuid.NullUUID{UUID: i, Valid: true}
}

func NullUUIDToString(nuid uuid.NullUUID) string {
	if nuid.Valid {
		return nuid.UUID.String()
	} else {
		return ""
	}
}

func RecruitInsertParamsTransform(rs []*scraper.Recruit) []models.InsertRecruitsParams {
	var ret []models.InsertRecruitsParams
	for _, r := range rs {

		ret = append(ret, models.InsertRecruitsParams{
			Recruitid:       int32(r.RecruitId),
			Companyname:     &r.CompanyName,
			Enterprisename:  &r.EnterpriseName,
			Logourl:         r.LogoUrl,
			Citynamelist:    &r.CityNameList,
			Updatetime:      *utils.TimeStringToPgtypeTimestamp(&r.UpdateTime, "2006-01-02 15:04:05"),
			Endtime:         *utils.TimeStringToPgtypeDate(r.EndTime, "2006-01-02"),
			Begintime:       *utils.TimeStringToPgtypeDate(&r.Item.BeginTime, "2006-01-02"),
			Companytype:     &r.CompanyType,
			Content:         &r.Item.Content,
			Url:             &r.Item.Url,
			Overseasstudent: &r.Item.OverseasStudent,
			Domesticstudent: &r.Item.DomesticStudent,
			Releasesource:   &r.Item.ReleaseSource,
		})
	}
	return ret
}
