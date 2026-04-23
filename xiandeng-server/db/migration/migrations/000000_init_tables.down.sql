ALTER TABLE CustomSQLQueryHistory DROP CONSTRAINT customsqlqueryhistory_userid_fkey;
ALTER TABLE CustomSQLQueryHistory DROP CONSTRAINT customsqlqueryhistory_sqlid_fkey;

ALTER TABLE AccountSQL DROP CONSTRAINT accountsql_acctid_fkey;
ALTER TABLE AccountSQL DROP CONSTRAINT accountsql_sqlid_fkey;

ALTER TABLE InvitationCode DROP CONSTRAINT invcode_accountid_fkey; 
ALTER TABLE InvitationCode DROP CONSTRAINT invcode_userid_fkey;

ALTER TABLE WithdrawAttachment DROP CONSTRAINT withdrawattachment_withdrawid_fkey;

ALTER TABLE Withdraw DROP CONSTRAINT withdraw_acctid_fkey;

ALTER TABLE AccountAddress DROP CONSTRAINT acctaddress_acctid_fkey;

ALTER TABLE BalanceActivity DROP CONSTRAINT balanceactivity_orderid_fkey;
ALTER TABLE BalanceActivity DROP CONSTRAINT balanceactivity_withdrawid_fkey;
ALTER TABLE BalanceActivity DROP CONSTRAINT balanceactivity_acctid_fkey;

ALTER TABLE QianliaoCoupon DROP CONSTRAINT qianliaocoupon_stuid_fkey;

ALTER TABLE ProductPriceOverwrite DROP CONSTRAINT productpriceoverwrite_rooteprod_fkey;
ALTER TABLE ProductPriceOverwrite DROP CONSTRAINT productpriceoverwrite_downstreamacctid_fkey;

ALTER TABLE ProductImage DROP CONSTRAINT productimage_prodid_fkey;

ALTER TABLE ProductEntitlementType DROP CONSTRAINT productentitlementtype_productid_fkey;
ALTER TABLE ProductEntitlementType DROP CONSTRAINT productentitlementtype_entitlementtypeid_fkey;

ALTER TABLE OrderCoupon DROP CONSTRAINT ordercoupon_agentid_fkey;
ALTER TABLE OrderCoupon DROP CONSTRAINT ordercoupon_issuser_fkey;
ALTER TABLE OrderCoupon DROP CONSTRAINT ordercoupon_prodid_fkey;
ALTER TABLE OrderCoupon DROP CONSTRAINT ordercoupon_stuid_fkey;

ALTER TABLE OrderProduct DROP CONSTRAINT orderproduct_orderid_fkey;
ALTER TABLE OrderProduct DROP CONSTRAINT orderproduct_productid_fkey;
ALTER TABLE OrderProduct DROP CONSTRAINT orderproduct_couponcode_fkey;

ALTER TABLE Orders DROP CONSTRAINT order_stuid_fkey;

ALTER TABLE StudentEntitlement DROP CONSTRAINT studententitlement_stuid_fkey;
ALTER TABLE StudentEntitlement DROP CONSTRAINT studententitlement_enttpeid_fkey;
ALTER TABLE StudentEntitlement DROP CONSTRAINT studententitlement_lastorderproductid_fkey;

ALTER TABLE MajorEnterprise DROP CONSTRAINT majorenterprise_enterpriseid_fkey;
ALTER TABLE MajorEnterprise DROP CONSTRAINT majorenterprise_majorcode_fkey;

ALTER TABLE StudentAttribute DROP CONSTRAINT studentattribute_majorcode_fkey;
ALTER TABLE StudentAttribute DROP CONSTRAINT studentattribute_accountid_fkey;
ALTER TABLE AgentAttribute DROP CONSTRAINT agentattribute_accountid_fkey;
ALTER TABLE Guardian DROP CONSTRAINT guardian_guardianid_fkey;
ALTER TABLE Guardian DROP CONSTRAINT guardian_studentid_fkey;
ALTER TABLE Users DROP CONSTRAINT users_referaluserid_fkey;
ALTER TABLE Users DROP CONSTRAINT users_accountid_fkey;
ALTER TABLE Account DROP CONSTRAINT account_upstreamaccount_fkey;


DROP TABLE Faculty;
-- DROP TABLE University;
DROP TABLE CustomSQLQueryHistory;
DROP TABLE AccountSQL;
DROP TABLE CustomSQL;
DROP TABLE InvitationCode;
DROP TABLE WithdrawAttachment;
DROP TABLE Withdraw;
DROP TABLE AccountAddress;
DROP TABLE BalanceActivity;
DROP TABLE QianliaoCoupon;
DROP TABLE ProductPriceOverwrite;
DROP TABLE ProductImage;
DROP TABLE ProductEntitlementType;
DROP TABLE OrderProduct;
DROP TABLE Product;
DROP TABLE OrderCoupon;
DROP TABLE Orders;
DROP TABLE EntitlementType;
DROP TABLE StudentEntitlement;
DROP TABLE Guardian CASCADE;
DROP TABLE CasbinRule CASCADE;
DROP TABLE Role CASCADE;
DROP TABLE Privilege CASCADE;
DROP TABLE AgentAttribute CASCADE;
DROP TABLE StudentAttribute CASCADE;
DROP TABLE MajorEnterprise;
DROP TABLE GovEnterprise;
DROP TABLE Major;
DROP TABLE Users CASCADE;
DROP TABLE Account CASCADE;

DROP TYPE Gender;
DROP TYPE EntityType;

DROP EXTENSION "uuid-ossp";

