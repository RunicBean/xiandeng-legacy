package models

import (
	"fmt"

	"xiandeng.net.cn/server/pkg/utils"
	"xiandeng.net.cn/server/pkg/utils/string_util"
)

func (row ListMyDirectAgentsRow) ToMap() map[string]interface{} {
	return map[string]interface{}{
		"accountname":  row.Accountname,
		"nickname":     row.Nickname,
		"phone":        row.Phone,
		"email":        row.Email,
		"status":       row.Status.Accountstatus,
		"balanceleft":  row.Balanceleft,
		"balanceright": row.Balanceright,
		"id":           row.ID,
		"partition":    row.Partition.Accountpartition,
		"type":         row.Type.Entitytype,
	}
}

func ListMyDirectAgentsRowsToMaps(rows []ListMyDirectAgentsRow) []map[string]any {
	var result []map[string]any
	for _, row := range rows {
		result = append(result, row.ToMap())
	}
	return result
}

// func (row ListMyFirstLevelAgentsRow) ToMap() map[string]interface{} {
// 	return map[string]interface{}{
// 		"accountname": row.AccountName,
// 		"nickname":    row.Nickname,
// 		"phone":       row.Phone,
// 		"id":          row.AccountID,
// 		"partition":   row.Partition.Accountpartition,
// 		"type":        row.AccountType.Entitytype,
// 	}
// }

func (m *Account) ToMap() map[string]interface{} {
	return map[string]interface{}{
		"accountname":     m.Accountname,
		"balance":         m.Balance,
		"balanceleft":     m.Balanceleft,
		"balanceright":    m.Balanceright,
		"createdat":       m.Createdat,
		"id":              m.ID,
		"partition":       m.Partition.Accountpartition,
		"pendingreturn":   m.Pendingreturn,
		"reservebalance":  m.Reservebalance,
		"status":          m.Status.Accountstatus,
		"type":            m.Type.Entitytype,
		"updatedat":       m.Updatedat,
		"upstreamaccount": m.Upstreamaccount,
	}
}

func (m *SearchAgentsWithPendingFranchiseOrderRow) ToMap() map[string]interface{} {
	return map[string]interface{}{
		"accountname":      m.Accountname,
		"balance":          m.Balance,
		"balanceleft":      m.Balanceleft,
		"balanceright":     m.Balanceright,
		"createdat":        m.Createdat,
		"id":               m.ID,
		"partition":        m.Partition.Accountpartition,
		"pendingreturn":    m.Pendingreturn,
		"reservebalance":   m.Reservebalance,
		"status":           m.Status.Accountstatus,
		"type":             m.Type.Entitytype,
		"updatedat":        m.Updatedat,
		"upstreamaccount":  m.Upstreamaccount,
		"upacctname":       m.Upacctname,
		"pendingfee":       m.Pendingfee,
		"targettype":       m.Targettype.Entitytype,
		"franchiseorderid": m.FranchiseorderID,
	}
}

func (m *SearchAgentsWithAttributesRow) ToMap() map[string]interface{} {
	return map[string]interface{}{
		"type":                       m.Type.Entitytype,
		"accountname":                m.Accountname,
		"createdat":                  m.Createdat,
		"status":                     m.Status.Accountstatus,
		"partition":                  m.Partition.Accountpartition,
		"accountid":                  m.Accountid,
		"province":                   m.Province,
		"city":                       m.City,
		"agentcode":                  m.Agentcode,
		"paymentmethodalipayoffline": m.Paymentmethodalipayoffline,
		"paymentmethodwechatoffline": m.Paymentmethodwechatoffline,
		"paymentmethodcardoffline":   m.Paymentmethodcardoffline,
		"paymentmethodwechatpay":     m.Paymentmethodwechatpay,
		"paymentmethodliuliupay":     m.Paymentmethodliuliupay,
		"demo_flag":                  m.DemoFlag,
		"demo_account":               m.DemoAccount,
		"phone":                      m.Phone,
		"email":                      m.Email,
		"orguri":                     m.Orguri,
	}
}

func SearchAgentsWithAttributesRowsToMaps(rows []SearchAgentsWithAttributesRow) []map[string]any {
	var result []map[string]any
	for _, row := range rows {
		result = append(result, row.ToMap())
	}
	return result
}

func (p UpdateStudentAttrParams) ToMap() map[string]interface{} {
	return map[string]interface{}{
		"userid":    p.UserID,
		"majorcode": string_util.ConvertStringPtr(p.Majorcode),
		"mbti": fmt.Sprintf(
			"%s%s%s%s",
			string_util.ConvertStringPtr(p.Mbtienergy),
			string_util.ConvertStringPtr(p.Mbtimind),
			string_util.ConvertStringPtr(p.Mbtidecision),
			string_util.ConvertStringPtr(p.Mbtireaction)),
		"university":  string_util.ConvertStringPtr(p.University),
		"degree":      p.Degree,
		"degreeyears": *p.DegreeYears,
		"totalscore":  utils.PtrToFloat64(p.TotalScore),
		"chinese":     utils.PtrToFloat64(p.Chinese),
		"math":        utils.PtrToFloat64(p.Mathematics),
		"forlan":      utils.PtrToFloat64(p.ForeignLanguage),
		"physics":     utils.PtrToFloat64(p.Physics),
		"biology":     utils.PtrToFloat64(p.Biology),
		"chemistry":   utils.PtrToFloat64(p.Chemistry),
		"politics":    utils.PtrToFloat64(p.Politics),
		"history":     utils.PtrToFloat64(p.History),
		"geography":   utils.PtrToFloat64(p.Geography),
		"entrydate":   utils.PgDateToTimeString(p.EntryDate),
	}
}
