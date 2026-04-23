import { WithdrawType } from "@/models/withdraw";
// import { $axiosBack } from '@/api/client.ts';
import { useAxiosRequest } from "@/composables/client";


async function createWithdraw(
    withdrawMethodId: string|null,
    withdrawType: WithdrawType,
    amount: number
) {
    
    return await useAxiosRequest({
        url: `/withdraw/create`,
        method: "post",
        data: {
            current_user: true,
            withdraw_method_id: withdrawMethodId,
            withdraw_type: withdrawType,
            amount: amount
        }
    })
}

interface ListWithdrawQuery {
    current_user?: boolean
    user_id?: string
    account_id?: string
    withdraw_type?: WithdrawType
    status?: string
    created_at_start?: string
    created_at_end?: string
    amount_low?: number
    amount_high?: number
}
async function listWithdraws(query: ListWithdrawQuery) {
    const resp = await useAxiosRequest({
        url: `/withdraw/list`,
        method: "get",
        params: query
    })
    return resp.data
}

export {
    createWithdraw,
    listWithdraws,
    type ListWithdrawQuery
}