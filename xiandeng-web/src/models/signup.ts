import { AccountType } from "./account"

export class BasicForm {
    password: string = ""
    phone: string = ""
    email?: string
    checkPass: string = ""
    accountType: AccountType = AccountType.STUDENT
    refcode: string =  ""
    province: string = ""
    city: string = ""
    // 以下三属性提供给家长先注册的场景
    role: string = "" // guardian，student
    gardStudentName: string = "" // 填充进account name
    gardRelationship?: string
    // 以下属性提供给邀请加入account user的场景
    invitationAccountId: string = ""
    existAccountId?: string
    // 以下属性提供给代理注册
    agentName: string = ""
    agreeTerms: boolean = false
    // 以下属性提供给独立销售场景
    inviteUserId?: string
    inviteAgentRoleId?: string
}
export interface StudentForm {
    firstname: string
    lastname: string
    sex: string
    university: string
    department: string
    major: string
    majorType: string
    entryDate: string
    degreeYears?: number
}

export interface StudentMbtiForm {
    mbtiEnergy: string
    mbtiMind: string
    mbtiDecision: string
    mbtiReaction: string
}

export interface StudentGaokaoScoreForm {
    totalScore?: number
    chinese?: number
    mathematics?: number
    foreignLanguage?: number
    physics?: number
    chemistry?: number
    biology?: number
    politics?: number
    history?: number
    geography?: number
    [key: string]: number | undefined;
}

export interface AgentForm {

}

