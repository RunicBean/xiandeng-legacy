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

CREATE INDEX recruit_recruitid_idx ON Recruit (RecruitId);

CREATE OR REPLACE FUNCTION reset_couponcode_on_failed_status()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if the status of the order is updated to 'failed'
    IF NEW.status = 'failed' THEN
        -- Update the couponcode in orderproduct to NULL for the related orderid
        UPDATE orderproduct
        SET couponcode = NULL
        WHERE orderproduct.orderid = OLD.id;
    END IF;

    -- Return the updated order to proceed with the update operation
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_reset_couponcode_on_failed_status
AFTER UPDATE OF status ON public.orders
FOR EACH ROW
WHEN (OLD.status IS DISTINCT FROM NEW.status AND NEW.status = 'failed')
EXECUTE FUNCTION reset_couponcode_on_failed_status();

