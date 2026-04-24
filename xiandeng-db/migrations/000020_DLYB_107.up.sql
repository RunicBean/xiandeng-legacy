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