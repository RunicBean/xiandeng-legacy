package constants

import "time"

const (
	SESSION_NAME                   = "app_session"
	INTERNAL_RESOURCE_CONTEXT_NAME = "INTERNAL_RESOURCE"
)

const (
	OSS_SIGNED_URL_EXPIRE_MINUTES = 30
)

const (
	WECHAT_OFFICIAL_ACCOUNT_URL = "https://mp.weixin.qq.com/mp/profile_ext?action=home&__biz=MzU0Mzg4NzQ5Mw%3D%3D#wechat_redirect"
)

const (
	RECRUIT_URL      = "https://backservice.offerxiansheng.com/api/backend-service/bkd/campus-recruit-tag/list"
	RECRUIT_ITEM_URL = "https://backservice.offerxiansheng.com/api/backend-service/bkd/campus-recruit/details?recruitId="
)

const (
	INVITATION_CODE_LENGTH     = 13
	INVITATION_CODE_EXPIRES_IN = 8 * time.Hour
)

const (
	ORDER_PROOF_DIRECTORY = "order/proofs"
	TERMS_OVERALL_KEY     = "doc/terms-overall.pdf"
)

// JWT
const (
	ISSUER = "xiandeng.net.cn"
)

const PRODUCT_LOGIN_TOKEN_NAME = "prod-login-token"
const STAGING_PRODUCT_DOMAIN = ".ai-toolsets.com"
const PROD_PRODUCT_DOMAIN = ".xiandeng.net.cn"
