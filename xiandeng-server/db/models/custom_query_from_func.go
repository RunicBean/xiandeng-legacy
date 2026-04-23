package models

import (
	"context"

	"github.com/jackc/pgx/v5/pgtype"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
)

const sevenLevelSubAgents = `-- name: SevenLevelSubAgents :many
  WITH cte AS (
    SELECT
      salesaccountid,
      SUM(amount) AS sum
    FROM
      partitionaward p
    WHERE
      accountid = $1 -- (select id from account where accountname='区代5') 
      AND partition = $2 -- 'L'::accountpartition
    GROUP BY
      salesaccountid
  )
    SELECT
      a.account_id,
      a.account_name, 
      COALESCE(cte.sum, 0) AS pv,
      level.value::TEXT AS account_type, 
      u.nickname,
      u.phone,
      u.email,
      CASE a.sub_level WHEN 1 THEN '是' ELSE '否' END AS direct_child
    FROM
      get_accounts_by_partition_and_depth(
        $1, --(select id from account where accountname='区代5') , 
        $2 --'L'::accountpartition
      ) a
    LEFT JOIN cte ON a.account_id = cte.salesaccountid
    LEFT JOIN useraccountrole uar on a.account_id=uar.accountid and uar.roleid=(select id from roles where rolename='OWNER' and accountkind='AGENT')
	left JOIN users u ON uar.userid = u.id
	LEFT JOIN datadictionary level ON a.account_type::text = level.key AND level.namespace = 'entitytype'
	WHERE a.account_status::text='ACTIVE'
    ORDER BY direct_child desc, pv desc
`

type SevenLevelSubAgentsParams struct {
	Paccountid uuid.UUID        `json:"paccountid"`
	Ppartition Accountpartition `json:"ppartition"`
}

type SevenLevelSubAgentsRow struct {
	AccountId   uuid.UUID       `json:"account_id"`
	AccountName string          `json:"account_name"`
	Pv          decimal.Decimal `json:"pv"`
	Level       string          `json:"level"`
	Nickname    *string         `json:"nickname"`
	Phone       *string         `json:"phone"`
	Email       *string         `json:"email"`
	//UserInfo    string          `json:"user_info"`
	DirectChild string `json:"direct_child"`
}

func (q *Queries) SevenLevelSubAgents(ctx context.Context, arg SevenLevelSubAgentsParams) ([]SevenLevelSubAgentsRow, error) {
	rows, err := q.db.Query(ctx, sevenLevelSubAgents, arg.Paccountid, arg.Ppartition)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var items []SevenLevelSubAgentsRow
	for rows.Next() {
		var i SevenLevelSubAgentsRow
		if err := rows.Scan(
			&i.AccountId,
			&i.AccountName,
			&i.Pv,
			&i.Level,
			&i.Nickname,
			&i.Phone,
			&i.Email,
			&i.DirectChild,
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

const generateSimpleOrderWithPaymentMethod = `-- name: GenerateSimpleOrderWithPaymentMethod :one
select * from generate_simple_order($1::uuid, $2::uuid, CASE WHEN $3::boolean THEN $4::bigint ELSE null END, $5::text)
`

type GenerateSimpleOrderWithPaymentMethodParams struct {
	Productid     uuid.UUID `json:"productid"`
	Studentid     uuid.UUID `json:"studentid"`
	Couponexists  bool      `json:"couponexists"`
	Couponcode    int64     `json:"couponcode"`
	Paymentmethod string    `json:"paymentmethod"`
}

type GenerateSimpleOrderWithPaymentMethodRow struct {
	Orderid  int64   `json:"orderid"`
	Sumprice *int    `json:"actualprice"`
	Message  *string `json:"errmsg"`
}

func (q *Queries) GenerateSimpleOrderWithPaymentMethod(ctx context.Context, arg GenerateSimpleOrderWithPaymentMethodParams) (*GenerateSimpleOrderWithPaymentMethodRow, error) {
	row := q.db.QueryRow(ctx, generateSimpleOrderWithPaymentMethod,
		arg.Productid,
		arg.Studentid,
		arg.Couponexists,
		arg.Couponcode,
		arg.Paymentmethod,
	)
	var i GenerateSimpleOrderWithPaymentMethodRow
	if err := row.Scan(
		&i.Orderid,
		&i.Sumprice,
		&i.Message,
	); err != nil {
		return nil, err
	}
	return &i, nil
}

const getStudentPlanningDataByAccountId = `-- name: GetStudentPlanningDataByAccountId :one
select u.phone,
       u.email,
       u.nickname,
       u.firstname,
       u.lastname,
       u.sex,
       u.province,
       u.city,
       u.avatarurl,
       acct.type,
       sa.university,
       sa.majorcode,
       sa.StudySuggestion as genstudysuggestion,
       sa.degree,
       m.name as major,
       m.StudyingSuggestion,
       m.core_course_learning,
       m.practical_skill_development,
       m.skill_expansion,
       m.MajorReference,
       ms.Type as mbtitype,
       ms.Suggestion as CharacterSuggestion,
       acct.createdat     as acctcreatedat,
	   uni.logo as universitylogo,
       uni.isgraduateeligible,
       uni.remark as uniremark,
       sa.entry_date,
       sa.total_score,
       sa.chinese,
       sa.mathematics,
sa.foreign_language,
sa.physics,
sa.chemistry,
sa.biology,
sa.politics,
sa.history,
sa.geography
from public.users u
         left join useraccountrole uar on u.id = uar.userid
         left join account acct on acct.id = uar.accountid
         left join public.roles r on r.id = uar.roleid
         left join public.studentattribute sa on acct.id = sa.accountid
         LEFT JOIN Major m ON sa.majorcode = m.code
         LEFT JOIN MBTISuggestion ms ON CONCAT(sa.MBTIEnergy, sa.MBTIMind, sa.MBTIDecision, sa.MBTIReaction) = ms.Type
		 LEFT JOIN university uni on uni.schoolname = sa.university
where acct.id = $1::uuid
  and r.rolename = 'STUDENT'
`

type GetStudentPlanningDataByAccountIdRow struct {
	Phone                     *string          `json:"phone"`
	Email                     *string          `json:"email"`
	Nickname                  string           `json:"nickname"`
	Firstname                 *string          `json:"firstname"`
	Lastname                  *string          `json:"lastname"`
	Sex                       Gender           `json:"sex"`
	Province                  *string          `json:"province"`
	City                      *string          `json:"city"`
	Avatarurl                 *string          `json:"avatarurl"`
	Accounttype               Entitytype       `json:"accounttype"`
	University                *string          `json:"university"`
	Majorcode                 *string          `json:"majorcode"`
	Genstudysuggestion        *string          `json:"genstudysuggestion"`
	Degree                    *string          `json:"degree"`
	Major                     *string          `json:"major"`
	StudyingSuggestion        *string          `json:"studyingsuggestion"`
	CoreCourseLearning        *string          `json:"core_course_learning"`
	PracticalSkillDevelopment *string          `json:"practical_skill_development"`
	SkillExpansion            *string          `json:"skill_expansion"`
	MajorReference            *string          `json:"majorreference"`
	Mbtitype                  *string          `json:"mbtitype"`
	CharacterSuggestion       *string          `json:"charactersuggestion"`
	Acctcreatedat             pgtype.Timestamp `json:"acctcreatedat"`
	Universitylogo            *string          `json:"universitylogo"`
	Isgraduateeligible        bool             `json:"isgraduateeligible"`
	Uniremark                 *string          `json:"uniremark"`
	Entry_date                pgtype.Timestamp `json:"entry_date"`
	Total_score               *float32         `json:"total_score"`
	Chinese                   *float32         `json:"chinese"`
	Mathematics               *float32         `json:"mathematics"`
	Foreign_language          *float32         `json:"foreign_language"`
	Physics                   *float32         `json:"physics"`
	Chemistry                 *float32         `json:"chemistry"`
	Biology                   *float32         `json:"biology"`
	Politics                  *float32         `json:"politics"`
	History                   *float32         `json:"history"`
	Geography                 *float32         `json:"geography"`
}

func (q *Queries) GetStudentPlanningDataByAccountId(ctx context.Context, accountId uuid.UUID) (GetStudentPlanningDataByAccountIdRow, error) {
	row := q.db.QueryRow(ctx, getStudentPlanningDataByAccountId, accountId)
	var i GetStudentPlanningDataByAccountIdRow
	err := row.Scan(
		&i.Phone,
		&i.Email,
		&i.Nickname,
		&i.Firstname,
		&i.Lastname,
		&i.Sex,
		&i.Province,
		&i.City,
		&i.Avatarurl,
		&i.Accounttype,
		&i.University,
		&i.Majorcode,
		&i.Genstudysuggestion,
		&i.Degree,
		&i.Major,
		&i.StudyingSuggestion,
		&i.CoreCourseLearning,
		&i.PracticalSkillDevelopment,
		&i.SkillExpansion,
		&i.MajorReference,
		&i.Mbtitype,
		&i.CharacterSuggestion,
		&i.Acctcreatedat,
		&i.Universitylogo,
		&i.Isgraduateeligible,
		&i.Uniremark,
		&i.Entry_date,
		&i.Total_score,
		&i.Chinese,
		&i.Mathematics,
		&i.Foreign_language,
		&i.Physics,
		&i.Chemistry,
		&i.Biology,
		&i.Politics,
		&i.History,
		&i.Geography,
	)
	return i, err
}

const getStudentPrecheckDataByAccountId = `-- name: GetStudentPrecheckDataByAccountId :one
select u.phone,
       acct.type,
       sa.university,
       sa.majorcode,
       sa.StudySuggestion as genstudysuggestion,
       m.name as major
from public.users u
         left join useraccountrole uar on u.id = uar.userid
         left join account acct on acct.id = uar.accountid
         left join public.roles r on r.id = uar.roleid
         left join public.studentattribute sa on acct.id = sa.accountid
         LEFT JOIN Major m ON sa.majorcode = m.code
where acct.id = $1::uuid
  and r.rolename = 'STUDENT'
`

type GetStudentPrecheckDataByAccountIdRow struct {
	Phone              *string    `json:"phone"`
	Accounttype        Entitytype `json:"accounttype"`
	University         *string    `json:"university"`
	Majorcode          *string    `json:"majorcode"`
	Genstudysuggestion *string    `json:"genstudysuggestion"`
	Major              *string    `json:"major"`
}

func (q *Queries) GetStudentPrecheckDataByAccountId(ctx context.Context, accountId uuid.UUID) (GetStudentPrecheckDataByAccountIdRow, error) {
	row := q.db.QueryRow(ctx, getStudentPrecheckDataByAccountId, accountId)
	var i GetStudentPrecheckDataByAccountIdRow
	err := row.Scan(
		&i.Phone,
		&i.Accounttype,
		&i.University,
		&i.Majorcode,
		&i.Genstudysuggestion,
		&i.Major,
	)
	return i, err
}

const studentJoinAgent = `-- name: StudentJoinAgent :exec
select * from student_join_agent($1, $2, $3)
`

type StudentJoinAgentParams struct {
	Userid    string    `json:"user_id"`
	Accountid uuid.UUID `json:"account_id"`
	RoleId    string    `json:"role_id"`
}

func (q *Queries) StudentJoinAgent(ctx context.Context, arg StudentJoinAgentParams) error {
	_, err := q.db.Exec(ctx, studentJoinAgent,
		arg.Userid,
		arg.Accountid,
		arg.RoleId,
	)
	return err
}

const registerUser = `-- name: RegisterUser :one
select userid, acocuntid, accounttype, userrole from register_user($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
`

type RegisterUserParams struct {
	InvitationCode *string    `json:"invitation_code"`
	ExistAccountID *uuid.UUID `json:"exist_account_id"`
	UPhone         string     `json:"u_phone"`
	NickName       string     `json:"nick_name"`
	OpenID         string     `json:"open_id"`
	AccountName    *string    `json:"account_name"`
	UPassword      string     `json:"u_password"`
	URelationship  *string    `json:"u_relationship"`
	UEmail         *string    `json:"u_email"`
	AvatarUrl      *string    `json:"avatar_url"`
	USource        string     `json:"u_source"`
	InviteUserid   *string    `json:"invite_userid"`
	RoleId         *string    `json:"role_id"`
}

type RegisterUserRow struct {
	Userid      string    `json:"userid"`
	Accountid   uuid.UUID `json:"accountid"`
	AccountType Roletype  `json:"accounttype"`
	UserRole    string    `json:"userrole"`
}

func (q *Queries) RegisterUser(ctx context.Context, arg RegisterUserParams) (RegisterUserRow, error) {
	row := q.db.QueryRow(ctx, registerUser,
		arg.InvitationCode,
		arg.ExistAccountID,
		arg.UPhone,
		arg.NickName,
		arg.OpenID,
		arg.AccountName,
		arg.UPassword,
		arg.URelationship,
		arg.UEmail,
		arg.AvatarUrl,
		arg.USource,
		arg.InviteUserid,
		arg.RoleId,
	)
	var i RegisterUserRow
	err := row.Scan(
		&i.Userid,
		&i.Accountid,
		&i.AccountType,
		&i.UserRole)
	return i, err
}

const agentToStudent = `-- name: AgentToStudent :exec
SELECT agent_to_student FROM agent_to_student(
        $1::uuid, -- user id
        $2::text, -- account name
        $3::text -- 关系
              )
`

type AgentToStudentParams struct {
	Userid       uuid.UUID `json:"userid"`
	Accountname  string    `json:"accountname"`
	Relationship *string   `json:"relationship"`
}

func (q *Queries) AgentToStudent(ctx context.Context, arg AgentToStudentParams) error {
	_, err := q.db.Exec(ctx, agentToStudent, arg.Userid, arg.Accountname, arg.Relationship)
	return err
}

const getProduct = `-- name: GetProduct :one
SELECT id, type, productname, finalprice, publishstatus, description, purchaselimit, pricingschedule, createdat, updatedat, (pricingschedule->>'conversion-award')::numeric(10,2) as conversionaward FROM get_product(get_student_accountid_by_userid($1::uuid)) where id = $2
`

type GetProductRow struct {
	ID              uuid.UUID        `json:"id"`
	Type            *string          `json:"type"`
	Productname     string           `json:"productname"`
	Finalprice      decimal.Decimal  `json:"finalprice"`
	Publishstatus   bool             `json:"publishstatus"`
	Description     string           `json:"description"`
	Purchaselimit   *int16           `json:"purchaselimit"`
	Pricingschedule []byte           `json:"pricingschedule"`
	Createdat       pgtype.Timestamp `json:"createdat"`
	Updatedat       pgtype.Timestamp `json:"updatedat"`
	Conversionaward decimal.Decimal  `json:"conversionaward"`
}

func (q *Queries) GetProduct(ctx context.Context, userId uuid.UUID, productId uuid.UUID) (GetProductRow, error) {
	row := q.db.QueryRow(ctx, getProduct, userId, productId)
	var i GetProductRow
	err := row.Scan(
		&i.ID,
		&i.Type,
		&i.Productname,
		&i.Finalprice,
		&i.Publishstatus,
		&i.Description,
		&i.Purchaselimit,
		&i.Pricingschedule,
		&i.Createdat,
		&i.Updatedat,
		&i.Conversionaward,
	)
	return i, err
}

const getStudentUserByAccountID = `-- name: GetStudentUserByAccountID :one
select users.id, users.password, users.phone, users.email, users.nickname, users.aliasname, users.firstname, users.lastname, users.wechatopenid, users.wechatunionid, users.sex, users.province, users.city, users.birthdate, users.avatarurl, users.status, users.source, users.referaluserid, users.createdat, users.updatedat
from useraccountrole uar
         left join users on uar.userid = users.id
where accountid = $1
  AND roleid IN (SELECT id
                 FROM roles
                 WHERE accountkind = 'STUDENT')
limit 1
`

func (q *Queries) GetStudentUserByAccountID(ctx context.Context, accountid uuid.UUID) (User, error) {
	row := q.db.QueryRow(ctx, getStudentUserByAccountID, accountid)
	var i User
	err := row.Scan(
		&i.ID,
		&i.Password,
		&i.Phone,
		&i.Email,
		&i.Nickname,
		&i.Aliasname,
		&i.Firstname,
		&i.Lastname,
		&i.Wechatopenid,
		&i.Wechatunionid,
		&i.Sex,
		&i.Province,
		&i.City,
		&i.Birthdate,
		&i.Avatarurl,
		&i.Status,
		&i.Source,
		&i.Referaluserid,
		&i.Createdat,
		&i.Updatedat,
	)
	return i, err
}
