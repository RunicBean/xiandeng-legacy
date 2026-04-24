ALTER TABLE Account ALTER Balance DROP DEFAULT;
ALTER TABLE Account ALTER Balance DROP NOT NULL;
ALTER TABLE Account ALTER ReserveBalance DROP NOT NULL;
ALTER TABLE Account ALTER ReserveBalance DROP DEFAULT;
ALTER TABLE BalanceActivity DROP COLUMN OrderProductId;
DROP index idx_studententitlement_studentid_entitlementtypeid;
ALTER TABLE StudentEntitlement ALTER COLUMN ExpiresAt TYPE timestamp;
ALTER TABLE ProductEntitlementType ALTER COLUMN ValidDays DROP NOT NULL;
