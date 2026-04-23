package controller

import (
	"errors"
	"fmt"
	"net/http"
	"strings"
	"xiandeng.net.cn/server/constants"
	"xiandeng.net.cn/server/pkg/security"

	"github.com/google/uuid"
	"xiandeng.net.cn/server/db"
	"xiandeng.net.cn/server/db/models"
	"xiandeng.net.cn/server/internal/app"
	"xiandeng.net.cn/server/internal/code"
	"xiandeng.net.cn/server/internal/controller/response_model"
	"xiandeng.net.cn/server/internal/services"
	"xiandeng.net.cn/server/pkg/log"
)

type UserController struct {
	*Controller
	repo        db.Repository
	resource    services.ResourceService
	authService services.AuthService
}

func NewUserController(controller *Controller, repo db.Repository, authService services.AuthService, resourceService services.ResourceService) *UserController {
	return &UserController{
		Controller:  controller,
		resource:    resourceService,
		repo:        repo,
		authService: authService,
	}
}

type ParamGetUserWithPhone struct {
	Phone string `json:"phone" form:"phone" example:"Phone"`
}

// GetUserWithPhone 通过手机号获取用户
// @Summary 通过手机号获取用户
// @Description 通过手机号获取用户
// @Tags 用户
// @Produce application/json
// @Param object query ParamGetUserWithPhone false "用户手机号"
// @Security ApiKeyAuth
// @Success 200 {object} controller.ResponseJsonResult{data=response_model.User}
// @Failure 500 {object} controller.ResponseJsonResult{data=string}
// @Router /user/with_phone [get]
func (c *UserController) GetUserWithPhone() app.HandlerFunc {
	return func(ctx app.Context) {
		var param ParamGetUserWithPhone
		err := ctx.ShouldBind(&param)
		if err != nil {
			ctx.FailedJSON(http.StatusBadRequest, code.InvalidParams, fmt.Errorf("GetUserWithPhone requires phone: %v", err))
			return
		}
		queries := c.repo.NewQueries()
		u, err := queries.GetUserByPhone(ctx.RequestContext(), param.Phone)
		if err != nil {
			ctx.FailedJSON(http.StatusInternalServerError, code.UserGetError, fmt.Errorf("GetUserWithPhone: %v", err))
			return
		}
		ctx.SuccessJSON(response_model.User{
			ID:        u.ID.String(),
			NickName:  u.Nickname,
			AvatarURL: u.Avatarurl,
		})
	}

}

func (c *UserController) UserPhoneAvailable() app.HandlerFunc {
	return func(ctx app.Context) {
		var param ParamGetUserWithPhone
		err := ctx.ShouldBind(&param)
		if err != nil {
			ctx.AbortWithBadRequest(code.InvalidParams, log.SimpleMapParam{"phone": param.Phone})
			return
		}
		available, err := c.authService.CheckPhoneAvailable(ctx.RequestContext(), param.Phone)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.UserGetError, err.Error(), err)
			return
		}
		ctx.SuccessJSON(map[string]bool{"available": available})
	}
}

func (c *UserController) Users() app.HandlerFunc {
	return func(ctx app.Context) {
		users, err := c.repo.NewQueries().ListUsers(ctx.RequestContext(), 10)
		if err != nil {
			ctx.AbortWithStatusJSON(
				http.StatusInternalServerError,
				code.UserGetError,
				err.Error(),
				err,
			)
		}
		var gqlResult []*response_model.User
		for _, u := range users {
			id, _ := u.ID.Value()
			gqlResult = append(gqlResult, &response_model.User{
				ID:        id.(string),
				NickName:  u.Nickname,
				AvatarURL: u.Avatarurl,
			})
		}
		ctx.SuccessJSON(gqlResult)
	}
}

func (c *UserController) GetRoleOfUser() app.HandlerFunc {
	return func(ctx app.Context) {
		u := ctx.User()
		row, err := c.repo.NewQueries().GetRoleOfUser(ctx.RequestContext(), models.GetRoleOfUserParams{
			Accountid: ctx.Account().ID,
			Userid:    u.ID,
		})
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(map[string]any{
			"usertype":     row.Usertype,
			"accounttype":  row.Accounttype.Entitytype,
			"existstudent": row.Existstudent,
			"accountid":    ctx.Account().ID.String(),
		})
	}
}

func (c *UserController) GetUpstreamAgentAttr() app.HandlerFunc {
	return func(ctx app.Context) {
		fmt.Println(ctx.Account().ID.String())
		agentAttrs, err := c.repo.NewQueries().GetUpstreamAgentAttr(ctx.RequestContext(), ctx.Account().ID)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(agentAttrs)
	}
}

func (c *UserController) GetAgentAttr() app.HandlerFunc {
	return func(ctx app.Context) {
		agentAttrs, err := c.repo.NewQueries().GetAgentAttr(ctx.RequestContext(), ctx.Account().ID)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(agentAttrs)
	}
}

func (c *UserController) UpdateMyAgentSettings() app.HandlerFunc {
	return func(ctx app.Context) {
		args := models.UpdateAgentSettingsParams{}
		err := ctx.ShouldBind(&args)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusBadRequest, code.InvalidParams, err.Error(), err)
			return
		}
		args.Accountid = ctx.Account().ID
		err = c.repo.NewQueries().UpdateAgentSettings(ctx.RequestContext(), args)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}

	}
}

func (c *UserController) UpdateAgentAttributes() app.HandlerFunc {
	return func(ctx app.Context) {
		args := models.UpdateAgentAttributeParams{}
		err := ctx.ShouldBind(&args)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusBadRequest, code.InvalidParams, err.Error(), err)
			return
		}
		if args.Accountid == uuid.Nil {
			ctx.AbortWithStatusJSON(http.StatusBadRequest, code.InvalidParams, "accountid is required", errors.New("accountid is required"))
			return
		}
		err = c.repo.NewQueries().UpdateAgentAttribute(ctx.RequestContext(), args)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
	}
}

func (c *UserController) GetUserViewPrivilege() app.HandlerFunc {
	return func(ctx app.Context) {
		acctKind, ok := ctx.GetQuery("acct_kind")
		if !ok {
			ctx.AbortWithBadRequest(fmt.Errorf("acct_kind query missing"), log.SimpleParam("acct_kind"))
			return
		}
		acctKindStrs := strings.Split(strings.ToUpper(acctKind), ",")
		//var acctKinds = make([]models.Roletype, len(acctKindStrs))
		// modify acctKinds from []string to []models.Roletype
		//for i, v := range acctKindStrs {
		//	acctKinds[i] = models.Roletype(v)
		//}
		userId := ctx.User().ID
		userViewPrivilege, err := c.repo.NewQueries().GetUserViewPrivilege(ctx.RequestContext(), models.GetUserViewPrivilegeParams{
			Userid:       userId,
			Accountkinds: acctKindStrs,
		})
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(userViewPrivilege)
	}
}

func (c *UserController) GetRolesByAcctKind() app.HandlerFunc {
	return func(ctx app.Context) {
		acctKind, ok := ctx.GetQuery("acct_kind")
		if !ok {
			ctx.AbortWithBadRequest(fmt.Errorf("acct_kind query missing"), log.SimpleParam("acct_kind"))
			return
		}
		//acctKindStrs := strings.Split(strings.ToUpper(acctKind), ",")
		roles, err := c.repo.NewQueries().GetRolesByAcctKind(ctx.RequestContext(), models.Roletype(acctKind))
		//var acctKinds = make([]models.Roletype, len(acctKindStrs))
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(roles)
	}
}

type UpdatePasswordParams struct {
	NewPassword string  `json:"new_password" form:"new_password"`
	OrgName     *string `json:"org_name" form:"org_name"`
}

func (c *UserController) UpdatePassword() app.HandlerFunc {
	return func(ctx app.Context) {
		args := UpdatePasswordParams{}
		err := ctx.ShouldBind(&args)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusBadRequest, code.InvalidParams, err.Error(), err)
			return
		}
		if args.NewPassword == "" {
			ctx.AbortWithStatusJSON(http.StatusBadRequest, code.InvalidParams, "new_password is required", errors.New("new_password is required"))
			return
		}

		var redirectUrl string
		if args.OrgName == nil {
			redirectUrl = constants.WECHAT_OFFICIAL_ACCOUNT_URL
		} else {
			orgMetadata, _ := c.resource.GetOrgMetadata(ctx.RequestContext(), *args.OrgName)
			if orgMetadata.Redirecturl == nil {
				ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.OrgMetaInvalid, "redirecturl missing", nil, log.SimpleMapParam{"org_name": *args.OrgName})
				return
			}
			redirectUrl = *orgMetadata.Redirecturl
		}

		hashed, _ := security.HashPassword(args.NewPassword)
		uid := ctx.User().ID
		err = c.repo.NewQueries().UpdatePassword(ctx.RequestContext(), models.UpdatePasswordParams{
			ID:       uid,
			Password: hashed,
		})
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(map[string]string{
			"redirect_url": redirectUrl,
		})
	}
}

type UpdateAliasnameParams struct {
	Aliasname string `json:"aliasname" form:"aliasname"`
}

func (c *UserController) UpdateAliasname() app.HandlerFunc {
	return func(ctx app.Context) {
		body := UpdateAliasnameParams{}
		err := ctx.ShouldBind(&body)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusBadRequest, code.InvalidParams, err.Error(), err)
			return
		}
		user := ctx.User()
		err = c.repo.NewQueries().UpdateAliasname(ctx.RequestContext(), models.UpdateAliasnameParams{
			ID:        user.ID,
			Aliasname: &body.Aliasname,
		})
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON("ok")
	}
}
