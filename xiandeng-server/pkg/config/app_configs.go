package config

import "time"

// Auth
var (
	WechatStatusCacheExpireTime time.Duration = 5 * time.Minute
)

// Signup
var (
	InvitationCacheExpireTime time.Duration = 8 * time.Hour
	InvitationCodeLength      int           = 13
)

// Payment
var (
	WechatPayKeyPath string = "conf/apiclient_key.pem"
)

// Product
var (
	PlanningReportTemplatePath string = "reference/planning_report/template.docx"
)
