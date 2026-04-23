// import { $axiosBack } from "../client";
import { useAxiosRequest } from "@/composables/client";


async function revokePayment(orderId: number, retainEnt: boolean) {
    try {
        const res = await useAxiosRequest({
            method: 'post',
            url: '/payment/revoke',
            data: {
                order_id: orderId,
                retain_entitlement: retainEnt
            }
        })
        return res.data
    }
    catch (e) {
        throw e
    }
}

export {
    revokePayment
}