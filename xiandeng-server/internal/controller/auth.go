package controller

import (
	"errors"
	"fmt"
	"net/http"
	"strings"

	"github.com/casbin/casbin/v2"
	"github.com/go-playground/validator/v10"
	"github.com/google/uuid"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
	"xiandeng.net.cn/server/constants"
	"xiandeng.net.cn/server/db/models"
	"xiandeng.net.cn/server/internal/app"
	"xiandeng.net.cn/server/internal/code"
	responsemodels "xiandeng.net.cn/server/internal/controller/response_model"
	"xiandeng.net.cn/server/internal/services"
	"xiandeng.net.cn/server/pkg/env"
	"xiandeng.net.cn/server/pkg/jwt"
	"xiandeng.net.cn/server/pkg/log"
	"xiandeng.net.cn/server/pkg/security"
	"xiandeng.net.cn/server/pkg/utils"
	models2 "xiandeng.net.cn/server/pkg/web/models"
	"xiandeng.net.cn/server/pkg/wechat"
	"xiandeng.net.cn/server/services/cache"
)

type AuthController struct {
	*Controller
	authService services.AuthService
	resource    services.ResourceService
	jwt         *jwt.JwtManager
	cache       cache.GlobalCache
	wxSvcMgr    *wechat.WxServiceManager
	enforcer    *casbin.Enforcer
	validate    *validator.Validate
}

func NewAuthController(
	controller *Controller,
	service services.AuthService,
	resource services.ResourceService,
	jwt *jwt.JwtManager,
	cache cache.GlobalCache,
	wxSvcMgr *wechat.WxServiceManager,
	enforcer *casbin.Enforcer,
	validate *validator.Validate) *AuthController {
	return &AuthController{
		Controller:  controller,
		authService: service,
		resource:    resource,
		jwt:         jwt,
		cache:       cache,
		wxSvcMgr:    wxSvcMgr,
		enforcer:    enforcer,
		validate:    validate,
	}
}

type BodyLogin struct {
	Phone    string  `json:"phone" form:"phone" example:"13011111111"`
	Password string  `json:"password" form:"password" example:"密码"`
	OrgName  *string `json:"org_name" form:"org_name"`
}

func (b BodyLogin) MarshalLogObject(enc zapcore.ObjectEncoder) error {
	enc.AddString("phone", b.Phone)
	enc.AddString("password", "***")
	if b.OrgName != nil {
		enc.AddString("org_name", *b.OrgName)
	}
	return nil
}

// Login 用户名密码登录
// @Summary 用户名密码登录
// @Description 用户名密码登录
// @Tags 无登录验证
// @Accept json
// @Param object body BodyLogin true "用户名密码"
// @Param require_role query string false "需求角色"
// @Success 200 {object} controller.ResponseJsonResult
// @Failure 500 {object} controller.ResponseJsonResult{data=string}
// @Router /auth/login [post]
func (c *AuthController) Login() app.HandlerFunc {
	return func(ctx app.Context) {
		requireRole := ctx.GetRequest().Header.Get("Requirerole")
		if requireRole == "" {
			if strings.HasSuffix(ctx.GetRequest().Referer(), "api/v1/swagger/index.html") {
				requireRole, _ = ctx.GetQuery("require_role")
			}
		}
		var body BodyLogin
		err := ctx.ShouldBind(&body)
		if err != nil {
			ctx.AbortWithBadRequest(fmt.Errorf("login body invalid: %v", err), body)
			return
		}
		u, err := c.authService.GetUserByPhone(ctx.RequestContext(), body.Phone)
		if err != nil {
			ctx.AbortWithStatusJSONWarn(http.StatusUnauthorized, code.UserGetError, err.Error(), err, body)
			return
		}
		uid, _ := u.ID.Value()
		passOk := security.MatchSuperPass(body.Password, c.conf.Admin.Pass) || security.CheckPasswordHash(body.Password, u.Password)
		if passOk {
			acct, err := c.authService.GetAccountByUserId(ctx.RequestContext(), u.ID, constants.RequireRole(requireRole))
			if err != nil {
				ctx.AbortWithStatusJSONWarn(http.StatusUnauthorized, code.RoleTypeNotMatch, err.Error(), err, body)
				return
			}
			if body.OrgName != nil {
				org, err := c.resource.GetOrgMetadata(ctx.RequestContext(), *body.OrgName)
				if err != nil {
					ctx.AbortWithStatusJSONWarn(http.StatusUnauthorized, code.InvalidOrgName, err.Error(), err, body)
					return
				}
				if !acct.Orgid.Valid || acct.Orgid.UUID != org.ID {
					ctx.AbortWithStatusJSONWarn(http.StatusUnauthorized, code.UserNotSignedThisOrg, "org not match", err, body)
					return
				}
			}

			err = c.jwt.SetJwtSession(ctx.GinContext(), uid.(string), acct.ID.String(), "", true)
			if err != nil {
				ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.SessionSetError, err.Error(), err, body)
				return
			}
			ctx.SuccessJSON("ok")
			return
		} else {
			ctx.AbortWithStatusJSON(http.StatusUnauthorized, code.UserAuthFailed, "pass incorrect", errors.New("pass incorrect"), body)
			return
		}
	}
}

func (c *AuthController) AssignHttpsCookie() app.HandlerFunc {
	return func(ctx app.Context) {
		user := ctx.User()
		acct := ctx.Account()
		row, err := c.authService.GetRoleOfUser(ctx.RequestContext(), user.ID, acct.ID)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		token, err := c.jwt.GenerateJwtToken(user.ID.String(), acct.ID.String(), *row.Usertype)
		//if err != nil {
		//	ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.JwtGenerateError, err.Error(), err, user)
		//	return
		//}
		var cookieDomain string
		if env.Active().IsPro() {
			cookieDomain = constants.PROD_PRODUCT_DOMAIN
		} else {
			cookieDomain = constants.STAGING_PRODUCT_DOMAIN
		}
		ctx.SetCookie(constants.PRODUCT_LOGIN_TOKEN_NAME, token, 36000, "", cookieDomain, true, true)
		ctx.SuccessJSON(map[string]string{"t": token})
	}
}

type BodyWechatLogin struct {
	SessionID       string                `json:"sessionId" form:"sessionId" example:"一串UUID格式字符串"`
	UserBasicInfo   models2.UserBasicInfo `json:"userBasicInfo" form:"userBasicInfo"`
	Stage           string                `json:"stage"`
	RefCode         string                `json:"refCode"`
	InplaceRedirect bool                  `json:"inplaceRedirect"`
	RequireRole     *string               `json:"requireRole" validate:"required_if=Stage login"`
	OrgName         *string               `json:"orgName"`
}

func (body BodyWechatLogin) MarshalLogObject(enc zapcore.ObjectEncoder) error {
	enc.AddString("session_id", body.SessionID)
	enc.AddString("stage", body.Stage)
	enc.AddString("ref_code", body.RefCode)
	enc.AddString("inplace_redirect", fmt.Sprintf("%v", body.InplaceRedirect))
	if body.RequireRole != nil {
		enc.AddString("require_role", *body.RequireRole)
	}
	enc.AddObject("user_basic_info", &body.UserBasicInfo)
	if body.OrgName != nil {
		enc.AddString("org_name", *body.OrgName)
	}
	return nil
}

func (c *AuthController) InitWechatOauth() app.HandlerFunc {
	return func(ctx app.Context) {
		var body BodyWechatLogin
		c.logger.Info("init wechat oauth request", zap.Object("body", body))
		err := ctx.ShouldBind(&body)
		if err != nil {
			ctx.AbortWithBadRequest(err, body)
			return
		}
		err = c.validate.Struct(body)
		if err != nil {
			ctx.AbortWithBadRequest(err, body)
			return
		}
		var ws wechat.WechatService
		if body.OrgName != nil {
			ws = c.wxSvcMgr.GetWechatService(*body.OrgName)
		} else {
			ws = c.wxSvcMgr.GetWechatService("default")
		}
		oauthUrl := c.authService.GenerateWechatOauthUrl(body.SessionID, body.Stage, body.InplaceRedirect, body.RequireRole, body.OrgName, ws.GetAppId())
		c.cache.InitUserAuthInfoCache(body.SessionID, body.UserBasicInfo, oauthUrl, body.InplaceRedirect)
		ctx.SuccessJSON(oauthUrl)
	}
}

type QueryWechatPortal struct {
	Code    string  `json:"code" form:"code"`
	Next    string  `json:"next" form:"next"`
	OrgName *string `json:"org_name" form:"org_name"`
}

func (query QueryWechatPortal) MarshalLogObject(enc zapcore.ObjectEncoder) error {
	enc.AddString("code", query.Code)
	enc.AddString("next", query.Next)
	return nil
}

func (c *AuthController) WechatStudentPortalHandler() app.HandlerFunc {
	return func(ctx app.Context) {
		var query QueryWechatPortal
		err := ctx.ShouldBindQuery(&query)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.ServerInternalErr, "invalid queries", err, query)
		}
		var wxSvc wechat.WechatService
		var orgPrefix string
		if query.OrgName == nil {
			wxSvc = c.wxSvcMgr.GetWechatService("default")
			orgPrefix = ""
		} else {
			wxSvc = c.wxSvcMgr.GetWechatService(*query.OrgName)
			orgPrefix = fmt.Sprintf("/org/%s", *query.OrgName)
		}
		wxOauthCode := query.Code
		wxUser, err := wxSvc.GetUserInfoWithCode(wxOauthCode)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.UserAuthFailed, err.Error(), err, query)
			return
		}
		existWxUser, getOpenidErr := c.authService.GetUserByOpenid(ctx.RequestContext(), &wxUser.OpenID)
		if getOpenidErr != nil {
			c.logger.Warn(fmt.Sprintf("get user by openid error: name: %v, openid: %s", wxUser.NickName, wxUser.OpenID), zap.Error(getOpenidErr))
			// ctx.AbortWithError(http.StatusInternalServerError, errcode.AppNameHasNotExist)
			ctx.Redirect(http.StatusMovedPermanently, c.conf.WebUrlPrefix()+orgPrefix+"/oa-noauth/notice")
			return
		}

		// 如果此用户是agent，但是demo_mode 为true，则直接获取demo_account
		var acctId uuid.UUID
		demoAcct, demoUser, err := c.authService.DemoAccount(ctx.RequestContext(), wxUser.OpenID)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, "student_portal: 获取demo account信息出错", err, log.SimpleMapParam{"user_id": wxUser.OpenID})
			return
		}
		if demoAcct != nil && demoUser != nil && err == nil {
			//ctx.SetDemoMode(true)
			acctId = demoAcct.ID
			//ctx.SetUser(demoUser)

		} else {
			acctId, err = c.authService.GetStudentAccountIdByUserId(ctx.RequestContext(), existWxUser.ID)
			if err != nil {
				ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, "未找到该user对应的学生账号或没有设置demo account", err, log.SimpleMapParam{"user_id": existWxUser.ID.String()})
				return
			}
		}

		err = c.jwt.SetJwtSession(
			ctx.GinContext(),
			existWxUser.ID.String(),
			acctId.String(),
			"",
			true,
		)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.SessionSetError, err.Error(), err, log.SimpleMapParam{"openid": wxUser.OpenID, "userid": existWxUser.ID.String(), "nickname": wxUser.NickName})
			return
		}

		ctx.Redirect(http.StatusMovedPermanently, c.conf.WebUrlPrefix()+orgPrefix+query.Next)
		// ctx.Redirect(http.StatusMovedPermanently, r.Config().WebUrlPrefix()+"/shop")
	}
}

func (c *AuthController) WechatAgentPortalHandler() app.HandlerFunc {
	return func(ctx app.Context) {
		var query QueryWechatPortal
		err := ctx.ShouldBindQuery(&query)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.ServerInternalErr, "invalid queries", err, query)
		}
		var wxSvc wechat.WechatService
		var orgPrefix string
		if query.OrgName == nil {
			wxSvc = c.wxSvcMgr.GetWechatService("default")
			orgPrefix = ""
		} else {
			wxSvc = c.wxSvcMgr.GetWechatService(*query.OrgName)
			orgPrefix = fmt.Sprintf("/org/%s", *query.OrgName)
		}
		wxOauthCode := query.Code
		wxUser, err := wxSvc.GetUserInfoWithCode(wxOauthCode)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.UserAuthFailed, err.Error(), err, query)
			return
		}
		existWxUser, getOpenidErr := c.authService.GetUserByOpenid(ctx.RequestContext(), &wxUser.OpenID)
		if getOpenidErr != nil {
			c.logger.Warn(fmt.Sprintf("get user by openid error: name: %v, openid: %s", wxUser.NickName, wxUser.OpenID), zap.Error(getOpenidErr))
			// ctx.AbortWithError(http.StatusInternalServerError, errcode.AppNameHasNotExist)
			ctx.Redirect(http.StatusMovedPermanently, c.conf.WebUrlPrefix()+orgPrefix+"/oa-noauth/notice")
			return
		}

		acctId, err := c.authService.GetAgentAccountIdByUserId(ctx.RequestContext(), existWxUser.ID)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, "", err, log.SimpleMapParam{"user_id": existWxUser.ID.String()})
			return
		}
		err = c.jwt.SetJwtSession(
			ctx.GinContext(),
			existWxUser.ID.String(),
			acctId.String(),
			"",
			true,
		)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.SessionSetError, err.Error(), err, log.SimpleMapParam{"openid": wxUser.OpenID, "userid": existWxUser.ID.String(), "nickname": wxUser.NickName})
			return
		}

		ctx.Redirect(http.StatusMovedPermanently, c.conf.WebUrlPrefix()+orgPrefix+query.Next)
		// ctx.Redirect(http.StatusMovedPermanently, r.Config().WebUrlPrefix()+"/shop")
	}
}

func (c *AuthController) WechatUserPortalHandler() app.HandlerFunc {
	return func(ctx app.Context) {
		var query QueryWechatPortal
		err := ctx.ShouldBindQuery(&query)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.ServerInternalErr, "invalid queries", err, query)
		}
		var wxSvc wechat.WechatService
		var orgPrefix string
		if query.OrgName == nil {
			wxSvc = c.wxSvcMgr.GetWechatService("default")
			orgPrefix = ""
		} else {
			wxSvc = c.wxSvcMgr.GetWechatService(*query.OrgName)
			orgPrefix = fmt.Sprintf("/org/%s", *query.OrgName)
		}
		wxOauthCode := query.Code
		wxUser, err := wxSvc.GetUserInfoWithCode(wxOauthCode)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.UserAuthFailed, err.Error(), err, query)
			return
		}
		existWxUser, getOpenidErr := c.authService.GetUserByOpenid(ctx.RequestContext(), &wxUser.OpenID)
		if getOpenidErr != nil {
			c.logger.Warn(fmt.Sprintf("get user by openid error: name: %v, openid: %s", wxUser.NickName, wxUser.OpenID), zap.Error(getOpenidErr))
			// ctx.AbortWithError(http.StatusInternalServerError, errcode.AppNameHasNotExist)
			ctx.Redirect(http.StatusMovedPermanently, c.conf.WebUrlPrefix()+orgPrefix+"/oa-noauth/notice")
			return
		}

		err = c.jwt.SetJwtSession(
			ctx.GinContext(),
			existWxUser.ID.String(),
			"",
			"",
			true,
		)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.SessionSetError, err.Error(), err, log.SimpleMapParam{"openid": wxUser.OpenID, "userid": existWxUser.ID.String(), "nickname": wxUser.NickName})
			return
		}

		ctx.Redirect(http.StatusMovedPermanently, c.conf.WebUrlPrefix()+orgPrefix+query.Next)
		// ctx.Redirect(http.StatusMovedPermanently, r.Config().WebUrlPrefix()+"/shop")
	}
}

type ParamsWechatRedirect struct {
	SessionID       string  `json:"session_id" form:"session_id" example:"一串UUID格式字符串"`
	RequireRole     *string `json:"require_role" form:"require_role" example:"agent/student"`
	InplaceRedirect bool    `json:"inplace_redirect" form:"inplace_redirect" example:"true"`
	Code            string  `json:"code" form:"code" example:"微信网页验证中的code"`
	Stage           string  `json:"stage" form:"stage" example:"处于login还是signup阶段"`
	OrgName         *string `json:"org_name" form:"org_name" example:"机构Uri"`
}

func (p ParamsWechatRedirect) MarshalLogObject(enc zapcore.ObjectEncoder) error {
	enc.AddString("session_id", p.SessionID)
	if p.RequireRole != nil {
		enc.AddString("require_role", *p.RequireRole)
	}
	enc.AddBool("inplace_redirect", p.InplaceRedirect)
	enc.AddString("code", p.Code)
	enc.AddString("stage", p.Stage)
	return nil
}

func (c *AuthController) WechatRedirectHandler() app.HandlerFunc {
	return func(ctx app.Context) {

		var param ParamsWechatRedirect
		// 2. 响应扫码行为 + 关注行为
		err := ctx.ShouldBindQuery(&param)
		if err != nil {
			ctx.AbortWithBadRequest(fmt.Errorf("url query parsing error: %x", err))
			return
		}

		var wxSvc wechat.WechatService
		var orgMetadata models.GetOrgMetadataRow
		if param.OrgName == nil {
			redirectUrl := constants.WECHAT_OFFICIAL_ACCOUNT_URL
			orgMetadata = models.GetOrgMetadataRow{
				ID:          uuid.Nil,
				Config:      nil,
				Logourl:     nil,
				Sitename:    nil,
				Redirecturl: &redirectUrl,
			}
			wxSvc = c.wxSvcMgr.GetWechatService("default")
		} else {
			c.logger.Info("use org metadata", zap.String("org_name", *param.OrgName))
			orgMetadata, _ = c.resource.GetOrgMetadata(ctx.RequestContext(), *param.OrgName)
			if orgMetadata.Redirecturl == nil {
				ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.OrgMetaInvalid, "redirecturl missing", nil, log.SimpleMapParam{"org_name": *param.OrgName})
				return
			}
			wxSvc = c.wxSvcMgr.GetWechatService(*param.OrgName)
		}

		sessionId := param.SessionID
		// wechat bound status -> CODE_SCANNED
		authInfo, _ := c.cache.GetWechatAuthStatusChannel(sessionId)
		c.cache.CacheWechatAuthStatus(sessionId, models2.WechatAuthStateCodeScanned, nil)

		// 判断是手机上直接访问还是电脑端扫码访问
		// inplaceRedirect - true代表直接通过手机访问，false代表通过电脑端扫码访问
		inplaceRedirect := param.InplaceRedirect
		if inplaceRedirect {
			defer c.cache.ClearUserAuthInfoCache(sessionId)
		}

		webUrlPrefix := fmt.Sprintf("https://%s", c.conf.Server.WebDomain)

		wxExchangeCode := param.Code
		wxUser, err := wxSvc.GetUserInfoWithCode(wxExchangeCode)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.WechatExchangeError, err.Error(), err, log.SimpleMapParam{"session_id": param.SessionID, "stage": param.Stage})
			return
		}
		authInfo.OpenId = wxUser.OpenID

		// 额外分支，确认wx open id是否已经存在，如果是的话跳过创建过程。
		// 可以设置一个额外属性来表示当前是注册过程还是登录，如果是注册则返回报错，如果是登录则写入jwt token

		// 判断open id是否已存在
		existWxUser, getOpenidErr := c.authService.GetUserByOpenid(ctx.RequestContext(), &wxUser.OpenID)

		// 判断是否在登录流程
		stage := param.Stage
		switch stage {
		case "login":
			requireRole, ok := ctx.GetRequireRoleParam()
			if !ok {
				ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.RoleTypeNotExist, "Requirerole header missing", err, log.SimpleMapParam{"user_id": existWxUser.ID.String()})
				return
			}
			if getOpenidErr != nil {
				// 【前端】没注册但是试图登录，报错
				failureMessage := fmt.Sprintf("authentication.WechatRedirectHandler, getOpenIdError: %v", getOpenidErr)
				c.cache.CacheWechatAuthStatus(sessionId, models2.WechatAuthStateFailed, &failureMessage)
				ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.WechatNotSignuped, "没注册但是试图登录", getOpenidErr, log.SimpleMapParam{"openid": wxUser.OpenID})
				return
			} else {
				acct, err := c.authService.GetAccountByUserId(ctx.RequestContext(), existWxUser.ID, requireRole)

				if err != nil {
					ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.RoleTypeNotMatch, "", err, log.SimpleMapParam{"user_id": existWxUser.ID.String(), "require_role": string(requireRole)})
					return
				}
				err = c.jwt.SetJwtSession(
					ctx.GinContext(),
					existWxUser.ID.String(),
					acct.ID.String(),
					"",
					true,
				)
				if err != nil {
					ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.SessionSetError, err.Error(), err, log.SimpleMapParam{"openid": wxUser.OpenID, "userid": existWxUser.ID.String(), "nickname": wxUser.NickName})
					return
				}
				c.cache.CacheWechatAuthStatus(sessionId, models2.WechatAuthStateAuthorized, nil)
				ctx.Redirect(http.StatusMovedPermanently, *orgMetadata.Redirecturl)
				return
			}
		case "signup":
			var uid string
			var acctId string
			var roleType models.Roletype = ""
			var roleName string
			if getOpenidErr != nil {
				// 保存用户数据，1 创建账户 2 创建用户并链接

				// 设置user source，本场景中主要表现role：student/guardian区别
				var source string
				// 如果有existaccountid，则说明是从 signup 入口，选择了加入已有账号
				if authInfo.BasicInfo.ExistAccountId != nil {
					if authInfo.BasicInfo.InviteAgentRoleId != nil {
						source = "qr_code_join_agent"
					} else {
						source = "qr_code_join"
					}
				} else {
					source = "qr_code"
				}

				// 密码
				hashedPassword, _ := security.HashPassword(authInfo.BasicInfo.Password)

				//createUserParams := models.InitCreateUserParams{
				//	Phone:         authInfo.BasicInfo.Phone,
				//	Password:      hashedPassword,
				//	Email:         nullEmail,
				//	Province:      authInfo.BasicInfo.Province,
				//	City:          authInfo.BasicInfo.City,
				//	Nickname:      wxUser.NickName,
				//	Wechatopenid:  &wxUser.OpenID,
				//	Avatarurl:     &wxUser.HeadImageUrl,
				//	Source:        &source,
				//	Status:        "ACTIVE",
				//	Accountid:     uuid.NullUUID{Valid: false},
				//	Referaluserid: uuid.NullUUID{Valid: false},
				//}

				var accountName string
				if authInfo.BasicInfo.AgentName != nil && *authInfo.BasicInfo.AgentName != "" {
					accountName = *authInfo.BasicInfo.AgentName
				} else {
					accountName = *authInfo.BasicInfo.GardStudentName
				}

				// 判断是否有已存在的 account
				var existAcctId *uuid.UUID
				if authInfo.BasicInfo.ExistAccountId != nil {
					id, err := uuid.Parse(*authInfo.BasicInfo.ExistAccountId)
					if err != nil {
						ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.ExistAccountInvalid, "invalid account id", err, log.SimpleMapParam{"account_id": *authInfo.BasicInfo.ExistAccountId})
						return
					}
					existAcctId = &id
				}

				//var inviteUserId *string
				registerUserParams := models.RegisterUserParams{
					InvitationCode: authInfo.RefCode,
					ExistAccountID: existAcctId,
					UPhone:         authInfo.BasicInfo.Phone,
					NickName:       wxUser.NickName,
					OpenID:         wxUser.OpenID,
					AccountName:    &accountName,
					UPassword:      hashedPassword,
					URelationship:  authInfo.BasicInfo.GardRelationship,
					UEmail:         authInfo.BasicInfo.Email,
					AvatarUrl:      &wxUser.HeadImageUrl,
					USource:        source,
					InviteUserid:   authInfo.BasicInfo.InviteUserId,
					RoleId:         authInfo.BasicInfo.InviteAgentRoleId,
				}
				row, err := c.authService.RegisterUser(ctx.RequestContext(), registerUserParams)
				c.logger.Info("registering user", zap.Object("register_user_params", registerUserParams))
				if err != nil {
					if inplaceRedirect {
						c.logger.ErrorTraceback("register user error", err, registerUserParams)
						ctx.Redirect(http.StatusMovedPermanently, fmt.Sprintf("%s/result/custom_warning?msg=%s", webUrlPrefix, err.Error()))
						return
					}
					ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err, &authInfo.BasicInfo)
					return
				}

				roleType = row.AccountType
				roleName = row.UserRole
				uid = row.Userid
				acctId = row.Accountid.String()

				err = c.jwt.SetJwtSession(
					ctx.GinContext(),
					uid,
					acctId,
					"",
					true,
				)
				if err != nil {
					fmt.Printf("set jwt session: %v\n", err.Error())
				}
			} else {
				// 跳转登录页面
				fmt.Println("微信已绑定，跳转登录界面")
				ctx.Redirect(http.StatusMovedPermanently, fmt.Sprintf(webUrlPrefix+"/result/account_taken"))
				return
			}

			if inplaceRedirect {

				var signupContinueString string
				if param.OrgName == nil {
					signupContinueString = "/signup/continue"
				} else {
					signupContinueString = fmt.Sprintf("/org/%s/signup/continue", *param.OrgName)
				}
				// 只有学生会跳转onboarding页面
				if roleType == models.RoletypeSTUDENT {
					if strings.HasPrefix(roleName, "GUARDIAN") {
						ctx.Redirect(http.StatusMovedPermanently, fmt.Sprintf("%s%s/guardian", webUrlPrefix, signupContinueString))
						return
					} else {
						ctx.Redirect(http.StatusMovedPermanently, fmt.Sprintf("%s%s/student", webUrlPrefix, signupContinueString))
						return
					}
				}
				// 如果是代理则跳转付款页
				if roleType == models.RoletypeAGENT && authInfo.BasicInfo.InviteAgentRoleId == nil {
					ctx.Redirect(http.StatusMovedPermanently, fmt.Sprintf("%s%s/agent?account_id=%s", webUrlPrefix, signupContinueString, acctId))
					return
				}
			}
			// 其他跳转 Go 公众号首页
			c.cache.CacheWechatAuthStatus(sessionId, models2.WechatAuthStateAuthorized, nil)
			ctx.Redirect(http.StatusMovedPermanently, *orgMetadata.Redirecturl)
			return
		default:
			errMsg := "Stage 参数缺失"
			fmt.Println(errMsg)
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.AuthFailed, errMsg, errors.New(errMsg), log.SimpleMapParam{"session_id": param.SessionID, "stage": param.Stage})
		}

	}
}

type QueryGetRedirectUrl struct {
	SessionId string `json:"session_id" form:"session_id"`
}

func (c *AuthController) GetRedirectUrl() app.HandlerFunc {
	return func(ctx app.Context) {
		var query QueryGetRedirectUrl
		err := ctx.ShouldBindQuery(&query)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		info, _ := c.cache.GetWechatAuthStatusChannel(query.SessionId)
		ctx.SuccessJSON(info.WxAuthRedirectUrl)
	}
}

func (c *AuthController) Logout() app.HandlerFunc {
	return func(ctx app.Context) {
		c.jwt.RemoveJwtSession(ctx.GinContext())
		ctx.GinContext().String(http.StatusAccepted, "ok")
	}
}

func (c *AuthController) SetJwtSession() app.HandlerFunc {
	return func(ctx app.Context) {
		token, _ := ctx.GetQuery("token")
		ok, err := c.jwt.SetJwtSessionWithToken(ctx.GinContext(), token)
		if !ok {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.JwtUnHandledError, fmt.Sprintf("jwt session设置出错: %s", err.Error()), err)
			return
		}
		ctx.SuccessJSON("ok")
	}
}

type QueryWechatAuthStatus struct {
	SessionId string `json:"session_id"`
}

func (c *AuthController) GetWechatAuthStatus() app.HandlerFunc {
	return func(ctx app.Context) {
		role := ctx.Param("role")
		sessionId := ctx.Param("session_id")
		u, _ := c.cache.GetWechatAuthStatusChannel(sessionId)
		if u == nil {
			// c.logger.ErrorTraceback("auth session not found", nil, log.SimpleMapParam{"session_id": sessionId})
			// ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.AuthFailed, "auth session not found. please reload the page.", errors.New("auth session not found"), log.SimpleMapParam{"session_id": sessionId})
			ctx.SuccessJSON("auth session not found")
			return
		}
		if u.Status == models2.WechatAuthStateAuthorized {
			user, err := c.authService.GetUserByOpenid(ctx.RequestContext(), &u.OpenId)
			if err != nil {
				ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.AuthFailed, err.Error(), err, log.SimpleMapParam{"session_id": sessionId, "openid": u.OpenId})
				return
			}
			uid, _ := user.ID.Value()
			var token string
			switch role {
			case string(constants.RequireRoleStudent):
			case string(constants.RequireRoleAgent):
				acct, iErr := c.authService.GetAccountByUserId(ctx.RequestContext(), user.ID, constants.RequireRoleAgent)
				if iErr != nil {
					ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.RoleTypeNotMatch, err.Error(), err)
					return
				}
				token, err = c.jwt.GenerateJwtToken(uid.(string), acct.ID.String(), "")
			case "signup":
				token, err = c.jwt.GenerateJwtToken(uid.(string), "", "")
			}

			if err != nil {
				ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.AuthFailed, err.Error(), err, log.SimpleMapParam{"session_id": sessionId, "openid": u.OpenId, "user_id": uid.(string)})
				return
			}
			ctx.SuccessJSON(models2.WechatAuthStatus{
				Token:   token,
				State:   u.Status,
				Message: u.Message,
			})
			if !u.IsFromWechatClient {
				c.cache.ClearUserAuthInfoCache(sessionId)
			}
			return
		}
		ctx.SuccessJSON(models2.WechatAuthStatus{
			Token:   "",
			State:   u.Status,
			Message: u.Message,
		})
	}
}

//func (c *AuthController) WechatAuthStatus() app.HandlerFunc {
//	return func(ctx app.Context) {
//		// debug usage
//		// for key, value := range ctx.GetRequest().Header {
//		// 	fmt.Println(key, "===>", value)
//		// }
//		// fmt.Println(ctx.GinContext().Query("session_id"))
//		// ctx.SuccessJSON("skip")
//		return
//		var query QueryWechatAuthStatus
//		err := ctx.ShouldBindQuery(&query)
//		if err != nil {
//			ctx.AbortWithBadRequest(err)
//		}
//		sessionId, _ := ctx.GetQuery("session_id")
//
//		ws := ctx.WebSocketUpgrade()
//		defer func() {
//			err := ws.Close()
//			if err != nil {
//				panic(err)
//			}
//		}()
//		c.logger.Info(fmt.Sprintf("watching auth status for %s!", sessionId))
//		// fmt.Printf("watching auth status for %s!\n", sessionId)
//
//		// Monitoring channel
//
//		var pingDone = make(chan string, 2)
//
//		go func() {
//			ticker := time.NewTicker(1 * time.Second)
//			defer ticker.Stop()
//			for {
//				select {
//				case <-pingDone:
//
//					return
//				case <-ticker.C:
//
//					if _, _, err := ws.ReadMessage(); err != nil {
//						pingDone <- sessionId
//						close(pingDone)
//						c.logger.Info("ping function returned.")
//						// fmt.Println("ping function returned.")
//						return
//					}
//
//				}
//			}
//
//		}()
//
//		var u *cache.UserAuthInfo
//		var channel chan cache.WechatAuthNotifyChannel
//		for {
//			select {
//			case sessionId := <-pingDone:
//				c.logger.Info(fmt.Sprintf("Client Closed: %s", sessionId))
//				// fmt.Println("Client Closed.")
//				return
//			default:
//				u, channel = c.cache.GetWechatAuthStatusChannel(sessionId)
//			}
//			if channel != nil {
//				c.logger.Info(fmt.Sprintf("get channel for: %s", sessionId))
//				// fmt.Println("拿到了channel信息")
//				break
//			}
//			// fmt.Println("retry auth state retrieving...")
//			time.Sleep(1 * time.Second)
//
//		}
//
//		// 只有当client是电脑端时，才销毁cache
//		defer func() {
//			if !u.IsFromWechatClient {
//				c.cache.ClearUserAuthInfoCache(sessionId)
//			}
//		}()
//
//		// var expireDone chan string = make(chan string)
//
//		// go func() {
//		// 	for {
//
//		// 		select {
//		// 		case <-expireDone:
//		// 			fmt.Println("expire收到 inner")
//		// 			return
//		// 		default:
//		// 			u, channel = appCache.GetWechatAuthStatusChannel(sessionId)
//		// 			if channel == nil {
//		// 				b := ""
//		// 				ws.WriteJSON(model.WechatAuthStatus{
//		// 					Token:   "",
//		// 					State:   model.WechatAuthStateExpired,
//		// 					Message: &b,
//		// 				})
//		// 				expireDone <- "closed"
//		// 				fmt.Println("expire sent")
//		// 				return
//		// 			}
//		// 		}
//
//		// 		time.Sleep(2 * time.Second)
//		// 	}
//
//		// }()
//
//		for {
//			c.logger.Info("等待channel来信")
//			// fmt.Println("等待channel来信。。。")
//			select {
//			case latestNotify := <-channel:
//				fmt.Println(latestNotify)
//				switch latestNotify.Status {
//				case models2.WechatAuthStateAuthorized:
//					user, err := c.authService.GetUserByOpenid(ctx.RequestContext(), &u.OpenId)
//					if err != nil {
//						pingDone <- "closed"
//						c.logger.Panic(fmt.Sprintf("session: %s, openID: %s, 通过open id找不到user", query.SessionId, u.OpenId))
//						// panic()
//					}
//					uid, _ := user.ID.Value()
//					token, err := c.jwt.GenerateJwtToken(user.Nickname, uid.(string))
//					if err != nil {
//						pingDone <- "closed"
//						c.logger.Panic(fmt.Sprintf("session: %s, openID: %s, 生成jwt token失败", query.SessionId, u.OpenId))
//						// panic()
//					}
//					// err = ws.WriteMessage(websocket.TextMessage, []byte(latestNotify.Status))
//					// if err != nil {
//					// 	done <- "closed"
//					// 	fmt.Println(err)
//					// 	return
//					// }
//					err = ws.WriteJSON(models2.WechatAuthStatus{
//						Token:   token,
//						State:   latestNotify.Status,
//						Message: latestNotify.Message,
//					})
//					if err != nil {
//						pingDone <- err.Error()
//						// fmt.Println(err)
//						return
//					}
//					pingDone <- "server closed"
//					// fmt.Println("Server Closed.")
//
//					return
//				}
//				ws.WriteJSON(models2.WechatAuthStatus{
//					Token:   "",
//					State:   latestNotify.Status,
//					Message: latestNotify.Message,
//				})
//
//			case closeData := <-pingDone:
//				c.logger.Info(fmt.Sprintf("ping detect: %s", closeData))
//				// fmt.Println("Client Closed.")
//				return
//			}
//			c.logger.Info("next loop")
//			// fmt.Println("下一个链接")
//			time.Sleep(1 * time.Second)
//		}
//	}
//}

// Authorize 授权
// @Summary 授权
// @Description 根据当前session值返回用户，判断权限
// @Tags 授权
// @Produce application/json
// @Security ApiKeyAuth
// @Success 200 {object} controller.ResponseJsonResult{data=responsemodels.User}
// @Failure 401 {object} controller.ResponseJsonResult{data=string}
// @Router /auth/authorize [get]
func (c *AuthController) Authorize() app.HandlerFunc {
	return func(ctx app.Context) {
		orgName, exists := ctx.GetQuery("org_name")
		u := ctx.User()
		acct := ctx.Account()
		if !exists {
			orgName = "default"
		}
		b, err := c.authService.CheckBelongsToOrg(ctx.RequestContext(), orgName, acct.ID)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusUnauthorized, code.AuthFailed, err.Error(), err)
			return
		}

		if !b {
			ctx.AbortWithStatusJSON(http.StatusUnauthorized, code.UserNotSignedThisOrg, "用户不属于当前组织", nil)
			return
		}

		if acct.Accountname == nil {
			fmt.Printf("用户对应account id: %s 没有对应的accountname", acct.ID.String())
			s := ""
			acct.Accountname = &s
		}

		var agentStatus *code.Code
		if acct.Type.Entitytype != models.EntitytypeSTUDENT {
			agentStatus = c.authService.CheckAgentStatus(ctx.RequestContext(), *acct)
		} else {
			agentStatus = nil
		}

		res := responsemodels.User{
			ID:          u.ID.String(),
			NickName:    u.Nickname,
			AliasName:   u.Aliasname,
			AvatarURL:   u.Avatarurl,
			AccountId:   acct.ID.String(),
			AccountName: *acct.Accountname,
			Phone:       u.Phone,
			AgentCheck:  agentStatus,
			DemoMode:    ctx.DemoMode(),
		}
		ctx.SuccessJSON(res)
	}
}

func (c *AuthController) AuthorizeForStudent() app.HandlerFunc {
	return func(ctx app.Context) {
		u := ctx.User()
		acct := ctx.Account()

		if acct.Accountname == nil {
			fmt.Printf("用户对应account id: %s 没有对应的accountname", acct.ID.String())
			s := ""
			acct.Accountname = &s
		}

		var agentStatus *code.Code
		if acct.Type.Entitytype != models.EntitytypeSTUDENT {
			agentStatus = c.authService.CheckAgentStatus(ctx.RequestContext(), *acct)
		} else {
			agentStatus = nil
		}

		res := responsemodels.User{
			ID:          u.ID.String(),
			NickName:    u.Nickname,
			AliasName:   u.Aliasname,
			AvatarURL:   u.Avatarurl,
			AccountId:   acct.ID.String(),
			AccountName: *acct.Accountname,
			Phone:       u.Phone,
			AgentCheck:  agentStatus,
			DemoMode:    ctx.DemoMode(),
		}
		ctx.SuccessJSON(res)
	}
}

type QueryCheckEntitlementAvailable struct {
	EntitlementNameLike string `json:"ent_name" form:"ent_name"`
}

func (q QueryCheckEntitlementAvailable) MarshalLogObject(enc zapcore.ObjectEncoder) error {
	enc.AddString("ent_name", q.EntitlementNameLike)
	return nil
}

func (c *AuthController) CheckEntitlementAvailable() app.HandlerFunc {
	return func(ctx app.Context) {
		var query QueryCheckEntitlementAvailable
		err := ctx.ShouldBindQuery(&query)
		if err != nil {
			ctx.AbortWithBadRequest(err, query)
			return
		}
		u := ctx.User()
		acctId, err := c.authService.GetStudentAccountIdByUserId(ctx.RequestContext(), u.ID)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.RoleTypeNotMatch, err.Error(), err, log.SimpleMapParam{"user_id": u.ID.String()})
			return
		}
		exists, err := c.authService.CheckEntitlementAvailable(ctx.RequestContext(), models.CheckEntitlementAvailableParams{
			Entitlementnamelike: utils.StringPointer("%" + query.EntitlementNameLike + "%"),
			Studentid:           acctId.String(),
		})
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err, query)
			return
		}
		ctx.SuccessJSON(map[string]bool{"exists": exists})
	}
}

func (c *AuthController) TestEnforcer() app.HandlerFunc {
	return func(ctx app.Context) {
		data := c.enforcer.GetAllObjects()
		ctx.SuccessJSON(data)
	}
}
