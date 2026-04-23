package controller

import (
	"net/http"

	"xiandeng.net.cn/server/internal/app"
	"xiandeng.net.cn/server/internal/code"
	"xiandeng.net.cn/server/internal/services"
)

type ShowcaseController struct {
	*Controller
	showcaseService services.ShowcaseService
}

func NewShowcaseController(controller *Controller, service services.ShowcaseService) *ShowcaseController {
	return &ShowcaseController{
		Controller:      controller,
		showcaseService: service,
	}
}

type QueryCompany struct {
	CompanyName string `json:"company_name" form:"company_name"`
}

func (c *ShowcaseController) ListShowcasePageCarouselData() app.HandlerFunc {
	return func(ctx app.Context) {
		var query QueryCompany
		err := ctx.ShouldBindQuery(&query)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		d, err := c.showcaseService.ListShowcaseCarousel(ctx.RequestContext(), &query.CompanyName)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(d)
	}
}

func (c *ShowcaseController) ListShowcasePageItemData() app.HandlerFunc {
	return func(ctx app.Context) {
		var query QueryCompany
		err := ctx.ShouldBindQuery(&query)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		d, err := c.showcaseService.ListShowcaseItems(ctx.RequestContext(), &query.CompanyName)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(d)
	}
}

func (c *ShowcaseController) GetCompany() app.HandlerFunc {
	return func(ctx app.Context) {
		companyPath := ctx.Param("company_path")
		company, err := c.showcaseService.GetCompany(ctx.RequestContext(), &companyPath)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(company)
	}
}
