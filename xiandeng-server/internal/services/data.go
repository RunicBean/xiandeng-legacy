package services

import (
	"context"
	"fmt"

	"xiandeng.net.cn/server/constants"
	"xiandeng.net.cn/server/db"
	"xiandeng.net.cn/server/pkg/config"
	"xiandeng.net.cn/server/pkg/log"
)

type DataService interface {
	GetWording(ctx context.Context, ns constants.WordingNamespace) (map[string]string, error)
}

type dataService struct {
	*Service
}

func NewDataService(conf *config.Config, logger *log.Logger, repo db.Repository) DataService {
	return &dataService{
		Service: NewService(conf, logger, repo),
	}
}

func (s *dataService) GetWording(ctx context.Context, ns constants.WordingNamespace) (map[string]string, error) {
	nsStr := string(ns)
	rows, err := s.repo.NewQueries().GetWording(ctx, &nsStr)
	if err != nil {
		return nil, fmt.Errorf("failed to get entitytype wording: %v", err.Error())
	}
	ret := map[string]string{}
	for _, row := range rows {
		ret[row.Key] = *row.Value
	}
	return ret, nil
}
