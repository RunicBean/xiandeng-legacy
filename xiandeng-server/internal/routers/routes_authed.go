package router

import "xiandeng.net.cn/server/internal/app"

func registerV1AuthedRoutes(api app.RouterGroup, deps Deps) {
	// Invariant: Every route in this registrar must pass through GetUserMdw().
	// Why: This file is the single audit surface for "login required" APIs after the router split.
	systemAuthed := api.Group("/system", deps.UserMiddleware.GetUserMdw())
	{
		systemAuthed.POST("log_message", deps.SystemController.LogMessage())
	}

	accountAuthed := api.Group("/account", deps.UserMiddleware.GetUserMdw())
	{
		accountAuthed.GET(":account_id", deps.AccountController.GetAccount())
		accountAuthed.GET("/my-agent/list", deps.AccountController.ListMyAgents())
		accountAuthed.GET("/my-partition/list", deps.AccountController.ListPartitionAgents())
		accountAuthed.GET("/partition/sum", deps.AccountController.CalculateSumPv())
		accountAuthed.POST("/agent/upgrade", deps.AccountController.UpdateAgentTargettype())
		accountAuthed.GET("/agents/search", deps.AccountController.SearchAgents())
		accountAuthed.GET("/agents/search/attributes", deps.AccountController.SearchAgentsWithAttributes())
		accountAuthed.POST("/agent/partition", deps.AccountController.UpdateAgentPartition())
		accountAuthed.POST("/agent/assign_award/:account_id", deps.AccountController.AssignAgentAward())
		accountAuthed.POST("agent/my/settings/update", deps.UserController.UpdateMyAgentSettings())
		accountAuthed.POST("agent/attributes/update", deps.UserController.UpdateAgentAttributes())
		accountAuthed.GET("/pending-agents/foid/:foid", deps.AccountController.PendingAgentsByFranchiseOrderId())
		accountAuthed.GET("/agents/seven-level", deps.AccountController.SevenLevelSubAgents())
		accountAuthed.GET("/sub-agent/details", deps.AccountController.ListSubAgentDetails())
		accountAuthed.POST("/agent/to-student", deps.AccountController.AgentToStudent())
		accountAuthed.POST("/student/to-agent", deps.AccountController.StudentToAgent())
		accountAuthed.POST("student/join-agent", deps.AccountController.StudentJoinAgent())
		accountAuthed.POST("/hq/agent/update", deps.AccountController.UpdateAgentByHQ())
	}

	invCodeAuthed := api.Group("/invitation_code", deps.UserMiddleware.GetUserMdw())
	{
		invCodeAuthed.GET("list", deps.InvitationCodeController.ListInvitationCode())
		invCodeAuthed.POST("complete", deps.InvitationCodeController.CompleteInvitationCodes())
	}

	authAuthed := api.Group("/auth", deps.UserMiddleware.GetUserMdw())
	{
		authAuthed.GET("authorize", deps.AuthController.Authorize())
		authAuthed.GET("authorize/student", deps.AuthController.AuthorizeForStudent())
		authAuthed.GET("entitlement/check", deps.AuthController.CheckEntitlementAvailable())
		authAuthed.GET("user-role", deps.UserController.GetRoleOfUser())
		authAuthed.GET("upagent", deps.UserController.GetUpstreamAgentAttr())
		authAuthed.GET("agent", deps.UserController.GetAgentAttr())
		authAuthed.POST("product/cookie", deps.AuthController.AssignHttpsCookie())
	}

	userAuthed := api.Group("/user", deps.UserMiddleware.GetUserMdw())
	{
		userAuthed.GET("view/privilege", deps.UserController.GetUserViewPrivilege())
		userAuthed.GET("roles/by_acct_kind", deps.UserController.GetRolesByAcctKind())
		userAuthed.POST("password/update", deps.UserController.UpdatePassword())
		userAuthed.POST("aliasname/update", deps.UserController.UpdateAliasname())
	}

	wechatpayAuthed := api.Group("/wechatpay", deps.UserMiddleware.GetUserMdw())
	{
		wechatpayAuthed.POST("prepay/create", deps.WechatpayController.CreateWechatpayPrepay())
		wechatpayAuthed.POST("payment/close", deps.WechatpayController.ClosePayment())
		wechatpayAuthed.POST("order/confirm", deps.WechatpayController.ConfirmOrderSucceeded())
	}

	studentAuthed := api.Group("/student", deps.UserMiddleware.GetUserMdw())
	{
		studentAuthed.GET("list", deps.StudentController.ListStudents())
		studentAuthed.GET("list/for-planning", deps.StudentController.ListStudentForPlanning())
		studentAuthed.GET("list/for-planning/referral", deps.StudentController.ListStudentForPlanningByReferral())
		studentAuthed.POST("search", deps.StudentController.SearchStudents())
		studentAuthed.GET("detail/list", deps.StudentController.ListStudentDetails())
		studentAuthed.GET("detail/list/referral", deps.StudentController.ListStudentDetailsByReferral())
		studentAuthed.POST("update", deps.StudentController.UpdateStudentProfile())
		studentAuthed.GET("accountid/:account_id", deps.StudentController.GetStudentAccountid())
		studentAuthed.POST("study_suggestion/update", deps.StudentController.UpdateStudySuggestion())
		studentAuthed.GET("university/search", deps.StudentController.SearchUniversities())
		studentAuthed.GET("university/eligible", deps.StudentController.IsUniversityGraduateEligible())
	}

	couponAuthed := api.Group("/coupon", deps.UserMiddleware.GetUserMdw())
	{
		couponAuthed.POST("create", deps.CouponController.CreateCoupon())
		couponAuthed.GET("search", deps.CouponController.SearchCoupon())
		couponAuthed.GET(":code", deps.CouponController.GetCoupon())
	}

	orderAuthed := api.Group("/order", deps.UserMiddleware.GetUserMdw())
	{
		orderAuthed.POST("create", deps.OrderController.CreateOrder())
		orderAuthed.POST("simple_w_pm/create", deps.OrderController.GenerateSimpleOrderWithPaymentMethod())
		orderAuthed.POST("search", deps.OrderController.SearchOrders())
		orderAuthed.POST("update", deps.OrderController.UpdateOrder())
		orderAuthed.POST("confirm", deps.OrderController.ConfirmOfflineOrderSucceeded())
		orderAuthed.POST("decline", deps.OrderController.DeclineOrder())
		orderAuthed.POST("decline/simple", deps.OrderController.SimpleDeclineOrder())
		orderAuthed.POST("price/update", deps.OrderController.UpdateOrderPrice())
		orderAuthed.GET("liuliustatements", deps.OrderController.ListLiuliustatementByOrderId())
		orderAuthed.POST("pay_success", deps.OrderController.PaySuccess())
		orderAuthed.GET("restricted/list", deps.OrderController.ListRestrictedOrders())
		orderAuthed.GET("restricted/list/by_referral", deps.OrderController.ListRestrictedOrdersByReferral())
		orderAuthed.POST("tags", deps.OrderController.InsertOrderTags())
		orderAuthed.POST("tags/delete", deps.OrderController.DeleteOrderTags())
	}

	paymentAuthed := api.Group("/payment", deps.UserMiddleware.GetUserMdw())
	{
		paymentAuthed.POST("revoke", deps.PaymentController.RevokePayment())
	}

	productAuthed := api.Group("/product", deps.UserMiddleware.GetUserMdw())
	{
		productAuthed.GET("current/list/price", deps.ProductController.ListProductWithPrice())
		productAuthed.GET("list", deps.ProductController.ListProduct())
		productAuthed.GET("purchased", deps.ProductController.ListPurchasedProducts())
		productAuthed.GET("purchasable", deps.ProductController.ListPurchasableProducts())
		productAuthed.GET(":id", deps.ProductController.GetProduct())
	}

	walletAuthed := api.Group("/wallet", deps.UserMiddleware.GetUserMdw())
	{
		walletAuthed.GET("balance", deps.BalanceController.GetBalance())
		walletAuthed.POST("balanceactivity/list", deps.BalanceController.ListBalanceActivityDetails())
		walletAuthed.POST("mybalanceactivity/list", deps.BalanceController.ListMyBalanceActivityDetails())
		walletAuthed.POST("balanceactivity/export", deps.BalanceController.ExportBalanceActivityDetails())
		walletAuthed.POST("mybalanceactivity/export", deps.BalanceController.ExportMyBalanceActivityDetails())
		walletAuthed.GET("trippleaward/list", deps.BalanceController.ListTripleAwardDetails())
		walletAuthed.GET("trippleunlock/:source_id", deps.BalanceController.ListTripleUnlockDetails())
		walletAuthed.GET("withdraw/ongoing", deps.BalanceController.GetOngoingWithdrawAmount())
	}

	adjustmentAuthed := api.Group("/adjustment", deps.UserMiddleware.GetUserMdw())
	{
		adjustmentAuthed.POST("insert", deps.AdjustmentController.InsertAdjustment())
		adjustmentAuthed.GET("list", deps.AdjustmentController.ListAdjustmentRecords())
	}

	withdrawAuthed := api.Group("/withdraw", deps.UserMiddleware.GetUserMdw())
	{
		withdrawAuthed.POST("create", deps.WithdrawController.CreateWithdraw())
		withdrawAuthed.GET("list", deps.WithdrawController.ListWithdraw())
		withdrawAuthed.POST("method/bank/create", deps.WithdrawController.CreateBankWithdrawMethod())
		withdrawAuthed.GET("method/bank/list", deps.WithdrawController.ListBankWithdrawMethods())
		withdrawAuthed.PATCH("method/bank/update/:withdraw_method_id", deps.WithdrawController.UpdateBankWithdrawMethod())
		withdrawAuthed.DELETE("method/bank/delete/:withdraw_method_id", deps.WithdrawController.DeleteWithdrawMethod())
	}

	deliveryAuthed := api.Group("/delivery", deps.UserMiddleware.GetUserMdw())
	{
		deliveryAuthed.GET("list", deps.DeliveryController.ListDelivery())
		deliveryAuthed.POST("confirm", deps.DeliveryController.ConfirmDelivery())
	}

	inventoryAuthed := api.Group("/inventory", deps.UserMiddleware.GetUserMdw())
	{
		inventoryAuthed.POST("order/create", deps.InventoryController.CreateInventoryOrder())
		inventoryAuthed.POST("order/:io_id/status/update", deps.InventoryController.UpdateInventoryOrderStatus())
		inventoryAuthed.POST("order/:io_id/confirm", deps.InventoryController.ConfirmInventoryOrder())
		inventoryAuthed.POST("order/:io_id/update", deps.InventoryController.UpdateInventoryOrderPaymentMethod())
		inventoryAuthed.GET("list", deps.InventoryController.ListInventory())
		inventoryAuthed.GET("max_quantity", deps.InventoryController.GetMaximumQuantity())
		inventoryAuthed.GET("activities", deps.InventoryController.GetInventoryActivities())
		inventoryAuthed.GET("course_orders", deps.InventoryController.InventoryCourseOrders())
		inventoryAuthed.GET("list_for_hq", deps.InventoryController.ListInventoriesForHQ())
	}

	resourceAuthed := api.Group("/aresource", deps.UserMiddleware.GetUserMdw())
	{
		resourceAuthed.GET("recruit/list", deps.ResourceController.ListRecruitMenu())
		resourceAuthed.GET("recruit/:recruitid", deps.ResourceController.GetRecruitDetail())
		resourceAuthed.POST("recruit/update", deps.ResourceController.ScrapeOffer())
		resourceAuthed.GET("faculty/list", deps.ResourceController.ListFaculties())
		resourceAuthed.GET("department/list", deps.ResourceController.ListDepartments())
		resourceAuthed.GET("major/list", deps.ResourceController.ListMajors())
		resourceAuthed.GET("major/associate/search", deps.ResourceController.SearchAssociateMajors())
		resourceAuthed.GET("major/bachelor/search", deps.ResourceController.SearchBachelorMajors())
		resourceAuthed.GET("postgradsuggestion/:code", deps.ResourceController.GetPostgradSuggestion())
		resourceAuthed.GET("goventerprise/list", deps.ResourceController.ListGoventerprise())
		resourceAuthed.GET("qianliaocoupon/list", deps.ResourceController.ListMyQianliaoCoupon())
		resourceAuthed.POST("planning-report/create", deps.ResourceController.GenerateReport())
		resourceAuthed.GET("planning-report/get-data/:account_id", deps.ResourceController.GetStudentPlanningReportDataByAccountId())
		resourceAuthed.GET("planning-report/get-precheck-data/:account_id", deps.ResourceController.GetStudentPlanningPrecheckDataByAccountId())
	}

	oaAuthed := api.Group("/oa", deps.UserMiddleware.GetUserMdw())
	{
		oaAuthed.POST("/menu/create", deps.OfficialAccountController.CreatePortalMenu())
		oaAuthed.GET("/menu", deps.OfficialAccountController.GetPortalMenu())
		oaAuthed.DELETE("/menu", deps.OfficialAccountController.DeletePortalMenu())
		oaAuthed.POST("/tag/batch", deps.OfficialAccountController.BatchTagUsers())
		oaAuthed.POST("/tag/create", deps.OfficialAccountController.CreateTag())
		oaAuthed.GET("/tag/list", deps.OfficialAccountController.ListTags())
		oaAuthed.POST("skulink/create", deps.OfficialAccountController.CreateSKUPageUrl())
	}
}
