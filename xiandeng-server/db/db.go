//go:generate go run github.com/sqlc-dev/sqlc/cmd/sqlc generate
package db

import (
	"context"
	"xiandeng.net.cn/server/pkg/config"

	"xiandeng.net.cn/server/db/models"

	"github.com/jackc/pgx/v5/pgxpool"
)

// func finalizer(db *sql.DB) {
// 	if db == nil {
// 		return
// 	}

// 	err := db.Close()
// 	if err != nil {
// 		panic(err)
// 	}
// }

// func InitDB(dsn string) (db *sql.DB, err error) {
// 	db, err = sql.Open("mysql", dsn)
// 	if err != nil {
// 		panic(err)
// 	}
// 	if err = db.Ping(); err != nil {
// 		panic(err)
// 	}

// 	db.SetMaxOpenConns(20)
// 	db.SetMaxIdleConns(10)
// 	db.SetConnMaxLifetime(time.Minute * 10)

// 	runtime.SetFinalizer(db, finalizer)
// 	return db, nil
// }

func NewDBTX(conf *config.Config) (models.DBTX, error) {
	ctx := context.Background()
	pool, err := pgxpool.New(ctx, conf.Database.CredInfo)
	// pool, err := pgx.Connect(ctx, dsn)
	if err != nil {
		panic(err)
	}

	if err = pool.Ping(ctx); err != nil {
		panic(err)
	}

	return pool, nil
}
