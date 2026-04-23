// import {$axiosBack} from "../client"
import { useAxiosRequest } from "@/composables/client";


async function listDepartment() {
    return await useAxiosRequest({
        method: "get",
        url: "/aresource/department/list"
    })
}

async function listFaculty() {
    return await useAxiosRequest({
        method: "get",
        url: "/aresource/faculty/list",
    })
}

async function listDepartmentByFaculty(faculty: string) {
    return await useAxiosRequest({
        method: "get",
        url: "/aresource/department/list",
        params: {
            faculty
        }
    })
}

// StudentOnboarding 页面，获取专业
async function listMajorByDepartment(department: string) {
    return await useAxiosRequest({
        method: "get",
        url: "/aresource/major/list",
        params: {
            department
        }
    })
}

async function searchAssociateMajor(nameLike: string) {
    const result = await useAxiosRequest({
        method: "get",
        url: "/aresource/major/associate/search",
        params: {
            namelike: nameLike
        }
    })
    return result.data
}

async function searchBachelorMajor(nameLike: string) {
    const result = await useAxiosRequest({
        method: "get",
        url: "/aresource/major/bachelor/search",
        params: {
            namelike: nameLike
        }
    })
    return result.data
}

async function getPostgradSuggestion(majorCode: string) {
    return await useAxiosRequest({
        method: "get",
        url: "/aresource/postgradsuggestion/" + majorCode
    })
}

async function listGoventerprise(majorCode: string, name: string, page: number, pageSize: number) {
    return await useAxiosRequest({
        method: "get",
        url: "/aresource/goventerprise/list",
        params: {
            page,
            page_size: pageSize,
            name,
            major_code: majorCode
        }
    })
}

async function listMyQianliaoCoupon() {
    return await useAxiosRequest({
        method: "get",
        url: "/aresource/qianliaocoupon/list"
    })
}

interface RecruitMenuItem {
    citynamelist: string
    companyname: string
    logourl: string
    recruitid: number
    updatetime: string
    tag?: string
}
interface ListRecruitMenuResponse {
    data: Array<RecruitMenuItem>
}
async function listRecruitMenu(start: number, size: number) {
    return await useAxiosRequest({
        method: "get",
        url: "/aresource/recruit/list",
        params: {
            start,
            size
        }
    })
}

interface RecruitDetail {
    begintime: string
    browsecount: number | null
    citynamelist: string
    companyname: string
    companytype: string
    content: string
    createtype: number | null
    domesticstudent: string
    endtime: string | null
    enterprisename: string
    favoritecount: number | null
    id: number
    isrecommended: boolean | null
    logourl: string
    overseasstudent: string
    recruitid: number
    releasesource: string
    sharecount: number | null
    tag: string | null
    updatetime: string
    url: string
}

interface GetRecruitDetailResponse {
    data: RecruitDetail
}
async function getRecruitDetail(recruitId: number) {
    return await useAxiosRequest({
        method: "get",
        url: `/aresource/recruit/${recruitId}`,
    })
}

async function getTermsOverallSignedUrl() {
    return await useAxiosRequest({
        method: "get",
        url: "/resource/terms/overall/url"
    })
}

export {
    listDepartment,
    listFaculty,
    listDepartmentByFaculty,
    getPostgradSuggestion,
    listGoventerprise,

    listMajorByDepartment,
    searchAssociateMajor,
    searchBachelorMajor,

    listMyQianliaoCoupon,
    listRecruitMenu,
    type ListRecruitMenuResponse,
    type RecruitMenuItem,

    getRecruitDetail,
    type GetRecruitDetailResponse,
    type RecruitDetail,
    getTermsOverallSignedUrl,




}
