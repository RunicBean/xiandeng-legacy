// import {$axiosBack} from "@/api/client.ts";
import { useAxiosRequest } from "@/composables/client";

import type {StudentForm, StudentGaokaoScoreForm, StudentMbtiForm} from "@/models/signup.ts";

interface Student {
    accountid: string | null; // NullUUID 可以为 string | null
    userid: string;           // UUID 应该是一个 string
    accountname: string;
    phone: string;            // 普通字符串
    email?: string;           // 可选的字符串，使用 ? 表示该属性可能不存在
    nickname: string;         // 只要是简单字符串，就直接是 string 类型
    firstname?: string;       // 可选的字符串
    lastname?: string;        // 可选的字符串
    sex: string;              // 使用枚举类型 Gender
    avatarurl?: string;       // 可选的字符串
    university?: string;      // 可选的字符串
    createdat: Date | string; // 可以是 Date 对象或 ISO 格式的字符串
}

function getStudentFullname(s: Student | undefined) {
    if (!s) return ""
    if (!s.lastname || !s.firstname) {
        return ""
    }
    return s.lastname + s.firstname
}

interface ListStudentResponse {
    data: Array<Student>
}

async function listMyInvitedStudent(searchString?: string) {
    const res = await useAxiosRequest({
        method: "get",
        url: "/student/list",
        params: {
            current_account: true,
            search_string: searchString
        }
    })
    return res.data
}

async function searchUniversity(nameLike: string) {
    const res = await useAxiosRequest({
        method: "get",
        url: "/student/university/search",
        params: {
            namelike: nameLike
        }
    })
    return res.data
}

async function isUniversityGraduateEligible(schoolName: string) {
    const res = await useAxiosRequest({
        method: "get",
        url: "/student/university/eligible",
        params: {
            schoolname: schoolName
        }
    })
    return res.data
}


class SearchStudentBody {
    surveycompleted?: boolean;
    accountname?: string;
    email?: string;
    phone?: string;
    createdatfrom?: string;
    createdatto?: string;
    upstreamaccount?: string;
}

async function searchStudent(body: SearchStudentBody) {
    return await useAxiosRequest({
        method: "post",
        url: "/student/search",
        data: body
    })
}

interface StudentDetail {
    studentid: string;
    agentid: string;
    studentname: string;
    studentphone: string;
    studentwechatname: string;
    studentemail: string;
    guardianwechatname: string;
    guardianphone: string;
    guardianemail: string;
    relationship: string;
    createdat: string;
    purchasedproduct: Array<string>;
    tags: Array<string>;
}

interface ListStudentDetailsResponse {
    studentdetails: Array<StudentDetail>;
}

async function listStudentDetails(headQuarter?: boolean) {
    let params = headQuarter ? {
        head_quarter: headQuarter
    } : {};
    return await useAxiosRequest({
        method: "get",
        url: "/student/detail/list",
        params
    })
}

async function listStudentDetailsByReferral() {

    return await useAxiosRequest({
        method: "get",
        url: "/student/detail/list/referral",
    })
}

async function listStudentForPlanning(headQuarter?: boolean) {
    let params = headQuarter ? {
        head_quarter: headQuarter
    } : {};
    return await useAxiosRequest({
        method: "get",
        url: "/student/list/for-planning",
        params
    })
}

async function listStudentForPlanningByReferral() {

    return await useAxiosRequest({
        method: "get",
        url: "/student/list/for-planning/referral",
    })
}

async function updateStudentProfile(infoForm: StudentForm, mbtiForm: StudentMbtiForm, gaokaoForm: StudentGaokaoScoreForm) {
    return await useAxiosRequest({
        method: "post",
        url: "/student/update",
        data: {
            firstname: infoForm.firstname,
            lastname: infoForm.lastname,
            sex: infoForm.sex,
            university: infoForm.university,
            majorcode: infoForm.major,
            majortype: infoForm.majorType,
            entrydate: infoForm.entryDate,
            degreeyears: infoForm.degreeYears,
            mbtiForm,
            gaokaoForm,
        },
        headers: {
            "Content-Type": "application/json"
        }
    })
}

async function getStudentAttr(accountId: string) {
    return await useAxiosRequest({
        method: "get",
        url: "/student/accountid/" + accountId
    })
}

async function genStudySuggestion() {
    return await useAxiosRequest({
        method: "post",
        url: "/student/study_suggestion/update"
    })
}

export {listStudentDetails};
export {listStudentDetailsByReferral};
export {type ListStudentDetailsResponse};
export {listStudentForPlanning};
export {listStudentForPlanningByReferral};
export {type StudentDetail};
export {searchStudent};
export {SearchStudentBody};
export {listMyInvitedStudent};
export {type ListStudentResponse};
export {getStudentFullname};
export {type Student};
export {updateStudentProfile};
export {getStudentAttr};

export {genStudySuggestion};
export {searchUniversity};
export {isUniversityGraduateEligible};
