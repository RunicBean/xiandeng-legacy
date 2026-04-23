// import {$axiosBack} from "@/api/client.ts";
import { useAxiosRequest } from "@/composables/client";


async function createPrepay(orderNumber: number) {
    return await useAxiosRequest({
        url: "/wechatpay/prepay/create",
        method: "post",
        data: {
            "order_number": orderNumber,
        },
        headers: {
            "Content-Type": "application/json"
        }
    })
}

async function closePayment(orderId: number) {
    return await useAxiosRequest({
        url: "/wechatpay/payment/close",
        method: "post",
        data: {
            "order_id": orderId
        },
        headers: {
            "Content-Type": "application/json"
        }
    })
}

async function confirmPayment(orderId: number) {
    return await useAxiosRequest({
        url: "/wechatpay/order/confirm",
        method: "post",
        data: {
            "order_id": orderId
        },
        headers: {
            "Content-Type": "application/json"
        }
    })
}

export {confirmPayment};
export {closePayment};
export {createPrepay};