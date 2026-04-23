package controller

import (
	"fmt"
	"go.uber.org/zap"
	"net/http"
	"xiandeng.net.cn/server/pkg/log"

	"github.com/go-playground/validator/v10"
	"github.com/google/uuid"
	"xiandeng.net.cn/server/db"
	"xiandeng.net.cn/server/db/models"
	"xiandeng.net.cn/server/internal/app"
	"xiandeng.net.cn/server/internal/code"
	"xiandeng.net.cn/server/internal/controller/request_model"
	"xiandeng.net.cn/server/internal/services"
	"xiandeng.net.cn/server/tasks/server"
)

type StudentController struct {
	*Controller
	studentService services.StudentService
	taskClient     server.TaskClient
	repo           db.Repository
	validate       *validator.Validate
}

func NewStudentController(
	controller *Controller,
	service services.StudentService,
	taskClient server.TaskClient,
	repo db.Repository,
	validate *validator.Validate,
) *StudentController {
	return &StudentController{
		Controller:     controller,
		studentService: service,
		taskClient:     taskClient,
		repo:           repo,
		validate:       validate,
	}
}

func (c *StudentController) GetStudentAccountid() app.HandlerFunc {
	return func(ctx app.Context) {
		acctId := ctx.Param("account_id")
		id, err := c.studentService.GetStudentAccountid(ctx.RequestContext(), uuid.MustParse(acctId))
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.RecordNotFound, err.Error(), err)
			return
		}
		ctx.SuccessJSON(id)
	}
}

type GetStudySuggestionBody struct {
	AccountId string `json:"account_id"`
	UserId    string `json:"user_id"`
}

// @Summary 获取就读建议
// @Description 调研报告已完成后，才能执行此方法获取就读建议，获取过程同步
// @Tags PlanningReport
// @Router /student/study_suggestion 	[get]
func (c *StudentController) UpdateStudySuggestionWithIds() app.HandlerFunc {
	return func(ctx app.Context) {
		var body GetStudySuggestionBody
		err := ctx.ShouldBind(&body)
		if err != nil {
			ctx.FailedJSON(http.StatusBadRequest, code.InvalidParams, fmt.Errorf("GetStudySuggestion requires account_id and user_id: %v", err))
			return
		}
		data, err := c.studentService.UpdateStudySuggestionOnNotExists(ctx.RequestContext(), uuid.MustParse(body.AccountId), uuid.MustParse(body.UserId), true)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(data)
	}
}

// @Summary 更新就读建议
// @Description 调研报告已完成后，才能执行此方法获取就读建议，获取过程异步
// @Tags PlanningReport
// @Router /student/study_suggestion/update 	[patch]
func (c *StudentController) UpdateStudySuggestion() app.HandlerFunc {
	return func(ctx app.Context) {
		data, err := c.studentService.UpdateStudySuggestionOnNotExists(ctx.RequestContext(), ctx.Account().ID, ctx.User().ID, false)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(data)
	}
}

// @Summary 更新学生信息，就读建议
// @Description 更新学生信息，就读建议
// @Tags Onboarding
// @Accept application/json
// @Produce application/json
// @Param BodyUpdateStudentProfile body request_model.BodyUpdateStudentProfile true "BodyUpdateStudentProfile"
// @Security ApiKeyAuth
// @Router /onboarding/student/update [post]
func (c *StudentController) UpdateStudentProfile() app.HandlerFunc {
	return func(ctx app.Context) {
		var body request_model.BodyUpdateStudentProfile
		err := ctx.ShouldBind(&body)
		if err != nil {
			ctx.AbortWithBadRequest(err)
		}
		u := ctx.User()
		err = c.studentService.UpdateStudentProfile(ctx.RequestContext(), u, body)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON("updated")
	}
}

type ListMyInvitedStudentsQuery struct {
	//CurrentReferalUser *bool `json:"current_referal_user" form:"current_referal_user" validate:"required_without=CurrentAccount"`
	CurrentAccount *bool   `json:"current_account" form:"current_account"`
	SearchString   *string `json:"search_string" form:"search_string"`
}

func (c *StudentController) ListStudents() app.HandlerFunc {
	return func(ctx app.Context) {
		var query ListMyInvitedStudentsQuery
		err := ctx.ShouldBindQuery(&query)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		err = c.validate.Struct(query)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		//u := ctx.User()
		//var referaluserid *uuid.UUID
		//if query.CurrentReferalUser != nil && *query.CurrentReferalUser {
		//	referaluserid = &u.ID
		//} else {
		//	referaluserid = nil
		//}

		var agentAccountId *uuid.UUID
		if query.CurrentAccount != nil && *query.CurrentAccount {
			agentAccountId = &ctx.Account().ID
		}
		students, err := c.repo.NewQueries().ListStudents(ctx.RequestContext(), models.ListStudentsParams{
			//Referaluserid:  referaluserid,
			Agentaccountid: agentAccountId,
			SearchString:   query.SearchString,
		})
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(students)
	}
}

// func DownloadPlanningReport() app.HandlerFunc {
// 	return func(ctx app.Context) {
// 		ctx.GinContext().Stream()
// 	}
// }

type SearchStudentBody struct {
	Surveycompleted *bool   `json:"surveycompleted" form:"surveycompleted"`
	Accountname     *string `json:"accountname" form:"accountname"`
	Email           *string `json:"email" form:"email"`
	Phone           *string `json:"phone" form:"phone"`
	Createdatfrom   *string `json:"createdatfrom" form:"createdatfrom"`
	Createdatto     *string `json:"createdatto" form:"createdatto"`
	Upstreamaccount *string `json:"upstreamaccount" form:"upstreamaccount"`
}

func TransformSearchStudentBody(body SearchStudentBody) models.SearchStudentsParams {
	params := models.SearchStudentsParams{}
	if body.Upstreamaccount != nil && *body.Upstreamaccount != "" {

		params.Upstreamaccount = uuid.NullUUID{UUID: uuid.MustParse(*body.Upstreamaccount), Valid: true}

	}
	if body.Accountname != nil && *body.Accountname != "" {
		params.Accountname = body.Accountname
	}
	if body.Email != nil && *body.Email != "" {
		params.Email = body.Email
	}
	if body.Phone != nil && *body.Phone != "" {
		params.Phone = body.Phone
	}
	if body.Createdatfrom != nil && *body.Createdatfrom != "" {
		params.Createdatfrom = body.Createdatfrom
	}
	if body.Createdatto != nil && *body.Createdatto != "" {
		params.Createdatto = body.Createdatto
	}

	return params
}

func (c *StudentController) SearchStudents() app.HandlerFunc {
	return func(ctx app.Context) {
		var body SearchStudentBody
		err := ctx.ShouldBindQuery(&body)
		if err != nil {
			ctx.AbortWithBadRequest(fmt.Errorf("SearchStudents: %v", err.Error()))
			return
		}
		params := TransformSearchStudentBody(body)
		students, err := c.repo.NewQueries().SearchStudents(ctx.RequestContext(), params)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(students)
	}
}

type ListStudentDetailsQuery struct {
	HeadQuarter bool `json:"head_quarter" form:"head_quarter"`
}

func (c *StudentController) ListStudentDetails() app.HandlerFunc {
	return func(ctx app.Context) {
		var params ListStudentDetailsQuery
		if err := ctx.ShouldBindQuery(&params); err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		q := c.repo.NewQueries()
		var data []models.VStudentdetail
		var err error
		if params.HeadQuarter {
			data, err = q.ListStudentDetails(ctx.RequestContext(), models.ListStudentDetailsParams{
				Agentidfilter: false,
				Agentid:       uuid.NullUUID{},
			})
		} else {
			data, err = q.ListStudentDetails(ctx.RequestContext(), models.ListStudentDetailsParams{
				Agentidfilter: true,
				Agentid:       uuid.NullUUID{UUID: ctx.Account().ID, Valid: true},
			})
		}
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(data)

	}
}

func (c *StudentController) ListStudentDetailsByReferral() app.HandlerFunc {
	return func(ctx app.Context) {
		user := ctx.User()
		q := c.repo.NewQueries()
		var data []models.ListStudentDetailsByReferalRow
		var err error
		data, err = q.ListStudentDetailsByReferal(ctx.RequestContext(), models.ListStudentDetailsByReferalParams{
			Agentid:   uuid.NullUUID{UUID: ctx.Account().ID, Valid: true},
			Referalid: user.ID,
		})
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(data)

	}
}

func (c *StudentController) ListStudentForPlanning() app.HandlerFunc {
	return func(ctx app.Context) {
		var params ListStudentDetailsQuery
		if err := ctx.ShouldBindQuery(&params); err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		q := c.repo.NewQueries()
		var data []models.ListStudentForPlanningRow
		var err error
		if params.HeadQuarter {
			data, err = q.ListStudentForPlanning(ctx.RequestContext(), models.ListStudentForPlanningParams{
				Agentidfilter: false,
				Agentid:       uuid.NullUUID{},
			})
		} else {
			data, err = q.ListStudentForPlanning(ctx.RequestContext(), models.ListStudentForPlanningParams{
				Agentidfilter: true,
				Agentid:       uuid.NullUUID{UUID: ctx.Account().ID, Valid: true},
			})
		}
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(data)

	}
}

func (c *StudentController) ListStudentForPlanningByReferral() app.HandlerFunc {
	return func(ctx app.Context) {
		q := c.repo.NewQueries()
		var data []models.ListStudentForPlanningByReferralRow
		var err error
		data, err = q.ListStudentForPlanningByReferral(ctx.RequestContext(), models.ListStudentForPlanningByReferralParams{
			Agentidfilter:  true,
			Agentid:        uuid.NullUUID{UUID: ctx.Account().ID, Valid: true},
			Referraluserid: ctx.User().ID,
		})
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(data)

	}
}

func (c *StudentController) SearchUniversities() app.HandlerFunc {
	return func(ctx app.Context) {
		nameLike, ok := ctx.GetQuery("namelike")
		if !ok || nameLike == "" {
			ctx.AbortWithBadRequest(fmt.Errorf("namelike query missing"), log.SimpleParam("namelike"))
			return
		}
		universities, err := c.studentService.SearchUniversities(ctx.RequestContext(), nameLike)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		var ret []map[string]string
		for _, v := range universities {
			ret = append(ret, map[string]string{"value": v, "label": v})
		}
		ctx.SuccessJSON(ret)
	}
}

func (c *StudentController) IsUniversityGraduateEligible() app.HandlerFunc {
	return func(ctx app.Context) {
		schoolName, ok := ctx.GetQuery("schoolname")
		if !ok || schoolName == "" {
			ctx.AbortWithBadRequest(fmt.Errorf("schoolname query missing"), log.SimpleParam("schoolname"))
			return
		}
		isEligible, err := c.studentService.IsUniversityGraduateEligible(ctx.RequestContext(), schoolName)
		if err != nil {
			c.logger.Warn("given school not exists", zap.String("schoolname", schoolName))
			ctx.SuccessJSON(false)
			return
		}
		ctx.SuccessJSON(isEligible)
	}
}
