// import { $axiosBack } from '@/api/client.ts';
import { useAxiosRequest } from "@/composables/client";

import { InventoryOrderType } from '@/models/inventory';

// async function listDelivery(status: string) {
//     const res = await useAxiosRequest({
//         url: "/delivery/list",
//         method: "get",
//         params: {
//             status
//         }
//     })
//     return res.data
// }

async function createInventoryOrder(productId : string, quantity: number, inventoryOrderType: InventoryOrderType) {
    const res = await useAxiosRequest({
        url: "/inventory/order/create",
        method: "post",
        data: {
            product_id: productId,
            quantity,
            order_type: inventoryOrderType
        }
    })
    return res.data
}

async function listInventory() {
    const res = await useAxiosRequest({
        url: "/inventory/list",
        method: "get",
        params: {
            current_user: true
        }
    })
    return res.data
}

async function getMaxInventoryQuantity(productId: string) {
    const res = await useAxiosRequest({
        url: "/inventory/max_quantity",
        method: "get",
        params: {
            current_user: true,
            product_id: productId
        }
    })
    return res.data
}

async function updateInventoryOrderPaymentMethod(inventoryId: string, paymentMethod: string) {
    const res = await useAxiosRequest({
        url: `/inventory/order/${inventoryId}/update`,
        method: "post",
        data: {
            payment_method: paymentMethod
        }
    })
    return res.data
}

async function confirmInventoryOrder(inventoryId: string) {
    const res = await useAxiosRequest({
        url: `/inventory/order/${inventoryId}/confirm`,
        method: "post"
    })
    return res.data
}

async function updateInventoryOrderStatus(inventoryId: string, status: string) {
    const res = await useAxiosRequest({
        url: `/inventory/order/${inventoryId}/status/update`,
        method: "post",
        data: {
            status
        }
    })
    return res.data
}

async function getInventoryAcitivities() {
    const res = await useAxiosRequest({
        url: "/inventory/activities",
        method: "get",
        params: {
            current_user: true
        }
    })
    return res.data
}

async function getInventoryCourseOrders() {
    const res = await useAxiosRequest({
        url: "/inventory/course_orders",
        method: "get",
        params: {
            current_user: true
        }
    })
    return res.data
}

async function listInventoriesForHQ() {
    const res = await useAxiosRequest({
        url: "/inventory/list_for_hq",
        method: "get"
    })
    return res.data
}

export {
    createInventoryOrder,
    listInventory,
    getMaxInventoryQuantity,
    updateInventoryOrderPaymentMethod,
    getInventoryAcitivities,
    getInventoryCourseOrders,
    updateInventoryOrderStatus,
    listInventoriesForHQ,
    confirmInventoryOrder,
}
