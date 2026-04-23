export enum AuthStage {
    Login = "login",
    Signup = "signup"
}

export enum WechatAuthStatus {
    Init = "INIT",
    CodeScanned = "CODE_SCANNED",
    Authorized = "AUTHORIZED",
    Failed = "FAILED"
}

export const OFFICIAL_ACCOUNT_PAGE_URL = "https://mp.weixin.qq.com/mp/profile_ext?action=home&__biz=MzU0Mzg4NzQ5Mw%3D%3D#wechat_redirect"

export enum WindowSize {
    Small = 1,
    Medium = 2,
    Large = 3
}

export enum UserRole {
    Student = "student",
    Agent = "agent",
    Guardian = "guardian"
}