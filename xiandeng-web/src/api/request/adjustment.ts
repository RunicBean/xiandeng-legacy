import { useAxiosRequest } from "@/composables/client";

export interface AdjustmentForm {
    account_id: string;
    amount: string;
    balance_type: string;
    notes: string;
}

export interface AdjustmentRecord {
    createdat: string;
    accountname?: string;
    balancetype?: string;
    amount: string;
    balanceafter?: string;
    notes: string;
    nickname?: string;
}

// API响应类型定义
export interface ApiResponse<T = any> {
    errorCode: number;
    message: string;
    data: T;
    success: boolean;
    total: number;
}

export const BALANCE_TYPE_OPTIONS = [
    { label: '余额', value: 'balance' },
    { label: '左区余额', value: 'balanceleft' },
    { label: '右区余额', value: 'balanceright' },
    { label: '剩余意向金', value: 'pendingreturn' },
    { label: '三单循环(未解锁)', value: 'balancetriplelock' },
    { label: '三单循环(已解锁)', value: 'balancetriple' }
];

async function insertAdjustment(data: AdjustmentForm) {
    return await useAxiosRequest({
        method: "post",
        url: "/adjustment/insert",
        data: data,
        headers: {
            "Content-Type": "application/json"
        }
    });
}

async function listAdjustmentRecords() {
    return await useAxiosRequest({
        method: "get",
        url: "/adjustment/list",
        headers: {
            "Content-Type": "application/json"
        }
    });
}

export { insertAdjustment, listAdjustmentRecords }; 