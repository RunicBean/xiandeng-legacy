package controller

import (
	"fmt"
	"net/http"
	"xiandeng.net.cn/server/pkg/utils/model_util"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
	"xiandeng.net.cn/server/db"
	"xiandeng.net.cn/server/db/models"
	"xiandeng.net.cn/server/internal/app"
	"xiandeng.net.cn/server/internal/code"
	"xiandeng.net.cn/server/internal/services"
)

type ProductController struct {
	*Controller
	productService services.ProductService
	repo           db.Repository
}

func NewProductController(controller *Controller, service services.ProductService, repo db.Repository) *ProductController {
	return &ProductController{
		Controller:     controller,
		productService: service,
		repo:           repo,
	}

}

type QueryGetProductsByOrderId struct {
	OrderId int64 `json:"order_id" form:"order_id"`
}

// GetProducts 通过订单Id获取商品
// @Summary 通过订单Id获取商品
// @Description 通过订单Id获取商品
// @Tags 商品
// @Param QueryGetProductsByOrderId query QueryGetProductsByOrderId true "1"
// @Success 200 {object} controller.ResponseJsonResult
// @Produce application/json
// @Security ApiKeyAuth
// @Router /orderproduct/list [get]
func (c *ProductController) GetOrderProducts() app.HandlerFunc {
	return func(ctx app.Context) {
		var query QueryGetProductsByOrderId
		err := ctx.ShouldBindQuery(&query)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		data, err := c.repo.NewQueries().GetOrderProductsByOrderId(ctx.RequestContext(), &query.OrderId)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.RecordNotFound, err.Error(), err)
			return
		}
		ctx.SuccessJSON(data)
	}
}

// ListProduct 列出商品
// @Summary 列出商品
// @Description 列出商品
// @Tags 商品
// @Success 200 {object} controller.ResponseJsonResult
// @Produce application/json
// @Security ApiKeyAuth
// @Router /payment/product/list [get]
func (c *ProductController) ListProduct() app.HandlerFunc {
	return func(ctx app.Context) {
		acct := ctx.Account()
		prds, err := c.repo.NewQueries().ListProduct(ctx.RequestContext(), acct.ID)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.RecordNotFound, err.Error(), err)
		}
		ctx.SuccessJSON(prds)
	}
}

// ListPublishedProduct 列出已发布商品
// @Summary 列出已发布商品
// @Description 列出已发布商品
// @Tags 商品
// @Success 200 {object} controller.ResponseJsonResult
// @Produce application/json
// @Security ApiKeyAuth
// @Router /payment/product/published/list [get]
func (c *ProductController) ListPublishedProduct() app.HandlerFunc {
	return func(ctx app.Context) {

		prds, err := c.repo.NewQueries().ListPublishedProduct(ctx.RequestContext())
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.RecordNotFound, err.Error(), err)
		}
		ctx.SuccessJSON(prds)
	}
}

type BodyProductCreate struct {
	ProductName   string `json:"product_name"`
	FinalPrice    string `json:"final_price"`
	HqAgentPrice  string `json:"hq_agent_price"`
	Lv1AgentPrice string `json:"lv1_agent_price"`
	Lv2AgentPrice string `json:"lv2_agent_price"`
	PublishStatus bool   `json:"publish_status"`
	Description   string `json:"description"`
}

// CreateProduct 新建商品
// @Summary 新建商品
// @Description 新建商品
// @Tags 商品
// @Accept json
// @Param BodyProductCreate body BodyProductCreate true "请求体"
// @Success 200 {object} controller.ResponseJsonResult
// @Produce application/json
// @Security ApiKeyAuth
// @Router /payment/product/create [post]
func (c *ProductController) CreateProduct() app.HandlerFunc {
	return func(ctx app.Context) {
		var body BodyProductCreate
		err := ctx.ShouldBind(&body)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		finalPrice, err := decimal.NewFromString(body.FinalPrice)
		if err != nil {
			ctx.AbortWithBadRequest(err)
		}
		p, err := c.repo.NewQueries().CreateEntitlementProduct(ctx.RequestContext(), models.CreateEntitlementProductParams{
			Productname:   body.ProductName,
			Finalprice:    finalPrice,
			Publishstatus: body.PublishStatus,
			Description:   body.Description,
		})
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.ServerInternalErr, err.Error(), err)
			return
		}
		ret, err := model_util.ProductDBToGql(p)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.ServerInternalErr, err.Error(), err)
			return
		}
		ctx.SuccessCreateJSON(ret)
	}
}

func (c *ProductController) ListPurchasedProducts() app.HandlerFunc {
	return func(ctx app.Context) {
		prds, err := c.repo.NewQueries().GetPurchasedProducts(ctx.RequestContext(), ctx.User().ID)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(prds)
	}
}

func (c *ProductController) ListPurchasableProducts() app.HandlerFunc {
	return func(ctx app.Context) {
		prds, err := c.repo.NewQueries().GetPurchasableProducts(ctx.RequestContext(), ctx.User().ID)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(prds)
	}
}

// GetProduct 获取商品详情
// @Summary 获取商品详情
// @Description 获取商品详情
// @Tags 商品
// @Param  id    path  string  true  "Id"
// @Success 200 {object} controller.ResponseJsonResult
// @Produce application/json
// @Security ApiKeyAuth
// @Router /payment/product/{id} [get]
func (c *ProductController) GetProduct() app.HandlerFunc {
	return func(ctx app.Context) {
		prdid := ctx.Param("id")
		puid, err := uuid.Parse(prdid)
		if err != nil {
			ctx.AbortWithBadRequest(fmt.Errorf("get product product id not in uuid: %v", err))
			return
		}
		prd, err := c.repo.NewQueries().GetProduct(ctx.RequestContext(), ctx.User().ID, puid)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.RecordNotFound, err.Error(), err)
		}
		ctx.SuccessJSON(prd)
	}
}

// ListProduct 根据我的进货价列出商品
// @Summary 根据我的进货价列出商品
// @Description 根据我的进货价列出商品
// @Tags 商品
// @Success 200 {object} controller.ResponseJsonResult
// @Produce application/json
// @Security ApiKeyAuth
// @Router /payment/current/product/list [get]
// func (c *ProductController) ListProductForCurrentUser() app.HandlerFunc {
// 	return func(ctx app.Context) {
// 		prds, err := c.repo.NewQueries().ListMyProducts(ctx.RequestContext(), ctx.User().ID)
// 		if err != nil {
// 			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.RecordNotFound, fmt.Sprintf("ListProduct: %v", err.Error()))
// 		}
// 		ctx.SuccessJSON(prds)
// 	}
// }

func (c *ProductController) ListProductWithPrice() app.HandlerFunc {
	return func(ctx app.Context) {
		prds, err := c.repo.NewQueries().ListProductsWithPrice(ctx.RequestContext(), ctx.Account().ID)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.RecordNotFound, err.Error(), err)
		}
		ctx.SuccessJSON(prds)
	}
}

func (c *ProductController) ListProductImages() app.HandlerFunc {
	return func(ctx app.Context) {
		pid := ctx.Param("id")
		puid, err := uuid.Parse(pid)
		if err != nil {
			ctx.AbortWithBadRequest(fmt.Errorf("id is not a valid product id: %s", pid))
			return
		}

		images, err := c.repo.NewQueries().GetProductImages(ctx.RequestContext(), uuid.NullUUID{UUID: puid, Valid: true})
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(images)
	}
}
