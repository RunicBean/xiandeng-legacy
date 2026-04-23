package router

import (
	"xiandeng.net.cn/server/internal/app"
	"xiandeng.net.cn/server/internal/controller"
)

func registerV1PublicRoutes(api app.RouterGroup, deps Deps) {
	// Invariant: Only routes that must remain reachable without login belong in this registrar.
	// Why: Grouping by auth policy makes middleware boundaries explicit and easier to audit.
	api.GET("wechat_auth", deps.AuthController.WechatRedirectHandler())
	api.GET("student_portal", deps.AuthController.WechatStudentPortalHandler())
	api.GET("agent_portal", deps.AuthController.WechatAgentPortalHandler())
	api.GET("user_portal", deps.AuthController.WechatUserPortalHandler())

	systemPublic := api.Group("/system")
	{
		systemPublic.GET("health", deps.SystemController.Health())
		systemPublic.POST("webhook", deps.SystemController.WebhookPost())
		systemPublic.GET("webhook", deps.SystemController.WebhookGet())
		systemPublic.POST("log_common_message", deps.SystemController.LogCommonMessage())
		systemPublic.GET("test_task", deps.SystemController.TestTask())
		systemPublic.POST("order/proof/:order_id", deps.SystemController.UploadOrderProof())
		systemPublic.GET("order/proof/:order_id", deps.SystemController.ListOrderProof())
		systemPublic.GET("imap/test", deps.SystemController.TestImapFetch())
		systemPublic.GET("wording-map/:ns", deps.SystemController.GetWording())
		systemPublic.POST("generate_hash_password", deps.SystemController.GenerateHashPassword())
		systemPublic.POST("check_hash_password", deps.SystemController.CheckHashPassword())
		systemPublic.POST("study_suggestion/update", deps.StudentController.UpdateStudySuggestionWithIds())
	}

	accountPublic := api.Group("/account")
	{
		accountPublic.GET("/student/same-name/list", deps.AccountController.ListCheckNameResults())
		accountPublic.GET("/signup-data/:account_id", deps.AccountController.GetAccountSignupData())
	}

	api.GET("invitation_code/:code", deps.InvitationCodeController.InvitationCodeDetail())

	authPublic := api.Group("/auth")
	{
		authPublic.POST("login", deps.AuthController.Login())
		authPublic.GET("logout", deps.AuthController.Logout())
		authPublic.POST("jwt/set", deps.AuthController.SetJwtSession())
		authPublic.GET("wechat/portal/url", deps.AuthController.GetRedirectUrl())
		authPublic.POST("wechat/oauth/init", deps.AuthController.InitWechatOauth())
		authPublic.GET("wechat/status/:role/:session_id", deps.AuthController.GetWechatAuthStatus())
		authPublic.GET("enforcer/test", deps.AuthController.TestEnforcer())
	}

	userPublic := api.Group("/user")
	{
		userPublic.GET("with_phone", deps.UserController.GetUserWithPhone())
		userPublic.GET("phone_available", deps.UserController.UserPhoneAvailable())
	}

	wechatpayPublic := api.Group("/wechatpay")
	{
		wechatpayPublic.POST("webhook", deps.WechatpayController.WechatNotifyTemp())
	}

	productPublic := api.Group("/product")
	{
		productPublic.GET("published/list", deps.ProductController.ListPublishedProduct())
		productPublic.GET(":id/images", deps.ProductController.ListProductImages())
	}

	showcasePublic := api.Group("/showcase")
	{
		showcasePublic.GET("company/:company_path", deps.ShowcaseController.GetCompany())
		showcasePublic.GET("carousel/list", deps.ShowcaseController.ListShowcasePageCarouselData())
		showcasePublic.GET("item/list", deps.ShowcaseController.ListShowcasePageItemData())
	}

	resourcePublic := api.Group("/resource")
	{
		resourcePublic.GET("terms/overall/url", deps.ResourceController.GetTermsOverallSignedUrl())
		resourcePublic.GET("org/:uri/metadata", deps.ResourceController.GetOrgMetadata())
	}

	// Purpose: Keep swagger public so API explorers can inspect contracts before authentication.
	api.GET("/swagger/*any", controller.SwaggerControl())
}
