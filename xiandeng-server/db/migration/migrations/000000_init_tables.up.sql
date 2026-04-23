CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

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

CREATE TABLE Users (
  Id uuid PRIMARY key default uuid_generate_v4(),
  Password varchar(65535) NOT NULL,
  Phone varchar(255) UNIQUE NOT NULL,
  Email varchar(255) UNIQUE,
  NickName varchar(255) NOT NULL,
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
  AccountId uuid,
  ReferalUserId uuid,
  CreatedAt timestamp DEFAULT (CURRENT_TIMESTAMP),
  UpdatedAt timestamp DEFAULT (CURRENT_TIMESTAMP)
);



CREATE TABLE Account (
  Id UUID PRIMARY KEY default uuid_generate_v4(),
  Type EntityType,
  ReserveBalance decimal(8,2),
  Balance decimal(8,2),
  UpstreamAccount UUID,
  AccountName varchar(255),
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
  UpdatedAt timestamp DEFAULT (CURRENT_TIMESTAMP)
);


CREATE TABLE StudentAttribute (
  AccountId uuid PRIMARY KEY,
  University varchar(255),
  MajorCode VARCHAR(255),
  MBTIEnergy varchar(32),
  MBTIMind varchar(32),
  MBTIDecision varchar(32),
  MBTIReaction varchar(32),
  CreatedAt timestamp DEFAULT (CURRENT_TIMESTAMP),
  UpdatedAt timestamp DEFAULT (CURRENT_TIMESTAMP)
);

CREATE TABLE Major (
  Code varchar(255) PRIMARY KEY,
  Name varchar(255),
  Faculty varchar(255),
  Department varchar(255),
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
  UpdatedAt timestamp DEFAULT (CURRENT_TIMESTAMP)
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
  Code bigint PRIMARY KEY, -- zerofill
  AgentId uuid NOT NULL, -- 创建优惠券的代理
  IssuingUser uuid NOT NULL, -- 创建优惠券的用户
  DiscountAmount decimal(8,2), -- 优惠金额
  MaxCount int, -- 最多使用次数
  ProductId uuid, -- 非空则表示只能在购买某一种商品时使用
  StudentId uuid, -- 非空则表示只能给特定学生使用
  EffectStartDate date, -- 起始日期：有效期起始日期 （可置空)
  EffectDueDate date, -- 截止日期：有效期的截止日期 （不得早于起始日期，可置空）
  CreatedAt timestamp DEFAULT (CURRENT_TIMESTAMP),
  UsedAt timestamp DEFAULT (CURRENT_TIMESTAMP) -- 使用时间
);


CREATE TABLE Product (
  Id uuid PRIMARY KEY default uuid_generate_v4(),
  Type varchar(255) DEFAULT 'Entitlement',
  ProductName VARCHAR(255) NOT NULL, -- 商品名称
  FinalPrice DECIMAL(8,2) NOT NULL, -- 商品零售价格
  HQAgentPrice DECIMAL(8,2) NOT NULL, -- 总部代理进货价
  Lv1AgentPrice DECIMAL(8,2) NOT NULL, -- 一级代理进货价
  Lv2AgentPrice DECIMAL(8,2) NOT NULL, -- 二级代理进货价
  PublishStatus boolean NOT NULL, -- 上下架状态：0下架1上架
  Description TEXT NOT NULL, -- 商品描述
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
  Price decimal(8, 2)
);

CREATE TABLE QianliaoCoupon (
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
  Id uuid PRIMARY KEY default uuid_generate_v4(),
  AccountId uuid, -- 只有代理需要提现
  Amount decimal(8,2), -- 提现金额,非负数
  Status varchar(255), -- PENDING,DISPATCHED,CANCELLED,DECLINED
  Memo varchar(255),
  CreatedAt timestamp DEFAULT (CURRENT_TIMESTAMP),
  UpdatedAt timestamp DEFAULT (CURRENT_TIMESTAMP)
);


CREATE TABLE WithdrawAttachment (
  Id uuid PRIMARY KEY default uuid_generate_v4(),
  WithdrawId uuid,
  ImageURL text -- 图片URL
);

CREATE TABLE Privilege (
  Id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  AccountType EntityType,
  Name varchar(255)
);

CREATE TABLE Role (
  Id uuid PRIMARY KEY default uuid_generate_v4(),
  Name varchar(255),
  AccountType EntityType,
  IsSystem boolean,
  CreatedAt timestamp DEFAULT (CURRENT_TIMESTAMP),
  UpdatedAt timestamp DEFAULT (CURRENT_TIMESTAMP)
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

-- CREATE TABLE University (
--   Id serial NOT NULL PRIMARY KEY,
--   Province varchar(255),
--   City varchar(255),
--   Name varchar(255)
-- );

CREATE TABLE Faculty (
  Id serial NOT NULL PRIMARY KEY,
  Type varchar(128),
  Name varchar(255)
);


ALTER TABLE Users ADD CONSTRAINT users_referaluserid_fkey FOREIGN KEY (ReferalUserId) REFERENCES Users (Id);
ALTER TABLE Users ADD CONSTRAINT users_accountid_fkey FOREIGN KEY (AccountId) REFERENCES Account (Id);
ALTER TABLE Account ADD CONSTRAINT account_upstreamaccount_fkey FOREIGN KEY (UpstreamAccount) REFERENCES Account (Id);
ALTER TABLE Guardian ADD CONSTRAINT guardian_guardianid_fkey FOREIGN KEY (GuardianId) REFERENCES Users (Id);
ALTER TABLE Guardian ADD CONSTRAINT guardian_studentid_fkey FOREIGN KEY (StudentId) REFERENCES Users (Id);
ALTER TABLE AgentAttribute ADD CONSTRAINT agentattribute_accountid_fkey FOREIGN KEY (AccountId) REFERENCES Account (Id);
ALTER TABLE StudentAttribute ADD CONSTRAINT studentattribute_accountid_fkey FOREIGN KEY (AccountId) REFERENCES Account (Id);
ALTER TABLE StudentAttribute ADD CONSTRAINT studentattribute_majorcode_fkey FOREIGN KEY (MajorCode) REFERENCES Major (Code);
ALTER TABLE MajorEnterprise ADD CONSTRAINT majorenterprise_majorcode_fkey FOREIGN KEY (MajorCode) REFERENCES Major (Code);
ALTER TABLE MajorEnterprise ADD CONSTRAINT majorenterprise_enterpriseid_fkey FOREIGN KEY (EnterpriseId) REFERENCES GovEnterprise (Id);
ALTER TABLE StudentEntitlement ADD CONSTRAINT studententitlement_stuid_fkey FOREIGN KEY (StudentId) REFERENCES Account (Id);
ALTER TABLE StudentEntitlement ADD CONSTRAINT studententitlement_enttpeid_fkey FOREIGN KEY (EntitlementTypeId) REFERENCES EntitlementType (Id);
ALTER TABLE StudentEntitlement ADD CONSTRAINT studententitlement_lastorderproductid_fkey FOREIGN KEY (LastOrderId) REFERENCES Orders (Id);
ALTER TABLE Orders ADD CONSTRAINT order_stuid_fkey FOREIGN KEY (StudentId) REFERENCES Account (Id);
ALTER TABLE OrderProduct ADD CONSTRAINT orderproduct_orderid_fkey FOREIGN KEY (OrderId) REFERENCES Orders (Id);
ALTER TABLE OrderProduct ADD CONSTRAINT orderproduct_productid_fkey FOREIGN KEY (ProductId) REFERENCES Product (Id);
ALTER TABLE OrderProduct ADD CONSTRAINT orderproduct_couponcode_fkey FOREIGN KEY (CouponCode) REFERENCES OrderCoupon (Code);
ALTER TABLE OrderCoupon ADD CONSTRAINT ordercoupon_agentid_fkey FOREIGN KEY (AgentId) REFERENCES Account (Id);
ALTER TABLE OrderCoupon ADD CONSTRAINT ordercoupon_issuser_fkey FOREIGN KEY (IssuingUser) REFERENCES Users (Id);
ALTER TABLE OrderCoupon ADD CONSTRAINT ordercoupon_prodid_fkey FOREIGN KEY (ProductId) REFERENCES Product (Id);
ALTER TABLE OrderCoupon ADD CONSTRAINT ordercoupon_stuid_fkey FOREIGN KEY (StudentId) REFERENCES Account (Id);
ALTER TABLE ProductEntitlementType ADD CONSTRAINT productentitlementtype_productid_fkey FOREIGN KEY (ProductId) REFERENCES Product (Id);
ALTER TABLE ProductEntitlementType ADD CONSTRAINT productentitlementtype_entitlementtypeid_fkey FOREIGN KEY (EntitlementTypeId) REFERENCES EntitlementType (Id);
ALTER TABLE ProductImage ADD CONSTRAINT productimage_prodid_fkey FOREIGN KEY (ProductId) REFERENCES Product (Id);
ALTER TABLE ProductPriceOverwrite ADD CONSTRAINT productpriceoverwrite_rooteprod_fkey FOREIGN KEY (RootProduct) REFERENCES Product (Id);
ALTER TABLE ProductPriceOverwrite ADD CONSTRAINT productpriceoverwrite_downstreamacctid_fkey FOREIGN KEY (DownstreamAccountId) REFERENCES Account (Id);
ALTER TABLE QianliaoCoupon ADD CONSTRAINT qianliaocoupon_stuid_fkey FOREIGN KEY (StudentId) REFERENCES Account (Id);
ALTER TABLE BalanceActivity ADD CONSTRAINT balanceactivity_orderid_fkey FOREIGN KEY (OrderId) REFERENCES Orders (Id);
ALTER TABLE BalanceActivity ADD CONSTRAINT balanceactivity_withdrawid_fkey FOREIGN KEY (WithdrawId) REFERENCES Withdraw (Id);
ALTER TABLE BalanceActivity ADD CONSTRAINT balanceactivity_acctid_fkey FOREIGN KEY (AccountId) REFERENCES Account (Id);
ALTER TABLE AccountAddress ADD CONSTRAINT acctaddress_acctid_fkey FOREIGN KEY (AccountId) REFERENCES Account (Id);
ALTER TABLE Withdraw ADD CONSTRAINT withdraw_acctid_fkey FOREIGN KEY (AccountId) REFERENCES Account (Id);
ALTER TABLE WithdrawAttachment ADD CONSTRAINT withdrawattachment_withdrawid_fkey FOREIGN KEY (WithdrawId) REFERENCES Withdraw (Id);
ALTER TABLE InvitationCode ADD CONSTRAINT invcode_accountid_fkey FOREIGN KEY (AccountId) REFERENCES Account (Id);
ALTER TABLE InvitationCode ADD CONSTRAINT invcode_userid_fkey FOREIGN KEY (UserId) REFERENCES Users (Id);
ALTER TABLE AccountSQL ADD CONSTRAINT accountsql_acctid_fkey FOREIGN KEY (AccountId) REFERENCES Account (Id);
ALTER TABLE AccountSQL ADD CONSTRAINT accountsql_sqlid_fkey FOREIGN KEY (SQLId) REFERENCES CustomSQL (Id);
ALTER TABLE CustomSQLQueryHistory ADD CONSTRAINT customsqlqueryhistory_userid_fkey FOREIGN KEY (UserId) REFERENCES Users (Id);
ALTER TABLE CustomSQLQueryHistory ADD CONSTRAINT customsqlqueryhistory_sqlid_fkey FOREIGN KEY (SQLId) REFERENCES CustomSQL (Id);
