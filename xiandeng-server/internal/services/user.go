package services

import (
	"context"
	"fmt"
	"github.com/google/uuid"
	"xiandeng.net.cn/server/db/models"
	"xiandeng.net.cn/server/pkg/log"

	"xiandeng.net.cn/server/db"
	"xiandeng.net.cn/server/pkg/config"
	"xiandeng.net.cn/server/services/cache"
)

type UserService interface {
	GetUser(ctx context.Context, userId uuid.UUID) (models.User, error)
}

type userService struct {
	*Service
	cache cache.GlobalCache
}

func NewUserService(conf *config.Config, logger *log.Logger, repo db.Repository, c cache.GlobalCache) UserService {
	return &userService{
		Service: NewService(conf, logger, repo),
		cache:   c,
	}
}

func (s *userService) GetUser(ctx context.Context, userId uuid.UUID) (models.User, error) {
	u, err := s.repo.NewQueries().GetUser(ctx, userId)
	if err != nil {
		return models.User{}, fmt.Errorf("userService, GetUser: %s", err.Error())
	}
	return u, nil
}

var _ UserService = (*userService)(nil)
