// import { $axiosBack } from '../client';
import { useAxiosRequest } from "@/composables/client";

interface InvitationCode {
    accountId: string
    code: string
    createType: string
    expiresAt: string
    userId: string
}

interface ListInvitationCodeResponse {
    data: Array<InvitationCode>
}
const listInvitationCodes = async () => {
    
    return await useAxiosRequest({
        method: "get",
        url: "/invitation_code/list",
    })
}

const getInvitationCodeDetail = async (code: string) => {
    return await useAxiosRequest({
        method: "get",
        url: `/invitation_code/${code}`
    })
}

const completeInvCode = async () => {
    return await useAxiosRequest({
        method: "post",
        url: "/invitation_code/complete"
    })
}

export {
    listInvitationCodes,
    type ListInvitationCodeResponse,
    type InvitationCode,
    getInvitationCodeDetail,
    completeInvCode
}