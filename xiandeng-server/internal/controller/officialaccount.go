package controller

import (
	"fmt"
	"net/http"
	"net/url"

	"github.com/silenceper/wechat/v2/officialaccount"
	"xiandeng.net.cn/server/internal/app"
	"xiandeng.net.cn/server/internal/code"
)

type OfficialAccountController struct {
	*Controller
	officialAccount *officialaccount.OfficialAccount
}

func NewOfficialAccountController(
	controller *Controller,
	officialAccount *officialaccount.OfficialAccount,
) *OfficialAccountController {
	return &OfficialAccountController{
		Controller:      controller,
		officialAccount: officialAccount,
	}
}

type BodyCreatePortalMenu struct {
	TagID string `json:"tag_id" form:"tag_id"`
}

// CreatePortalMenu 创建公众号个性化菜单
// @Summary 创建公众号个性化菜单
// @Description 根据【用户标签】创建公众号个性化菜单，确定哪些人可以看到
// @Tags 公众号
func (oc *OfficialAccountController) CreatePortalMenu() app.HandlerFunc {
	return func(ctx app.Context) {
		var body BodyCreatePortalMenu
		err := ctx.ShouldBind(&body)
		if err != nil {
			ctx.AbortWithBadRequest(err)
		}
		state := "mystate"
		redirectUrl := "%s/server/api/v1/student_portal?next=/oa/shop"
		redirectUrl = fmt.Sprintf(redirectUrl, oc.conf.WebUrlPrefix())
		accessUrl := "https://open.weixin.qq.com/connect/oauth2/authorize?appid=%s&redirect_uri=%s&response_type=code&scope=snsapi_userinfo&state=%s#wechat_redirect"
		accessUrl = fmt.Sprintf(accessUrl, oc.conf.Auth.WxAppID, url.QueryEscape(redirectUrl), state)
		err = oc.officialAccount.GetMenu().AddConditionalByJSON(fmt.Sprintf(
			`{
				"button":[
				{
					"name":"个性化菜单",
					"sub_button":[
					{
						"type":"view",
						"name":"产品",
						"url":"%s"
					}]
				}],
				"matchrule": {
					"tag_id": "%s"
				}
				
			}`, accessUrl, body.TagID,
		))
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessCreateJSON("ok")
	}
}

// GetPortalMenu 获取公众号菜单信息
// @Summary 获取公众号菜单信息
// @Description 获取公众号菜单信息
// @Tags 公众号
// @Produce application/json
// @Security ApiKeyAuth
// @Router /oa/menu [get]
func (oc *OfficialAccountController) GetPortalMenu() app.HandlerFunc {
	return func(ctx app.Context) {
		resMenu, err := oc.officialAccount.GetMenu().GetMenu()
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, "", fmt.Errorf("GetMenu: %v", err))
			return
		}
		ctx.SuccessJSON(resMenu)
	}
}

type BodyDeletePortalMenu struct {
	MenuID int64 `json:"menu_id" form:"menu_id"`
}

// DeletePortalMenu 删除个性化菜单
// @Summary 删除个性化菜单
// @Description 根据menuid删除个性化菜单
// @Tags 公众号
func (oc *OfficialAccountController) DeletePortalMenu() app.HandlerFunc {
	return func(ctx app.Context) {
		var body BodyDeletePortalMenu
		err := ctx.ShouldBind(&body)
		if err != nil {
			ctx.AbortWithBadRequest(err)
		}
		err = oc.officialAccount.GetMenu().DeleteConditional(body.MenuID)
		if err != nil {
			ctx.FailedJSON(http.StatusInternalServerError, code.ServerInternalErr, err)
			return
		}
		ctx.SuccessJSON("ok")
	}
}

type BodyCreateTag struct {
	Tag struct {
		Name string `json:"name" form:"name"`
	} `json:"tag" form:"tag"`
}

// CreateTag 新建标签
// @Summary 新建标签
// @Description 新建标签
// @Tags 公众号
// @Accept json
// @Param BodyCreateTag body BodyCreateTag true "请求体"
// @Success 200 {object} controller.ResponseJsonResult
// @Produce application/json
// @Security ApiKeyAuth
// @Router /oa/tag/create [post]
func (oc *OfficialAccountController) CreateTag() app.HandlerFunc {
	return func(ctx app.Context) {
		var body BodyCreateTag
		err := ctx.ShouldBind(&body)
		if err != nil {
			ctx.AbortWithBadRequest(err)
		}
		tag, err := oc.officialAccount.GetUser().CreateTag(body.Tag.Name)
		if err != nil {
			ctx.FailedJSON(http.StatusInternalServerError, code.ServerInternalErr, err)
			return
		}
		ctx.SuccessJSON(tag)
	}
}

type BodyBatchTagUsers struct {
	OpenIDList []string `json:"openid_list" form:"openid_list"`
	TagID      int32    `json:"tagid" form:"tagid"`
}

// BatchTagUsers 批量打标签
// @Summary 批量打标签
// @Description 批量打标签
// @Tags 公众号
// @Accept json
// @Param BodyBatchTagUsers body BodyBatchTagUsers true "请求体"
// @Success 200 {object} controller.ResponseJsonResult
// @Produce application/json
// @Security ApiKeyAuth
// @Router /oa/tag/batch [post]
func (oc *OfficialAccountController) BatchTagUsers() app.HandlerFunc {
	return func(ctx app.Context) {
		var body BodyBatchTagUsers
		err := ctx.ShouldBind(&body)
		if err != nil {
			ctx.AbortWithBadRequest(err)
		}
		err = oc.officialAccount.GetUser().BatchTag(body.OpenIDList, body.TagID)
		if err != nil {
			ctx.FailedJSON(http.StatusInternalServerError, code.ServerInternalErr, err)
			return
		}
		ctx.SuccessJSON("ok")
	}
}

// ListTags 获取所有标签
// @Summary 获取所有标签
// @Description 获取所有标签
// @Tags 公众号
// @Success 200 {object} controller.ResponseJsonResult
// @Produce application/json
// @Security ApiKeyAuth
// @Router /oa/tag/list [get]
func (oc *OfficialAccountController) ListTags() app.HandlerFunc {
	return func(ctx app.Context) {
		tags, err := oc.officialAccount.GetUser().GetTag()
		if err != nil {
			ctx.FailedJSON(http.StatusInternalServerError, code.ServerInternalErr, err)
			return
		}
		ctx.SuccessJSON(tags)
	}
}

type CreateSKUPageUrlBody struct {
	Next string `form:"next" json:"next"`
}

// CreateSKUPageUrl 创建SKU链接
// @Summary 创建SKU链接
// @Description 创建SKU链接
// @Tags 公众号
// @Param CreateSKUPageUrlBody body CreateSKUPageUrlBody true "CreateSKUPageUrlBody"
// @Produce application/json
// @Success 201 {object} controller.ResponseJsonResult
// @Security ApiKeyAuth
// @Router /oa/skulink/create [post]
func (oc *OfficialAccountController) CreateSKUPageUrl() app.HandlerFunc {
	return func(ctx app.Context) {
		var body CreateSKUPageUrlBody
		ctx.ShouldBind(&body)
		state := "mystate"
		redirect_url := "%s/server/api/v1/student_portal?next=" + body.Next
		redirect_url = fmt.Sprintf(redirect_url, oc.conf.WebUrlPrefix())
		accessUrl := "https://open.weixin.qq.com/connect/oauth2/authorize?appid=%s&redirect_uri=%s&response_type=code&scope=snsapi_userinfo&state=%s#wechat_redirect"
		accessUrl = fmt.Sprintf(accessUrl, oc.conf.Auth.WxAppID, url.QueryEscape(redirect_url), state)
		ctx.SuccessCreateJSON(accessUrl)
	}
}
