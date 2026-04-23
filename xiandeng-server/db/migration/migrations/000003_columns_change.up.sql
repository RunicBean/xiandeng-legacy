ALTER TABLE Account ALTER Balance SET DEFAULT 0;
ALTER TABLE Account ALTER Balance SET NOT NULL;
ALTER TABLE Account ALTER ReserveBalance SET NOT NULL;
ALTER TABLE Account ALTER ReserveBalance SET DEFAULT 0;
ALTER TABLE BalanceActivity ADD OrderProductId bigint NOT NULL;
ALTER TABLE BalanceActivity ADD CONSTRAINT balanceactivity_orderproductid_fkey FOREIGN KEY (OrderProductId) REFERENCES OrderProduct (Id);
create unique index idx_studententitlement_studentid_entitlementtypeid on StudentEntitlement (StudentId, EntitlementTypeId);
ALTER TABLE StudentEntitlement ALTER COLUMN ExpiresAt TYPE date USING expiresat::date;
ALTER TABLE ProductEntitlementType ALTER COLUMN ValidDays SET NOT NULL;

