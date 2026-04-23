package controller

import (
	"errors"
	"fmt"
	"net/http"
	"strconv"

	"xiandeng.net.cn/server/pkg/utils/model_util"

	"github.com/google/uuid"
	"xiandeng.net.cn/server/db"
	"xiandeng.net.cn/server/db/models"
	"xiandeng.net.cn/server/internal/app"
	"xiandeng.net.cn/server/internal/code"
	"xiandeng.net.cn/server/internal/services"
	"xiandeng.net.cn/server/pkg/config"
	"xiandeng.net.cn/server/pkg/log"
	"xiandeng.net.cn/server/pkg/oss"
	product_svc "xiandeng.net.cn/server/services/product"
	"xiandeng.net.cn/server/services/scraper"
)

type ResourceController struct {
	*Controller
	resourceService services.ResourceService
	repo            db.Repository
	ossClient       oss.OSSClient
}

func NewResourceController(
	controller *Controller,
	service services.ResourceService,
	repo db.Repository,
	ossClient oss.OSSClient) *ResourceController {
	return &ResourceController{
		Controller:      controller,
		resourceService: service,
		repo:            repo,
		ossClient:       ossClient,
	}
}

type ScrapeOfferQuery struct {
	Page     int `json:"page" form:"page"`
	PageSize int `json:"page_size" form:"page_size"`
}

// ref: https://swaggo.github.io/swaggo.io/declarative_comments_format/api_operation.html
// @Summary 获取offer先生信息
// @Description 获取offer先生
// @Tags 商品
// @Produce  json
// @Param object query ScrapeOfferQuery false "ScrapeOfferQuery"
// @Success 200 {object} any
// @Failure 400 {object} any
// @Router /aresource/recruit/update [post]
func (c *ResourceController) ScrapeOffer() app.HandlerFunc {
	return func(ctx app.Context) {
		var query ScrapeOfferQuery
		err := ctx.ShouldBindQuery(&query)
		if err != nil {
			ctx.AbortWithBadRequest(err)
		}
		rs := scraper.NewRecruitScraper()
		data, err := rs.ScrapeAndParse(query.Page, query.PageSize)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.ServerInternalErr, err.Error(), err)
			return
		}

		newdata := make([]*scraper.Recruit, 0)
		for _, d := range data {
			e, _ := c.repo.NewQueries().CheckRecruitIdExists(ctx.RequestContext(), int32(d.RecruitId))
			if !e {
				newdata = append(newdata, d)
			}
		}

		count, err := c.repo.NewQueries().InsertRecruits(ctx.RequestContext(), model_util.RecruitInsertParamsTransform(newdata))
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.ServerInternalErr, err.Error(), err)
			return
		}
		ctx.SuccessCreateJSON(map[string]int64{
			"updated": count,
		})

	}
}

type QueryListRecruitMenu struct {
	Start int `json:"start" form:"start"`
	Size  int `json:"size" form:"size"`
}

func (c *ResourceController) ListRecruitMenu() app.HandlerFunc {
	return func(ctx app.Context) {
		var query QueryListRecruitMenu
		err := ctx.ShouldBindQuery(&query)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		data, err := c.repo.NewQueries().ListRecruitMainPage(ctx.RequestContext(), models.ListRecruitMainPageParams{
			Start: int32(query.Start),
			Size:  int32(query.Size),
		})
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(data)
	}
}

func (c *ResourceController) GetRecruitDetail() app.HandlerFunc {
	return func(ctx app.Context) {
		recruitIdStr := ctx.Param("recruitid")
		recruitId, err := strconv.Atoi(recruitIdStr)
		if err != nil {
			ctx.AbortWithBadRequest(errors.New("recruitid 需为数字"))
			return
		}
		r, err := c.repo.NewQueries().GetRecruitDetail(ctx.RequestContext(), int32(recruitId))
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.RecruitRecordNotFound, err.Error(), err, log.SimpleMapParam{"recruit_id": strconv.Itoa(recruitId)})
			return
		}
		ctx.SuccessJSON(r)
	}
}

// GenerateReport 生成报告
// @Summary 生成报告
// @Description 生成报告
// @Tags 服务
// @Success 201 {object} controller.ResponseJsonResult
// @Produce application/json
// @Security ApiKeyAuth
// @Router /resource/planning-report/create [post]
func (c *ResourceController) GenerateReport() app.HandlerFunc {
	return func(ctx app.Context) {
		u := ctx.User()
		r, err := c.repo.NewQueries().GetStudentPlanningData(ctx.RequestContext(), models.GetStudentPlanningDataParams{
			ID:   u.ID,
			ID_2: ctx.Account().ID,
		})
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		rg, err := product_svc.NewReportGenerator(config.PlanningReportTemplatePath)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		remotePath, err := rg.GenerateAndUpload(r, c.ossClient)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessCreateJSON(remotePath)
	}
}

// GetStudentPlanningReportData 获取当前学生的报告信息
// @Summary 获取当前学生的报告信息
// @Description 获取当前学生的报告信息
// @Tags 服务
// @Success 201 {object} controller.ResponseJsonResult
// @Produce application/json
// @Security ApiKeyAuth
// @Router /resource/planning-report [get]
//func (c *ResourceController) GetStudentPlanningReportData() app.HandlerFunc {
//	return func(ctx app.Context) {
//		u := ctx.User()
//		r, err := c.repo.NewQueries().GetStudentPlanningData(ctx.RequestContext(), u.ID)
//		if err != nil {
//			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
//			return
//		}
//		ctx.SuccessJSON(r)
//	}
//}

// GetStudentPlanningReportDataByAccountId 获取当前学生的报告信息
// @Summary 获取当前学生的报告信息
// @Description 获取当前学生的报告信息
// @Tags 服务
// @Success 201 {object} controller.ResponseJsonResult
// @Produce application/json
// @Security ApiKeyAuth
// @Router /resource/planning-report/{id} [get]
func (c *ResourceController) GetStudentPlanningReportDataByAccountId() app.HandlerFunc {
	return func(ctx app.Context) {
		accountId := ctx.Param("account_id")
		r, err := c.repo.NewQueries().GetStudentPlanningDataByAccountId(ctx.RequestContext(), uuid.MustParse(accountId))
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(r)
	}
}

func (c *ResourceController) GetStudentPlanningPrecheckDataByAccountId() app.HandlerFunc {
	return func(ctx app.Context) {
		accountId := ctx.Param("account_id")
		r, err := c.repo.NewQueries().GetStudentPrecheckDataByAccountId(ctx.RequestContext(), uuid.MustParse(accountId))
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(r)
	}
}

type QueryListDepartments struct {
	Faculty *string `json:"faculty" form:"faculty"`
}

func (c *ResourceController) ListDepartments() app.HandlerFunc {
	return func(ctx app.Context) {
		query := QueryListDepartments{}
		err := ctx.ShouldBindQuery(&query)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		var depts []*string
		if query.Faculty != nil && *query.Faculty != "" {
			depts, err = c.repo.NewQueries().ListDepartmentsByFaculty(ctx.RequestContext(), query.Faculty)

		} else {
			depts, err = c.repo.NewQueries().ListDepartments(ctx.RequestContext())
		}

		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(depts)
	}
}

type SearchAssociateMajorsQuery struct {
	NameLike *string `json:"namelike" form:"namelike"`
}

func (c *ResourceController) SearchAssociateMajors() app.HandlerFunc {
	return func(ctx app.Context) {
		var query SearchAssociateMajorsQuery
		err := ctx.ShouldBindQuery(&query)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		var majors []models.Major
		var namePattern string
		if query.NameLike == nil {
			namePattern = "%"
		} else {
			namePattern = fmt.Sprintf("%%%s%%", *query.NameLike)
		}
		majors, err = c.repo.NewQueries().SearchAssociateMajors(ctx.RequestContext(), &namePattern)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		var retMajors []struct {
			Value string `json:"value"`
			Label string `json:"label"`
		}
		for _, m := range majors {
			retMajors = append(retMajors, struct {
				Value string `json:"value"`
				Label string `json:"label"`
			}{
				Value: m.Code,
				Label: *m.Name,
			})
		}
		ctx.SuccessJSON(retMajors)
	}
}

type SearchBachelorMajorsQuery struct {
	NameLike *string `json:"namelike" form:"namelike"`
}

func (c *ResourceController) SearchBachelorMajors() app.HandlerFunc {
	return func(ctx app.Context) {
		var query SearchBachelorMajorsQuery
		err := ctx.ShouldBindQuery(&query)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		var majors []models.Major
		var namePattern string
		if query.NameLike == nil {
			namePattern = "nomatch"
		} else {
			if *query.NameLike == "" {
				namePattern = "nomatch"
			} else {
				namePattern = fmt.Sprintf("%%%s%%", *query.NameLike)
			}
		}
		majors, err = c.repo.NewQueries().SearchBachelorMajors(ctx.RequestContext(), &namePattern)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		var retMajors []struct {
			Value string `json:"value"`
			Label string `json:"label"`
		}
		for _, m := range majors {
			retMajors = append(retMajors, struct {
				Value string `json:"value"`
				Label string `json:"label"`
			}{
				Value: m.Code,
				Label: *m.Name,
			})
		}
		ctx.SuccessJSON(retMajors)
	}
}

type QueryListMajors struct {
	Department *string `json:"department" form:"department"`
}

func (c *ResourceController) ListMajors() app.HandlerFunc {
	return func(ctx app.Context) {
		var query QueryListMajors
		err := ctx.ShouldBindQuery(&query)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		var majors []models.Major
		if query.Department == nil || *query.Department == "" {
			majors, err = c.repo.NewQueries().ListMajors(ctx.RequestContext())
		} else {
			majors, err = c.repo.NewQueries().ListMajorsByDepartment(ctx.RequestContext(), query.Department)
		}
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(majors)
	}
}

func (c *ResourceController) ListFaculties() app.HandlerFunc {
	return func(ctx app.Context) {
		faculties, err := c.repo.NewQueries().ListFaculties(ctx.RequestContext())
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(faculties)
	}
}

//type QueryListDepartmentByFaculty struct {
//	Faculty string `json:"faculty" form:"faculty"`
//}
//
//func (c *ResourceController) ListDepartmentsByFaculty() app.HandlerFunc {
//	return func(ctx app.Context) {
//		query := QueryListDepartmentByFaculty{}
//		err := ctx.ShouldBindQuery(&query)
//		if err != nil {
//			ctx.AbortWithBadRequest(err)
//			return
//		}
//		depts, err := c.repo.NewQueries().ListDepartmentsByFaculty(ctx.RequestContext(), &query.Faculty)
//		if err != nil {
//			ctx.AbortWithError(http.StatusInternalServerError, fmt.Errorf("ListDepartmentsByFaculty query: %x", err))
//			return
//		}
//		ctx.SuccessJSON(depts)
//	}
//}

func (c *ResourceController) GetPostgradSuggestion() app.HandlerFunc {
	return func(ctx app.Context) {
		majorCode := ctx.Param("code")
		suggestion, err := c.repo.NewQueries().GetPostgradSuggestionByMajorCode(ctx.RequestContext(), majorCode)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(suggestion)
	}
}

type QueryListGoventerprise struct {
	Page      int    `json:"page" form:"page"`
	PageSize  int    `json:"page_size" form:"page_size"`
	MajorCode string `json:"major_code" form:"major_code"`
	Name      string `json:"name" form:"name"`
}

func (c *ResourceController) ListGoventerprise() app.HandlerFunc {
	return func(ctx app.Context) {
		query := QueryListGoventerprise{}
		err := ctx.ShouldBindQuery(&query)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		count, err := c.repo.NewQueries().CountGoventerpriseByMajor(ctx.RequestContext(), models.CountGoventerpriseByMajorParams{
			Majorcode: query.MajorCode,
			Name:      "%" + query.Name + "%",
		})
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		goventerprises, err := c.repo.NewQueries().ListGoventerpriseByMajor(ctx.RequestContext(), models.ListGoventerpriseByMajorParams{
			Limit:     int32(query.PageSize),
			Offset:    int32((query.Page - 1) * query.PageSize),
			Majorcode: query.MajorCode,
			Name:      "%" + query.Name + "%",
		})
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(map[string]interface{}{
			"totalCount": count,
			"data":       goventerprises,
		})
	}
}

func (c *ResourceController) ListMyQianliaoCoupon() app.HandlerFunc {
	return func(ctx app.Context) {
		userAcctid := ctx.Account().ID
		cList, err := c.repo.NewQueries().GetQianliaoCoupon(ctx.RequestContext(), userAcctid)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.Logger().Info(fmt.Sprintf("got %d qianliao coupon", len(cList)))
		if len(cList) > 0 {
			ctx.Logger().Info(fmt.Sprintf("the first coupon: %v", *cList[0].Couponcode))
		}
		ctx.SuccessJSON(cList)
	}
}

func (c *ResourceController) GetTermsOverallSignedUrl() app.HandlerFunc {
	return func(ctx app.Context) {
		ctx.SuccessJSON(c.resourceService.GetTermsOverallSignedUrl())
	}
}

func (c *ResourceController) GetOrgMetadata() app.HandlerFunc {
	return func(ctx app.Context) {
		uri := ctx.Param("uri")
		data, err := c.resourceService.GetOrgMetadata(ctx.RequestContext(), uri)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(data)
	}
}
