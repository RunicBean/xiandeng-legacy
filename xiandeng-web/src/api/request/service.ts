// import {$axiosBack} from "../client"
import { useAxiosRequest } from "@/composables/client";


async function getStudentPlanningReportData(accountId?: string) {
    const suffix = accountId ? "/" + accountId : ""
    return await useAxiosRequest({
        method: "get",
        url: "/aresource/planning-report/get-data" + suffix,
    })
}

async function getStudentPlanningPrecheckData(accountId?: string) {
    const suffix = accountId ? "/" + accountId : ""
    return await useAxiosRequest({
        method: "get",
        url: "/aresource/planning-report/get-precheck-data" + suffix,
    })
}


interface PlanningReportData {
    firstname: string
    lastname: string
    sex: string
    university: string
    major: string
    genstudysuggestion: string
    studyingsuggestion: string
    majorreference: string
    charactersuggestion: string
    degree: string
    core_course_learning: string
    practical_skill_development: string
    skill_expansion: string
    mbtitype: string
    accounttype: string
    universitylogo: string
    isgraduateeligible: boolean
    uniremark: string
    entry_date: string
    total_score: number
    chinese: number
    mathematics: number
    foreign_language: number
    physics: number
    chemistry: number
    biology: number
    politics: number
    history: number
    geography: number
    // type: {
    //     entitytype: string
    // }
}


export {
    getStudentPlanningReportData,
    getStudentPlanningPrecheckData,
    type PlanningReportData,

}
