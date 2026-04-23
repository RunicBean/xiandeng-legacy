package errcode

var (
	// Common status
	Success           = NewErr(0, "操作成功")
	ServerInternalErr = NewErr(500000, "服务器内部错误")
	InvalidParams     = NewErr(400000, "请求所需参数错误")

	// Auth status
	AppRegSuccess       = NewErr(100000, "注册成功")
	AppLoginSuccess     = NewErr(100001, "登陆成功")
	AppNameHasExit      = NewErr(100002, "用户名已存在")
	AppNameHasNotExist  = NewErr(100003, "用户不存在")
	AppAuthFailed       = NewErr(100004, "用户名密码验证失败")
	AppFailed           = NewErr(100005, "验证失败")
	AppUserIDParseError = NewErr(100006, "用户ID解析失败，格式错误")

	JwtNotFound         = NewErr(100100, "密文不存在")
	JwtMalformed        = NewErr(100101, "密文格式错误")
	JwtSignatureInvalid = NewErr(100102, "密文签名错误")
	JwtTokenExpired     = NewErr(100103, "密文过期，请重新获取")
	JwtUnHandledError   = NewErr(100104, "密文其他错误")

	// Invitation Link
	InvitationGenerationError = NewErr(100200, "邀请码生成错误")
	InvitationCacheError      = NewErr(100201, "邀请属性相关错误")
	InvitationCacheNotFound   = NewErr(100202, "邀请链接找不到")

	// QrCode status
	QrCodeExist   = NewErr(110000, "") // 未过期
	QrCodeExpired = NewErr(110001, "") // 已过期
	QrCodeScanned = NewErr(110002, "") // 已被扫描
)
