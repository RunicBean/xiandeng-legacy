ALTER TABLE GovEnterprise DROP LogoUrl;

CREATE TABLE Faculty (
  Id serial NOT NULL PRIMARY KEY,
  Type varchar(128),
  Name varchar(255)
);