package code

type Code struct {
	Number  int    `json:"number"`
	Message string `json:"message"`
}

func (c Code) Error() string {
	return c.Message
}

func NewCode(code int, msg string) Code {
	return Code{
		Number:  code,
		Message: msg,
	}
}

var (
	// Common status
	OK                = NewCode(0, "操作成功")
	ServerInternalErr = NewCode(500000, "服务器内部错误")
	RequestTimeout    = NewCode(500001, "请求超时")

	InvalidParams     = NewCode(400000, "请求所需参数错误")
	StructValidateErr = NewCode(400001, "validator struct参数校验错误")

	DBQueriesExecErr = NewCode(600000, "数据库语句执行错误")
	TaskExecutionErr = NewCode(700000, "任务执行错误")

	// Auth status
	UserRegSuccess       = NewCode(100000, "注册成功")
	UserLoginSuccess     = NewCode(100001, "登陆成功")
	UserNameHasExisted   = NewCode(100002, "用户名已存在")
	UserGetError         = NewCode(100003, "用户不存在或数据库中搜索失败")
	UserAuthFailed       = NewCode(100004, "用户名密码验证失败")
	AuthFailed           = NewCode(100005, "验证失败")
	UserIDParseError     = NewCode(100006, "用户ID解析失败，格式错误")
	RoleTypeNotMatch     = NewCode(100007, "角色类型不匹配")
	RoleTypeNotExist     = NewCode(100008, "角色类型不存在")
	UserNotSignedThisOrg = NewCode(100009, "用户未加入该机构")

	JwtNotFound         = NewCode(100100, "密文不存在")
	JwtMalformed        = NewCode(100101, "密文格式错误")
	JwtSignatureInvalid = NewCode(100102, "密文签名错误")
	JwtTokenExpired     = NewCode(100103, "密文过期，请重新获取")
	SessionSetError     = NewCode(100104, "Session设置出错")
	JwtUnHandledError   = NewCode(100105, "密文其他错误")

	WechatExchangeError = NewCode(100110, "微信授权换取用户信息失败")
	WechatNotSignuped   = NewCode(100111, "未完成注册流程")
	ExistAccountInvalid = NewCode(100112, "已存在账号输入有误")

	// Invitation Link
	InvitationGenerationError = NewCode(100200, "邀请码生成错误")
	InvitationCacheError      = NewCode(100201, "邀请属性相关错误")
	InvitationCacheNotFound   = NewCode(100202, "邀请链接找不到")

	// Agent login status
	AgentLoginSuccess      = NewCode(100300, "代理登陆成功")
	AgentLoginUpgrading    = NewCode(100301, "账号正在升级")
	AgentLoginInit         = NewCode(100302, "未完成注册流程，账号激活中")
	AgentUpstreamPartition = NewCode(100303, "管理职未完成分区分配")
	AgentClosed            = NewCode(100304, "账号已关户")

	// Organization
	OrgMetaInvalid = NewCode(100400, "机构元数据无效")
	InvalidOrgName = NewCode(100401, "机构名无效")

	// QrCode status
	QrCodeExist   = NewCode(110000, "") // 未过期
	QrCodeExpired = NewCode(110001, "") // 已过期
	QrCodeScanned = NewCode(110002, "") // 已被扫描

	// Payment

	PaymentCreateError  = NewCode(120001, "支付交易创建失败")
	PaymentSignError    = NewCode(120002, "支付签名失败")
	PaymentVerifyFailed = NewCode(120003, "支付验证失败")
	PaymentCommonError  = NewCode(120004, "支付相关失败")
	CouponCreateError   = NewCode(120005, "优惠券创建失败")
	OrderUpdateError    = NewCode(120006, "订单更新确认失败")

	// Resource
	RecordNotFound    = NewCode(130001, "记录没找到")
	RecordUpdateError = NewCode(130002, "记录更新失败")

	// Services
	RecruitRecordNotFound = NewCode(130003, "招聘信息记录未找到")

	//
)
