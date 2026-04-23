import {useAxiosRequest} from "@/composables/client.ts";

const getOrgMetadata = async (orgUri: string) => {
    return await useAxiosRequest({
        method: "get",
        url: `/resource/org/${orgUri}/metadata`
    })
}

export {
    getOrgMetadata
}