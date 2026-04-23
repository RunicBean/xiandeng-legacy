// import { $axiosBack } from '@/api/client.ts';
import { useAxiosRequest } from "@/composables/client";


async function listDelivery(status: string) {
    const res = await useAxiosRequest({
        url: "/delivery/list",
        method: "get",
        params: {
            status
        }
    })
    return res.data
}

async function confirmDelivery(deliveryId: string) {
    const res = await useAxiosRequest({
        url: "/delivery/confirm",
        method: "post",
        data: {
            delivery_id: deliveryId
        }
    })
    return res.data
}

export {
    listDelivery,
    confirmDelivery
}
