package services

import (
	"context"
	"xiandeng.net.cn/server/db"
	"xiandeng.net.cn/server/db/models"
	"xiandeng.net.cn/server/pkg/config"
	"xiandeng.net.cn/server/pkg/log"
)

type ShowcaseService interface {
	GetCompany(ctx context.Context, companyPath *string) (models.Company, error)
	ListShowcaseItems(ctx context.Context, company *string) ([]models.Showcasepageitemdatum, error)
	ListShowcaseCarousel(ctx context.Context, company *string) ([]models.Showcasepagecarouseldatum, error)
}

type showcaseService struct {
	*Service
}

func NewShowcaseService(conf *config.Config, logger *log.Logger, repo db.Repository) ShowcaseService {
	return &showcaseService{
		Service: NewService(conf, logger, repo),
	}
}

func (s *showcaseService) ListShowcaseCarousel(ctx context.Context, company *string) ([]models.Showcasepagecarouseldatum, error) {
	return s.repo.NewQueries().ListCarouselData(ctx, company)
}

func (s *showcaseService) ListShowcaseItems(ctx context.Context, company *string) ([]models.Showcasepageitemdatum, error) {
	return s.repo.NewQueries().ListItemData(ctx, company)
}

func (s *showcaseService) GetCompany(ctx context.Context, companyPath *string) (models.Company, error) {
	return s.repo.NewQueries().GetCompanyByPath(ctx, companyPath)
}
