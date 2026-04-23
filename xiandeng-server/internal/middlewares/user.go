package middlewares

import (
	"fmt"
	"net/http"
	"strings"

	"xiandeng.net.cn/server/constants"
	"xiandeng.net.cn/server/internal/services"

	"github.com/google/uuid"
	"xiandeng.net.cn/server/db"
	"xiandeng.net.cn/server/db/models"
	"xiandeng.net.cn/server/pkg/jwt"
	"xiandeng.net.cn/server/pkg/log"

	"xiandeng.net.cn/server/internal/app"
	"xiandeng.net.cn/server/internal/code"
)

type UserMiddleware struct {
	repo db.Repository
	jwt  *jwt.JwtManager
	as   services.AuthService
}

func NewUserMiddleware(repo db.Repository, jwt *jwt.JwtManager, as services.AuthService) *UserMiddleware {
	return &UserMiddleware{
		repo,
		jwt,
		as,
	}
}

func (m *UserMiddleware) GetUserByGinContext(ctx app.Context) (*models.User, error) {
	claims, token, err := m.jwt.ValidateJwtSessionToken(ctx.GinContext())
	if err != nil {
		ctx.LogWarn("jwt验证失败", err, log.SimpleMapParam{"token": token})
		return nil, err
	}
	queries := m.repo.NewQueries()
	uid, err := uuid.Parse(claims.Subject)
	if err != nil {
		ctx.LogWarn("用户授权未找到，可能是jwt不正确。最好重新授权一遍", err, log.SimpleMapParam{"sub": claims.Subject})
		return nil, fmt.Errorf("用户授权未找到，可能是jwt不正确。最好重新授权一遍。sub: %s", claims.Subject)
	}
	u, err := queries.GetUser(ctx.GinContext(), uid)
	if err != nil {
		ctx.LogWarn("get user by userid failed", err, log.SimpleMapParam{"userid": uid.String()})
		return nil, fmt.Errorf("get user by userid (%s) failed: %v", uid.String(), err)
	}
	return &u, nil
}

func (m *UserMiddleware) GetUserMdw() app.HandlerFunc {
	return func(ctx app.Context) {
		up, err := m.GetUserByGinContext(ctx)
		if err != nil {
			// println(err.Error())
			if strings.Contains(err.Error(), "session not found") {
				ctx.Abort(http.StatusUnauthorized, code.JwtNotFound, err.Error())
				return
			} else {
				ctx.Abort(http.StatusUnauthorized, code.UserGetError, err.Error())
				return
			}

		}
		ctx.SetUser(up)

		// If Requirerole header exists, then setAccount
		if ctx.GetRequest().Header.Get("Requirerole") != "" {
			role := constants.RequireRole(ctx.GetRequest().Header.Get("Requirerole"))
			if role != constants.RequireRoleAgent && role != constants.RequireRoleStudent {
				ctx.AbortWithStatusJSON(http.StatusBadRequest, code.RoleTypeNotExist, "", nil, log.SimpleMapParam{"require_role": string(role)})
				return
			}
			// 确认是否是demo account，然后按照对应account赋值
			var acct models.Account
			// 如果是role为 student，则用demo account模式
			if role == constants.RequireRoleStudent {
				if up.Wechatopenid != nil {
					demoAcct, demoUser, err := m.as.DemoAccount(ctx.RequestContext(), *up.Wechatopenid)
					if demoAcct != nil && demoUser != nil && err == nil {
						ctx.SetDemoMode(true)
						acct = *demoAcct
						ctx.SetUser(demoUser)
					} else {
						if err != nil {
							ctx.Logger().Warn(fmt.Sprintf("retrieve demo account err: %s", err.Error()))
						}
						acct, err = m.as.GetAccountByUserId(ctx.RequestContext(), up.ID, role)
					}
				} else {
					acct, err = m.as.GetAccountByUserId(ctx.RequestContext(), up.ID, role)
				}
			} else {
				acct, err = m.as.GetAccountByUserId(ctx.RequestContext(), up.ID, role)
			}

			if err != nil {
				ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.RoleTypeNotMatch, "", err, log.SimpleMapParam{"user_id": up.ID.String(), "require_role": string(role)})
				return
			}
			ctx.SetAccount(&acct)
		}
		ctx.Logger().Info("get middleware user/account info success")
		ctx.Next()
	}
}

//func (m *UserMiddleware) GetAccountMdw(requireRole constants.RequireRole) app.HandlerFunc {
//	return func(ctx app.Context) {
//		m.GetUserMdw()
//		user := ctx.User()
//		acct, err := m.as.GetAccountByUserId(ctx.RequestContext(), user.ID, requireRole)
//		if err != nil {
//			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.RoleTypeNotMatch, "", err, log.SimpleMapParam{"user_id": user.ID.String(), "require_role": string(requireRole)})
//			return
//		}
//		ctx.SetAccount(&acct)
//		ctx.Next()
//	}
//}
