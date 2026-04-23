// import {$axiosBack} from '../client';

import { useAxiosRequest } from "@/composables/client";

interface Coupon {
    code: number
    discountamount: number
    agentid: string; // UUIDs 可以表示为 string.
    issuinguser: string; // UUIDs 可以表示为 string.
    maxcount?: number | null; // 可选的 int32, 可以为 number, null 或 omitted.
    productid: string | null; // NullUUID 能表示为 string 或 null.
    studentid: string | null; // NullUUID 能表示为 string 或 null.
    effectstartdate: Date | string; // 代表日期, 可以用 Date 对象或者 ISO 字符串.
    effectduedate: Date | string; // 代表日期, 可以用 Date 对象或者 ISO 字符串.
    createdat: Date | string; // 代表时间戳, 可以是 Date 对象或者 ISO 字符串.
    usedat?: Date | string | null; // 可选的时间戳, 可以是 Date, string 或 null.
}

interface CouponSearchQuery {
    cur_agent: boolean;
    product_ids?: Array<string>;     // '?' 表示该属性是可选的
    student_ids?: Array<string>;     // 使用 'string | null' 也是可以的，依据实际需要来选择
    issuing_user_ids?: Array<string>;
    discount_amount?: number;
    agent_id?: string;
    valid_only?: boolean;
    expired_only?: boolean;
    created_at: string;
    created_at_start?: string;
    created_at_end?: string;
    code?: number;
    max_count?: number;
}

interface CouponSearchResponse {
    data: Array<Coupon>
    total: number
}

async function searchCoupon(params: CouponSearchQuery) {
    return await useAxiosRequest({
        url: "/coupon/search",
        method: "get",
        params
    })
}


async function getCoupon(code: string) {
    return await useAxiosRequest({
        url: "/coupon/" + code,
        method: "get"
    })
}

class CreateCouponBody {
    discountamount: string = ""
    maxcount: number = 0
    productid: string = ""
    studentid: string = ""
    effectstartdate: string = ""
    effectduedate: string = ""
}

async function createCoupon(form: CreateCouponBody) {
    return await useAxiosRequest({
        url: "/coupon/create",
        method: "post",
        data: form,
        headers: {
            "Content-Type": "application/json"
        }
    })
}

export {createCoupon};
export {CreateCouponBody};
export {getCoupon};
export {searchCoupon};
export {type CouponSearchResponse};
export {type CouponSearchQuery};
export {type Coupon};