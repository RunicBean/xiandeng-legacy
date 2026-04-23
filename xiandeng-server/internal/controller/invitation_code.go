package controller

import (
	"errors"
	"net/http"
	"xiandeng.net.cn/server/pkg/utils/model_util"

	"github.com/jackc/pgx/v5"
	"xiandeng.net.cn/server/internal/app"
	"xiandeng.net.cn/server/internal/code"
	"xiandeng.net.cn/server/internal/services"
	req_models "xiandeng.net.cn/server/pkg/web/models"
)

type InvitationCodeController struct {
	*Controller
	invCodeService services.InvitationCodeService
	userService    services.UserService
}

func NewInvitationCodeController(controller *Controller, invCodeService services.InvitationCodeService, userService services.UserService) *InvitationCodeController {
	return &InvitationCodeController{
		Controller:     controller,
		invCodeService: invCodeService,
		userService:    userService,
	}
}

type BodyGenerateInvitationCode struct {
	TypeArg req_models.AccountType `json:"type"`
}

// GenerateInvitationCode 生成邀请码
// @Summary 生成邀请码
// @Description 生成邀请码
// @Tags 注册
// @Accept application/json
// @Produce application/json
// @Param BodyGenerateInvitationCode body BodyGenerateInvitationCode true "BodyGenerateInvitationCode"
// @Security ApiKeyAuth
// @Success 201 {object} controller.ResponseJsonResult{data=string}
// @Failure 500 {object} controller.ResponseJsonResult{data=string}
// @Router /invitation_code [post]
//func (c *InvitationCodeController) GenerateInvitationCode() app.HandlerFunc {
//	return func(ctx app.Context) {
//		var body BodyGenerateInvitationCode
//		err := ctx.ShouldBind(&body)
//		if err != nil {
//			ctx.AbortWithBadRequest(err)
//			return
//		}
//
//		user := ctx.User()
//		userId := user.ID.String()
//		u, err := c.userService.GetUser(ctx.RequestContext(), user.ID)
//		if err != nil {
//
//			ctx.AbortWithStatusJSON(http.StatusBadRequest, code.InvitationGenerationError, fmt.Sprintf("userID用户不存在：%s\n", userId), fmt.Errorf("userID用户不存在"), log.SimpleMapParam{"user_id": userId})
//			return
//		}
//
//		iCode := c.invCodeService.GenerateCode(ctx.RequestContext(), utils.AccountTypeGqlToDB(body.TypeArg), utils.NullUUIDToString(u.Accountid), userId)
//		ctx.SuccessCreateJSON(iCode)
//	}
//}

// ListInvitationCode 列出邀请码
// @Tags 注册
// @Produce application/json
// @Security ApiKeyAuth
// @Success 201 {object} controller.ResponseJsonResult{data=[]req_models.InvitationCode}
// @Router /invitation_code/list [get]
func (c *InvitationCodeController) ListInvitationCode() app.HandlerFunc {
	return func(ctx app.Context) {
		user := ctx.User()
		codes, err := c.invCodeService.ListCodes(ctx.RequestContext(), user.ID)
		if err != nil {
			ctx.AbortWithStatusJSON(
				http.StatusInternalServerError,
				code.ServerInternalErr,
				err.Error(),
				err,
			)
			return
		}
		retCodes := model_util.InvitationCodesDBToGql(codes)
		ctx.SuccessJSON(retCodes)
	}
}

// InvitationCodeDetail 邀请码详情
// @Tags 注册
// @Produce application/json
// @Param  code    path  string  true  "Code"
// @Success 201 {object} controller.ResponseJsonResult{data=[]req_models.InvitationCode}
// @Router /invitation_code/{code} [get]
func (c *InvitationCodeController) InvitationCodeDetail() app.HandlerFunc {
	return func(ctx app.Context) {
		invCode := ctx.Param("code")
		detail, err := c.invCodeService.GetInvitationDataFromDB(ctx.RequestContext(), invCode)
		if err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				ctx.AbortWithStatusJSONWarn(
					http.StatusNotFound,
					code.RecordNotFound,
					"invitation code not found",
					err,
				)
				return
			}
			ctx.AbortWithStatusJSON(
				http.StatusInternalServerError,
				code.ServerInternalErr,
				err.Error(),
				err,
			)
			return
		}
		ret := model_util.InvitationCodeDBToGql(detail)
		ctx.SuccessJSON(ret)
	}
}

func (c *InvitationCodeController) CompleteInvitationCodes() app.HandlerFunc {
	return func(ctx app.Context) {
		user := ctx.User()
		err := c.invCodeService.CompleteInvitationCodes(ctx.RequestContext(), user.ID)
		if err != nil {
			ctx.AbortWithStatusJSON(
				http.StatusInternalServerError,
				code.ServerInternalErr,
				err.Error(),
				err,
			)
			return
		}
		ctx.SuccessCreateJSON("ok")
	}
}
