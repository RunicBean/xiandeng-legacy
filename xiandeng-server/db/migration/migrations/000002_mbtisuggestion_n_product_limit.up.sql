CREATE TABLE MBTISuggestion (
  Id serial NOT NULL PRIMARY KEY,
  Type char(4),
  Suggestion text
);

ALTER TABLE Product ADD PurchaseLimit smallint DEFAULT 0;
ALTER TABLE Major ADD MajorReference TEXT;
ALTER TABLE Major ADD StudyingSuggestion TEXT;