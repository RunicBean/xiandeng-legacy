package models

import (
	"context"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shopspring/decimal"
)

func (g Gender) HumanReadable() string {
	switch g {
	case Gender0:
		return "未知"
	case Gender1:
		return "男"
	case Gender2:
		return "女"
	default:
		panic(fmt.Sprintf("Gender value error: %s", g))
	}
}

const searchOrderCoupon = `-- name: SearchOrderCoupon :many
SELECT code, agentid, issuinguser, discountamount, maxcount, productid, studentid, effectstartdate, effectduedate, createdat, lastusedat FROM OrderCoupon
WHERE ($1::boolean = false OR StudentId::text = ANY($2))
AND ($3::boolean = false OR IssuingUser::text = ANY($4))
AND ($5::boolean = false OR DiscountAmount = $6)
AND ($7::boolean = false OR ProductId::text = ANY($8))
AND ($9::text = '' OR AgentId = $9::uuid)
AND ($10::boolean = false OR ((CURRENT_TIMESTAMP >= EffectStartDate OR EffectStartDate IS NULL) AND (CURRENT_TIMESTAMP <= EffectDueDate OR EffectDueDate IS NULL)))
AND ($11::boolean = false OR ((CURRENT_TIMESTAMP < EffectStartDate AND EffectStartDate IS NOT NULL) OR (CURRENT_TIMESTAMP > EffectDueDate OR EffectDueDate IS NOT NULL)))
AND ($12::text = '' OR DATE(CreatedAt) >= DATE($12::text))
AND ($13::text = '' OR DATE(CreatedAt) <= DATE($13::text))
AND ($14::boolean = false OR Code = $15)
AND ($16::boolean = false OR MaxCount = $17)
`

type SearchOrderCouponParams struct {
	Studentidvalid      bool                `json:"studentidvalid"`
	Studentids          []string            `json:"studentids"`
	Issuinguservalid    bool                `json:"issuinguservalid"`
	Issuingusers        []string            `json:"issuingusers"`
	Discountamountvalid bool                `json:"discountamountvalid"`
	Discountamount      decimal.NullDecimal `json:"discountamount"`
	Productidvalid      bool                `json:"productidvalid"`
	Productids          []string            `json:"productids"`
	Agentid             string              `json:"agentid"`
	Validonly           bool                `json:"validonly"`
	Expiredonly         bool                `json:"expiredonly"`
	Createdatstart      string              `json:"createdatstart"`
	Createdatend        string              `json:"createdatend"`
	Codevalid           bool                `json:"codevalid"`
	Code                int64               `json:"code"`
	Maxcountvalid       bool                `json:"maxcountvalid"`
	Maxcount            *int32              `json:"maxcount"`
}

func (q *Queries) SearchOrderCoupon(ctx context.Context, arg SearchOrderCouponParams) ([]Ordercoupon, error) {
	rows, err := q.db.Query(ctx, searchOrderCoupon,
		arg.Studentidvalid,
		arg.Studentids,
		arg.Issuinguservalid,
		arg.Issuingusers,
		arg.Discountamountvalid,
		arg.Discountamount,
		arg.Productidvalid,
		arg.Productids,
		arg.Agentid,
		arg.Validonly,
		arg.Expiredonly,
		arg.Createdatstart,
		arg.Createdatend,
		arg.Codevalid,
		arg.Code,
		arg.Maxcountvalid,
		arg.Maxcount,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var items []Ordercoupon
	for rows.Next() {
		var i Ordercoupon
		if err := rows.Scan(
			&i.Code,
			&i.Agentid,
			&i.Issuinguser,
			&i.Discountamount,
			&i.Maxcount,
			&i.Productid,
			&i.Studentid,
			&i.Effectstartdate,
			&i.Effectduedate,
			&i.Createdat,
			&i.Lastusedat,
		); err != nil {
			return nil, err
		}
		items = append(items, i)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return items, nil
}

const createOrderCouponWithDbProcedure = `-- name: CreateOrderCouponWithDbProcedure :one
select generate_new_coupon from generate_new_coupon(
  $1::uuid, 
  $2::numeric, 
  $3::int,
  $4::uuid,
  $5::uuid,
  $6::Date,
  $7::Date
)
`

type CreateOrderCouponWithDbProcedureParams struct {
	Userid         uuid.UUID       `json:"userid"`
	Discountamount decimal.Decimal `json:"discountamount"`
	Maxcount       *int32          `json:"maxcount"`
	Productid      uuid.NullUUID   `json:"productid"`
	Studentid      uuid.NullUUID   `json:"studentid"`
	Startdate      pgtype.Date     `json:"startdate"`
	Duedate        pgtype.Date     `json:"duedate"`
}

func (q *Queries) CreateOrderCouponWithDbProcedure(ctx context.Context, arg CreateOrderCouponWithDbProcedureParams) (interface{}, error) {
	row := q.db.QueryRow(ctx, createOrderCouponWithDbProcedure,
		arg.Userid,
		arg.Discountamount,
		arg.Maxcount,
		arg.Productid,
		arg.Studentid,
		arg.Startdate,
		arg.Duedate,
	)
	var generate_new_coupon interface{}
	err := row.Scan(&generate_new_coupon)
	return generate_new_coupon, err
}

const searchOrders = `-- name: SearchOrders :many
SELECT 
o.Id as OrderId,
o.UpdatedAt as UpdateTime,
o.Price as Price,
o.PaymentMethod,
o.Status,
acct.AccountName as StudentName,
agent_acct.AccountName as AgentName,
array_agg(p.ProductName) AS ProductList
FROM Orders o
LEFT JOIN Account acct
ON o.StudentId = acct.Id
LEFT JOIN Account agent_acct
ON acct.UpstreamAccount = agent_acct.Id
JOIN OrderProduct op
ON op.OrderId = o.Id
JOIN Product p ON op.ProductId = p.Id
WHERE (acct.AccountName LIKE $1 OR $1 IS NULL)
    AND (agent_acct.AccountName LIKE $2 OR $2 IS NULL)
    AND (o.UpdatedAt >= $3 OR $3 IS NULL)
	AND (o.UpdatedAt <= $4 OR $4 IS NULL)
    AND (o.Price >= $5 OR $5 IS NULL)
	AND (o.Price <= $6 OR $6 IS NULL)
	AND (o.PaymentMethod = $8 OR $8 IS NULL)
	AND (o.Status = ANY($9) OR $9 IS NULL)
GROUP BY o.Id, o.UpdatedAt, o.Price, acct.AccountName, agent_acct.AccountName
HAVING (array_to_string(array_agg(p.ProductName), ',') LIKE $7 OR $7 IS NULL)
`

type SearchOrdersParams struct {
	Studentname        *string             `json:"studentname"`
	Agentname          *string             `json:"agentname"`
	Updateatstart      *string             `json:"updateatstart"`
	Updateatend        *string             `json:"updateatend"`
	Pricerangestart    decimal.NullDecimal `json:"pricerangestart"`
	Pricerangeend      decimal.NullDecimal `json:"pricerangeend"`
	Productnamepattern any                 `json:"productnamepattern"`
	Paymentmethod      *string             `json:"paymentmethod"`
	StatusList         []string            `json:"statuslist"`
}

type SearchOrdersRow struct {
	Orderid       int64               `json:"orderid"`
	Updatetime    pgtype.Timestamp    `json:"updatetime"`
	Price         decimal.NullDecimal `json:"price"`
	Paymentmethod *string             `json:"paymentmethod"`
	Status        *string             `json:"status"`
	Studentname   *string             `json:"studentname"`
	Agentname     *string             `json:"agentname"`
	Productlist   interface{}         `json:"productlist"`
}

func (q *Queries) SearchOrders(ctx context.Context, arg SearchOrdersParams) ([]SearchOrdersRow, error) {
	rows, err := q.db.Query(ctx, searchOrders,
		arg.Studentname,
		arg.Agentname,
		arg.Updateatstart,
		arg.Updateatend,
		arg.Pricerangestart,
		arg.Pricerangeend,
		arg.Productnamepattern,
		arg.Paymentmethod,
		arg.StatusList,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var items []SearchOrdersRow
	for rows.Next() {
		var i SearchOrdersRow
		if err := rows.Scan(
			&i.Orderid,
			&i.Updatetime,
			&i.Price,
			&i.Paymentmethod,
			&i.Status,
			&i.Studentname,
			&i.Agentname,
			&i.Productlist,
		); err != nil {
			return nil, err
		}
		items = append(items, i)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return items, nil
}

const listBalanceActivityDetails = `-- name: ListBalanceActivityDetails :many
select 
ba.createdat
,ba.source
,ba.amount
,ba.balanceafter
,case ba.balancetype::text 
	when 'balance' then '余额'
	when 'balanceleft' then '左区余额'
	when 'balanceright' then '右区余额'
	when 'pendingreturn' then '剩余意向金'
	when 'balancetriplelock' then '三单循环(未解锁)'
	when 'balancetriple' then '三单循环(已解锁)'
	else null
end as balancetype
,case 
	when p.productname is not null then concat('售课: ',p.productname)
	when fo.originaltype is not null then concat('升级: ', originaltype.value,' -> ',targettype.value)
	when fo.targettype is not null then concat('加盟: ', targettype.value)
	else null
end as category
,case 
	when p.productname is not null then salesaccount.accountname
	when fo.targettype is not null then newaccount.accountname
	else null
end as salesprovider
,case
	when o.id is not null then o.id::text
	when fo.id is not null then fo.id::text
	else null
end as relatedorder
from balanceactivity ba
left join account a on ba.accountid=a.id
left join franchiseorder fo on ba.franchiseorderid=fo.id
left join account newaccount on fo.accountid=newaccount.id
left join orders o on ba.orderid=o.id
left join orderproduct op on o.id=op.orderid
left join product p on op.productid=p.id
left join datadictionary targettype on targettype.key=fo.targettype::text
left join datadictionary originaltype on originaltype.key=fo.originaltype::text
left join account student on o.studentid=student.id
left join account salesaccount on salesaccount.id=student.upstreamaccount
where (
  case when $1 = '提现' then ba.source = '提现'
  else ba.source != '提现' end
) AND (ba.createdat >= $2 OR $2 IS NULL)
	AND (ba.createdat <= $3 OR $3 IS NULL)
    AND (ba.amount >= $4 OR $4 IS NULL)
	AND (ba.amount <= $5 OR $5 IS NULL)
	AND (p.productname = any($6) OR $6 IS NULL)
  AND (o.id = $7 OR $7 IS NULL)
  AND (a.id = $8 OR $8 IS NULL)
order by ba.createdat desc
`

type ListBalanceActivityDetailsParams struct {
	Source          *string             `json:"source"`
	Createdatstart  *string             `json:"createdatstart"`
	Createdatend    *string             `json:"createdatend"`
	Pricerangestart decimal.NullDecimal `json:"pricerangestart"`
	Pricerangeend   decimal.NullDecimal `json:"pricerangeend"`
	Productlist     []string            `json:"productlist"`
	ID              *int64              `json:"id"`
	Accountid       *uuid.UUID          `json:"accountid"`
}

type ListBalanceActivityDetailsRow struct {
	Createdat     pgtype.Timestamp    `json:"createdat"`
	Source        *string             `json:"source"`
	Amount        decimal.NullDecimal `json:"amount"`
	Balanceafter  decimal.NullDecimal `json:"balanceafter"`
	Balancetype   interface{}         `json:"balancetype"`
	Category      interface{}         `json:"category"`
	Salesprovider interface{}         `json:"salesprovider"`
	Relatedorder  interface{}         `json:"relatedorder"`
}

func (q *Queries) ListBalanceActivityDetails(ctx context.Context, arg ListBalanceActivityDetailsParams) ([]ListBalanceActivityDetailsRow, error) {
	rows, err := q.db.Query(ctx, listBalanceActivityDetails,
		arg.Source,
		arg.Createdatstart,
		arg.Createdatend,
		arg.Pricerangestart,
		arg.Pricerangeend,
		arg.Productlist,
		arg.ID,
		arg.Accountid,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var items []ListBalanceActivityDetailsRow
	for rows.Next() {
		var i ListBalanceActivityDetailsRow
		if err := rows.Scan(
			&i.Createdat,
			&i.Source,
			&i.Amount,
			&i.Balanceafter,
			&i.Balancetype,
			&i.Category,
			&i.Salesprovider,
			&i.Relatedorder,
		); err != nil {
			return nil, err
		}
		items = append(items, i)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return items, nil
}

const searchStudents = `-- name: SearchStudents :many
SELECT
acct.accountname,
acct.createdat,
u.phone,
u.email,
case when 
  sa.university is not null and
  sa.majorcode is not null and
  sa.mbtienergy is not null and
  sa.mbtimind is not null and
  sa.mbtidecision is not null and
  sa.mbtireaction is not null then true
  else false end as surveycompleted,
array_agg(e.name) as entitlements
FROM Users u
LEFT JOIN UserAccountRole uar
ON u.id = uar.userid
LEFT JOIN Roles r
ON r.id = uar.roleid
LEFT JOIN Account acct
ON uar.AccountId = acct.id
LEFT JOIN StudentAttribute sa
ON acct.id = sa.AccountId
JOIN StudentEntitlement s
ON acct.id = s.StudentId
join entitlementtype e 
on s.entitlementtypeid = e.id
WHERE (acct.UpstreamAccount = $1 OR $1 IS NULL)
AND acct.type = 'STUDENT'
AND r.rolename = 'STUDENT'
AND (acct.AccountName LIKE $2 OR $2 IS NULL)
AND (u.Email LIKE $3 OR $3 IS NULL)
AND (u.Phone LIKE $4 OR $4 IS NULL)
AND (acct.CreatedAt >= $5 OR $5 IS NULL)
AND (acct.CreatedAt <= $6 OR $6 IS NULL)
GROUP BY (1,2,3,4,5)
`

type SearchStudentsParams struct {
	Upstreamaccount uuid.NullUUID `json:"upstreamaccount"`
	Accountname     *string       `json:"accountname"`
	Email           *string       `json:"email"`
	Phone           *string       `json:"phone"`
	Createdatfrom   *string       `json:"createdatfrom"`
	Createdatto     *string       `json:"createdatto"`
}

type SearchStudentsRow struct {
	Accountname     *string          `json:"accountname"`
	Createdat       pgtype.Timestamp `json:"createdat"`
	Phone           string           `json:"phone"`
	Email           *string          `json:"email"`
	Surveycompleted bool             `json:"surveycompleted"`
	Entitlements    interface{}      `json:"entitlements"`
}

func (q *Queries) SearchStudents(ctx context.Context, arg SearchStudentsParams) ([]SearchStudentsRow, error) {
	rows, err := q.db.Query(ctx, searchStudents,
		arg.Upstreamaccount,
		arg.Accountname,
		arg.Email,
		arg.Phone,
		arg.Createdatfrom,
		arg.Createdatto,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var items []SearchStudentsRow
	for rows.Next() {
		var i SearchStudentsRow
		if err := rows.Scan(
			&i.Accountname,
			&i.Createdat,
			&i.Phone,
			&i.Email,
			&i.Surveycompleted,
			&i.Entitlements,
		); err != nil {
			return nil, err
		}
		items = append(items, i)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return items, nil
}

const listPartitionAgents = `-- name: ListPartitionAgents :many

SELECT DISTINCT ON (a.account_id)
  a.account_id,
  a.account_name,
  cte.sum,
  ad.type,
  u.nickname,
  u.phone
FROM
  get_accounts_by_partition_and_depth(
    $1,
    $2
  ) a
LEFT join (
  SELECT
    salesaccountid,
    SUM(amount) AS sum
  FROM
    partitionaward p
  WHERE
    accountid = $1
    AND partition = $2
  GROUP BY
    salesaccountid
) cte ON a.account_id = cte.salesaccountid
LEFT JOIN account ad ON a.account_id = ad.id
LEFT JOIN useraccountrole uar ON a.account_id = uar.accountid
LEFT JOIN roles r ON uar.roleid = r.rolename
LEFT JOIN users u ON uar.userid = u.id
WHERE r.rolename = 'OWNER';`

type ListPartitionAgentsRow struct {
	Accountid   *uuid.UUID `json:"account_id"`
	Accountname *string    `json:"account_name"`
	Sum         *int64     `json:"sum"`
	Type        *string    `json:"type"`
	Nickname    *string    `json:"nickname"`
	Phone       *string    `json:"phone"`
}

func (q *Queries) ListPartitionAgents(ctx context.Context, accountId uuid.UUID, partition Accountpartition) ([]ListPartitionAgentsRow, error) {
	rows, err := q.db.Query(ctx, listPartitionAgents, accountId, partition)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var items []ListPartitionAgentsRow
	for rows.Next() {
		var i ListPartitionAgentsRow
		if err := rows.Scan(
			&i.Accountid,
			&i.Accountname,
			&i.Sum,
			&i.Type,
			&i.Nickname,
			&i.Phone,
		); err != nil {
			return nil, err
		}
		items = append(items, i)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return items, nil
}

const getAccountWithPendingFranchiseOrder = `-- name: GetAccountWithPendingFranchiseOrder :one
select 
account.accountname,
account.type,
account.status,
account.upstreamaccount,
fo.id,
fo.pendingfee,
fo.originaltype,
fo.targettype from account
left join (select id, accountid, status, paymentmethod, originaltype, targettype, pendingfee, createdat, updatedat from franchiseorder where status = 'pending') fo
on account.id = fo.accountid where account.id = $1
`

type GetAccountWithPendingFranchiseOrderRow struct {
	Accountname      *string             `json:"accountname"`
	Type             NullEntitytype      `json:"type"`
	Status           NullAccountstatus   `json:"status"`
	Upstreamaccount  uuid.NullUUID       `json:"upstreamaccount"`
	FranchiseorderID uuid.NullUUID       `json:"franchiseorderid"`
	Pendingfee       decimal.NullDecimal `json:"pendingfee"`
	Originaltype     NullEntitytype      `json:"originaltype"`
	Targettype       NullEntitytype      `json:"targettype"`
}

func (q *Queries) GetAccountWithPendingFranchiseOrder(ctx context.Context, id uuid.UUID) (GetAccountWithPendingFranchiseOrderRow, error) {
	row := q.db.QueryRow(ctx, getAccountWithPendingFranchiseOrder, id)
	var i GetAccountWithPendingFranchiseOrderRow
	err := row.Scan(
		&i.Accountname,
		&i.Type,
		&i.Status,
		&i.Upstreamaccount,
		&i.FranchiseorderID,
		&i.Pendingfee,
		&i.Originaltype,
		&i.Targettype,
	)
	return i, err
}

const searchAgentsWithPendingFranchiseOrder = `-- name: SearchAgentsWithPendingFranchiseOrder :many
select 
account.id, 
account.type, account.reservebalance, 
account.balance, 
account.upstreamaccount, 
upacct.accountname as upacctname, 
account.accountname, 
account.status, account.partition, account.balanceleft, account.balanceright, 
fo.targettype, fo.pendingfee, fo.id, account.pendingreturn, account.createdat, account.updatedat 
from account
left join (select id, accountid, status, paymentmethod, originaltype, targettype, pendingfee, createdat, updatedat from franchiseorder where status = 'pending') fo on account.id = fo.accountid 
left join account upacct on upacct.id = account.upstreamaccount
where account.type in ('HQ_AGENT', 'LV1_AGENT', 'LV2_AGENT') and (account.accountname like $1 or $1 is null)
`

type SearchAgentsWithPendingFranchiseOrderRow struct {
	ID               uuid.UUID            `json:"id"`
	Type             NullEntitytype       `json:"type"`
	Reservebalance   decimal.NullDecimal  `json:"reservebalance"`
	Balance          decimal.NullDecimal  `json:"balance"`
	Upstreamaccount  uuid.NullUUID        `json:"upstreamaccount"`
	Upacctname       *string              `json:"upacctname"`
	Accountname      *string              `json:"accountname"`
	Status           NullAccountstatus    `json:"status"`
	Partition        NullAccountpartition `json:"partition"`
	Balanceleft      decimal.NullDecimal  `json:"balanceleft"`
	Balanceright     decimal.NullDecimal  `json:"balanceright"`
	Targettype       NullEntitytype       `json:"targettype"`
	Pendingfee       decimal.NullDecimal  `json:"pendingfee"`
	FranchiseorderID uuid.NullUUID        `json:"franchiseorder_id"`
	Pendingreturn    decimal.NullDecimal  `json:"pendingreturn"`
	Createdat        pgtype.Timestamp     `json:"createdat"`
	Updatedat        pgtype.Timestamp     `json:"updatedat"`
}

func (q *Queries) SearchAgentsWithPendingFranchiseOrder(ctx context.Context, accountname *string) ([]SearchAgentsWithPendingFranchiseOrderRow, error) {
	rows, err := q.db.Query(ctx, searchAgentsWithPendingFranchiseOrder, accountname)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var items []SearchAgentsWithPendingFranchiseOrderRow
	for rows.Next() {
		var i SearchAgentsWithPendingFranchiseOrderRow
		if err := rows.Scan(
			&i.ID,
			&i.Type,
			&i.Reservebalance,
			&i.Balance,
			&i.Upstreamaccount,
			&i.Upacctname,
			&i.Accountname,
			&i.Status,
			&i.Partition,
			&i.Balanceleft,
			&i.Balanceright,
			&i.Targettype,
			&i.Pendingfee,
			&i.FranchiseorderID,
			&i.Pendingreturn,
			&i.Createdat,
			&i.Updatedat,
		); err != nil {
			return nil, err
		}
		items = append(items, i)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return items, nil
}

const completeInvitationCodes = `-- name: CompleteInvitationCodes :many
select o_code, o_createtype from check_and_insert_invitationcode($1::uuid)
`

type CompleteInvitationCodesResult struct {
	ICode      string `json:"o_code"`
	CreateType string `json:"o_createtype"`
}

func (q *Queries) CompleteInvitationCodes(ctx context.Context, userid uuid.UUID) ([]CompleteInvitationCodesResult, error) {
	rows, err := q.db.Query(ctx, completeInvitationCodes, userid)
	var result []CompleteInvitationCodesResult
	for rows.Next() {
		var i CompleteInvitationCodesResult
		if err := rows.Scan(
			&i.ICode,
			&i.CreateType,
		); err != nil {
			return nil, err
		}
		result = append(result, i)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return result, err
}

const listWithdraw = `-- name: ListWithdraw :many
select 
w.id, w.accountid, w.amount, w.status, w.type, w.memo, w.lastoperateuserid, w.userwithdrawmethodid, w.createdat, w.updatedat, 
a.Accountname, 
a.Type, 
uwm.Accountname as withdrawaccountname, 
uwm.accountnumber as withdrawaccountnumber, 
uwm.bank as withdrawbank from Withdraw w
LEFT JOIN UserWithdrawMethod uwm ON w.UserWithdrawMethodId = uwm.Id
LEFT JOIN Account a ON w.AccountId = a.Id
LEFT JOIN Users u ON w.LastOperateUserId = u.Id
WHERE (w.AccountId::text = $1 OR $1 IS NULL)
AND (w.LastOperateUserId::text = $2 OR $2 IS NULL)
AND (w.type::text = $3 OR $3 IS NULL)
AND (w.status::text = $4 OR $4 IS NULL)
AND (w.createdat >= $5 OR $5 IS NULL)
AND (w.createdat <= $6 OR $6 IS NULL)
AND (w.amount >= $7 OR $7 IS NULL)
AND (w.amount <= $8 OR $8 IS NULL)
`

type ListWithdrawParams struct {
	Accountid      *string          `json:"accountid"`
	Userid         *string          `json:"userid"`
	Withdrawtype   *Withdrawtype    `json:"withdrawtype"`
	Status         *string          `json:"status"`
	Createdatstart *string          `json:"createdatstart"`
	Createdatend   *string          `json:"createdatend"`
	Amountlow      *decimal.Decimal `json:"amountlow"`
	Amounthigh     *decimal.Decimal `json:"amounthigh"`
}

type ListWithdrawRow struct {
	ID                    interface{}         `json:"id"`
	Accountid             uuid.NullUUID       `json:"accountid"`
	Amount                decimal.NullDecimal `json:"amount"`
	Status                *string             `json:"status"`
	Type                  Withdrawtype        `json:"type"`
	Memo                  *string             `json:"memo"`
	Lastoperateuserid     uuid.NullUUID       `json:"lastoperateuserid"`
	Userwithdrawmethodid  uuid.NullUUID       `json:"userwithdrawmethodid"`
	Createdat             pgtype.Timestamp    `json:"createdat"`
	Updatedat             pgtype.Timestamp    `json:"updatedat"`
	Accountname           *string             `json:"accountname"`
	Type_2                NullEntitytype      `json:"type_2"`
	Withdrawaccountname   *string             `json:"withdrawaccountname"`
	Withdrawaccountnumber *string             `json:"withdrawaccountnumber"`
	Withdrawbank          *string             `json:"withdrawbank"`
}

func (q *Queries) ListWithdraw(ctx context.Context, arg ListWithdrawParams) ([]ListWithdrawRow, error) {
	rows, err := q.db.Query(ctx, listWithdraw,
		arg.Accountid,
		arg.Userid,
		arg.Withdrawtype,
		arg.Status,
		arg.Createdatstart,
		arg.Createdatend,
		arg.Amountlow,
		arg.Amounthigh,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var items []ListWithdrawRow
	for rows.Next() {
		var i ListWithdrawRow
		if err := rows.Scan(
			&i.ID,
			&i.Accountid,
			&i.Amount,
			&i.Status,
			&i.Type,
			&i.Memo,
			&i.Lastoperateuserid,
			&i.Userwithdrawmethodid,
			&i.Createdat,
			&i.Updatedat,
			&i.Accountname,
			&i.Type_2,
			&i.Withdrawaccountname,
			&i.Withdrawaccountnumber,
			&i.Withdrawbank,
		); err != nil {
			return nil, err
		}
		items = append(items, i)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return items, nil
}

const listStudents = `-- name: ListStudents :many
SELECT 
uar.AccountId as accountid,
u.id as userid,
acct.AccountName,
phone,
email,
nickname,
firstname,
lastname,
sex,
avatarurl,
sa.university,
acct.createdat
FROM Users u
LEFT JOIN useraccountrole uar
ON u.id = uar.userid
LEFT JOIN Account acct
ON uar.AccountId = acct.id
LEFT JOIN Roles r
ON r.id = uar.roleid
LEFT JOIN StudentAttribute sa
ON acct.id = sa.AccountId
LEFT JOIN Major m
ON sa.majorcode = m.code 
WHERE (acct.upstreamaccount = $1::uuid OR $1 IS NULL)
AND acct.type = 'STUDENT'
AND r.rolename = 'STUDENT'
AND ((acct.accountname ilike $2 OR phone ilike $2) OR $2 IS NULL)
`

type ListStudentsParams struct {
	Agentaccountid *uuid.UUID `json:"agentaccountid"`
	SearchString   *string    `json:"searchstring"`
}

type ListStudentsRow struct {
	Accountid   uuid.NullUUID    `json:"accountid"`
	Userid      uuid.UUID        `json:"userid"`
	Accountname *string          `json:"accountname"`
	Phone       string           `json:"phone"`
	Email       *string          `json:"email"`
	Nickname    string           `json:"nickname"`
	Firstname   *string          `json:"firstname"`
	Lastname    *string          `json:"lastname"`
	Sex         Gender           `json:"sex"`
	Avatarurl   *string          `json:"avatarurl"`
	University  *string          `json:"university"`
	Createdat   pgtype.Timestamp `json:"createdat"`
}

func (q *Queries) ListStudents(ctx context.Context, arg ListStudentsParams) ([]ListStudentsRow, error) {
	var likeString *string
	if arg.SearchString != nil {
		b := strings.Builder{}
		b.WriteString("%")
		b.WriteString(*arg.SearchString)
		b.WriteString("%")
		fmt.Println(b.String())
		s := b.String()
		likeString = &s
	}
	rows, err := q.db.Query(ctx, listStudents, arg.Agentaccountid, likeString)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var items []ListStudentsRow
	for rows.Next() {
		var i ListStudentsRow
		if err := rows.Scan(
			&i.Accountid,
			&i.Userid,
			&i.Accountname,
			&i.Phone,
			&i.Email,
			&i.Nickname,
			&i.Firstname,
			&i.Lastname,
			&i.Sex,
			&i.Avatarurl,
			&i.University,
			&i.Createdat,
		); err != nil {
			return nil, err
		}
		items = append(items, i)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return items, nil
}

const listProductsWithPrice = `-- name: ListProductsWithPrice :many
SELECT 
prd.Id,
prd.ProductName,
prd.Description,
prd.FinalPrice,
((prd.PricingSchedule->>concat(acct.type,'-course-purchase-price'))::numeric(8,2) - (prd.PricingSchedule->>'conversion-award')::numeric(8,2))::numeric(8,2) as inventoryprice
from get_product($1) prd
join account acct
on true
where acct.Id = $1
`

type ListProductsWithPriceRow struct {
	ID             uuid.UUID        `json:"id"`
	Productname    string           `json:"productname"`
	Description    string           `json:"description"`
	Finalprice     decimal.Decimal  `json:"finalprice"`
	Inventoryprice *decimal.Decimal `json:"inventoryprice"`
}

func (q *Queries) ListProductsWithPrice(ctx context.Context, id uuid.UUID) ([]ListProductsWithPriceRow, error) {
	rows, err := q.db.Query(ctx, listProductsWithPrice, id)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var items []ListProductsWithPriceRow
	for rows.Next() {
		var i ListProductsWithPriceRow
		if err := rows.Scan(
			&i.ID,
			&i.Productname,
			&i.Description,
			&i.Finalprice,
			&i.Inventoryprice,
		); err != nil {
			return nil, err
		}
		items = append(items, i)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return items, nil
}

const updateUser = `-- name: UpdateUser :exec
UPDATE Users
SET
  Password = COALESCE($2, Password),
  NickName = COALESCE($3, NickName),
  Email = COALESCE($4, Email),
  Phone = COALESCE($5, Phone),
  LastName = COALESCE($6, LastName),
  FirstName = COALESCE($7, FirstName),
  Sex = COALESCE($8, Sex)
WHERE Id = $1
`

type UpdateUserParams struct {
	ID        uuid.UUID `json:"id"`
	Password  *string   `json:"password"`
	Nickname  *string   `json:"nickname"`
	Email     *string   `json:"email"`
	Phone     *string   `json:"phone"`
	Lastname  *string   `json:"lastname"`
	Firstname *string   `json:"firstname"`
	Sex       *Gender   `json:"sex"`
}

func (q *Queries) UpdateUser(ctx context.Context, arg UpdateUserParams) error {
	_, err := q.db.Exec(ctx, updateUser,
		arg.ID,
		arg.Password,
		arg.Nickname,
		arg.Email,
		arg.Phone,
		arg.Lastname,
		arg.Firstname,
		arg.Sex,
	)
	return err
}

const getUserViewPrivilege = `-- name: GetUserViewPrivilege :many
with uar as (
	select accountid,roleid from useraccountrole uar, roles r where uar.roleid=r.id and userid=$1 and r.accountkind = any ($2)
),
userorg as (
	select orgid from account,uar where id=uar.accountid
), 
cte as (
    select privname,coalesce(isallow::int,0) as allowed,coalesce(isdeny::int,0) as denied
	from orgprivilege,userorg
	where case when userorg.orgid is null then orgprivilege.orgid is null else orgprivilege.orgid=userorg.orgid end --默认org是orgid=null
	union all
	select privname,coalesce(isallow::int,0) as allowed,coalesce(isdeny::int,0) as denied
	from roleprivilege,uar
	where roleprivilege.roleid=uar.roleid
)
select privname from cte
group by 1
having sum(allowed)>0 and sum(denied)=0
`

type GetUserViewPrivilegeParams struct {
	Userid       uuid.UUID `json:"userid"`
	Accountkinds []string  `json:"accountkinds"`
}

// $1: 当前用户 $2: 如果是代理的话，取'HQ','AGENT'  如果是学生的话，取'STUDENT'
// 聆鹿user '7d2c9a8e-3539-4438-9819-6519356448cf' 宋静user '4467d95e-45a5-432b-9396-32568cf380d9'
func (q *Queries) GetUserViewPrivilege(ctx context.Context, arg GetUserViewPrivilegeParams) ([]string, error) {
	rows, err := q.db.Query(ctx, getUserViewPrivilege, arg.Userid, arg.Accountkinds)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var items []string
	for rows.Next() {
		var privname string
		if err := rows.Scan(&privname); err != nil {
			return nil, err
		}
		items = append(items, privname)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return items, nil
}

const removeTagsForOrder = `-- name: RemoveTagsForOrder :exec
delete from ordertags where orderid = any($1)
`

func (q *Queries) RemoveTagsForOrder(ctx context.Context, orderid []int64) error {
	_, err := q.db.Exec(ctx, removeTagsForOrder, orderid)
	return err
}
