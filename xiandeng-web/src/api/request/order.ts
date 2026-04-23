// import {$axiosBack} from "@/api/client.ts";
import { useAxiosRequest } from "@/composables/client";


interface ProductCouponPair {
    id: string
    coupon_code: string
}

async function createOrder(productCouponPairs: Array<ProductCouponPair>, generalCouponCode: string) {
    return await useAxiosRequest({
        url: "/order/create",
        method: "post",
        data: {
            "product_coupon_pairs": productCouponPairs,
            "general_coupon_code": generalCouponCode
        },
        headers: {
            "Content-Type": "application/json"
        }
    })
}

async function generateSimpleOrderWithPaymentMethod(productId: string, paymentMethod: string, currentUser?: boolean, studentId?: string) {
    const res = await useAxiosRequest({
        url: "/order/simple_w_pm/create",
        method: "post",
        data: {
            "current_user": currentUser,
            "student_id": studentId,
            "product_id": productId,
            "payment_method": paymentMethod
        },
        headers: {
            "Content-Type": "application/json"
        }
    })
    return res.data
}

class BodySearchOrders {
    agent_name?: string
    price_range_end?: number
    price_range_start?: number
    product_name?: string
    student_name?: string
    updateat_end?: string
    updateat_start?: string
    payment_method?: string
    status_list?: Array<string>
}

interface SearchOrderResult {
    orderid: number
    updatetime: string
    paymentmethod: string
    price: string
    studentname: string
    agentname: string
    productlist: Array<string>
    status: string
}

async function searchOrders(body: BodySearchOrders) {
    return await useAxiosRequest({
        url: "/order/search",
        method: "post",
        data: body,
        headers: {
            "Content-Type": "application/json"
        }
    })
}

interface BodyUpdateOrder {
    payment_method_do_update: boolean
    payment_method?: string
    payment_method_update_null: boolean
    status_do_update: boolean
    status?: string
    updatedat_to_now: boolean
    order_id: number
}

async function updateOrder(body: BodyUpdateOrder) {
    return await useAxiosRequest({
        url: "/order/update",
        method: "post",
        data: body,
        headers: {
            "Content-Type": "application/json"
        }
    })
}



async function confirmOfflineOrder(orderId: number, paymentMethod: string, revokePay: boolean, forceSettle?:boolean) {
    return await useAxiosRequest({
        url: "/order/confirm",
        method: "post",
        data: {
            "order_id": orderId,
            "payment_method": paymentMethod,
            "revoke_pay": revokePay,
            "force_settle": forceSettle ? true : false
        },
        headers: {
            "Content-Type": "application/json"
        }
    })
}

async function declineOfflineOrder(orderId: number) {
    return await useAxiosRequest({
        url: "/order/decline",
        method: "post",
        data: {
            "order_id": orderId,
        },
        headers: {
            "Content-Type": "application/json"
        }
    })
}

async function simpleDeclineOrder(orderId: number) {
    return await useAxiosRequest({
        url: "/order/decline/simple",
        method: "post",
        data: {
            "order_id": orderId,
        },
        headers: {
            "Content-Type": "application/json"
        }
    })
}

async function updateOrderPrice(orderId: number, price: string) {
    return await useAxiosRequest({
        url: "/order/price/update",
        method: "post",
        data: {
            "order_id": orderId,
            "actual_price": price,
        },
        headers: {
            "Content-Type": "application/json"
        }
    })
}

async function listLiuliustatements(orderId: number) {
    const res = await useAxiosRequest({
        url: "/order/liuliustatements",
        method: "get",
        params: {
            "order_id": orderId
        }
    })
    return res.data
}

async function paySuccess(orderId: number) {
    return await useAxiosRequest({
        url: "/order/pay_success",
        method: "post",
        data: {
            "order_id": orderId
        },
        headers: {
            "Content-Type": "application/json"
        }
    })
}

async function listRestrictedOrders() {
    const res = await useAxiosRequest({
        url: "/order/restricted/list",
        method: "get",
    })
    return res.data
}

async function listRestrictedOrdersByReferral() {
    const res = await useAxiosRequest({
        url: "/order/restricted/list/by_referral",
        method: "get",
    })
    return res.data
}

async function batchSetOrderTags(orderIds: (string|number)[], tags: string[]) {
    return await useAxiosRequest({
        url: "/order/tags",
        method: "post",
        data: {
            "order_ids": orderIds,
            "tags": tags
        },
        headers: {
            "Content-Type": "application/json"
        }
    })
}

async function deleteOrderTags(orderIds: (string|number)[]) {
    return await useAxiosRequest({
        url: `/order/tags/delete`,
        method: "post",
        data: {
            "order_ids": orderIds
        },
        headers: {
            "Content-Type": "application/json"
        }
    })
}

export {confirmOfflineOrder};
export {declineOfflineOrder};
export {updateOrder};
export {searchOrders};
export {type SearchOrderResult};
export {BodySearchOrders};
export {createOrder};
export {listLiuliustatements};
export {paySuccess};
export {generateSimpleOrderWithPaymentMethod};
export {simpleDeclineOrder};
export {updateOrderPrice};
export {listRestrictedOrders};
export {listRestrictedOrdersByReferral};
export {batchSetOrderTags};
export {deleteOrderTags};
