package controller

import (
	"errors"
	"fmt"
	"net/http"
	"strconv"
	"strings"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
	"go.uber.org/zap/zapcore"
	"xiandeng.net.cn/server/db"
	"xiandeng.net.cn/server/db/models"
	"xiandeng.net.cn/server/internal/app"
	"xiandeng.net.cn/server/internal/code"
	"xiandeng.net.cn/server/internal/services"
	"xiandeng.net.cn/server/pkg/log"
	"xiandeng.net.cn/server/pkg/utils"
)

type CouponController struct {
	*Controller
	couponService services.CouponService
	repo          db.Repository
}

func NewCouponController(controller *Controller, service services.CouponService, repo db.Repository) *CouponController {
	return &CouponController{
		Controller:    controller,
		couponService: service,
		repo:          repo,
	}
}

type BodyCreateCoupon struct {
	DiscountAmount  decimal.Decimal `json:"discountamount"`
	MaxCount        *int32          `json:"maxcount"`
	ProductId       *string         `json:"productid"`
	StudentId       *string         `json:"studentid"`
	EffectStartDate *string         `json:"effectstartdate" validate:"datetime=2006-01-02"`
	EffectDueDate   *string         `json:"effectduedate" validate:"datetime=2006-01-02"`
}

func (b BodyCreateCoupon) MarshalLogObject(enc zapcore.ObjectEncoder) error {
	enc.AddString("discountamount", b.DiscountAmount.String())
	if b.MaxCount != nil {
		enc.AddInt32("maxcount", *b.MaxCount)
	}
	if b.ProductId != nil {
		enc.AddString("productid", *b.ProductId)
	}
	if b.StudentId != nil {
		enc.AddString("studentid", *b.StudentId)
	}
	if b.EffectStartDate != nil {
		enc.AddString("effectstartdate", *b.EffectStartDate)
	}
	if b.EffectDueDate != nil {
		enc.AddString("effectduedate", *b.EffectDueDate)
	}
	return nil
}

// CreateCoupon 创建优惠券
// @Summary 创建优惠券
// @Description 创建优惠券
// @Tags 支付
// @Param BodyCreateCoupon body BodyCreateCoupon true "请求体"
// @Success 200 {object} controller.ResponseJsonResult
// @Produce application/json
// @Security ApiKeyAuth
// @Router /coupon/create [post]
func (c *CouponController) CreateCoupon() app.HandlerFunc {
	return func(ctx app.Context) {
		var body BodyCreateCoupon
		err := ctx.ShouldBind(&body)
		if err != nil {
			ctx.AbortWithBadRequest(err, body)
			return
		}
		u := ctx.User()

		var dbParams = models.CreateOrderCouponWithDbProcedureParams{}
		dbParams.Userid = u.ID
		dbParams.Discountamount = body.DiscountAmount
		if body.ProductId != nil && *body.ProductId != "" {
			dbParams.Productid = uuid.NullUUID{
				UUID:  uuid.MustParse(*body.ProductId),
				Valid: true,
			}
		}
		if body.StudentId != nil && *body.StudentId != "" {
			dbParams.Studentid = uuid.NullUUID{
				UUID:  uuid.MustParse(*body.StudentId),
				Valid: true,
			}
		}
		if body.MaxCount != nil && *body.MaxCount != 0 {
			dbParams.Maxcount = body.MaxCount
		}
		if body.EffectDueDate != nil && *body.EffectDueDate != "" {
			dbParams.Duedate = *utils.TimeStringToPgtypeDate(body.EffectDueDate, "2006-01-02")
		}
		if body.EffectStartDate != nil && *body.EffectStartDate != "" {
			dbParams.Startdate = *utils.TimeStringToPgtypeDate(body.EffectStartDate, "2006-01-02")
		}
		result, err := c.couponService.CreateCoupon(ctx.RequestContext(), dbParams)
		// err = q.CreateOrderCoupon(ctx.RequestContext(), dbParams)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.RecordUpdateError, fmt.Sprintf("CreateOrderCoupon: %v", err.Error()), err, body)
			return
		}
		d := result.(string)
		if !strings.Contains(d, "创建成功") {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.CouponCreateError, d, errors.New(d))
			return
		}
		ctx.SuccessJSON("ok")
	}
}

type QuerySearchCoupon struct {
	CurrentAgent   bool     `json:"cur_agent" form:"cur_agent"`
	ProductIds     []string `json:"product_ids[]" form:"product_ids[]" binding:"omitempty"`
	StudentIds     []string `json:"student_ids[]" form:"student_ids[]" binding:"omitempty"`
	IssuingUserIds []string `json:"issuing_user_ids[]" form:"issuing_user_ids[]" binding:"omitempty"`
	DiscountAmount *float32 `json:"discount_amount" form:"discount_amount" binding:"omitempty"`
	AgentId        *string  `json:"agent_id" form:"agent_id" binding:"omitempty"`
	ValidOnly      *bool    `json:"valid_only" form:"valid_only"`
	ExpiredOnly    *bool    `json:"expired_only" form:"expired_only"`
	CreatedAtStart *string  `json:"created_at_start" form:"created_at_start" binding:"omitempty"`
	CreatedAtEnd   *string  `json:"created_at_end" form:"created_at_end" binding:"omitempty"`
	Code           *int64   `json:"code" form:"code" binding:"omitempty"`
	MaxCount       *int32   `json:"max_count" form:"max_count" binding:"omitempty"`
}

// SearchCoupon 根据条件搜索优惠券
// @Summary 根据条件搜索优惠券
// @Description 根据条件搜索优惠券
// @Tags 支付
// @Param QuerySearchCoupon query QuerySearchCoupon true "请求体"
// @Success 200 {object} controller.ResponseJsonResult
// @Produce application/json
// @Security ApiKeyAuth
// @Router /aresource/coupon/search [get]
func (c *CouponController) SearchCoupon() app.HandlerFunc {
	return func(ctx app.Context) {
		var query QuerySearchCoupon
		err := ctx.ShouldBindQuery(&query)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}

		dbParams := models.SearchOrderCouponParams{}
		//AgentId
		if query.CurrentAgent {
			dbParams.Agentid = ctx.Account().ID.String()
		} else if query.AgentId != nil {
			dbParams.Agentid = *query.AgentId
		}

		// ProductIds
		if query.ProductIds != nil {
			dbParams.Productidvalid = true
			dbParams.Productids = query.ProductIds
		}
		// StudentIds
		if query.StudentIds != nil {
			dbParams.Studentidvalid = true
			dbParams.Studentids = query.StudentIds
		}
		// IssuingUserIds
		if query.IssuingUserIds != nil {
			dbParams.Issuinguservalid = true
			dbParams.Issuingusers = query.IssuingUserIds
		}
		// DiscountAmount
		if query.DiscountAmount != nil && *query.DiscountAmount != 0 {
			dbParams.Discountamountvalid = true
			dbParams.Discountamount = decimal.NewNullDecimal(decimal.NewFromFloat32(*query.DiscountAmount))
		}
		// ValidOnly
		if query.ValidOnly != nil && *query.ValidOnly {
			dbParams.Validonly = true
		} else if query.ExpiredOnly != nil && *query.ExpiredOnly {
			dbParams.Expiredonly = true
		}

		//CreatedAt
		if query.CreatedAtEnd != nil {
			dbParams.Createdatend = *query.CreatedAtEnd
		}
		if query.CreatedAtStart != nil {
			dbParams.Createdatstart = *query.CreatedAtStart
		}

		// Code
		if query.Code != nil {
			dbParams.Codevalid = true
			dbParams.Code = *query.Code
		}
		if query.MaxCount != nil && *query.MaxCount != 0 {
			dbParams.Maxcountvalid = true
			dbParams.Maxcount = query.MaxCount
		}
		coupons, err := c.repo.NewQueries().SearchOrderCoupon(ctx.RequestContext(), dbParams)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(coupons)
	}
}

type QueryGetStudentCoupon struct {
	ProductId string `form:"product_id" json:"product_id" binding:"uuid4"`
}

// GetCoupon 学生根据code获取优惠券
// @Summary 根据code获取优惠券，并检查studentid和当前用户是否一致
// @Description 根据code获取优惠券，并检查studentid和当前用户是否一致
// @Tags 支付
// @Param ProductId query QueryGetStudentCoupon true "传入商品ID"
// @Param Code path string true "优惠券码"
// @Success 200 {object} controller.ResponseJsonResult
// @Produce application/json
// @Security ApiKeyAuth
// @Router /aresource/student/coupon/{code} [get]
//func (c *CouponController) GetStudentCoupon() app.HandlerFunc {
//	return func(ctx app.Context) {
//		var query QueryGetStudentCoupon
//		err := ctx.ShouldBindQuery(&query)
//		if err != nil {
//			ctx.AbortWithBadRequest(err)
//			return
//		}
//		u := ctx.User()
//		codeParam := ctx.Param("code")
//		code, err := strconv.Atoi(codeParam)
//		if err != nil {
//			ctx.AbortWithBadRequest(fmt.Sprintf("invalid code format: %s", codeParam))
//			return
//		}
//
//		coupon, err := q.GetCouponByCode(ctx.RequestContext(), int64(code))
//		if err != nil {
//			ctx.AbortWithError(http.StatusInternalServerError, err)
//			return
//		}
//
//		// 检查studentid是否一致
//		if coupon.Studentid.Valid {
//			if u.Accountid != coupon.Studentid {
//				ctx.AbortWithError(http.StatusInternalServerError, fmt.Errorf("优惠券不属于当前用户"))
//				return
//			}
//		}
//		//
//		if coupon.Productid.Valid {
//			if query.ProductId != coupon.Productid.UUID.String() {
//				ctx.AbortWithError(http.StatusInternalServerError, fmt.Errorf("优惠券不属于当前商品"))
//				return
//			}
//		}
//		ctx.SuccessJSON(coupon)
//
//	}
//}

func (c *CouponController) GetCoupon() app.HandlerFunc {
	return func(ctx app.Context) {
		codeParam := ctx.Param("code")
		couponCode, err := strconv.Atoi(codeParam)
		if err != nil {
			ctx.AbortWithBadRequest(fmt.Errorf("invalid code format: %s", codeParam))
			return
		}

		coupon, err := c.repo.NewQueries().GetCouponByCode(ctx.RequestContext(), int64(couponCode))
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err, log.SimpleMapParam{"code": strconv.Itoa(couponCode)})
			return
		}
		ctx.SuccessJSON(coupon)
	}
}
