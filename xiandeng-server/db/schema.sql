CREATE TYPE Gender AS ENUM (
  '0',
  '1',
  '2'
);

CREATE TYPE EntityType AS ENUM (
  'HEAD_QUARTER',
  'HQ_AGENT',
  'LV1_AGENT',
  'LV2_AGENT',
  'STUDENT'
);

CREATE TYPE withdrawtype AS ENUM ('balance', 'partition', 'triple');

CREATE TYPE public.new_user_acount AS (
    userid uuid,
    acocuntid uuid);


CREATE TABLE Users (
  Id uuid PRIMARY key default uuid_generate_v4(),
  Password varchar(65535) NOT NULL,
  Phone varchar(255) UNIQUE NOT NULL,
  Email varchar(255) UNIQUE,
  NickName varchar(255) NOT NULL,
    AliasName varchar(512) NULL,
  FirstName varchar(255),
  LastName varchar(255),
  WechatOpenId varchar(255),
  WechatUnionId varchar(255),
  Sex Gender NOT NULL DEFAULT '0',
  Province varchar(255),
  City varchar(255),
  BirthDate date,
  AvatarURL text,
  Status varchar(255) NOT NULL,
  Source varchar(255),
  ReferalUserId uuid,
  CreatedAt timestamp DEFAULT (CURRENT_TIMESTAMP),
  UpdatedAt timestamp DEFAULT (CURRENT_TIMESTAMP)
);

create type accountstatus as enum ('INIT', 'ACTIVE', 'CLOSED');
CREATE TYPE accountpartition AS ENUM ('L', 'R');

CREATE TABLE Account (
  Id UUID PRIMARY KEY default uuid_generate_v4(),
  Type EntityType,
  ReserveBalance decimal(8,2),
  Balance decimal(8,2),
  UpstreamAccount UUID,
  AccountName varchar(255),
  Status accountstatus,
  partition accountpartition,
    balanceleft decimal(8,2),
    balanceright decimal(8,2),
  pendingreturn numeric(8, 2),
    balancetriple decimal(8,2),
    balancetriplelock decimal(8,2),
    orgid uuid,
  CreatedAt timestamp DEFAULT (CURRENT_TIMESTAMP),
  UpdatedAt timestamp DEFAULT (CURRENT_TIMESTAMP) 
);


-- 家长
CREATE TABLE Guardian (
  GuardianId uuid PRIMARY KEY,
  StudentId uuid,
  Relationship varchar(255), -- Enum-参考亲宝宝
  CreatedAt timestamp DEFAULT (CURRENT_TIMESTAMP),
  UpdatedAt timestamp DEFAULT (CURRENT_TIMESTAMP)
);


CREATE TABLE AgentAttribute (
  AccountId uuid PRIMARY KEY,
  Province varchar(255),
  City varchar(255),
  CreatedAt timestamp DEFAULT (CURRENT_TIMESTAMP),
  UpdatedAt timestamp DEFAULT (CURRENT_TIMESTAMP),
  AgentCode varchar(64),
  PaymentMethodWechatOffline boolean NOT NULL DEFAULT true,
  PaymentMethodAlipayOffline boolean NOT NULL DEFAULT true,
  PaymentMethodCardOffline boolean NOT NULL DEFAULT true,
  PaymentMethodWechatPay boolean NOT NULL DEFAULT true,
--   CouponInputEnabled boolean NOT NULL DEFAULT true,
  paymentmethodliuliupay boolean NOT NULL DEFAULT true,
  demo_flag bool NOT NULL DEFAULT false,
  demo_account UUID,
  CONSTRAINT fk_agentattribute_demo_account
      FOREIGN KEY (demo_account)
          REFERENCES account(id)
          ON DELETE SET NULL
--   liuliuqrcode text NULL,
--   liuliustoreaddress text NULL
);


CREATE TABLE StudentAttribute (
  AccountId uuid PRIMARY KEY,
  University varchar(255),
  MajorCode VARCHAR(255),
  MBTIEnergy varchar(32),
  MBTIMind varchar(32),
  MBTIDecision varchar(32),
  MBTIReaction varchar(32),
  StudySuggestion TEXT,
    entry_date date,
    degree_years smallint,
    grade smallint,
    semester smallint,
    degree majortype,
    total_score float,
    chinese float,
    mathematics float,
    foreign_language float,
    physics float,
    chemistry float,
    biology float,
    politics float,
    history float,
    geography float,
  CreatedAt timestamp DEFAULT (CURRENT_TIMESTAMP),
  UpdatedAt timestamp DEFAULT (CURRENT_TIMESTAMP)
);

CREATE TYPE public."majortype" AS ENUM (
	'BACHELOR',
	'ASSOCIATE',
	'MASTER',
	'PHD');

CREATE TABLE Major (
  Code varchar(255) PRIMARY KEY,
  Name varchar(255), -- 专业
  Faculty varchar(255), -- 门类
  Department varchar(255), -- 大类
  StudyingSuggestion TEXT, -- 就读建议
  MajorReference TEXT, -- 专业资源
  "type" majortype,
  PostgradSuggestion varchar(65535)
);

CREATE TABLE GovEnterprise (
  Id smallint PRIMARY KEY,
  Name varchar(255),
  Website text
);

CREATE TABLE MajorEnterprise (
  MajorCode varchar(255),
  EnterpriseId smallint,
  PRIMARY KEY (MajorCode, EnterpriseId)
);


CREATE TABLE StudentEntitlement (
  Id uuid PRIMARY KEY default uuid_generate_v4(),
  StudentId uuid,
  EntitlementTypeId uuid,
  LastOrderId bigint, -- 最后一次下单Id
  CreatedAt timestamp DEFAULT (CURRENT_TIMESTAMP),
  ExpiresAt timestamp, -- 有效期
  UpdatedAt timestamp DEFAULT (CURRENT_TIMESTAMP)
);


CREATE TABLE EntitlementType (
  Id uuid PRIMARY KEY default uuid_generate_v4(),
  Name varchar(255)
);

-- 订单只能整体完成和整体失败，不能部分完成
CREATE TABLE Orders (
  Id bigint PRIMARY KEY, -- yyyymmddnnnnnnnn
  Status varchar(255), -- pending payment,succeeded,expired
  StudentId uuid,
  PaymentMethod varchar(255), -- 目前只有wechat-native
  Price DECIMAL(8,2), -- 商品实付价格的总和
  CreatedAt timestamp DEFAULT (CURRENT_TIMESTAMP),
  PayAt timestamp, -- 支付时间
  UpdatedAt timestamp DEFAULT (CURRENT_TIMESTAMP),
  settledat TIMESTAMP NULL
);


-- 多个商品可以同时下单。但要注意如果多个商品包含相同Entitlement，要在页面提醒买家
CREATE TABLE OrderProduct (
  Id bigint PRIMARY KEY, -- OrderId+数字后缀
  OrderId bigint,
  ProductId uuid,
  OriginalPrice DECIMAL(8,2),
  CouponCode bigint, -- 最好可以纯数字
  ActualPrice DECIMAL(8,2)
);


CREATE TABLE OrderCoupon (
  Code bigint PRIMARY KEY, -- zerofill, 8 digits
  AgentId uuid NOT NULL, -- 创建优惠券的代理
  IssuingUser uuid NOT NULL, -- 创建优惠券的用户
  DiscountAmount decimal(8,2), -- 优惠金额
  MaxCount int, -- 最多使用次数
  ProductId uuid, -- 非空则表示只能在购买某一种商品时使用
  StudentId uuid, -- 非空则表示只能给特定学生使用
  EffectStartDate date, -- 起始日期：有效期起始日期 （可置空)
  EffectDueDate date, -- 截止日期：有效期的截止日期 （不得早于起始日期，可置空）
  CreatedAt timestamp DEFAULT (CURRENT_TIMESTAMP),
  LastUsedAt timestamp DEFAULT (CURRENT_TIMESTAMP) -- 使用时间
);


CREATE TABLE Product (
  Id uuid PRIMARY KEY default uuid_generate_v4(),
  Type varchar(255) DEFAULT 'Entitlement',
  ProductName VARCHAR(255) NOT NULL, -- 商品名称
  FinalPrice DECIMAL(8,2) NOT NULL, -- 商品零售价格
  PublishStatus boolean NOT NULL, -- 上下架状态：0下架1上架
  Description TEXT NOT NULL, -- 商品描述
  PurchaseLimit smallint DEFAULT 0,
  pricingschedule jsonb,
  CreatedAt timestamp DEFAULT (CURRENT_TIMESTAMP),
  UpdatedAt timestamp DEFAULT (CURRENT_TIMESTAMP)
);


CREATE TABLE ProductEntitlementType (
  ProductId uuid,
  EntitlementTypeId uuid,
  ValidDays int, -- 授权有效期，以天计算。如果为空，代表长期有效
  PRIMARY KEY (ProductId, EntitlementTypeId)
);


CREATE TABLE ProductImage (
  Id uuid PRIMARY KEY default uuid_generate_v4(),
  ProductId uuid,
  ImageURL text, -- 图片URL
  IsMaster boolean, -- 是否主图：0.非主图1.主图
  ImageOrder smallint, -- 图片排序
  ImageStatus boolean -- 图片是否有效：0无效 1有效
);


CREATE TABLE ProductPriceOverwrite (
  Id uuid PRIMARY KEY default uuid_generate_v4(),
  RootProduct uuid, -- 参考总部发布的商品
  Name varchar(255) NOT NULL,
  DownstreamAccountId uuid, -- 协议下游买家Id,Parent可通过Account hierarchy获得
  Price decimal(8,2),
  createdat timestamp NULL,
  updatedat timestamp NULL
);

CREATE TABLE QianliaoCoupon (
  Id serial PRIMARY KEY,
  CouponCode varchar(255),
  StudentId uuid,
  CreatedAt timestamp DEFAULT (CURRENT_TIMESTAMP),
  UpdatedAt timestamp DEFAULT (CURRENT_TIMESTAMP)
);

CREATE TABLE BalanceActivity (
  Id uuid PRIMARY KEY default uuid_generate_v4(),
  Source varchar(255), -- 提现，分成
  OrderId bigint, -- 收入,关联订单号
  WithdrawId uuid, -- 提现成功，关联提现id
  AccountId uuid,
  Amount decimal(8,2), -- 正数为收入，负数为支出
  BalanceAfter decimal(8, 2),
  CreatedAt timestamp DEFAULT (CURRENT_TIMESTAMP),
  UpdatedAt timestamp DEFAULT (CURRENT_TIMESTAMP)
);


CREATE TABLE AccountAddress (
  Id uuid PRIMARY KEY default uuid_generate_v4(),
  AccountId uuid, -- 只有学生account需要地址
  Zip int NOT NULL, -- 邮编
  Province varchar(10) NOT NULL,
  City varchar(20) NOT NULL,
  District varchar(255) NOT NULL,
  Address varchar(255) NOT NULL, -- 具体的地址门牌号
  IsDefault boolean NOT NULL, -- 是否默认
  CreatedAt timestamp DEFAULT (CURRENT_TIMESTAMP),
  UpdatedAt timestamp DEFAULT (CURRENT_TIMESTAMP)
);



CREATE TABLE Withdraw (
  -- Id uuid PRIMARY KEY default uuid_generate_v4(),
  id bpchar(16) NOT NULL,
  AccountId uuid, -- 只有代理需要提现
  Amount decimal(8,2), -- 提现金额,非负数
  Status varchar(255), -- PENDING,DISPATCHED,CANCELLED,DECLINED
  Type withdrawtype NOT NULL,
  Memo varchar(255),
  LastOperateUserId uuid,
  UserWithdrawMethodId uuid,
  CreatedAt timestamp DEFAULT (CURRENT_TIMESTAMP),
  UpdatedAt timestamp DEFAULT (CURRENT_TIMESTAMP)
);


CREATE TABLE WithdrawAttachment (
  Id uuid PRIMARY KEY default uuid_generate_v4(),
  WithdrawId uuid,
  ImageURL text -- 图片URL
);


CREATE TYPE public."roletype" AS ENUM (
	'HQ',
	'AGENT',
	'STUDENT');

-- CREATE TABLE Role (
--   Id uuid PRIMARY KEY default uuid_generate_v4(),
--   Name varchar(255),
--   AccountType EntityType,
--   IsSystem boolean,
--   CreatedAt timestamp DEFAULT (CURRENT_TIMESTAMP),
--   UpdatedAt timestamp DEFAULT (CURRENT_TIMESTAMP)
-- );


CREATE TABLE public.roles (
                              id uuid DEFAULT uuid_generate_v4() NOT NULL,
                              rolename varchar(255) not NULL,
                              accountkind public."roletype" NOT NULL,
                              issystem bool not NULL,
                              rolename_cn varchar(255) NULL,
                              createdat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
                              updatedat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
                              CONSTRAINT role_pkey PRIMARY KEY (id)
);


CREATE TABLE public.useraccountrole (
                                        id uuid DEFAULT uuid_generate_v4() NOT NULL,
                                        userid uuid NOT NULL,
                                        accountid uuid NOT NULL,
                                        roleid uuid NOT NULL,
                                        createdat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
                                        updatedat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
                                        CONSTRAINT useraccountrole_pkey PRIMARY KEY (id),
                                        CONSTRAINT useraccountrole_userid_fkey FOREIGN KEY (userid) REFERENCES public.users(id),
                                        CONSTRAINT useraccountrole_roleid_fkey FOREIGN KEY (roleid) REFERENCES public.roles(id),
                                        CONSTRAINT useraccount_accountid_fkey FOREIGN KEY (accountid) REFERENCES public.account(id)
);

Create TABLE CasbinRule (
    p_type varchar(32) NOT NULL,
    v0 uuid NOT NULL,
    v1 uuid NOT NULL,
    v2 varchar(255) NOT NULL,
    v3 varchar(255) NOT NULL,
    v4 varchar(255) NOT NULL,
    v5 varchar(255) NOT NULL
);

CREATE TABLE InvitationCode (
  Code char(13) PRIMARY KEY,
  AccountId uuid,
  UserId uuid,
  CreateType EntityType,
  CreatedAt timestamp DEFAULT (CURRENT_TIMESTAMP),
  ExpiresAt timestamp,
  UpdatedAt timestamp DEFAULT (CURRENT_TIMESTAMP)
);

CREATE TABLE CustomSQL (
  Id serial NOT NULL PRIMARY KEY,
  Description varchar(255) NOT NULL,
  Query varchar(65535) NOT NULL,
  Param1Name varchar(255),
  Param1Default varchar(255),
  Param2Name varchar(255),
  Param2Default varchar(255),
  Param3Name varchar(255),
  Param3Default varchar(255),
  Param4Name varchar(255),
  Param4Default varchar(255),
  Param5Name varchar(255),
  Param5Default varchar(255),
  Param6Name varchar(255),
  Param6Default varchar(255),
  Param7Name varchar(255),
  Param7Default varchar(255),
  Param8Name varchar(255),
  Param8Default varchar(255),
  Param9Name varchar(255),
  Param9Default varchar(255)
);

CREATE TABLE AccountSQL (
  AccountType EntityType,
  AccountId uuid,
  SQLId int,
  PRIMARY KEY (AccountType, AccountId, SQLId)
);


CREATE TABLE CustomSQLQueryHistory (
  Id serial NOT NULL PRIMARY KEY,
  UserId uuid NOT NULL,
  SQLId int NOT NULL,
  Param1Default varchar(255),
  Param2Default varchar(255),
  Param3Default varchar(255),
  Param4Default varchar(255),
  Param5Default varchar(255),
  Param6Default varchar(255),
  Param7Default varchar(255),
  Param8Default varchar(255),
  Param9Default varchar(255),
  Status varchar(32) NOT NULL,
  Message varchar(255),
  CreatedAt timestamp DEFAULT (CURRENT_TIMESTAMP),
  UpdatedAt timestamp DEFAULT (CURRENT_TIMESTAMP)
);

CREATE TABLE MBTISuggestion (
  Id serial NOT NULL PRIMARY KEY,
  Type char(4),
  Suggestion text
);

CREATE TABLE OrderOfflinePayProof (
 orderid int8 NOT NULL,
 imageurl text NOT NULL,
 id uuid DEFAULT uuid_generate_v4() NOT NULL,
 createdat timestamp DEFAULT CURRENT_TIMESTAMP NULL,
 CONSTRAINT orderofflinepayproof_pk PRIMARY KEY (id)
);

-- CREATE TABLE University (
--   Id serial NOT NULL PRIMARY KEY,
--   Province varchar(255),
--   City varchar(255),
--   Name varchar(255)
-- );

-- CREATE TABLE Faculty (
--   Id serial NOT NULL PRIMARY KEY,
--   Type varchar(128),
--   Name varchar(255)
-- );

 CREATE TABLE studenttags (
    studentid UUID,
    tag VARCHAR(255),
    PRIMARY KEY (studentid, tag)
);

create table ShowcasePageItemData(
                                     Id serial not null primary key,
                                     ImageLink varchar(255) default null,
                                     ExtLink varchar(255) default null,
                                     Company varchar(255) default null,
                                     Title varchar(255) default null,
                                     GroupTitle varchar(255) default null,
                                     CreatedAt timestamp DEFAULT (CURRENT_TIMESTAMP),
                                     UpdatedAt timestamp DEFAULT (CURRENT_TIMESTAMP)
);

create table ShowcasePageCarouselData(
                                         Id serial not null primary key,
                                         ImageLink varchar(255) default null,
                                         ExtLink varchar(255) default null,
                                         Company varchar(255) default null,
                                         CreatedAt timestamp DEFAULT (CURRENT_TIMESTAMP),
                                         UpdatedAt timestamp DEFAULT (CURRENT_TIMESTAMP)
);

create table Company(
                        Id serial not null primary key,
                        Path varchar(255) default null,
                        Name varchar(255) default null,
                        CreatedAt timestamp DEFAULT (CURRENT_TIMESTAMP),
                        UpdatedAt timestamp DEFAULT (CURRENT_TIMESTAMP)
);

CREATE TABLE public.franchisefee (
                                     agenttype public."entitytype" NOT NULL,
                                     price numeric(8, 2) NOT NULL,
                                     description text NULL,
                                     CONSTRAINT franchisefee_pk PRIMARY KEY (agenttype)
);

CREATE TABLE public.franchiseorder (
	id uuid DEFAULT uuid_generate_v4() NOT NULL,
	accountid uuid NOT NULL,
	status varchar(255) DEFAULT 'PENDING'::character varying NULL,
	paymentmethod varchar(255) NULL,
	originaltype public."entitytype" NULL,
	targettype public."entitytype" NOT NULL,
	pendingfee numeric(8, 2) NOT NULL,
	createdat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	updatedat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	CONSTRAINT franchiseorder_pkey PRIMARY KEY (id),
	CONSTRAINT fk_accountid FOREIGN KEY (accountid) REFERENCES public.account(id)
);

CREATE TABLE datadictionary (
    key varchar(255) PRIMARY KEY,
    value text,
    namespace varchar(255)
);

CREATE TABLE partitionaward (
    id SERIAL PRIMARY KEY,
    accountid UUID NOT NULL,
    salesaccountid UUID NOT NULL,
    amount DECIMAL(8,2) CHECK (amount > 0),
    orderid BIGINT,
    linkedaccountid UUID,
    partition accountpartition NOT NULL,
    franchiseorderid UUID,
    createdat TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
    
    -- Foreign keys
    CONSTRAINT fk_account_accountid FOREIGN KEY (accountid) REFERENCES account(id),
    CONSTRAINT fk_account_salesaccountid FOREIGN KEY (salesaccountid) REFERENCES account(id),
    CONSTRAINT fk_orders_orderid FOREIGN KEY (orderid) REFERENCES orders(id),
    CONSTRAINT fk_account_linkedaccountid FOREIGN KEY (linkedaccountid) REFERENCES account(id),
    
    -- Unique constraint
    CONSTRAINT unique_accountid_orderid_linkedaccountid UNIQUE (accountid, orderid, linkedaccountid)
);

CREATE TABLE projectdelivery (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    orderproductid BIGINT,
    deliveryaccount UUID,
    price NUMERIC(8,2),
    status VARCHAR(255) DEFAULT 'PENDING',
    source VARCHAR(255),
    assignmode VARCHAR(255), 
    starttime TIMESTAMP,
    endtime TIMESTAMP,
    createdat TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text),
    updatedat TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text),
    
    -- Foreign Key constraints
    CONSTRAINT fk_orderproductid FOREIGN KEY (orderproductid) REFERENCES orderproduct(id),
    CONSTRAINT fk_deliveryaccount FOREIGN KEY (deliveryaccount) REFERENCES account(id)
);

CREATE TABLE public.liuliustatement (
	id uuid DEFAULT uuid_generate_v4() NOT NULL,
	transactionid varchar(255) NOT NULL,
	transactiontime timestamp NOT NULL,
	store varchar(255) NULL,
	cashier varchar(255) NULL,
	item varchar(255) NULL,
	paymentmethod varchar(255) NULL,
	transactionamount numeric(8, 2) NOT NULL,
	fee numeric(8, 2) NULL,
	settleamount numeric(8, 2) NULL,
	memo text NULL,
	filename varchar(64) NULL,
	orderid int8 NULL,
	createdat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	updatedat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	automationlog text NULL,
	CONSTRAINT liuliustatement_pkey PRIMARY KEY (id),
	CONSTRAINT fk_order FOREIGN KEY (orderid) REFERENCES public.orders(id)
);

CREATE TYPE public."accountbalancetype" AS ENUM (
	'balance',
	'balanceleft',
	'balanceright',
	'balancetriplelock',
	'balancetriple',
	'pendingreturn');

-- new table change
CREATE TABLE public.auditlog (
	audit_id serial4 NOT NULL,
	table_name text NULL,
	operation bpchar(1) NULL,
	changed_at timestamptz DEFAULT CURRENT_TIMESTAMP NULL,
	user_name text NULL,
	old_data jsonb NULL,
	new_data jsonb NULL,
	CONSTRAINT auditlog_pkey PRIMARY KEY (audit_id)
);

CREATE TABLE public.triplecycleaward (
	accountid uuid NOT NULL,
	"number" int4 NOT NULL,
	linkedaccountid uuid NOT NULL,
	originaltype public."entitytype" NULL,
	targettype public."entitytype" NOT NULL,
	amount numeric(8, 2) NOT NULL,
	pendingreturn numeric(8, 2) NOT NULL,
	createdat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	updatedat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	franchiseorderid uuid NULL,
  id uuid DEFAULT uuid_generate_v4() NOT NULL,
	CONSTRAINT triplecycleaward_pkey PRIMARY KEY (id),
	CONSTRAINT fk_accountid FOREIGN KEY (accountid) REFERENCES public.account(id),
	CONSTRAINT fk_franchiseorder_franchiseorderid FOREIGN KEY (franchiseorderid) REFERENCES public.franchiseorder(id),
	CONSTRAINT fk_linkedaccountid FOREIGN KEY (linkedaccountid) REFERENCES public.account(id)
);

CREATE TABLE public.userwithdrawmethod (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    userid UUID NOT NULL,
    withdrawmethod VARCHAR(255) NOT NULL, -- 'bank'
    accountname VARCHAR(64),
    accountnumber VARCHAR(64),
    bank VARCHAR(64),
    createdat TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
    updatedat TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
    CONSTRAINT fk_userwithdrawmethod_userid FOREIGN KEY (userid) REFERENCES public.users(id)
);

CREATE TYPE public."inventoryordertype" AS ENUM (
	'hq_initiated',
	'from_balance',
	'agent_topup');

CREATE TYPE public."inventoryorderstatus" AS ENUM (
	'pending',
	'declined',
	'paid',
	'settled');
  
CREATE TABLE public.inventoryorder (
	id bpchar(16) NOT NULL,
	accountid uuid NOT NULL,
	productid uuid NOT NULL,
	quantity int4 NOT NULL,
	"type" public."inventoryordertype" NOT NULL,
	lastoperateuserid uuid NULL,
	status public."inventoryorderstatus" NOT NULL,
	paymentmethod varchar(255) NULL,
	unitprice numeric(8, 2) NULL,
	payat timestamp NULL,
	settledat timestamp NULL,
	createdat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	updatedat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	CONSTRAINT inventoryorder_pkey PRIMARY KEY (id),
	CONSTRAINT fk_inventoryorder_account FOREIGN KEY (accountid) REFERENCES public.account(id),
	CONSTRAINT fk_inventoryorder_operateuser FOREIGN KEY (lastoperateuserid) REFERENCES public.users(id),
	CONSTRAINT fk_inventoryorder_product FOREIGN KEY (productid) REFERENCES public.product(id)
);

CREATE TABLE public.productinventory (
	id uuid DEFAULT uuid_generate_v4() NOT NULL,
	accountid uuid NOT NULL,
	productid uuid NOT NULL,
	quantity int4 NOT NULL,
	lastinventoryorderid bpchar(16) NULL,
	lastorderid int8 NULL,
	createdat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	updatedat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	CONSTRAINT productinventory_pkey PRIMARY KEY (id),
	CONSTRAINT fk_productinventory_account FOREIGN KEY (accountid) REFERENCES public.account(id),
	CONSTRAINT fk_productinventory_inventoryorder FOREIGN KEY (lastinventoryorderid) REFERENCES public.inventoryorder(id),
	CONSTRAINT fk_productinventory_orders FOREIGN KEY (lastorderid) REFERENCES public.orders(id),
	CONSTRAINT fk_productinventory_product FOREIGN KEY (productid) REFERENCES public.product(id)
);

CREATE TABLE public.productinventoryhistory (
	id serial4 NOT NULL,
	sourceid uuid NOT NULL,
	quantity int4 NOT NULL,
	inventoryorderid bpchar(16) NULL,
	orderid int8 NULL,
  quantityafter int4 NOT NULL,
	createdat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	CONSTRAINT productinventoryhistory_pkey PRIMARY KEY (id),
	CONSTRAINT productinventoryhistory_sourceid_fkey FOREIGN KEY (sourceid) REFERENCES public.productinventory(id)
);

CREATE TABLE public.tripleawardhistory (
	id serial4 NOT NULL,
	sourceid uuid NOT NULL,
	amount numeric(10, 2) NOT NULL,
	orderid int8 NOT NULL,
	pendingreturnafter numeric(10, 2) NOT NULL,
	createdat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	CONSTRAINT tripleawardhistory_pkey PRIMARY KEY (id),
	CONSTRAINT tripleawardhistory_orderid_fkey FOREIGN KEY (orderid) REFERENCES public.orders(id),
	CONSTRAINT tripleawardhistory_sourceid_fkey FOREIGN KEY (sourceid) REFERENCES public.triplecycleaward(id)
);

CREATE TABLE public.inventoryorderproof (
                                            id uuid DEFAULT uuid_generate_v4() NOT NULL,
                                            inventoryorderid bpchar(16) NOT NULL,
                                            imageurl text NOT NULL,
                                            createdat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
                                            CONSTRAINT pk_inventoryorderproof PRIMARY KEY (id),
                                            CONSTRAINT fk_inventoryorderproof_inventoryorder FOREIGN KEY (inventoryorderid) REFERENCES public.inventoryorder(id)
);


CREATE TABLE public.university (
                                   schoolname varchar(31) NOT NULL,
                                   location varchar(31) NULL,
                                   level varchar(31) NULL,
                                   remark varchar(255) NULL,
                                   isgraduateeligible boolean NULL,
                                   CONSTRAINT users_pk PRIMARY KEY (schoolname));

CREATE TABLE public.organization (
                                     id uuid DEFAULT uuid_generate_v4() NOT NULL,
                                     uri varchar(10) NOT NULL,
                                     rootaccountid uuid NULL,
                                     config jsonb NULL,
                                     isinherit bool DEFAULT false NOT NULL,
                                     logourl text NULL,
                                     sitename varchar(32) NULL,
                                     wxappid varchar(100) NULL,
                                     wxappsecret varchar(255) NULL,
                                     redirecturl varchar(255) NULL,
                                     createdat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
                                     CONSTRAINT organization_pkey PRIMARY KEY (id),
                                     CONSTRAINT organization_uri_key UNIQUE (uri),
                                     CONSTRAINT organization_accountid_fkey FOREIGN KEY (rootaccountid) REFERENCES public.account(id)

);

CREATE TABLE public.privilege (
                                  "name" varchar(30) NOT NULL,
                                  description text NULL,
                                  createdat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
                                  CONSTRAINT privilege_pkey PRIMARY KEY ("name")
);


CREATE TABLE public.roleprivilege (
                                      id uuid DEFAULT uuid_generate_v4() NOT NULL,
                                      roleid uuid NOT NULL,
                                      privname varchar(30) not null,
                                      isallow boolean,
                                      isdeny boolean,
                                      createdat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
                                      updatedat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
                                      CONSTRAINT roleprivilege_pk PRIMARY KEY (id),
                                      CONSTRAINT roleprivilege_roleid_fk FOREIGN KEY (roleid) REFERENCES public.roles(id),
                                      CONSTRAINT roleprivilege_privname_fk FOREIGN KEY (privname) REFERENCES public.privilege("name")
);
CREATE UNIQUE INDEX idx_roleprivilege_role_priv ON public.roleprivilege USING btree (roleid,privname);
CREATE INDEX idx_roleprivilege_roleid ON public.roleprivilege USING btree (roleid);
CREATE INDEX idx_roleprivilege_privname ON public.roleprivilege USING btree (privname);



CREATE TABLE public.orgprivilege (
                                     id uuid DEFAULT uuid_generate_v4() NOT NULL,
                                     orgid uuid,
                                     privname varchar(30) not null,
                                     isallow boolean,
                                     isdeny boolean,
                                     createdat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
                                     updatedat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
                                     CONSTRAINT orgprivilege_pk PRIMARY KEY (id),
                                     CONSTRAINT orgprivilege_orgid_fk FOREIGN KEY (orgid) REFERENCES public.organization(id),
                                     CONSTRAINT orgprivilege_privname_fk FOREIGN KEY (privname) REFERENCES public.privilege(name)
);

CREATE TABLE public.ordertags (
                                  orderid int8 NOT NULL,
                                  tag varchar(255) NOT NULL,
                                  CONSTRAINT ordertags_pkey PRIMARY KEY (orderid, tag),
                                  CONSTRAINT ordertags_orderid_fk FOREIGN KEY (orderid) REFERENCES public.orders(id)
);

CREATE TABLE public.adjustment (
                                   id uuid DEFAULT uuid_generate_v4() NOT NULL,
                                   accountid uuid NOT NULL,
                                   amount numeric(8, 2) NOT NULL,
                                   balancetype public."accountbalancetype" NOT NULL,
                                   "type" uuid NULL, -- Reserved for future use
                                   notes varchar(255) NOT NULL,
                                   operateuserid uuid NULL,
                                   createdat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
                                   CONSTRAINT adjustment_pkey PRIMARY KEY (id),
                                   CONSTRAINT fk_account FOREIGN KEY (accountid) REFERENCES public.account(id),
                                   CONSTRAINT fk_operateuser FOREIGN KEY (operateuserid) REFERENCES public.users(id)
);

-- TODO: 以下为function

CREATE OR REPLACE FUNCTION public.get_product(account_id uuid, product_id uuid DEFAULT NULL::uuid,
       OUT id uuid,
       OUT productname character varying,
       OUT description text)
RETURN RECORD
--  RETURNS TABLE(id uuid, type character varying, productname character varying, finalprice numeric, publishstatus boolean, description text, createdat timestamp without time zone, updatedat timestamp without time zone, purchaselimit smallint, pricingschedule jsonb)
;

-- 通过下面的function去拿agent的进货价 （在其他的function中需要引用这个）
CREATE OR REPLACE FUNCTION public.get_purchase_price(product_id UUID,account_id UUID)
 RETURNS decimal(8,2)
 LANGUAGE plpgsql
AS $$
DECLARE 
    tmp_purchase_price decimal(8,2);
begin
 raise notice '====begin====';
 select price into tmp_purchase_price from productpriceoverwrite where rootproduct=product_id and downstreamaccountid=account_id;
 if tmp_purchase_price is null then
  select case a.type  when 'LV2_AGENT' then p.lv2agentprice
       when 'LV1_AGENT' then p.lv1agentprice
       when 'HQ_AGENT' then p.hqagentprice
       when 'HEAD_QUARTER' then 0
       else 0 end as purchaseprice --这个else没啥用
   into tmp_purchase_price
   from account a,product p
   where a.id=account_id and p.id=product_id;
 end if;   
RETURN tmp_purchase_price;
END; $$
;

CREATE OR REPLACE FUNCTION public.pay_success(order_id bigint, force_settle boolean DEFAULT false)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE 
	v_order record;
    v_orderproduct record;
    v_product record;
    v_entitlement record;
    tmp_balanceafter decimal(8,2);
	tmp_balanceafter_reverse decimal(8,2);
    v_entitlement_name varchar;
    v_fee decimal(8,2):=0;
	rec RECORD;
	award_layer smallint:=0;-- 0: not rewarded, 1: lv2 rewarded, 2: lv1 rewarded, 3: hq rewarded
	accounttype_awardlayer JSONB := '{"LV2_AGENT": 1, "LV1_AGENT": 2, "HQ_AGENT": 3}';
	partition_balancetype JSONB := '{"L": "balanceleft", "R": "balanceright"}';
	is_indirect_awarded bool:=false;
	v_purchase_price numeric(8,2):=0;--进货价
	v_award numeric(8,2);--临时记录奖励金额   
	v_award_z numeric(8,2):=0;
	v_award_z_ratio float;
	v_award_extension_level smallint;
	v_partition accountpartition;
	v_return numeric(8,2):=0;
	v_sales_account UUID; -- 实际销售账号
	v_direct_upstream_account UUID;
	v_delivery_price numeric(8,2);
	v_delivery_account UUID;
BEGIN
    RAISE NOTICE '====begin pay_success(order_id bigint,force_settle boolean DEFAULT false)====';
    SELECT * INTO v_order FROM orders WHERE id = order_id;
    IF v_order IS NULL THEN
        RETURN 'failed. Order does not exist: ' || order_id;
    ELSIF EXISTS (SELECT FROM balanceactivity WHERE orderid = order_id) THEN
        RETURN 'failed. The balance activity already exists for this order';
    ELSIF v_order.status IN ('success','settled','uncommisioned','declined','failed','refunded') THEN
        RETURN cast('failed. The order has reached final status: ' || v_order.status as varchar);
    END IF;
    
	select value into v_award_extension_level from datadictionary where key='award-extension-level';--扩展层级

	IF EXISTS (select from get_upstreamaccount_chain(v_order.studentid) where account_id!=v_order.studentid and account_type in ('LV2_AGENT','LV1_AGENT','HQ_AGENT') and account_status!='ACTIVE') THEN--上游账号必须都是active的
		RETURN '付款失败。上游账号状态异常。';
	elsif exists (select from get_upstreamaccount_chain(v_order.studentid) 
		where row_num<=(v_award_extension_level+2) and row_num>1 and account_type in ('LV2_AGENT','LV1_AGENT','HQ_AGENT') and account_partition is null
		and (SELECT type from account where id=account_upstreamaccount)!='HEAD_QUARTER') then
		return '付款失败。分区设定异常。';
	END IF;
    
    FOR v_orderproduct IN (SELECT id, productid, couponcode, actualprice FROM orderproduct WHERE orderid = order_id) 
	LOOP 
        RAISE NOTICE 'productid: %', v_orderproduct.productid;
        IF v_orderproduct.couponcode IS NULL AND v_orderproduct.actualprice>0 THEN --实付金额不为0时，必须填销售代码
			RETURN '付款失败。销售代码为空。';
		END IF;
        -- 初始化各个变量
        SELECT * INTO v_product FROM product  WHERE id = v_orderproduct.productid;
		SELECT agentid INTO v_sales_account FROM ordercoupon where code=v_orderproduct.couponcode;
        v_fee := 0;
		v_award_z:= v_product.pricingschedule ->> 'cross-level-award-base';
		select value into v_award_z_ratio from datadictionary where key=concat('','award-z-ratio');--扩展奖比例


		IF v_order.status != 'paid' THEN  -- 执行所有付款成功应触发的动作      
	        FOR v_entitlement IN (SELECT entitlementtypeid, validdays FROM productentitlementtype  WHERE productid = v_orderproduct.productid) 
			LOOP -- 激活学生授权
	            INSERT INTO studententitlement(id,studentid,entitlementtypeid,lastorderid,expiresat) VALUES (uuid_generate_v4(),v_order.studentid,v_entitlement.entitlementtypeid,order_id,CURRENT_DATE+v_entitlement.validdays)
	            ON CONFLICT (studentid, entitlementtypeid) DO 
	            UPDATE SET 
	                lastorderid = order_id,
	                expiresat = CASE 
	                                WHEN studententitlement.expiresat < CURRENT_DATE THEN CURRENT_DATE + v_entitlement.validdays 
	                                ELSE studententitlement.expiresat + v_entitlement.validdays 
	                            END,
	                updatedat = (now() AT TIME ZONE 'Asia/Shanghai');           
	            RAISE NOTICE '授权:%,days:%', v_entitlement.entitlementtypeid, v_entitlement.validdays;
	            
	            SELECT name INTO v_entitlement_name FROM entitlementtype WHERE id = v_entitlement.entitlementtypeid;
	            
	            IF v_entitlement_name = '在线视频课' 
	            AND NOT EXISTS (SELECT FROM qianliaocoupon WHERE studentid = v_order.studentid) THEN -- 如果没有分配千聊优惠券，则从空余优惠券里选一个分配
	                UPDATE qianliaocoupon SET studentid=v_order.studentid,updatedat=(now() AT TIME ZONE 'Asia/Shanghai') WHERE couponcode=(SELECT couponcode FROM qianliaocoupon WHERE studentid IS NULL LIMIT 1);
	            END IF;
	        END LOOP;
	
			-- 分配服务提供商
			v_delivery_price:= v_product.pricingschedule ->> 'external-delivery-price';
			v_delivery_account:= v_product.pricingschedule ->> 'external-delivery-account';
			IF v_delivery_price > 0 THEN
				IF (SELECT type FROM account where id=v_delivery_account) NOT IN ('HEAD_QUARTER','HQ_AGENT','LV1_AGENT','LV2_AGENT') THEN
					RAISE EXCEPTION '交付账号异常: %',v_delivery_account;
				END IF;
				-- 设定初始交付周期为产品对应的任意一个entitlementtype的validdays
				INSERT INTO projectdelivery(orderproductid,deliveryaccount,price,source,assignmode,starttime,endtime) VALUES(v_orderproduct.id,v_delivery_account,v_delivery_price,'PRODUCT','AUTO',NOW() AT TIME ZONE 'Asia/Shanghai',(NOW() AT TIME ZONE 'Asia/Shanghai') + (SELECT CONCAT(validdays,' day')::INTERVAL FROM productentitlementtype  WHERE productid = v_orderproduct.productid LIMIT 1));
			END IF; 
		END IF;

		IF v_order.paymentmethod NOT IN ('liuliupay') OR force_settle=true THEN -- 执行所有背靠背结算动作 （微信直连的结算暂时没有做，也在付款时直接分账）
		    FOR rec IN select * from get_upstreamaccount_chain(v_order.studentid)-- 执行分账
		 	LOOP
		        --raise notice 'row:% | id:% | type:% |name:% |%',rec.row_num,rec.account_id,rec.account_type,rec.account_name,is_indirect_awarded;
				IF (award_layer=3 and is_indirect_awarded) OR rec.account_type='HEAD_QUARTER' or v_orderproduct.actualprice<=0 THEN -- 实付<=0，不分账
					RAISE NOTICE '--exist loop at %',rec.account_name;
					EXIT; -- exist the loop when all awards are distributed
				END IF;
				IF rec.account_id=v_order.studentid THEN -- 学生
					RAISE NOTICE '-- 学生:%',rec.account_name;
				ELSE -- 上级
					--判断是否属于 直属招商奖励
					IF (award_layer<3 AND rec.account_type='HQ_AGENT') OR (award_layer<2 AND rec.account_type='LV1_AGENT') OR (award_layer<1 AND rec.account_type='LV2_AGENT') OR rec.row_num=2 THEN
						-- 确定剩余意向金返还数额
						select pendingreturn into v_return from account where id=rec.account_id;
						IF rec.row_num=2 THEN -- 直属上级
							v_direct_upstream_account := rec.account_id;
							-- 直接售课奖励
							v_purchase_price := v_product.pricingschedule ->> concat(rec.account_type,'-course-purchase-price');-- 获取进货价
							v_award := v_orderproduct.actualprice - v_purchase_price; -- commission是实际价格减去进货价
							-- 写余额，step 1 写售课奖励
							update account set balance = balance+v_award WHERE id=rec.account_id returning balance into tmp_balanceafter;	
							insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype) 
								values('售课奖励',order_id,v_orderproduct.id,rec.account_id,v_award,tmp_balanceafter,'balance');
							--写余额，step 2 转化订单奖励，给到v_sales_account 
							update account set balance = balance+(v_product.pricingschedule->>'conversion-award')::numeric(8,2) WHERE id=v_sales_account returning balance into tmp_balanceafter;	
							-- 操作余额变动,记录时间为原时间+1毫秒
							insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype,createdat,updatedat) 
								values('转化订单奖励',order_id,v_orderproduct.id,v_sales_account,(v_product.pricingschedule->>'conversion-award')::numeric(8,2),tmp_balanceafter,'balance',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '1 millisecond',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '1 millisecond');
	
							-- 写余额，step 3 return>0时，返还意向金
							IF v_return > 0 THEN
								update account set balance = balance + (v_product.pricingschedule->>'earnest-return')::numeric, pendingreturn=pendingreturn - (v_product.pricingschedule ->> 'earnest-return')::numeric WHERE id=rec.account_id returning balance,pendingreturn into tmp_balanceafter,tmp_balanceafter_reverse;	
								-- account的pendingreturn 远大于解锁三单循环的pendingreturn。 解锁三单循环的pendingreturn不需要考虑>0的条件（即使是负数的也接着扣）
								update triplecycleaward set pendingreturn=pendingreturn-(v_product.pricingschedule->>'earnest-return')::numeric,updatedat=NOW() AT TIME ZONE 'Asia/Shanghai' where linkedaccountid=v_direct_upstream_account;
								raise notice '解锁三单循环: 金额% 学生直接上级代理:%',(v_product.pricingschedule->>'earnest-return'),v_direct_upstream_account;
								-- 操作余额变动,记录时间为原时间+2毫秒
								insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype,createdat,updatedat) 
									values('意向金返还(余额)',order_id,v_orderproduct.id,rec.account_id,(v_product.pricingschedule->>'earnest-return')::numeric,tmp_balanceafter,'balance',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '2 millisecond',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '2 millisecond');
								insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype,createdat,updatedat) 
									values('意向金返还(剩余意向金)',order_id,v_orderproduct.id,rec.account_id,-(v_product.pricingschedule->>'earnest-return')::numeric,tmp_balanceafter_reverse,'pendingreturn',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '2 millisecond',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '2 millisecond');
							END IF;
							-- 写余额，step 4 线上付款时，手续费由直接上级代理承担
							if v_order.paymentmethod='wechatpay' then
								v_fee := v_orderproduct.actualprice * 0.007;
								-- 扣除手续费
								update account set balance = balance - v_fee where id=rec.account_id returning balance into tmp_balanceafter;
								-- 操作余额变动,记录时间为原时间+3毫秒
								insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype,createdat,updatedat) 
									values('微信支付手续费0.7%',order_id,v_orderproduct.id,rec.account_id,-v_fee,tmp_balanceafter,'balance',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '3 millisecond',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '3 millisecond');
							end if;		
							--设置发放奖励状态
							award_layer := (accounttype_awardlayer->>rec.account_type)::NUMERIC;	
							RAISE NOTICE '-- 直属售课奖励:% 金额:% 剩余意向金:% 转化费:% 手续费:%  付款方式:% 奖励发放状态:%|%',rec.account_name,v_award,v_return,v_product.pricingschedule->>'conversion-award',v_fee,v_order.paymentmethod,award_layer,is_indirect_awarded;
						ELSE
							-- 跨级售课奖励
							v_award := v_product.pricingschedule ->> concat(rec.account_type,'-course-direct-award');
							update account set balance = balance+v_award WHERE id=rec.account_id returning balance into tmp_balanceafter;	
							insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype) 
								values('售课跨级奖励',order_id,v_orderproduct.id,rec.account_id,v_award,tmp_balanceafter,'balance');
							IF v_return > 0 THEN-- 跨级意向金返还
								update account set balance = balance+(v_product.pricingschedule->>'earnest-return')::numeric,pendingreturn=pendingreturn-(v_product.pricingschedule->>'earnest-return')::numeric WHERE id=rec.account_id returning balance,pendingreturn into tmp_balanceafter,tmp_balanceafter_reverse;	
								-- 操作余额变动,记录时间为原时间+1毫秒							
								insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype,createdat,updatedat) 
									values('跨级意向金返还(余额)',order_id,v_orderproduct.id,rec.account_id,(v_product.pricingschedule->>'earnest-return')::numeric,tmp_balanceafter,'balance',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '1 millisecond',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '1 millisecond');
								insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype,createdat,updatedat) 
									values('跨级意向金返还(剩余意向金)',order_id,v_orderproduct.id,rec.account_id,-(v_product.pricingschedule->>'earnest-return')::numeric,tmp_balanceafter_reverse,'pendingreturn',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '1 millisecond',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '1 millisecond');
							END IF;
							--设置发放奖励状态
							award_layer := (accounttype_awardlayer->>rec.account_type)::NUMERIC;				
							RAISE NOTICE '-- 跨级奖励:% 金额:%. 奖励发放状态:%|%',rec.account_name,v_award,award_layer,is_indirect_awarded;		
						END IF;		
					END IF;
					IF rec.row_num >=3 AND rec.row_num <= (v_award_extension_level+2) THEN -- 层级小于7时，扩展奖
						v_award := v_award_z * v_award_z_ratio;
						IF v_partition IS NULL THEN
							RAISE EXCEPTION '管理职未进行分区设置，请联系核实。';
						ELSIF v_partition='L' THEN
							update account set balanceleft = balanceleft+v_award WHERE id=rec.account_id returning balanceleft into tmp_balanceafter;	
						ELSE
							update account set balanceright = balanceright+v_award WHERE id=rec.account_id returning balanceright into tmp_balanceafter;	
						END IF;
						insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype) 
							values(concat('售课扩展奖:',v_partition,'区'),order_id,v_orderproduct.id,rec.account_id,v_award,tmp_balanceafter,(partition_balancetype->>v_partition::TEXT)::accountbalancetype);
						insert into partitionaward(accountid,salesaccountid,orderid,amount,partition) values(rec.account_id,v_direct_upstream_account,order_id,v_award,v_partition);
						RAISE NOTICE '-- 扩展奖:% 金额:% x % = % ,分区:% 奖励发放状态:%|%',rec.account_name,v_award_z,v_award_z_ratio,v_award,v_partition,award_layer,is_indirect_awarded;
					ELSIF rec.row_num > (v_award_extension_level+2) THEN--层级大于8，设置奖励发放状态
						is_indirect_awarded:=true;
					END IF;
					-- 非学生账号时，获取分区，作为下一次循环（上级）的左右分区。这个动作必须在本层完成完成分账之后，给下一层用。
					select partition into v_partition from account where id=rec.account_id;
				END IF;
		    END LOOP;
		END IF;
    END LOOP;  
    
	IF v_order.paymentmethod IN ('wechatpay','liuliupay') AND force_settle=false THEN -- 标记订单状态
	    UPDATE orders  SET status='paid',payat=(now() AT TIME ZONE 'Asia/Shanghai'),updatedat=(now() AT TIME ZONE 'Asia/Shanghai') WHERE id=order_id;    
	ELSIF v_order.status = 'paid' THEN
	    UPDATE orders  SET status='settled',settledat=(now() AT TIME ZONE 'Asia/Shanghai'),updatedat=(now() AT TIME ZONE 'Asia/Shanghai') WHERE id=order_id;   
	ELSE
	    UPDATE orders  SET status='settled',payat=(now() AT TIME ZONE 'Asia/Shanghai'),settledat=(now() AT TIME ZONE 'Asia/Shanghai'),updatedat=(now() AT TIME ZONE 'Asia/Shanghai') WHERE id=order_id; 
	END IF;

    RAISE NOTICE '====end pay_success()====';
    RETURN 'success';
END; 
$function$
;

create type actual_price_with_error as (actualprice decimal(8,2), errmsg varchar);

-- 下单前检查优惠券，加了一些validation rule，修复了一些bug。这些我尽量都mock数据去测试了
CREATE OR REPLACE FUNCTION public.order_coupon_check(order_id bigint,coupon_code bigint)
 RETURNS actual_price_with_error
 LANGUAGE plpgsql
AS $$
DECLARE 
    var_orderproduct record;
    var_product_finalprice  decimal(8,2);
    var_product record;
    var_student_id UUID;
    var_discount decimal(8,2);
    var_sumprice decimal(8,2) := 0;
    var_coupon record;
    var_errmsg varchar;
    var_random_product_flag boolean;
    var_direct_agent_id UUID;
begin
 raise notice '====begin====';
 select studentid into var_student_id from orders where id=order_id;
 select upstreamaccount into var_direct_agent_id from account where id=var_student_id;
 if not exists (select from orders where id=order_id) then 
  --raise no_data_found using message='该订单号不存在：'||order_id;
  return (cast(-1 as decimal(8,2)),cast('该订单号不存在：'|| order_id as varchar));
 end if;

 if coupon_code is not null then -- 对优惠券进行检查
  if not exists (select from ordercoupon where code=coupon_code) then 
   return (cast(-1 as decimal(8,2)),cast('该优惠券码不存在：'||coupon_code as varchar));
  end if;
  select * into var_coupon from ordercoupon where code=coupon_code;
  if var_coupon.effectstartdate is not null then
   if CURRENT_DATE < var_coupon.effectstartdate then
    return (cast(-1 as decimal(8,2)),cast('优惠券不在有效期(起始日期:' || var_coupon.effectstartdate || ')。' as varchar));
   end if;
  end if;
  if var_coupon.effectduedate is not null then
   if CURRENT_DATE > var_coupon.effectduedate then
    return (cast(-1 as decimal(8,2)),cast('优惠券不在有效期(截止日期:' || var_coupon.effectduedate || ')。' as varchar));
   end if;
  end if;
  if var_direct_agent_id!=var_coupon.agentid then
   return (cast(-1 as decimal(8,2)),cast('优惠券不是您的直属代理签发的。' as varchar));
  end if;
  if var_coupon.studentid is not null then
   if var_coupon.studentid!=var_student_id then
    return (cast(-1 as decimal(8,2)),cast('您不是优惠券的有效学员。' as varchar));
   end if;
  end if;
  if var_coupon.productid is not null then
   if not exists (select from orderproduct where orderid=order_id and productid=var_coupon.productid) then
    return (cast(-1 as decimal(8,2)),cast('该优惠券对您本次购买的商品无效。' as varchar));
   end if;
   if (select finalprice-get_purchase_price(id,var_direct_agent_id)-var_coupon.discountamount from product where id=var_coupon.productid) < 0 then--优惠金额过高：超过直接上级代理的利润。
    return (cast(-1 as decimal(8,2)),cast('该优惠金额无效，请与销售人员核实。' as varchar));
   end if;
  else
   raise notice 'direct agent: % | discount: %',var_direct_agent_id,var_coupon.discountamount;
   var_coupon.productid := (select op.productid from orderproduct op,product p where op.productid=p.id and orderid=order_id and p.finalprice - get_purchase_price(p.id,var_direct_agent_id) >= var_coupon.discountamount limit 1);
   if var_coupon.productid is null then
    return (cast(-1 as decimal(8,2)),cast('优惠券金额超过订单中所有商品售价。' as varchar));
   end if;
  end if;
  if var_coupon.maxcount is not null then
   if (select count(*) from orderproduct where couponcode=coupon_code) >= var_coupon.maxcount then
    return (cast(-1 as decimal(8,2)),cast('优惠券超过最大使用次数（' || var_coupon.maxcount || '次)。' as varchar));
   end if;
  end if;
 end if; 

 for var_orderproduct in (select id,productid from orderproduct where orderid=order_id)
 loop 
  raise notice 'productid: %',var_orderproduct.productid;
  select finalprice,purchaselimit,productname into var_product from product where id=var_orderproduct.productid;
  if var_product.purchaselimit is not null then
   if (select count(*) from orderproduct op,orders o where op.orderid=o.id and o.status='success' and op.productid=var_orderproduct.productid and o.studentid=var_student_id) >= var_product.purchaselimit then
   update orderproduct set originalprice=null,actualprice=null,couponcode=null where orderid=order_id;--function不支持rollback。模拟rollback的效果
   return (cast(-1 as decimal(8,2)),cast('超过商品最大购买次数:' || var_product.productname as varchar));
   end if;
  end if;
  var_discount := 0;
  if coupon_code is not null then
   if var_coupon.productid=var_orderproduct.productid then --有优惠券的时候，设置优惠金额，否则优惠为0
    var_discount := var_coupon.discountamount;
    update orderproduct set couponcode=coupon_code where id=var_orderproduct.id;--商品上设置优惠券
   end if; 
  end if;
  var_sumprice := var_sumprice + var_product.finalprice - var_discount;
  raise notice 'sumprice: % | discount: %',var_sumprice,var_discount;
  update orderproduct set originalprice=var_product.finalprice,actualprice = var_product.finalprice - var_discount where id=var_orderproduct.id;--更新商品价格
 end loop;
 update orders set price=var_sumprice where id=order_id;--更新订单价格
 raise notice '====end====';
RETURN (var_sumprice,cast('' as varchar));
END; $$
;

CREATE OR REPLACE FUNCTION public.get_order_price(order_id bigint)
 RETURNS decimal(8,2)
 LANGUAGE plpgsql
AS $$
DECLARE 
    var_orderproduct record;
    var_product_finalprice  decimal(8,2);
    var_student_id UUID;
    var_discount decimal(8,2);
    var_sumprice decimal(8,2) := 0;
begin
 raise notice '====begin====';
 select studentid into var_student_id from orders where id=order_id;
 for var_orderproduct in (select id,productid,couponcode from orderproduct where orderid=order_id)
 loop 
  raise notice 'productid: %',var_orderproduct.productid;
  select finalprice into var_product_finalprice from product where id=var_orderproduct.productid;
  var_discount := 0;
  if var_orderproduct.couponcode is not null then --有优惠券的时候，设置优惠金额，否则优惠为0
   select discountamount into var_discount from ordercoupon where code=var_orderproduct.couponcode;
  end if; 
  var_sumprice := var_sumprice + var_product_finalprice - var_discount;
  raise notice 'sumprice: % | discount: %',var_sumprice,var_discount;

 end loop;
 raise notice '====end====';
RETURN var_sumprice;
END; $$
;

create type order_price_error as (orderid bigint, actualprice decimal(8,2), errmsg varchar);

CREATE OR REPLACE FUNCTION public.generate_simple_order(product_id uuid, student_id uuid, coupon_code bigint, payment_method text DEFAULT NULL::text)
 RETURNS order_price_error
 LANGUAGE plpgsql;

CREATE TABLE Recruit (
    Id serial PRIMARY KEY,
    ShareCount integer,
    BrowseCount integer,
    FavoriteCount integer,
    RecruitId integer UNIQUE NOT NULL,
    CompanyName varchar(512),
    LogoUrl varchar(65535),
    EnterpriseName varchar(512),
    Tag varchar(64),
    CityNameList varchar(1024),
    CreateType timestamp,
    UpdateTime timestamp,
    CompanyType varchar(64),
    IsRecommended boolean,
    Content varchar(65535),
    Url varchar(65535),
    BeginTime date,
    EndTime date,
    OverseasStudent varchar(65535),
    DomesticStudent varchar(65535),
    ReleaseSource varchar(512)
);

CREATE OR REPLACE FUNCTION public.generate_new_coupon(user_id UUID,discount_amount decimal(8,2),max_count int4,product_id UUID,student_id UUID,start_date date,due_date date)
 RETURNS varchar
 LANGUAGE plpgsql
AS $$
DECLARE 
    var_coupon_code int8 := FLOOR(random() * (99999999 - 10000000 + 1) + 10000000);
    var_agent record;
    var_allowed_max_discount decimal(8,2);
begin
 raise notice '====begin====';
 raise notice 'code:%',var_coupon_code;
 if user_id is null then
  return '创建失败。用户名不可以为空值。';
 end if;
 select id,type into var_agent from account where id=(select accountid from users where id=user_id);
 if var_agent.type = 'STUDENT' then
  return '创建失败。账户类型不可以为“学员”。';
 end if;
 if discount_amount is null then
  return '创建失败。优惠金额不可以为空值。';
 end if;
 if product_id is not null then
  select finalprice-get_purchase_price(product_id,var_agent.id) into var_allowed_max_discount from product where id=product_id;
  raise notice 'max_discount:% | purchase_price:%',var_allowed_max_discount,get_purchase_price(product_id,var_agent.id);
  if discount_amount<0 or discount_amount > var_allowed_max_discount then  
   return cast('创建失败。优惠金额必须为正，且小于￥' || var_allowed_max_discount || '。' as varchar);
  end if;
 end if;
 if start_date is not null and due_date is not null then 
  if start_date > due_date then
   return '创建失败。优惠券起始日期晚于截止日期。';
  end if;
 end if;
 if exists (select from ordercoupon where code=var_coupon_code) then 
  return '创建失败。优惠券码重复，请重新生成。';
 end if;
 if exists (select from ordercoupon where discountamount=discount_amount and agentid=var_agent.id and productid IS NOT DISTINCT FROM product_id and studentid IS NOT DISTINCT FROM student_id and effectstartdate IS NOT DISTINCT FROM start_date and effectduedate IS NOT DISTINCT FROM due_date) then
  return '创建失败。已存在面向相同商品、学员、金额、有效期的优惠券。';
 end if;
 insert into ordercoupon(code,agentid,issuinguser,discountamount,maxcount,productid,studentid,effectstartdate,effectduedate)
  values(var_coupon_code,var_agent.id,user_id,discount_amount,max_count,product_id,student_id,start_date,due_date);
 raise notice '====end====';
 RETURN cast('创建成功。券码：' || var_coupon_code  as varchar);
END; $$
;

CREATE OR REPLACE FUNCTION public.get_account_chain(accid uuid,top_level_account uuid default null)
 RETURNS TABLE(account_id uuid)
 LANGUAGE plpgsql
AS $function$
declare var_upstream_account RECORD;
begin
	 -- First, fetch the upstream account of the given account and store it in var_account
SELECT upstreamaccount,type INTO var_upstream_account FROM account WHERE id = accid;

-- Return the initial account information
return query select accid;

if top_level_account is null then
	    if var_upstream_account.type != 'HEAD_QUARTER' then
	   	    return query select ac.account_id from get_account_chain(var_upstream_account.upstreamaccount) ac;
end if;
else
	    if accid != top_level_account then
	   	    return query select * from get_account_chain(var_upstream_account.upstreamaccount,top_level_account);
end if;
end if;
END; $function$
;

create MATERIALIZED VIEW public.mv_balance_activity_details AS
SELECT
    ba.orderid,
    ba.createdat,
    ba.accountid,
    ba.source,
    CASE
        WHEN ba.orderid IS NOT NULL THEN p.productname
        ELSE NULL
        END AS productname,
    child.accountname AS child_accountname,
    child.type AS child_account_type,
    ba.amount,
    ba.balanceafter
FROM
    public.balanceactivity AS ba
        LEFT JOIN
    public.orders AS o ON ba.orderid = o.id
        LEFT JOIN
    public.orderproduct AS op ON o.id = op.orderid
        LEFT JOIN
    public.product AS p ON op.productid = p.id
        LEFT JOIN
    public.account AS child ON ba.accountid = child.upstreamaccount
        and child.id in (select account_id from get_account_chain(o.studentid,ba.accountid));
 
CREATE INDEX idx_mv_createdat ON public.mv_balance_activity_details (createdat);
CREATE INDEX idx_mv_accountid ON public.mv_balance_activity_details (accountid);
CREATE INDEX idx_mv_productname ON public.mv_balance_activity_details (productname);
CREATE INDEX idx_mv_source ON public.mv_balance_activity_details (source);
CREATE INDEX idx_mv_child_accountname ON public.mv_balance_activity_details (child_accountname);
CREATE INDEX idx_mv_child_account_type ON public.mv_balance_activity_details (child_account_type);
CREATE INDEX idx_mv_amount ON public.mv_balance_activity_details (amount);


CREATE or replace VIEW public.v_users AS
SELECT
    u.*,
    CASE
        WHEN EXISTS (SELECT 1 FROM guardian g WHERE g.guardianid = u.id) THEN 'guardian'
        WHEN (SELECT type FROM account WHERE id = u.accountid LIMIT 1) = 'STUDENT' THEN 'student'
        ELSE 'agent'
    END AS usertype
FROM
    public.users u;

create or replace view public.v_studentdetails as
SELECT DISTINCT ON (s.id) s.id AS studentid,
       s.upstreamaccount AS agentid,
       s.accountname AS studentname,
       s.createdat,
       suser.phone AS studentphone,
       suser.nickname AS studentwechatname,
       suser.email AS studentemail,
       guser.phone AS guardianphone,
       guser.nickname AS guardianwechatname,
       guser.email AS guardianemail,
       g.relationship,
       (SELECT array_agg(productname) AS purchasedproduct
        FROM (
            SELECT productname
            FROM product
            WHERE id IN (
                SELECT DISTINCT productid
                FROM orderproduct op
                WHERE op.orderid IN (
                    SELECT id
                    FROM orders o
                    WHERE o.status = 'success' AND o.studentid = s.id
                )
            )
            ORDER BY 1
        ) p),
       (SELECT array_agg(tag) AS tags
        FROM (
            SELECT tag
            FROM studenttags
            WHERE studentid = s.id
            ORDER BY 1
        ) t)
FROM account s
LEFT JOIN v_users suser ON suser.accountid = s.id AND suser.usertype = 'student'
LEFT JOIN v_users guser ON guser.accountid = s.id AND guser.usertype = 'guardian'
LEFT JOIN guardian g ON g.guardianid = guser.id
WHERE s.type = 'STUDENT'
ORDER BY s.id, s.createdat DESC;

CREATE OR REPLACE FUNCTION public.revoke_pay(order_id bigint,retain_entitlement BOOLEAN DEFAULT FALSE)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE
var_order record;
    var_balanceactivity record;
   	var_productentitlementtype record;
   	tmp_balanceafter decimal(8,2);
begin
	raise notice '====begin====';
select * into var_order from orders where id=order_id;
if var_order.status!='success' then
 		return 'failed. Order status must be "success" to be revoked.';
end if;
 	if var_order.paymentmethod = 'wechatpay' then
 		return 'failed. Only offline order can be revoked';
end if;
 	if var_order.price <= 0 then
 		return 'failed. Order amount need to be greater than zero.';
end if;
for var_balanceactivity in (select * from balanceactivity where orderid=order_id)
 	loop
	 	-- 操作逆分账，按余额变动反向操作分账
update account set balance = balance - var_balanceactivity.amount,updatedat=(now() AT TIME ZONE 'Asia/Shanghai') where id=var_balanceactivity.accountid returning balance into tmp_balanceafter;
-- 增加余额变动信息
insert into balanceactivity(id,source,orderid,orderproductid,accountid,amount,balanceafter) values
    (uuid_generate_v4(),concat('撤销',var_balanceactivity.source),var_balanceactivity.orderid,var_balanceactivity.orderproductid,var_balanceactivity.accountid,-var_balanceactivity.amount,tmp_balanceafter);
end loop;
 	if retain_entitlement=false then
 		-- 撤销权限
 		for var_productentitlementtype in (select * from productentitlementtype where productid in (select productid from orderproduct where orderid=order_id))
 		loop
update studententitlement set expiresat=expiresat - var_productentitlementtype.validdays,updatedat=(now() AT TIME ZONE 'Asia/Shanghai') where studentid=var_order.studentid and entitlementtypeid=var_productentitlementtype.entitlementtypeid;
end loop;
	 	-- 取消优惠券
UPDATE orderproduct SET couponcode = null WHERE orderid = order_id and couponcode is not null;
end if;
	-- 标记订单为deleted
update orders set status='deleted',updatedat=(now() AT TIME ZONE 'Asia/Shanghai') where id=order_id;
raise notice '====end====';
RETURN 'success';
END; $function$
;



CREATE OR REPLACE FUNCTION assign_award(acc_id UUID)
RETURNS character varying 
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD;
	v_target_account RECORD;
	award_layer smallint:=0;-- 0: not rewarded, 1: lv2 rewarded, 2: lv1 rewarded, 3: hq rewarded
	accounttype_awardlayer JSONB := '{"LV2_AGENT": 1, "LV1_AGENT": 2, "HQ_AGENT": 3}';
	is_indirect_awarded bool:=false;
	var_tmp_award_amount int:=0;--直属招商奖励金额
	v_target_account_type entitytype;
	v_orig_account_type entitytype;
	v_accumulated_award int=0;
	v_three_return_award_amount numeric(8,2):=0;--三单一返奖励金额
	v_reward_x float;--三单一返系数
	v_award_y numeric(8,2):=0;
	v_award_y_ratio float;
	v_award_extension_level smallint;
	v_partition accountpartition;
    tmp_balanceafter decimal(8,2);
	v_tmp bpchar='';--用于跨级奖励的描述
BEGIN
	raise notice '====begin assign_award(acc_id UUID)====';
	IF not exists (select from account where id=acc_id) THEN
		return cast('failed. Account does not exists：'|| acc_id as varchar);
	END IF;

	-- get target account detail
	select * INTO v_target_account FROM account where id=acc_id;

	IF EXISTS (select from get_account_chain(acc_id) ac, account a where ac.account_id=a.id	and a.id!=acc_id and a.status!='ACTIVE') THEN--只有上游账号全部是active的情况下，才可以激活账号
		--RAISE NOTICE '激活失败。上游账号状态异常。';
		RETURN '激活失败。上游账号状态异常。';
	END IF;IF (v_target_account.status='INIT' and v_target_account.targettype IS NOT NULL) OR (v_target_account.status='ACTIVE' and v_target_account.targettype IS NULL) THEN
		--RAISE NOTICE '激活失败。账号设定冲突.状态:% 升级类型:%',v_target_account.status,v_target_account.targettype;
		RETURN cast(('激活失败。账号设定冲突.状态:' || v_target_account.status || ' 升级类型:' || v_target_account.targettype) as varchar);
	END IF;

	--进行初始参数设定	
	select value into v_award_y_ratio from datadictionary where key=concat('','award-y-ratio');--扩展奖比例
	select value into v_award_extension_level from datadictionary where key='award-extension-level';--扩展层级
	IF v_target_account.targettype IS NULL THEN -- 新加盟商户,orig_account_type保持为null
		v_target_account_type := v_target_account.type;
		select value into v_award_y from datadictionary where key=concat(v_target_account_type,'-award-y');
		select value into v_three_return_award_amount from datadictionary where key=concat(v_target_account_type,'-award-x');
	ELSE -- 升级商户
		v_orig_account_type := v_target_account.type;
		v_target_account_type := v_target_account.targettype;
		select value into v_award_y from datadictionary where key=concat(v_target_account_type,'-award-y');
		select value into v_three_return_award_amount from datadictionary where key=concat(v_target_account_type,'-award-x');
		select v_award_y - value into v_award_y from datadictionary where key=concat(v_orig_account_type,'-award-y');
		select v_three_return_award_amount - value into v_three_return_award_amount from datadictionary where key=concat(v_orig_account_type,'-award-x');
	END IF;

    FOR rec IN select * from get_upstreamaccount_chain(acc_id)
 	LOOP
        --raise notice 'row:% | id:% | type:% |name:% |%',rec.row_num,rec.account_id,rec.account_type,rec.account_name,is_indirect_awarded;
		IF (award_layer=3 and is_indirect_awarded) OR rec.account_type='HEAD_QUARTER' THEN
			RAISE NOTICE '--exist loop';
			EXIT; -- exist the loop when all awards are distributed
		END IF;
		IF rec.account_id=acc_id THEN -- 加盟的商户
			RAISE NOTICE '-- 加盟商:% %',rec.account_name,v_target_account_type;
		ELSE -- 上级
			--判断是否属于 直属招商奖励
			IF (award_layer<3 AND rec.account_type='HQ_AGENT') OR (award_layer<2 AND rec.account_type='LV1_AGENT') OR (award_layer<1 AND rec.account_type='LV2_AGENT') OR rec.row_num=2 THEN	
				IF rec.row_num=2 THEN -- 直属上级
					-- 确定分区
					select partition into v_partition from account where id=rec.account_id;
					IF v_partition IS NULL THEN
						RAISE EXCEPTION '管理职未进行分区设置，请联系核实。';
					END IF;
					-- 三单一返奖励					
					RAISE NOTICE '--三单一返基数:%',v_three_return_award_amount;
					select ( (count(*) + coalesce(sum(upgradecount),0) ) % 3) + 1 into v_reward_x from account where upstreamaccount=rec.account_id and status!='INIT';--ACTIVE 和 CLOSED account都计算在内. 临时借用v_reward_x来存储
					select value into v_reward_x from datadictionary where key=concat('award-mod-',v_reward_x);
					RAISE NOTICE '--三单一返系数:%',v_reward_x;
					v_three_return_award_amount:=v_three_return_award_amount*v_reward_x;
					-- 写余额 Step 1: 三单一返
					update account set balance = balance+v_three_return_award_amount WHERE id=rec.account_id returning balance into tmp_balanceafter;	
					insert into balanceactivity(id,source,linkedaccountid,accountid,amount,balanceafter) values(uuid_generate_v4(),concat('招商三单一返奖励 (系数:',v_reward_x::bpchar,')'),acc_id,rec.account_id,v_three_return_award_amount,tmp_balanceafter);
					RAISE NOTICE '--三单一返奖励:% 金额:%',rec.account_name,v_three_return_award_amount;
				END IF;
				-- 直属招商奖励
				select value into var_tmp_award_amount from datadictionary where key=concat(rec.account_type,'-',v_target_account_type,'-direct-award');
				-- 对于升级商户，奖励要减去差额
				IF v_orig_account_type IS NOT NULL THEN
					select var_tmp_award_amount - value INTO var_tmp_award_amount from datadictionary where key=concat(rec.account_type,'-',v_orig_account_type,'-direct-award');
				END IF;
				var_tmp_award_amount:=var_tmp_award_amount-v_accumulated_award;
				v_accumulated_award=v_accumulated_award+var_tmp_award_amount;
				-- 写余额，记录时间为原时间+1毫秒
				update account set balance = balance+var_tmp_award_amount WHERE id=rec.account_id returning balance into tmp_balanceafter;	
				if rec.row_num>2 THEN v_tmp := '跨级'; END IF; --跨级奖励的描述
				insert into balanceactivity(id,source,linkedaccountid,accountid,amount,balanceafter,createdat,updatedat) values(uuid_generate_v4(),concat('直属招商',v_tmp,'奖励'),acc_id,rec.account_id,var_tmp_award_amount,tmp_balanceafter,NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '1 millisecond',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '1 millisecond');
				--设置发放奖励状态
				award_layer := (accounttype_awardlayer->>rec.account_type)::NUMERIC;				
				RAISE NOTICE '-- 直属招商奖励:% 金额:%. 奖励发放状态:%|%',rec.account_name,var_tmp_award_amount,award_layer,is_indirect_awarded;
			--END IF;
			
			ELSIF rec.row_num <= (v_award_extension_level+1) THEN -- 层级小于7时，扩展奖
				IF v_partition='L' THEN
					update account set balanceleft = balanceleft+(v_award_y*v_award_y_ratio)::numeric(8,2) WHERE id=rec.account_id returning balanceleft into tmp_balanceafter;	
				ELSE
					update account set balanceright = balanceright+(v_award_y*v_award_y_ratio)::numeric(8,2) WHERE id=rec.account_id returning balanceright into tmp_balanceafter;	
				END IF;
				insert into balanceactivity(id,source,linkedaccountid,accountid,amount,balanceafter) values(uuid_generate_v4(),concat('招商扩展奖:',v_partition,'区'),acc_id,rec.account_id,(v_award_y*v_award_y_ratio)::numeric(8,2),tmp_balanceafter);
				RAISE NOTICE '-- 扩展奖:% 金额:% x % = % ,分区:% 奖励发放状态:%|%',rec.account_name,v_award_y,v_award_y_ratio,v_award_y*v_award_y_ratio,v_partition,award_layer,is_indirect_awarded;
			ELSE
				is_indirect_awarded:=true;--层级大于8，设置奖励发放状态
			END IF;
		END IF;
    END LOOP;

	IF v_target_account.targettype IS NULL THEN -- 新加盟商户
		update account set status='ACTIVE',pendingfee=0 where id=acc_id;
	ELSE -- 升级商户
	update account set type=v_target_account_type,pendingfee=0,targettype=null where id=acc_id;
	END IF;
	RETURN 'success';
END;
$$ ;

CREATE OR REPLACE FUNCTION get_accounts_by_partition_and_depth(p_account_id uuid, p_partition accountpartition)
 RETURNS TABLE(account_id uuid, account_name character varying,account_type entitytype, sub_level int)
AS $$
BEGIN
    RETURN QUERY WITH RECURSIVE account_tree AS (
        -- Anchor member: start with the direct children of the input account
        SELECT
            a.id,
            a.accountname,
			a.type,
            1 AS level
        FROM
            account a
        WHERE
            a.upstreamaccount = p_account_id
            AND a.partition = p_partition

        UNION ALL

        -- Recursive member: find children of the current level accounts
        SELECT
            a.id,
            a.accountname,
			a.type,
            at.level + 1 AS level
        FROM
            account a
            JOIN account_tree at ON a.upstreamaccount = at.id
        WHERE
            a.type IN ('LV1_AGENT', 'LV2_AGENT', 'HQ_AGENT')
            AND at.level < 7
    )
    SELECT id, accountname, type, level
    FROM account_tree
    WHERE level BETWEEN 1 AND 7;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.complete_invitation_codes(user_id uuid)
 RETURNS TABLE(i_code character, create_type entitytype)
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_record RECORD;
    random_code CHAR(13);
	v_accountid UUID;
	code_array bpchar(13)[] := '{}';  -- Initialize the array
    type_array entitytype[] := '{}';  -- Initialize the array
    code_type public."entitytype";    -- Declare the loop variable
BEGIN
    RAISE NOTICE '====begin complete_invitation_codes(user_id UUID)====';
	SELECT accountid into v_accountid FROM users where id=user_id;

    -- Loop through the ENUM values
    FOREACH code_type IN ARRAY ARRAY['HQ_AGENT', 'LV1_AGENT', 'LV2_AGENT', 'STUDENT']::public."entitytype"[] LOOP
        -- Generate a random 13-character code
        random_code := (SELECT string_agg(chr((65+floor(random()*26)::integer)),'')FROM generate_series(1,13));
		if exists (select from invitationcode where code=random_code) then -- 监测到code冲突的话，自动重新生成
			LOOP
		        random_code := (SELECT string_agg(chr((65+floor(random()*26)::integer)),'')FROM generate_series(1,13));	
		        IF NOT EXISTS (select from invitationcode where code=random_code) THEN
		            EXIT;
		        END IF;
		    END LOOP;
		end if;

		SELECT code,createtype INTO v_record FROM invitationcode where userid=user_id and accountid=v_accountid and createtype=code_type;
		IF v_record IS NULL THEN--补全邀请码类型
	        INSERT INTO invitationcode (code, userid, accountid, createtype) VALUES (random_code, user_id, v_accountid, code_type)
			RETURNING code, createtype INTO v_record;
		END IF;
        -- Append the record's code and type to the arrays
        code_array := array_append(code_array, v_record.code);
        type_array := array_append(type_array, v_record.createtype);

    END LOOP;

    -- Return the results
    RETURN QUERY SELECT unnest(code_array) AS i_code, unnest(type_array) AS create_type;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.confirm_delivery(delivery_id uuid)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_delivery RECORD;
    tmp_balanceafter decimal(8,2);
	v_orderid bigint;
BEGIN
	raise notice '====begin confirm_delivery(delivry_id uuid)====';
	SELECT * INTO v_delivery FROM projectdelivery where id=delivery_id;
	IF v_delivery IS NULL THEN
		raise exception 'Delivery does not exist: %',delivery_id;
 	ELSIF v_delivery.status NOT IN ('PENDING') THEN
        raise exception 'The delivery has reached final status: %',v_delivery.status;
	END IF;

	-- 分账
	SELECT orderid INTO v_orderid FROM orderproduct where id=(SELECT orderproductid FROM projectdelivery WHERE id=delivery_id);
	update account set balance = balance+v_delivery.price WHERE id=v_delivery.deliveryaccount returning balance into tmp_balanceafter;	
	insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype) 
		values('服务供应商分成',v_orderid,v_delivery.orderproductid,v_delivery.deliveryaccount,v_delivery.price,tmp_balanceafter,'balance');
	update projectdelivery set status='CONFIRMED',confirmedat=NOW() AT TIME ZONE 'Asia/Shanghai' where id=delivery_id;

    RAISE NOTICE '====end confirm_delivery()====';
	RETURN 'success';
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_max_inventory_quantity(account_id uuid, product_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE 
    v_account record;
	v_product record;
	v_purchase_price numeric(8,2);
	v_quantity int;
begin
	raise notice '====begin get_max_inventory_quantity(account_id uuid,product_id uuid)====';
	select * into v_account from account where id=account_id;
	select * into v_product from product where id=product_id;
	v_purchase_price := v_product.pricingschedule ->> concat(v_account.type,'-course-purchase-price');-- 获取进货价
	raise notice 'purchase price:%',v_purchase_price;
	v_quantity := (v_account.balance + least(v_account.balanceleft,v_account.balanceright)*2 +  v_account.balancetriple) / v_purchase_price;
 	raise notice '====end get_max_inventory_quantity()====';	
	RETURN v_quantity;
END; $function$
;

CREATE OR REPLACE FUNCTION public.confirm_inventory(inventoryorder_id character)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_inventoryorder RECORD;
	v_remaining_price numeric(8,2);
	v_account RECORD;
	v_account_after RECORD;
BEGIN
	raise notice '====begin confirm_inventory(inventoryorder_id character)====';
	SELECT * INTO v_inventoryorder FROM inventoryorder where id=inventoryorder_id;
	IF v_inventoryorder IS NULL THEN
		RAISE EXCEPTION 'Inventoryorder does not exist: %',inventoryorder_id;
 	ELSIF v_inventoryorder.status::text NOT IN ('pending') THEN
        RAISE EXCEPTION 'Inventoryorder state machine transition is not allowed. status: %',v_inventoryorder.status::text;
	ELSIF v_inventoryorder.type::text NOT IN ('agent_topup') THEN
        RAISE EXCEPTION 'Inventoryorder type is not allowed. status: %',v_inventoryorder.type::text;
	END IF;

	--分配库存
	INSERT INTO productinventory (accountid,productid,quantity,lastinventoryorderid,lastorderid)
	VALUES (v_inventoryorder.accountid,v_inventoryorder.productid,v_inventoryorder.quantity,v_inventoryorder.id,null)
	ON CONFLICT (accountid,productid)
	DO UPDATE SET quantity=productinventory.quantity+v_inventoryorder.quantity,lastinventoryorderid=v_inventoryorder.id,lastorderid=null;
	update inventoryorder set status='settled' where id=v_inventoryorder.id;

    RAISE NOTICE '====end confirm_inventory()====';
	RETURN 'success';
END;
$function$
;

CREATE OR REPLACE FUNCTION get_student_user_by_account_id(account_id uuid)
    RETURNS TABLE
            (
                phone              varchar,
                email              varchar,
                nickname           varchar,
                firstname          varchar,
                lastname           varchar,
                sex                gender,
                province           varchar,
                city               varchar,
                avatarurl          text,
                accountname        varchar,
                accounttype        entitytype,
                acctcreatedat      timestamp,
                university         varchar,
                majorcode          varchar,
                genstudysuggestion text,
                mbtienergy varchar,
                mbtimind varchar,
                mbtidecision varchar,
                mbtireaction varchar,
                major varchar,
                StudyingSuggestion text,
                MajorReference text,
                mbtitype char,
                CharacterSuggestion text
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
return query
select u.phone,
       u.email,
       u.nickname,
       u.firstname,
       u.lastname,
       u.sex,
       u.province,
       u.city,
       u.avatarurl,
       acct.accountname,
       acct.type,
       acct.createdat     as acctcreatedat,
       sa.university,
       sa.majorcode,
       sa.StudySuggestion as genstudysuggestion,
       sa.mbtienergy,
       sa.mbtimind,
       sa.mbtidecision,
       sa.mbtireaction,
       m.name as major,
       m.StudyingSuggestion,
       m.MajorReference,
       ms.Type as mbtitype,
       ms.Suggestion as CharacterSuggestion
from public.users u
         left join useraccountrole uar on u.id = uar.userid
         left join account acct on acct.id = uar.accountid
         left join public.roles r on r.id = uar.roleid
         left join public.studentattribute sa on acct.id = sa.accountid
         LEFT JOIN Major m ON sa.majorcode = m.code
         LEFT JOIN MBTISuggestion ms ON CONCAT(sa.MBTIEnergy, sa.MBTIMind, sa.MBTIDecision, sa.MBTIReaction) = ms.Type
where acct.id = account_id
  and r.rolename = 'STUDENT';
END;
$function$;

CREATE OR REPLACE FUNCTION public.register_user(invitation_code character varying, exist_account_id uuid, u_phone character varying, nick_name character varying, open_id character varying, account_name character varying, u_password character varying, u_relationship character varying, u_email character varying, avatar_url text, u_source character varying, invite_userid uuid,role_id uuid default null)
 RETURNS new_user_acount
 LANGUAGE plpgsql;

CREATE FUNCTION get_agent_accountid_by_userid(user_id uuid)
    RETURNS uuid
    LANGUAGE plpgsql
AS
$$
BEGIN
    RETURN (select accountid from useraccountrole
                                      left join account acct on acct.id=useraccountrole.accountid
            where userid=user_id and acct.type in ('LV1_AGENT','LV2_AGENT', 'HQ_AGENT', 'HEAD_QUARTER'););
END;
$$;

CREATE FUNCTION get_student_accountid_by_userid(user_id uuid)
    RETURNS uuid
    LANGUAGE plpgsql
AS
$$
BEGIN
    RETURN (select accountid from useraccountrole
                                      left join account acct on acct.id=useraccountrole.accountid
            where userid=$1 and acct.type in ('STUDENT')
    )
END;
$$;

CREATE OR REPLACE FUNCTION public.agent_to_student(user_id uuid, account_name character varying, u_relationship character varying)
 RETURNS character varying
 LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.student_to_agent(user_id uuid, account_name character varying, account_type entitytype)
 RETURNS character varying
 LANGUAGE plpgsql;