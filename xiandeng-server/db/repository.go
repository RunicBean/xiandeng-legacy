package db

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"xiandeng.net.cn/server/db/models"
	"xiandeng.net.cn/server/pkg/log"
)

type Repository interface {
	NewQueries() *models.Queries
	StartTransaction(ctx context.Context) (pgx.Tx, *models.Queries, error)
	GenerateCode(
		ctx context.Context,
		accountId uuid.UUID,
		userId uuid.UUID,
		createType models.NullEntitytype,
		code string,
		duration time.Duration) error
	//CreateUser(
	//	ctx context.Context,
	//	userInput models2.UserBasicInfo,
	//	arg models.InitCreateUserParams) (entityType models.Entitytype, userId string, accountId string, err error)
}

type repository struct {
	db     models.DBTX
	logger *log.Logger
}

func (r *repository) NewQueries() *models.Queries {
	return models.New(r.db)
}

func NewRepository(db models.DBTX, logger *log.Logger) Repository {
	return &repository{db: db, logger: logger}
}
