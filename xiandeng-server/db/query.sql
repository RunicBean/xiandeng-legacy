-- name: GetUser :one
SELECT 
*
FROM Users u
WHERE u.Id = $1 LIMIT 1;

-- name: ListUsers :many
SELECT 
Id,
NickName,
AvatarURL
FROM Users LIMIT $1;

-- name: GetUserByPhone :one
SELECT
*
FROM Users
WHERE Phone = $1;

-- name: GetUserByOpenid :one
SELECT
*
FROM Users
WHERE WechatOpenId = $1;

-- name: InitCreateUser :one
INSERT INTO Users (
  Phone,
  Password,
  NickName,
  Email,
  Province,
  City,
  WechatOpenId,
  AvatarURL,
  Source,
  Status,
  ReferalUserId
) VALUES (
  $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11
)
RETURNING Id;

-- name: UpdatePassword :exec
UPDATE Users SET
    Password = $2
WHERE Id = $1;

-- name: UpdateAliasname :exec
UPDATE Users SET
    AliasName = $2
WHERE Id = $1;

-- name: DeleteUser :exec
DELETE FROM Users
WHERE Id = $1;


-- name: GetAccount :one
SELECT * FROM Account WHERE Id = $1;

-- name: GetRoleOfUser :one
select
    r.rolename as usertype,
    acct.type as accounttype,
    exists(select 1 from useraccountrole uar left join roles r on uar.roleid = r.id where uar.accountid = $1 and r.rolename = 'STUDENT') as existstudent

from useraccountrole uar
left join roles r on r.Id = uar.RoleId
left join account acct on uar.accountid = acct.id
where uar.AccountId = $1 and uar.UserId = $2;
-- select
-- case
-- 	when exists(select 1 from guardian g where g.guardianid = @UserId) then 'guardian'
-- 	when (select type from account where id = (select accountid from users where id = @UserId) limit 1) = 'STUDENT' then 'student'
-- else 'agent' end as usertype,
-- acct.type as accounttype,
-- exists(select id from users where accountid = acct.id and id not in (select g2.guardianid from guardian g2)) as existstudent
-- from account acct
-- where id = (select accountid from users where id = @UserId)
-- ;

-- name: CreateAccount :one
INSERT INTO Account (
  Type, UpstreamAccount, AccountName
) VALUES (
  $1, $2, $3
)
RETURNING *;

-- name: CreateGuardian :exec
INSERT INTO Guardian (
  GuardianId, StudentId, Relationship
) VALUES (
  $1, $2, $3
);

-- name: DeleteInvitationCode :execresult
DELETE FROM InvitationCode
WHERE AccountId = $1
AND UserId = $2
AND CreateType = $3;

-- name: CreateInvitationCode :execresult
INSERT INTO InvitationCode (
  Code,
  AccountId,
  UserId,
  CreateType,
  ExpiresAt
) 
SELECT $1, $2, $3, $4, $5;

-- name: GetInvitationData :one
SELECT * FROM InvitationCode WHERE Code = $1;

-- name: CheckDownstreamStudentExists :one
select exists(SELECT accountname FROM Account a LEFT JOIN InvitationCode ic ON a.UpstreamAccount = ic.AccountId WHERE ic.Code = $1 AND a.Type = 'STUDENT' and a.accountname = $2);

-- name: ListInvitationCodesByUserId :many
SELECT Code, AccountId, CreateType, ExpiresAt FROM InvitationCode WHERE UserId = $1;


-- name: CreateAgentAttr :exec
INSERT INTO AgentAttribute (
  AccountId,
  Province,
  City
) VALUES (
  $1, $2, $3
);

-- name: GetAgentAttr :one
SELECT * FROM AgentAttribute WHERE AccountId = $1;

-- name: GetUpstreamAgentAttr :one
SELECT aa.*, acct.type FROM AgentAttribute aa
LEFT JOIN Account acct ON aa.AccountId = acct.Id
WHERE AccountId = (SELECT UpstreamAccount FROM Account acct1 WHERE acct1.Id = $1);

-- name: UpdateAgentSettings :exec
UPDATE AgentAttribute SET
  PaymentMethodAlipayOffline = $2,
  PaymentMethodCardOffline = $3,
  PaymentMethodWechatOffline = $4,
  PaymentMethodWechatPay = $5
WHERE AccountId = $1;

-- name: InitCreateStudentAttr :exec
INSERT INTO StudentAttribute (
  AccountId
) VALUES (
  $1
) on conflict do nothing;

-- name: GetStudentAttr :one
SELECT accountid FROM StudentAttribute WHERE accountid = $1;

-- name: UpdateStudentAttr :exec
UPDATE StudentAttribute SET
  University = $2,
  MajorCode = $3,
  MBTIEnergy = $4,
  MBTIMind = $5,
  MBTIDecision = $6,
  MBTIReaction = $7,
  Degree = $8,
  total_score = $9,
  chinese = $10,
  mathematics = $11,
  foreign_language = $12,
  physics = $13,
  chemistry = $14,
  biology = $15,
  politics = $16,
  history = $17,
  geography = $18,
  entry_date = $19,
  degree_years = $20
FROM Users
WHERE StudentAttribute.AccountId = get_student_accountid_by_userid($1);

-- name: UpdateStudentStudySuggestion :exec
UPDATE StudentAttribute SET
  StudySuggestion = $2
WHERE AccountId = $1;

-- name: GetStudySuggestion :one
SELECT StudySuggestion FROM StudentAttribute WHERE AccountId = $1;

-- name: GetStudentDetails :one
SELECT 
phone,
email,
nickname,
firstname,
lastname,
sex,
province,
city,
avatarurl,
acct.type,
sa.university,
sa.majorcode,
m.name as major,
m.Faculty as faculty,
m.Department as department,
ms.Type,
acct.createdat
FROM Users u
LEFT JOIN Account acct
ON acct.id = $2
LEFT JOIN StudentAttribute sa
ON acct.id = sa.AccountId
LEFT JOIN Major m
ON sa.majorcode = m.code
LEFT JOIN MBTISuggestion ms
ON CONCAT(sa.MBTIEnergy, sa.MBTIMind, sa.MBTIDecision, sa.MBTIReaction) = ms.Type
WHERE u.Id = $1;

-- name: GetStudentPlanningData :one
SELECT 
u.id as userid,
phone,
email,
nickname,
firstname,
lastname,
sex,
province,
city,
avatarurl,
acct.type,
sa.university,
sa.majorcode,
sa.StudySuggestion as genstudysuggestion,
m.name as major,
m.StudyingSuggestion,
m.MajorReference,
ms.Type as mbtitype,
ms.Suggestion as CharacterSuggestion,
acct.createdat
FROM Users u
LEFT JOIN Account acct
ON $2 = acct.id
LEFT JOIN StudentAttribute sa
ON acct.id = sa.AccountId
LEFT JOIN Major m
ON sa.majorcode = m.code
LEFT JOIN MBTISuggestion ms
ON CONCAT(sa.MBTIEnergy, sa.MBTIMind, sa.MBTIDecision, sa.MBTIReaction) = ms.Type
WHERE u.Id = $1;

-- name: GetMajorName :one
select name from major where code = $1;

-- name: GetStudentAttrsForSuggestGeneration :one
SELECT 
acct.accountname,
case when u.sex = '1' then '男' 
when u.sex = '2' then '女' else '未知' end as sex,
m.name as major,
sa.university,
m.StudyingSuggestion,
m.MajorReference,
CONCAT(sa.MBTIEnergy, sa.MBTIMind, sa.MBTIDecision, sa.MBTIReaction) as mbtitype
FROM Users u
LEFT JOIN Account acct
ON acct.id = @AccountId
LEFT JOIN StudentAttribute sa
ON acct.id = sa.AccountId
LEFT JOIN Major m
ON sa.majorcode = m.code
WHERE u.Id = @UserId;

-- name: ListFaculties :many
SELECT DISTINCT Faculty FROM Major;

-- name: ListDepartmentsByFaculty :many
SELECT DISTINCT Department FROM Major WHERE Faculty = $1; 

-- name: ListDepartments :many
SELECT DISTINCT Department FROM Major;

-- name: ListMajorsByDepartment :many
SELECT DISTINCT * FROM Major WHERE Department = $1;

-- name: SearchAssociateMajors :many
SELECT DISTINCT * FROM Major WHERE type = 'ASSOCIATE' and name like $1;

-- name: SearchBachelorMajors :many
SELECT DISTINCT * FROM Major WHERE type = 'BACHELOR' and name like $1;

-- name: ListMajors :many
SELECT DISTINCT * FROM Major;

-- name: GetPostgradSuggestionByMajorCode :one
SELECT PostgradSuggestion FROM Major WHERE Code = $1;

-- name: ListGoventerpriseByMajor :many
SELECT * FROM GovEnterprise ge
WHERE (@MajorCode::varchar = '' OR Id IN (
  SELECT EnterpriseId FROM MajorEnterprise me
  WHERE me.MajorCode = @MajorCode::varchar
)) AND (@Name::varchar = '' OR Name LIKE @Name::varchar) LIMIT $1 OFFSET $2;

-- name: CountGoventerpriseByMajor :one
SELECT COUNT(*) FROM GovEnterprise ge
WHERE (@MajorCode::varchar = '' OR Id IN (
  SELECT EnterpriseId FROM MajorEnterprise me
  WHERE me.MajorCode = @MajorCode::varchar
)) AND (@Name::varchar = '' OR Name LIKE @Name::varchar);

-- name: CreateEntitlementProduct :one
INSERT INTO Product (
  ProductName,
  FinalPrice,
  PublishStatus,
  Description
) VALUES (
  $1, $2, $3, $4
)
RETURNING *;

-- name: UpdateProduct :execresult
UPDATE Product SET
  ProductName = CASE WHEN @product_name_do_update::boolean
    THEN @product_name::varchar(255) ELSE ProductName END,
  FinalPrice = CASE WHEN @final_price_do_update::boolean
    THEN @final_price::decimal(8,2) ELSE FinalPrice END,
  PublishStatus = CASE WHEN @publish_status_do_update::boolean
    THEN @publish_status ELSE PublishStatus END,
  Description = CASE WHEN @description_do_update::boolean
    THEN @description ELSE Description END,
  UpdatedAt = CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'
WHERE 
  Id = @updated_by_id;

-- name: ListProduct :many
SELECT * FROM get_product($1);

-- name: ListPublishedProduct :many
SELECT * FROM product WHERE publishstatus = true;

-- name: GetPurchasableProducts :many
SELECT 
  p.id, 
  p.productname, 
  p.description 
FROM
    get_product(get_student_accountid_by_userid(@StudentId::uuid)) p
WHERE
  (p.purchaselimit IS NULL
OR
  p.purchaselimit > (
      SELECT COUNT(*) 
      FROM 
          public.orders o 
          JOIN public.orderproduct op ON o.id = op.orderid
      WHERE 
          o.studentid = get_student_accountid_by_userid(@StudentId::uuid)
          AND op.productid = p.id 
          AND o.status in ('paid','settled','uncommisioned')
  )) AND p.publishstatus = true;

-- name: GetPurchasedProducts :many
SELECT 
o.id,
o.payat,
p.productname,
p.description
FROM 
      public.orders o 
      left JOIN public.orderproduct op ON o.id = op.orderid
      left join get_product(get_student_accountid_by_userid(@StudentId::uuid)) p on op.productid = p.id
  WHERE 
      o.studentid = get_student_accountid_by_userid(@StudentId::uuid)
  AND o.status IN ('settled', 'paid','uncommisioned');

-- name: GetProductImages :many
SELECT * FROM ProductImage WHERE ProductId = $1;

-- name: CreateOrder :execresult
INSERT INTO Orders (
  Id,
  Status,
  StudentId,
  PaymentMethod
) VALUES (
  $1, $2, $3, $4
);

-- name: UpdateOrderStatus :execresult
UPDATE Orders SET 
Status = $2
WHERE Id = $1;

-- name: DeclineOrder :execresult
update Orders set status='declined',failurereason='headquarter declined' where id= $1;

-- name: SimpleDeclineOrder :execresult
update Orders set status='declined', updatedat=(now() at time zone 'Asia/Shanghai') where id= $1;

-- name: UpdateOrderPrice :execresult
update Orders set price = $2 where id = $1;

-- name: UpdateOrder :execresult
UPDATE Orders SET
PaymentMethod = CASE 
  WHEN @PaymentMethodDoUpdate::boolean THEN @PaymentMethod::varchar(255) 
  WHEN @PaymentMethodUpdateNull::boolean THEN null
  ELSE PaymentMethod 
END,
Status = CASE 
  WHEN @StatusDoUpdate::boolean THEN @Status::varchar(255) 
  ELSE Status 
END,
UpdatedAt = CASE
  WHEN @UpdatedAtToNow::boolean THEN CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'
  ELSE UpdatedAt
END
WHERE Id = @OrderId;

-- name: UpdateOrderAsPayed :execresult
UPDATE Orders SET
Status = "success",
PayAt = $2
WHERE Id = $1;

-- name: ListOrders :many
SELECT * FROM Orders;

-- name: ListRestrictedOrders :many
select
    o.createdat,
    o.id,
    p.productname,
    case
        when referal.aliasname is null then referal.nickname
        else referal.aliasname
    end as nickname,  -- referal's wechat name
    stat.value as status, -- status
    pm.value as paymentmethod, -- paymentmethod
    o.price,
    student.accountname,
    o.payat,
    (SELECT array_agg(tag) AS tags
     FROM (
              SELECT tag
              FROM ordertags
              WHERE orderid = o.id
              ORDER BY 1
          ) t)
from orders o
         left join orderproduct op on op.orderid=o.id
         left join product p on op.productid=p.id
         left join account student on o.studentid=student.id
         left join datadictionary stat on stat.key=o.status and stat.namespace='orderstatus'
         left join datadictionary pm on pm.key=o.paymentmethod and pm.namespace='paymentmethod'
         left join useraccountrole uar on student.id=uar.accountid
         left join roles r on uar.roleid=r.id and r.accountkind='STUDENT'
         left join users u on uar.userid=u.id
         left join users referal on u.referaluserid=referal.id
where student.upstreamaccount= @AccountId::uuid
  and u.createdat=( -- get the earliest user
    select min(u2.createdat) FROM public.users u2,useraccountrole uar2
    WHERE uar2.accountid=student.id and uar2.userid = u2.id
);

-- name: ListRestrictedOrdersByReferral :many
select
    o.createdat,
    o.id,
    p.productname,
    referal.nickname, -- referral's wechat name
    stat.value as status, -- status
    pm.value as paymentmethod, -- paymentmethod
    o.price,
    student.accountname,
    o.payat,
    (SELECT array_agg(tag) AS tags
     FROM (
              SELECT tag
              FROM ordertags
              WHERE orderid = o.id
              ORDER BY 1
          ) t)
from orders o
         left join orderproduct op on op.orderid=o.id
         left join product p on op.productid=p.id
         left join account student on o.studentid=student.id
         left join datadictionary stat on stat.key=o.status and stat.namespace='orderstatus'
         left join datadictionary pm on pm.key=o.paymentmethod and pm.namespace='paymentmethod'
         left join useraccountrole uar on student.id=uar.accountid
         left join roles r on uar.roleid=r.id and r.accountkind='STUDENT'
         left join users u on uar.userid=u.id
         left join users referal on u.referaluserid=referal.id
where student.upstreamaccount = @AccountId::uuid
  and u.createdat=( -- get the earliest user
    select min(u2.createdat) FROM public.users u2,useraccountrole uar2
    WHERE uar2.accountid=student.id and uar2.userid = u2.id
) and referal.id = @ReferralUserId::uuid;

-- name: ListPaymentMethods :many
SELECT DISTINCT PaymentMethod FROM Orders 
WHERE PaymentMethod IS NOT NULL
AND PaymentMethod != '';

-- name: GetOrder :one
SELECT * FROM Orders WHERE Id = $1;

-- name: UpdateOrderProductPrice :execresult
UPDATE OrderProduct SET ActualPrice = $2 WHERE OrderId = $1;

-- name: CreateOrderProductRelation :execresult
INSERT INTO OrderProduct (
  Id,
  OrderId,
  ProductId,
  OriginalPrice,
  CouponCode,
  ActualPrice
) VALUES (
  $1, $2, $3, $4, $5, $6
);

-- name: GetOrderPrice :one
select get_order_price as OrderPrice from get_order_price(@OrderId::bigint);

-- name: GetPurchasePrice :one
select get_purchase_price as PurchasePrice from get_purchase_price(@ProductId::uuid, @AccountId::uuid);

-- name: PaySuccess :one
select pay_success(@OrderId::bigint, @ForceSettle::boolean);

-- name: RevokePay :one
select revoke_pay from revoke_pay(@OrderId::bigint, @RetainEntitlement::boolean);

-- name: OrderCouponCheck :one
select * from order_coupon_check(@OrderId::bigint, @CouponCode::bigint);

-- name: GenerateSimpleOrder :one
select * from generate_simple_order(@ProductId::uuid, @StudentId::uuid, CASE WHEN @CouponExists::boolean THEN @CouponCode::bigint ELSE null END);

-- name: GetOrderProductsByOrderId :many
SELECT * FROM OrderProduct op
LEFT JOIN Product p
ON op.ProductId = p.Id
WHERE OrderId = $1;


-- -- name: CreateOrderCoupon :exec
-- INSERT INTO OrderCoupon (
--   Code,
--   AgentId,
--   IssuingUser,
--   DiscountAmount,
--   MaxCount,
--   ProductId,
--   StudentId,
--   EffectStartDate,
--   EffectDueDate,
--   CreatedAt
-- ) VALUES (
--   $1, $2, $3, $4, $5, $6, $7, $8, $9, $10
-- );

-- name: ListOrderCoupon :many
SELECT * FROM OrderCoupon
WHERE (@StudentId::text = '' OR StudentId = @StudentId::uuid)
AND (@ProductId::text = '' OR ProductId = @ProductId::uuid)
AND (@AgentId::text = '' OR AgentId = @AgentId::uuid)
AND (@Valid::boolean = false OR (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai' >= EffectStartDate AND CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai' <= EffectDueDate));

-- name: GetCouponByCode :one
SELECT * FROM OrderCoupon
WHERE Code = $1;

-- name: UseOrderCoupon :exec
UPDATE OrderCoupon SET
LastUsedAt = CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'
WHERE Code = $1;

-- name: ListEntitlement :many
SELECT * FROM StudentEntitlement
WHERE (@StudentId::text = '' OR StudentId = @StudentId::uuid)
AND (@FilterValid::boolean = false OR ExpiresAt IS NULL OR CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai' <= ExpiresAt);

-- name: GetQianliaoCoupon :many
SELECT * FROM QianliaoCoupon
WHERE StudentId = @StudentId::uuid;

-- name: ListRecruitMainPage :many
SELECT 
RecruitId,
CompanyName,
LogoUrl,
Tag,
CityNameList,
UpdateTime
FROM Recruit
ORDER BY UpdateTime desc
OFFSET @Start::int
LIMIT (CASE WHEN @Size::int > 0 THEN @Size::int END);

-- name: CheckRecruitIdExists :one
SELECT EXISTS(SELECT 1 FROM Recruit WHERE RecruitId = $1);

-- name: GetRecruitDetail :one
SELECT * FROM Recruit WHERE RecruitId = $1;

-- name: InsertRecruits :copyfrom
INSERT INTO Recruit
(
  RecruitId,
  CompanyName,
  EnterpriseName,
  LogoUrl,
  CityNameList,
  UpdateTime,
  CompanyType,
  EndTime,
  Content,
  Url,
  BeginTime,
  OverseasStudent,
  DomesticStudent,
  ReleaseSource
) VALUES (
  $1, 
  $2, 
  $3, 
  $4,
  $5,
  $6,
  $7,
  $8,
  $9,
  $10,
  $11,
  $12,
  $13,
  $14
);

-- name: GetActiveEntitlements :many
select e.name from studententitlement s left join entitlementtype e 
on s.entitlementtypeid = e.id 
WHERE (@StudentId::text = '' OR StudentId = @StudentId::uuid) and now() <= s.expiresat;

-- name: CheckEntitlementAvailable :one
select exists(select e.name from studententitlement s left join entitlementtype e 
on s.entitlementtypeid = e.id 
WHERE (@StudentId::text = '' OR StudentId = @StudentId::uuid)
and e.name like @EntitlementNameLike
and (now() <= s.expiresat or s.expiresat is null));


-- name: GetBalance :one
select Balance, ReserveBalance, BalanceLeft, BalanceRight, PendingReturn, BalanceTriple, BalanceTripleLock from account where id = $1;

-- name: GetOngoingWithdraws :many
select type, status, amount from Withdraw where status in ('REQUESTED', 'LOCKED') and accountid = $1;

-- name: ListStudentDetails :many
select * from v_studentdetails where (@AgentIdFilter::boolean = false OR AgentId::uuid = @AgentId);

-- name: ListStudentDetailsByReferal :many
select v.*, referal.id as referalid from v_studentdetails as v
 left join useraccountrole uar on studentid=uar.accountid
 left join users u on uar.userid=u.id
 left join users referal on u.referaluserid=referal.id where AgentId::uuid = @AgentId
and referal.id = @ReferalId;


-- name: ListCarouselData :many
select * from showcasepagecarouseldata where company = $1;

-- name: ListItemData :many
select * from showcasepageitemdata where company = $1;

-- name: GetCompanyByPath :one
select * from company where path = $1;

-- name: ListStudentForPlanning :many
select studentid,
       agentid,
       studentname,
       v.createdat,
       tags,
       exists(select e.name
              from studententitlement s
                       left join entitlementtype e
                                 on s.entitlementtypeid = e.id
              WHERE StudentId = v.studentid
                and e.name like '%规划报告%'
                and (now() <= s.expiresat or s.expiresat is null)) as purchased,
       case when sa.majorcode is not null then true else false end    filled,
       case
           when sa.studysuggestion = 'pending' then 'pending'
           when sa.studysuggestion is not null then 'done'
           end                                                        generated
from v_studentdetails v
         left join studentattribute sa
                   on v.studentid = sa.accountid
where (@AgentIdFilter::boolean = false OR v.AgentId::uuid = @AgentId);

-- name: ListStudentForPlanningByReferral :many
select studentid,
       agentid,
       studentname,
       v.createdat,
       tags,
       exists(select e.name
              from studententitlement s
                       left join entitlementtype e
                                 on s.entitlementtypeid = e.id
              WHERE StudentId = v.studentid
                and e.name like '%规划报告%'
                and (now() <= s.expiresat or s.expiresat is null)) as purchased,
       case when sa.majorcode is not null then true else false end    filled,
       case
           when sa.studysuggestion = 'pending' then 'pending'
           when sa.studysuggestion is not null then 'done'
           end                                                        generated
from v_studentdetails v
         left join studentattribute sa
                   on v.studentid = sa.accountid
         left join useraccountrole uar on studentid=uar.accountid
         left join roles r on uar.roleid=r.id and r.accountkind='STUDENT'
         left join users u on uar.userid=u.id
         left join users referal on u.referaluserid=referal.id
where (@AgentIdFilter::boolean = false OR v.AgentId::uuid = @AgentId)
and referal.id = @ReferralUserId::uuid;

-- usedby /account/my-agent/list
-- name: ListMyDirectAgents :many
select account.id, accountname, partition, balanceleft, balanceright, type, account.status,
u.phone, u.email, u.nickname
from account
inner join users u on account.id = get_agent_accountid_by_userid(u.id)
 where upstreamaccount = $1;

-- name: UpdateAgentTargettype :exec
-- update account set targettype = $1 where id = $2;
insert into franchiseorder (
  accountid,
  originaltype,
  targettype
) VALUES (
  $1, (select type from account where id=$1), $2
);

-- name: AssignAward :exec
SELECT assign_award(fo.id) FROM franchiseorder fo, account a WHERE fo.accountid=a.id and fo.status='pending' and a.id = @AccountId::uuid;

-- name: SearchAgentsWithAttributes :many
select
    type,
    accountname,
    account.createdat,
    account.status,
    partition,
    aa.accountid,
    aa.province,
    aa.city,
    aa.agentcode,
    aa.PaymentMethodWechatOffline,
    aa.PaymentMethodAlipayOffline,
    aa.PaymentMethodCardOffline,
    aa.PaymentMethodWechatPay,
    aa.PaymentMethodLiuliupay,
    aa.demo_flag,
    aa.demo_account,
    r.rolename,
    u.phone,
    u.email,
    o.uri as orguri
from account
         right join useraccountrole uar on account.id = uar.accountid
         left join public.users u on u.id = uar.userid
         left join public.roles r on r.id = uar.roleid
         left join agentattribute aa on account.id = aa.accountid
         left join organization o on o.id = account.orgid
where
    type in ('HQ_AGENT', 'LV1_AGENT', 'LV2_AGENT') and r.rolename = 'OWNER'
  and (account.accountname like $1 or $1 is null)
and (@Phone::text = '' or u.phone like @Phone::text)
and (@Email::text = '' or u.email like @Email::text);

-- name: CalculateSumPv :many
select partition, sum(amount)::Decimal as sum from partitionaward 
where accountid= $1
group by partition;

-- name: ListSubAgentDetails :many
select salesaccount.accountname 
,p.createdat 
,p.amount 
,pd.productname 
,targetlevel.value as level
 from partitionaward p 
 left join orders o on p.orderid=o.id 
 left join orderproduct op on op.orderid=o.id 
 left join product pd on op.productid=pd.id
 left join account a on p.accountid=a.id
 left join account salesaccount on p.salesaccountid=salesaccount.id
 left join franchiseorder fo on p.franchiseorderid=fo.id 
 left join datadictionary targetlevel on fo.targettype::text=targetlevel.key and targetlevel.namespace='entitytype'
 where a.id = $1 --当前登录的账号 e.g. a.accountname='合伙人8'
 and salesaccount.id = $2 -- 一级菜单的账号 e.g. salesaccount.accountname='合伙人10'
 order by p.createdat;

-- name: UpstreamAgentPendingAccounts :many
select a.accountname as upagent,child.accountname as childagent, fo.createdat as ordercreatedat from account a 
	left join account child on a.id=child.upstreamaccount 
	left join franchiseorder fo on fo.accountid=child.id
where fo.status='pending'
and fo.createdat < (select createdat from franchiseorder where id= @FranchiseOrderId::uuid)
and a.id =(select upstreamaccount from account where id=(select accountid from franchiseorder where id= @FranchiseOrderId::uuid));

-- name: ListLiuliustatementByOrderId :many
select * from liuliustatement where orderid = $1;

-- name: GetWording :many
select key, value from datadictionary where namespace=$1;

-- name: CreateWithdrawMethod :one
insert into userwithdrawmethod(userid, withdrawmethod, accountname, accountnumber, bank) values ($1, $2, $3, $4, $5) returning id;

-- name: ListWithdrawMethods :many
select * from userwithdrawmethod where userid=$1 and withdrawmethod = $2;

-- name: DeleteWithdrawMethod :exec
delete from userwithdrawmethod where id=$1;

-- name: UpdateBankWithdrawMethod :exec
update userwithdrawmethod set accountname=$2, accountnumber=$3, bank=$4 where id=$1;

-- name: CreateWithdraw :one
insert into Withdraw(accountid, type, LastOperateUserId, amount, UserWithdrawMethodId) values ($1, $2, $3, $4, $5) returning id;

-- name: UpdateWithdrawStatus :exec
update Withdraw set status=$2 where id=$1;

-- name: DeleteWithdraw :exec
delete from Withdraw where id=$1;

-- name: ListDelivery :many
select 
pd.id,
p.productname
,pd.price
,student.accountname
,agent.accountname 
from projectdelivery pd 
left join orderproduct op on pd.orderproductid =op.id 
left join orders o on op.orderid = o.id 
left join account student on o.studentid = student.id 
left join product p on op.productid = p.id 
left join account agent on student.upstreamaccount=agent.id
where deliveryaccount = $1 -- e.g. 'cc961f55-bbd5-4c9d-91f5-ee7b70e4ab29'
and pd.status=$2;

-- name: ConfirmDelivery :one
select * from public.confirm_delivery(@DeliveryId);

-- name: CreateInventoryOrder :one
insert into inventoryorder(accountid, productid, quantity, type, status) values ($1, $2, $3, $4, $5) returning id;

-- name: UpdateInventoryOrderPaymentMethod :exec
update inventoryorder set paymentmethod=$2 where id=$1::text;

-- name: UpdateInventoryOrderStatus :exec
update inventoryorder set status=$2, updatedat=(CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai') where id=$1::text;

-- name: ConfirmInventoryOrder :exec
select confirm_inventory(@InventoryOrderId);

-- name: ListInventory :many
select
    pdi.id,
    p.id as productid,
    p.productname,
    pdi.quantity,
    coalesce(io.quantity,0) as wip,
    coalesce(-(select sum(quantity) from productinventoryhistory pih where pih.sourceid=pdi.id and pih.quantity<0),0) as used
from productinventory pdi
left join product p on pdi.productid = p.id
left join inventoryorder io on pdi.accountid=io.accountid and io.productid=pdi.productid and io.status='pending'
where pdi.accountid = $1 --(select id from account where accountname='区代5')
union all
select
    null,
    null,
    p2.productname,
    0::int4,
    io2.quantity,
    0::int4
from inventoryorder io2
    left join product p2 on io2.productid=p2.id
where io2.accountid = $1 --(select id from account where accountname='区代5')
    and io2.productid not in (select productid from productinventory pdi2 where accountid = $1 --(select id from account where accountname='区代5')
);

-- name: GetInventoryActivities :many
select pih.createdat --as 创建时间
,p.productname --as 商品名称
,pih.quantity --as 变化数量
,pih.quantityafter --as 调整后数量
,pih.inventoryorderid --as 库存订单号
,pih.orderid --as 订单号
from productinventoryhistory pih 
left join productinventory "pi" on "pi".id=pih.sourceid  
left join product p on "pi".productid=p.id
where "pi".accountid= $1
order by pih.createdat desc;

-- name: GetMaximumQuantity :one
select get_max_inventory_quantity(@AccountId, @ProductId);

-- name: InventoryCourseOrders :many
select 
salesaccount.id as salesid
,o.createdat --as 创建时间
,o.id --as 订单号
,student.accountname --as 学生姓名
,p.productname --as 商品名称
,paymentmethod.value as paymentmethod --as 付款方式
,status.value as status --as 状态
,oc.code --as 销售代码
,oc.discountamount --as 优惠金额
,o.price --as 实付金额
, case when proof.existed > 0 then '有' else '无' end as proof--凭证
from orders o 
left join account student on o.studentid =student.id 
left join account salesaccount on student.upstreamaccount=salesaccount.id 
left join orderproduct op on o.id=op.orderid 
left join product p on op.productid=p.id 
left join ordercoupon oc on op.couponcode=oc.code 
left join datadictionary paymentmethod on o.paymentmethod=paymentmethod.key and paymentmethod."namespace"='paymentmethod'
left join datadictionary status on o.status=status.key and status."namespace"='orderstatus'
left join (select orderid,count(*) as existed from orderofflinepayproof group by 1) proof on proof.orderid=o.id 
where salesaccount.id= $1
order by o.createdat desc; -- e.g. '378a4104-a8a9-4b3e-b675-039a23530fb3'

-- name: ListTripleAwardDetails :many
SELECT (t."number"-1)/3+1 AS whichround, -- 第几轮,
       (t."number"-1)%3+1 AS whichorder, -- 第几单,
       child.accountname AS childaccountname, -- 加盟商,
       t.targettype AS targettype, -- 级别,
       '电话:'||coalesce(u.phone,'')||' | 微信名:'||coalesce(u.nickname,'')||' | 邮箱:'||coalesce(u.email,'') as childaccountinfo, -- 加盟商负责人,
       t.amount AS amount, -- 三单循环奖励金额,
       d.value as unlockcondition, -- 解锁条件,
       CASE
           WHEN t.pendingreturn > 0 THEN t.pendingreturn::text
           ELSE '已解锁'
END AS unlockpendingreturn, -- 剩余解锁金额,
       t.createdat AS createdat, -- 创建时间,
       case when t.updatedat=t.createdat then null else t.updatedat end AS lastupdatedat -- 最后售课时间  -- 记录刚生成的时候，updatedat=created.此时没有售课
FROM triplecycleaward t
LEFT JOIN account child ON t.linkedaccountid = child.id
LEFT JOIN useraccountrole uar ON uar.accountid = child.id AND uar.roleid = (( SELECT roles.id
       FROM roles WHERE roles.accountkind = 'AGENT'::roletype AND roles.rolename::text = 'OWNER'::text))
LEFT JOIN users u ON u.id = uar.userid
left join datadictionary d on d.key=concat(t.targettype::text,'-x-unlock')
where t.accountid= $1  -- Please replace the variable with current account. Example:(select id from account where accountname='总代1')
order by number;

-- name: ListTripleUnlockDetails :many
select 
th.createdat, -- 解锁时间
th.amount, -- as 本次解锁金额,
th.pendingreturnafter||coalesce(case when th.pendingreturnafter<0 then '(已解锁)' else null end,'') AS pendingamount, -- 剩余解锁金额,
p.productname, -- as 课程,
d.value as unlockcondition, -- 解锁条件,
child.accountname as childaccountname -- 加盟商
from tripleawardhistory th
left join orders o on th.orderid=o.id 
left join orderproduct op on op.orderid=o.id 
left join product p on p.id=op.productid
left join triplecycleaward t on t.id=th.sourceid
LEFT JOIN account child ON t.linkedaccountid = child.id
left join datadictionary d on d.key=t.targettype::text||'-x-unlock'
where th.sourceid= $1; -- Replace with parent triplecycleaward.id e.g. '54f92831-26c1-478e-8b9b-7e0d89117b6a'

-- name: ListInventoriesForHQ :many
select
    io.createdat,-- as 创建时间,
    io.id,-- as 库存订单号,
    acct.accountname,-- as 代理名,
    p.productname,-- as 商品,
    io.unitprice,-- as 单价,
    io.quantity,-- as 数量,
    io.unitprice*io.quantity as totalprice,-- 总价,
    case when proof.existed > 0 then '有' else '无' end as proof -- 凭证
from inventoryorder io
    left join product p on io.productid=p.id
    left join (select inventoryorderid,count(*) as existed from inventoryorderproof group by 1) proof on proof.inventoryorderid=io.id
    left join account acct on io.accountid=acct.id
where io.type='agent_topup'
  and io.status='pending'
order by 1 desc;

-- name: GetAgentAccountIdByUserId :one
select accountid from useraccountrole
                 left join account acct on acct.id=useraccountrole.accountid
                 where userid=$1 and acct.type in ('LV1_AGENT','LV2_AGENT', 'HQ_AGENT', 'HEAD_QUARTER');

-- name: GetStudentAccountIdByUserId :one
select accountid from useraccountrole
                 left join account acct on acct.id=useraccountrole.accountid
                 where userid=$1 and acct.type in ('STUDENT');

-- name: ListNameCheckResults :many
select
    id,
    accountname,
    (select u.phone from useraccountrole uar
                             left join public.users u on u.id = uar.userid
                             left join public.roles r on uar.roleid = r.id
     where uar.accountid = account.id and r.rolename = 'STUDENT'),
    (select concat(g.relationship, ' ', u.phone) from useraccountrole uar
                                                          left join public.users u on u.id = uar.userid
                                                          left join public.roles r on uar.roleid = r.id
                                                          left join public.guardian g on u.id = g.guardianid
     where uar.accountid = account.id and r.rolename = 'GUARDIAN_PRIMARY') as guardian
from account
where accountname = $1 and type = 'STUDENT'
;

-- name: StudentToAgent :exec
select * from student_to_agent(
        @UserId::uuid, -- user id
        @AccountName::text, -- account name
        @EntityType::entitytype -- entity type. 要加上类型转换::entitytype LV1_AGENT/LV2_AGENT
              );

-- name: SearchUniversitiesByNamelike :many
select schoolname from university where schoolname like $1;

-- name: IsUniversityGraduateEligible :one
select isgraduateeligible from university where schoolname = $1;

-- name: ListOrgWxCredentials :many
select id, uri, wxappid, wxappsecret from organization;

-- name: GetOrgMetadata :one
select id, config, logourl, sitename, redirecturl from organization where uri = $1;

-- name: InsertOrderTags :copyfrom
insert into ordertags (orderid, tag) values ($1, $2);

-- name: GetRolesByAcctKind :many
select id, rolename_cn from roles where accountkind=$1 and rolename!='OWNER';

-- name: InsertAdjustment :exec
insert into adjustment (accountid, amount, balancetype, notes, operateuserid)
values ($1, $2, $3, $4, $5);

-- name: ListAdjustmentRecords :many
select
    adj.createdat -- as 创建时间
     ,a.accountname-- as 账号名称
     ,adj.balancetype-- as 余额类型
     ,adj.amount-- 调账金额
     , ba.balanceafter-- as 调账后余额
     , adj.notes-- as 备注
     ,u.nickname-- as 操作用户
from adjustment adj
         left join account a on adj.accountid = a.id
         left join balanceactivity ba on ba.adjustmentid =adj.id
         left join users u on adj.operateuserid = u.id;

-- name: GetDemoAccount :one
SELECT demo_account
FROM agentattribute
WHERE demo_flag = TRUE
  AND accountid = (SELECT accountid
                   FROM useraccountrole
                   WHERE userid = (SELECT id
                                   FROM users
                                   WHERE wechatopenid = $1)
                     AND roleid IN (SELECT id
                                    FROM roles
                                    WHERE accountkind != 'STUDENT'));
