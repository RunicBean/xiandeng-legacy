create table Company(
     Id serial not null primary key,
     Path varchar(255) default null,
     Name varchar(255) default null,
     CreatedAt timestamp DEFAULT (CURRENT_TIMESTAMP),
     UpdatedAt timestamp DEFAULT (CURRENT_TIMESTAMP)
);