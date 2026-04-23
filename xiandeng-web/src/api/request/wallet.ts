
import { useAxiosRequest } from "@/composables/client";

interface Balance {
    balance: number
    pendingreturn: number
    balanceleft: number
    balanceright: number
    balancetriple: number
    balancetriplelock: number
}

async function getBalance() {
    return await useAxiosRequest({
        method: "get",
        url: "/wallet/balance",
    })
}

class BalanceActivitySearchQuery {
    createdat_start?: string
    createdat_end?: string
    source?: string
    price_range_start?: number
    price_range_end?: number
    product_list?: Array<string>
    id?: string
}

async function listBalanceActivity(query: BalanceActivitySearchQuery) {
    return await useAxiosRequest({
        method: "post",
        url: "/wallet/balanceactivity/list",
        data: query,
        headers: {
            "Content-Type": "application/json"
        }
    })
}

async function listMyBalanceActivity(query: BalanceActivitySearchQuery) {
    return await useAxiosRequest({
        method: "post",
        url: "/wallet/mybalanceactivity/list",
        data: query,
        headers: {
            "Content-Type": "application/json"
        }
    })
}

async function listTripleAwardDetails() {
    const res = await useAxiosRequest({
        method: "get",
        url: "/wallet/trippleaward/list",
        headers: {
            "Content-Type": "application/json"
        }
    })
    return res.data
}

async function listTripleUnlockDetails(sourceId: string) {
    const res = await useAxiosRequest({
        method: "get",
        url: "/wallet/trippleunlock/" + sourceId,
        headers: {
            "Content-Type": "application/json"
        }
    })
    return res.data
}

function exportMyBalanceActivity(query: BalanceActivitySearchQuery) {
    return useAxiosRequest({
        method: "post",
        url: "/wallet/mybalanceactivity/export",
        data: query,
        headers: {
            "Content-Type": "application/json",
        },
        responseType: 'blob'
    })
}

async function getOngoingWithdraw() {
    const resp = await useAxiosRequest({
        method: "get",
        url: "/wallet/withdraw/ongoing",
    })
    return resp.data;
}

export {listMyBalanceActivity};
export {listBalanceActivity};
export {exportMyBalanceActivity};
export {type Balance};
export {BalanceActivitySearchQuery};
export {getBalance};
export {getOngoingWithdraw};
export {listTripleAwardDetails};
export {listTripleUnlockDetails};