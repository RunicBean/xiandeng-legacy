import { useProfileStore } from "@/stores/profile";
import { prefixUrl, wsPrefixUrl } from "../helpers/common";

function newWebsocketClient(path: string) {

  return new WebSocket(`${wsPrefixUrl}/ws/api/v1` + path)
}

import axios, {AxiosRequestConfig, InternalAxiosRequestConfig} from "axios";
import {usePermissionStore} from "@/stores/permission.ts";

let baseUrl = `${prefixUrl}/server/api/v1`

const $axiosBack = axios.create({
    baseURL: baseUrl,
    timeout: 99999,
    // headers: {
    //     "TRACE_ID": profileStore.sessionId
    // }
})

$axiosBack.interceptors.response.use(
    response => {
        // console.log(response.data);
        return response.data
    },
    error => {
        // switch (error.response.status) {
        //     case 500:
        //         console.log(error.response.data);
        //         break
        //     case 403:
        //         console.log(error.response.data);
        //         break
        //     case 401:
        //         console.log(error.response.data);
                
        // }
        throw error
    }
)

function useAxiosRequest(config: AxiosRequestConfig<any>) {
    const profileStore = useProfileStore()
    const permitStore = usePermissionStore()

    function defineConfig(config: InternalAxiosRequestConfig) {
        config.headers.Traceid = profileStore.sessionId
        if (permitStore.requireRole) {
            config.headers.Requirerole = permitStore.requireRole
        }
        return config
    }
    $axiosBack.interceptors.request.use(
        defineConfig,
        error => {
            return error
        },
    )
    return $axiosBack.request(config)
}

const $blobFetcher = axios.create({
    baseURL: baseUrl,
    timeout: 99999
})




export {
    newWebsocketClient,
    // $axiosBack,
    useAxiosRequest,
    $blobFetcher,
}
