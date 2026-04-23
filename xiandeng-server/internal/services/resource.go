package services

import (
	"context"
	"xiandeng.net.cn/server/constants"
	"xiandeng.net.cn/server/db"
	"xiandeng.net.cn/server/db/models"
	"xiandeng.net.cn/server/pkg/config"
	"xiandeng.net.cn/server/pkg/log"
	"xiandeng.net.cn/server/pkg/resource"
)

type ResourceService interface {
	GetTermsOverallSignedUrl() string
	GetOrgMetadata(ctx context.Context, uri string) (models.GetOrgMetadataRow, error)
}

type resourceService struct {
	*Service
	resource resource.Resource
}

func NewResourceService(conf *config.Config, logger *log.Logger, repo db.Repository, res resource.Resource) ResourceService {
	return &resourceService{
		Service:  NewService(conf, logger, repo),
		resource: res,
	}
}

func (rs *resourceService) GetTermsOverallSignedUrl() string {
	return rs.resource.GetTermsOverallSignedUrl(constants.TERMS_OVERALL_KEY)
}

func (rs *resourceService) GetOrgMetadata(ctx context.Context, uri string) (models.GetOrgMetadataRow, error) {
	return rs.repo.NewQueries().GetOrgMetadata(ctx, uri)
}
