// import { $axiosBack } from '@/api/client.ts';
import { useAxiosRequest } from "@/composables/client";

import { WithdrawMethodType } from '@/models/withdraw';

interface WithdrawMethod {
    id: string
    bank: string
    accountname: string
    accountnumber: string
    createdat: string
    updatedat: string
    userid: string
    withdrawmethod: WithdrawMethodType
    [key: string]: string
}
async function listWithdrawMethods(methodType: WithdrawMethodType, userId?: string) {
    let params: {
        user_id?: string
        current_user?: boolean
    } = {}
    if (userId) params.user_id = userId
    else params.current_user = true
    const resp = await useAxiosRequest({
        url: `/withdraw/method/${methodType}/list`,
        method: "get",
        params
    })
    return resp.data
}

async function createWithdrawMethod(
    methodType: WithdrawMethodType, 
    bankName: string,
    accountName: string,
    accountNumber: string,
    userId?: string
) {
    let params: {
        user_id?: string
        current_user?: boolean
        bank_name: string
        account_name: string
        account_number: string
    } = {
        bank_name: bankName,
        account_name: accountName,
        account_number: accountNumber
    }
    if (userId) params.user_id = userId
    else params.current_user = true
    return await useAxiosRequest({
        url: `/withdraw/method/${methodType}/create`,
        method: "post",
        data: params
    })
}

async function deleteWithdrawMethod(methodType: WithdrawMethodType, methodId: string) {
    return await useAxiosRequest({
        url: `/withdraw/method/${methodType}/delete/${methodId}`,
        method: "delete"
    })
}

async function updateWithdrawMethod(methodType: WithdrawMethodType, methodId: string, bankName: string, accountName: string, accountNumber: string) {
    return await useAxiosRequest({
        url: `/withdraw/method/${methodType}/update/${methodId}`,
        method: "patch",
        data: {
            bank_name: bankName,
            account_name: accountName,
            account_number: accountNumber
        }
    })
}

export {
    type WithdrawMethod,
    listWithdrawMethods,
    createWithdrawMethod,
    deleteWithdrawMethod,
    updateWithdrawMethod
}