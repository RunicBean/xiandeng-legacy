//go:build wireinject
// +build wireinject

package wire

import (
	"github.com/google/wire"
	"xiandeng.net.cn/server/db"
	"xiandeng.net.cn/server/internal/app"
	"xiandeng.net.cn/server/internal/controller"
	"xiandeng.net.cn/server/internal/middlewares"
	router "xiandeng.net.cn/server/internal/routers"
	"xiandeng.net.cn/server/internal/services"
	"xiandeng.net.cn/server/pkg/config"
	"xiandeng.net.cn/server/pkg/imap"
	"xiandeng.net.cn/server/pkg/jwt"
	"xiandeng.net.cn/server/pkg/log"
	"xiandeng.net.cn/server/pkg/oss"
	"xiandeng.net.cn/server/pkg/rbac"
	"xiandeng.net.cn/server/pkg/resource"
	"xiandeng.net.cn/server/pkg/validate"
	"xiandeng.net.cn/server/pkg/wechat"
	"xiandeng.net.cn/server/pkg/wechatpay"
	"xiandeng.net.cn/server/services/cache"
	"xiandeng.net.cn/server/tasks/server"
)

var repositorySet = wire.NewSet(
	db.NewDBTX,
	db.NewRepository,
)

var serviceSet = wire.NewSet(
	services.NewService,
	services.NewAuthService,
	services.NewUserService,
	services.NewCouponService,
	services.NewOrderService,
	services.NewWechatpayService,
	services.NewResourceService,
	services.NewAccountService,
	services.NewStudentService,
	services.NewInvitationCodeService,
	services.NewPaymentGeneralService,
	services.NewProductService,
	services.NewShowcaseService,
	services.NewFileSystemService,
	services.NewImapService,
	services.NewDataService,
	services.NewWithdrawService,
	services.NewDeliveryService,
	services.NewInventoryService,
	services.NewAdjustmentService,
)

var controllerSet = wire.NewSet(
	controller.NewController,
	controller.NewAuthController,
	controller.NewCouponController,
	controller.NewOrderController,
	controller.NewWechatpayController,
	controller.NewAccountController,
	controller.NewStudentController,
	controller.NewResourceController,
	controller.NewInvitationCodeController,
	controller.NewWalletController,
	controller.NewProductController,
	controller.NewSystemController,
	controller.NewOfficialAccountController,
	controller.NewUserController,
	controller.NewShowcaseController,
	controller.NewPaymentController,
	controller.NewWithdrawController,
	controller.NewDeliveryController,
	controller.NewInventoryController,
	controller.NewAdjustmentController,
)

var middlewareSet = wire.NewSet(
	middlewares.NewUserMiddleware,
)

var routerSet = wire.NewSet(
	wire.Struct(new(router.Deps), "*"),
	router.NewAppServer,
)

func NewWire(*config.Config, *log.Logger) (*app.WebServer, func(), error) {
	panic(wire.Build(
		jwt.NewJwtManager,
		cache.GetAppCache,
		wechat.NewWxServiceManager,
		server.NewTaskClient,
		wechatpay.NewWechatPayEngine,
		wechat.NewOfficialAccount,
		imap.NewImapClient,
		rbac.NewEnforcer,
		resource.NewResource,
		//server.NewTaskServer,
		oss.NewOSSClient,
		//schedule.NewScheduler,
		validate.NewValidator,
		repositorySet,
		serviceSet,
		controllerSet,
		middlewareSet,
		routerSet,
	))
}
