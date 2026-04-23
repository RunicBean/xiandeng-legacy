// import { $axiosBack } from "../client";
import { useAxiosRequest } from "@/composables/client";


function logMessage(message: string) {
    return useAxiosRequest({
        url: "/system/log_message",
        method: "post",
        data: {
            message
        },
        headers: {
            "Content-Type": "application/json"
        }
    })
}

function logCommonMessage(message: string) {
    return useAxiosRequest({
        url: "/system/log_common_message",
        method: "post",
        data: {
            message
        },
        headers: {
            "Content-Type": "application/json"
        }
    })
}

async function uploadOrderProof(orderId: number, formData: FormData) {
    await useAxiosRequest({
        url: `/system/order/proof/${orderId}`,
        method: "post",
        data: formData,
        headers: {
            'Content-Type': 'multipart/form-data'
        }
    })
    .then((res) => {
        return res.data
    })
    .catch((err) => {
        throw err
    })
}

async function listOrderProof(orderId: number) {
    return useAxiosRequest({
        url: `/system/order/proof/${orderId}`,
        method: "get"
    })
    .then((res) => {
        return res.data
    })
    .catch((err) => {
        throw err
    })
}

async function getWording(namespace: string) {
    const resp = await useAxiosRequest({
        url: "/system/wording-map/" + namespace,
    })
    return resp.data
}

export {
    logMessage,
    logCommonMessage,
    uploadOrderProof,
    listOrderProof,
    getWording
}