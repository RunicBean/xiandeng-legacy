
export enum RequireRoleType {
    AGENT = "agent",
    STUDENT = "student",
}

export enum UserRoleType {
    OWNER = "OWNER",
    ADMIN = "ADMIN",
    STUDENT = "STUDENT",
    GUARDIAN_PRIMARY = "GUARDIAN_PRIMARY",
    GUARDIAN_SUPPLEMENT = "GUARDIAN_SUPPLEMENT",
}

export function isUserStudent(role: UserRoleType) {
    return role == UserRoleType.STUDENT
}

export function isUserGuardian(role: UserRoleType) {
    return role == UserRoleType.GUARDIAN_PRIMARY || role == UserRoleType.GUARDIAN_SUPPLEMENT
}

export class UserProfile {
    id?: string
    nickName?: string
    aliasName?: string
    avatarUrl?: string
    accountId?: string
    accountName?: string
    phone?: string
    agentCheck?: {number: number, message: string}
    demoMode?: boolean
}
