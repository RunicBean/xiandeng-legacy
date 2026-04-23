package migration

import (
	"database/sql"
	"xiandeng.net.cn/server/pkg/config"

	"github.com/golang-migrate/migrate/v4"
	"github.com/golang-migrate/migrate/v4/database/pgx/v5"
	_ "github.com/golang-migrate/migrate/v4/source/file"
)

const (
	migrationSource = "file://db/migration/migrations"
)

func NewMigrate(conf *config.Config) *migrate.Migrate {
	db, err := sql.Open("pgx/v5", conf.Database.CredInfo)
	if err != nil {
		panic(err)
	}
	driver, err := pgx.WithInstance(db, &pgx.Config{})
	if err != nil {
		panic(err)
	}
	m, err := migrate.NewWithDatabaseInstance(
		migrationSource,
		conf.Database.DbName,
		driver)
	if err != nil {
		panic(err)
	}
	return m
}
