// import {$axiosBack} from "@/api/client.ts";
import { useAxiosRequest } from "@/composables/client";


async function listShowcaseCarousel(companyName: string) {
    return await useAxiosRequest({
        method: "get",
        url: "/showcase/carousel/list",
        params: {
            company_name: companyName,
        }
    })
}

async function listShowcaseItems(companyName: string) {
    return await useAxiosRequest({
        method: "get",
        url: "/showcase/item/list",
        params: {
            company_name: companyName,
        }
    })
}

async function getCompany(companyPath: string) {
    return await useAxiosRequest({
        method: "get",
        url: "/showcase/company/" + companyPath,
    })
}


export {listShowcaseItems};
export {listShowcaseCarousel};
export {getCompany};