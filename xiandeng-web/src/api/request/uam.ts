import { useAxiosRequest } from '@/composables/client';
import {BasicForm} from '@/models/signup';
import {RequireRoleType} from "@/models/user.ts";
import {AxiosResponse} from "axios";
// import {$axiosBack, newWebsocketClient} from '../client';


const getUserWithPhone = async (phone: string) => {

    return await useAxiosRequest({
        method: "get",
        url: "/user/with_phone",
        params: {
            phone
        }
    })
}

const checkUserPhoneAvailable = async (phone: string) => {
    return await useAxiosRequest({
        method: "get",
        url: "/user/phone_available",
        params: {
            phone
        }
    })
}

const login = async (phone: string, password: string, orgName?: string) => {
    return await useAxiosRequest({
        method: "post",
        url: "/auth/login",
        data: {
            phone,
            password,
            org_name: orgName
        },
        headers: {
            "Content-Type": "application/json"
        }
    })
}

const setProductCookie = async () => {
    return await useAxiosRequest({
        method: "post",
        url: "/auth/product/cookie",
        // params: {
        //     product
        // }
    })
}

const authorize = async (org_name?: string) => {
    return await useAxiosRequest({
        method: "get",
        url: "/auth/authorize",
        params: {
            org_name
        }
    })
}

const authorizeForStudent = async () => {
    return await useAxiosRequest({
        method: "get",
        url: "/auth/authorize/student",
    })
}

const checkEntitlement = async (entitleNameLike: string) => {
    return await useAxiosRequest({
        method: "get",
        url: "/auth/entitlement/check",
        params: {
            ent_name: entitleNameLike
        }
    })
}



const upstreamStudentCheck = async (code: string, accountName: string) => {
    return await useAxiosRequest({
        method: "get",
        url: "/account/student/exists",
        params: {
            code,
            student_account_name: accountName
        }
    })
}

const listStudentsWithSameName = async (name: string) => {
    return await useAxiosRequest({
        method: "get",
        url: "/account/student/same-name/list",
        params: {
            account_name: name
        }
    })
}

const startWxQrcodeScan = async (
    sessionId: string,
    userBasicInfo: BasicForm,
    stage: string,
    inplaceRedirect: boolean,
    refCode?: string,
    requireRole?: RequireRoleType,
    orgName?: string) => {
    return await useAxiosRequest({
        method: "post",
        url: "/auth/wechat/oauth/init",
        data: {
            sessionId,
            userBasicInfo: {
                phone: userBasicInfo.phone,
                refCode,
                password: userBasicInfo.password,
                email: userBasicInfo.email,
                province: userBasicInfo.province,
                city: userBasicInfo.city,
                role: userBasicInfo.role,
                gardStudentName: userBasicInfo.gardStudentName,
                gardRelationship: userBasicInfo.gardRelationship,
                invitationAccountId: userBasicInfo.invitationAccountId,
                agentName: userBasicInfo.agentName,
                existAccountId: userBasicInfo.existAccountId,
                inviteUserId: userBasicInfo.inviteUserId,
                inviteAgentRoleId: userBasicInfo.inviteAgentRoleId
            },
            stage,
            inplaceRedirect,
            requireRole,
            orgName
        },
        headers: {
            "Content-Type": "application/json"
        }
    })
}

const getRedirectUrl = async (sessionId: string) => {
    return await useAxiosRequest({
        method: "get",
        url: "/auth/wechat/portal/url",
        params: {
            session_id: sessionId
        }
    })

}

// // function startWxLogin(sessionId: string, userBasicForm: BasicForm) {
// //     return useMutation(gql`
// //         mutation {
// //             startWxLogin(sessionId: "${sessionId}", userBasicInfo: {
// //                 phone: "${userBasicForm.phone}",
// //                 password: "${userBasicForm.password}"
// //             })
// //         }
// //     `)
// // }

// function watchWechatAuthStatus(sessionId: string, onMessage: (event: MessageEvent) => any) {

//     const wsconn = newWebsocketClient(`/auth/wechat/status/watch?session_id=${sessionId}`)
//     wsconn.addEventListener("open", () => {
//         console.log("websocket opened")

//         setInterval(() => {
//             if (wsconn.readyState === WebSocket.OPEN) {
//                 wsconn.send(JSON.stringify({ type: 'ping' }));
//             }
//           }, 9000); // 每9秒发送一次ping
//     })
//     wsconn.onmessage = onMessage
// }

async function getWechatAuthStatus(role: RequireRoleType, sessionId: string) {
    return await useAxiosRequest({
        method: "get",
        url: `/auth/wechat/status/${role}/${sessionId}`,
    })
}

async function setJwtTokenSession(token: string) {
    return await useAxiosRequest({
        method: "post",
        url: "/auth/jwt/set",
        params: {
            token
        }
    })
}

interface RoleData {
    usertype: string
    accounttype: string
    existstudent: boolean
    accountid: string
}
async function getRoleOfUser() {
    return await useAxiosRequest({
        method: "get",
        url: "auth/user-role"
    })
}

interface Upagent {
    agentcode?: string;
    paymentmethodwechatoffline?: boolean;
    paymentmethodalipayoffline?: boolean;
    paymentmethodcardoffline?: boolean;
    paymentmethodwechatpay?: boolean;
    couponinputenabled?: boolean;
    type?: {
        entitytype: string;
    } | null;
    [key: string]: string | boolean | undefined | object | null;
}

class UpdateAgentForm {
    paymentmethodwechatoffline?: boolean;
    paymentmethodalipayoffline?: boolean;
    paymentmethodcardoffline?: boolean;
    paymentmethodwechatpay?: boolean;
    couponinputenabled?: boolean;
    [key: string]: string | boolean | undefined;
}

interface AgentResponse {
    data: Upagent;
}

async function getUpagent() {
    return await useAxiosRequest({
        method: "get",
        url: "auth/upagent"
    })
}

async function getAgent() {
    return await useAxiosRequest({
        method: "get",
        url: "auth/agent"
    })
}

async function updateAgentSettings(form: UpdateAgentForm) {
    return await useAxiosRequest({
        method: "post",
        url: "auth/agent/settings/update",
        data: form,
        headers: {
            "Content-Type": "application/json"
        }
    })
}


async function getAccount(accountId: string) {
    const response = await useAxiosRequest({
        method: "get",
        url: "account/" + accountId
    })
    return response.data
}

interface Account {
    account_name: string
    pending_fee: string
    original_type: string
    target_type: string
    account_type: string
    account_status: string
}

async function getAccountSignupData(accountId: string) {
    const response = await useAxiosRequest({
        method: "get",
        url: "account/signup-data/" + accountId
    })
    return response.data
}

interface BodyAgentToStudent {
    account_name: string
    user_id: string
    relationship?: string
}

async function agentToStudent(body: BodyAgentToStudent) {
    const response = await useAxiosRequest({
        method: "post",
        url: "account/agent/to-student",
        data: body
    })
    return response.data
}

interface BodyStudentToAgent {
    account_name: string
    user_id: string
    entity_name: string
}

async function studentToAgent(body: BodyStudentToAgent) {
    const response = await useAxiosRequest({
        method: "post",
        url: "account/student/to-agent",
        data: body
    })
    return response.data
}

interface BodyStudentJoinAgent {
    account_id: string
    user_id: string
    role_id: string
}

async function studentJoinAgent(body: BodyStudentJoinAgent) {
    const response = await useAxiosRequest({
        method: "post",
        url: "account/student/join-agent",
        data: body
    })
    return response.data
}

async function getUserViewPrivilege(acctKind: string) {
    const response = await useAxiosRequest({
        method: "get",
        url: `user/view/privilege`,
        params: {
            acct_kind: acctKind
        }
    })
    return response.data
}

async function getRolesByAcctKind(acctKind: string) {
    const response: AxiosResponse<Array<{id: string, rolename_cn: string}>> = await useAxiosRequest({
        method: "get",
        url: `user/roles/by_acct_kind`,
        params: {
            acct_kind: acctKind
        }
    })
    return response.data
}

async function updatePassword(newPassword: string) {
    const response: AxiosResponse<{redirect_url: string}> = await useAxiosRequest({
        method: "post",
        url: "user/password/update",
        data: {
            new_password: newPassword
        }
    })
    return response.data
}

async function updateNickname(aliasname: string) {
    const response: AxiosResponse<string> = await useAxiosRequest({
        method: "post",
        url: "user/aliasname/update",
        data: {aliasname}
    })
    return response.data
}

export {
    login,
    setProductCookie,
    startWxQrcodeScan,
    // watchWechatAuthStatus,
    getWechatAuthStatus,
    getUserWithPhone,
    checkUserPhoneAvailable,
    upstreamStudentCheck,
    listStudentsWithSameName,


    setJwtTokenSession,
    getRedirectUrl,

    type RoleData,
    getRoleOfUser,
    getAccount,
    getAccountSignupData,
    type Account,
    getUpagent,
    getAgent,
    updateAgentSettings,
    type Upagent,
    type AgentResponse,
    UpdateAgentForm,

    // 授权
    authorize,
    authorizeForStudent,
    checkEntitlement,

    agentToStudent,
    type BodyAgentToStudent,
    studentToAgent,
    type BodyStudentToAgent,
    studentJoinAgent,
    type BodyStudentJoinAgent,
    getUserViewPrivilege,
    getRolesByAcctKind,
    updatePassword,
    updateNickname,
}
