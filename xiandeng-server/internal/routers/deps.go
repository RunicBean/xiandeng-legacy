package router

import (
	"xiandeng.net.cn/server/internal/controller"
	"xiandeng.net.cn/server/internal/middlewares"
)

type Deps struct {
	// Purpose: Keep route registration files declarative. They depend on one bundle instead of a
	// long positional parameter list, which makes future regrouping safer for both humans and LLMs.
	UserMiddleware *middlewares.UserMiddleware

	AuthController            *controller.AuthController
	AccountController         *controller.AccountController
	ResourceController        *controller.ResourceController
	InvitationCodeController  *controller.InvitationCodeController
	StudentController         *controller.StudentController
	CouponController          *controller.CouponController
	OrderController           *controller.OrderController
	WechatpayController       *controller.WechatpayController
	ProductController         *controller.ProductController
	SystemController          *controller.SystemController
	BalanceController         *controller.WalletController
	OfficialAccountController *controller.OfficialAccountController
	UserController            *controller.UserController
	ShowcaseController        *controller.ShowcaseController
	PaymentController         *controller.PaymentController
	WithdrawController        *controller.WithdrawController
	DeliveryController        *controller.DeliveryController
	InventoryController       *controller.InventoryController
	AdjustmentController      *controller.AdjustmentController
}
