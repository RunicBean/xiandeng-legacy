export enum AccountType {
    HEAD_QUARTER = "HEAD_QUARTER",
    HQ_AGENT = "HQ_AGENT",
    LV1_AGENT = "LV1_AGENT",
    LV2_AGENT = "LV2_AGENT",
    STUDENT = "STUDENT"
}

export enum AccountKind {
    AGENT = "AGENT",
    HQ = "HQ"
}

export function isAgent(accountType: AccountType): boolean {
    return [AccountType.HQ_AGENT, AccountType.LV1_AGENT, AccountType.LV2_AGENT].includes(accountType);
}

export function isHQOrAgent(accountType: AccountType): boolean {
    return [AccountType.HEAD_QUARTER, AccountType.HQ_AGENT, AccountType.LV1_AGENT, AccountType.LV2_AGENT].includes(accountType);
}

export function isStudent(accountType: AccountType): boolean {
    return [AccountType.STUDENT].includes(accountType as AccountType);
}

export function isHQ(accountType: AccountType): boolean {
    return [AccountType.HEAD_QUARTER].includes(accountType as AccountType);
}

export const AccountTypeHierarchySerial = new Map<string, number>([
    ["HEAD_QUARTER", 0],
    ["HQ_AGENT", 1],
    ["LV1_AGENT", 2],
    ["LV2_AGENT", 3]
])

export const AgentAccountTypeHierarchySerial = new Map<string, number>([
    ["HQ_AGENT", 1],
    ["LV1_AGENT", 2],
    ["LV2_AGENT", 3]
])

export function formatSex(sexCode: string|number|undefined|null) {
    let sexStr
    if (typeof sexCode == "undefined" || sexCode == null) {return ""}
    if (typeof sexCode == "number") {
        sexStr = sexCode.toString()
    } else {
        sexStr = sexCode
    }
    switch (sexStr) {
        case "0":
            return "未知"
            break
        case "1":
            return "男"
            break
        case "2":
            return "女"
            break
        default:
            throw("undefined sexcode.")
    }
}

export enum Partition {
    L = "L",
    R = "R"
}


export interface UserBasicInfoInput {
    phone: string
    password: string
    email?: string
    province?: string
    city?: string
}
