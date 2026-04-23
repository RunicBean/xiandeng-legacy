<template>
    <PlanningReport :report-data="reportData" :is-graduate-eligible="isGraduateEligible" />
</template>

<script setup lang="ts">
import {AccountType} from '@/models/account'
import { useRequest } from 'vue-request';
import {
    getStudentPlanningPrecheckData,
    getStudentPlanningReportData,
    type PlanningReportData
} from '@/api/request/service'
import { useRouter } from 'vue-router';
import {ref} from 'vue'
import { useProfileStore } from '@/stores/profile';
import {genStudySuggestion, isUniversityGraduateEligible} from "@/api/request/student.ts";
import {isUserGuardian, UserRoleType} from "@/models/user.ts";
import {appendOrgPrefixUrl} from "@/helpers/common.ts";
import PlanningReport from "@components/common_components/planning/PlanningReport.vue";

const profileStore = useProfileStore()
const $router = useRouter()
const reportData = ref<PlanningReportData>()
const isGraduateEligible = ref(false)

useRequest(getStudentPlanningPrecheckData, {
    defaultParams: [profileStore.roleData?.accountid],
    onSuccess: async (res) => {
        reportData.value = res.data


        if (reportData.value?.major == "" || !reportData.value?.major) {
          if (isUserGuardian(profileStore.roleData?.usertype as UserRoleType)) {
            $router.replace(appendOrgPrefixUrl('/result/guardian_to_planning_page', profileStore.orgMetadata?.uri))
            return
          }
          alert("请先填写完成问卷，正在跳转...")
          $router.replace(appendOrgPrefixUrl('/oa/onboarding', profileStore.orgMetadata?.uri))
          return
        } else {
          // 问卷已完成但就读建议为空，生成报告
          if (reportData.value?.genstudysuggestion == "" || !reportData.value?.genstudysuggestion) {
            await genStudySuggestion()
            $router.replace(appendOrgPrefixUrl('/result/generating_studysuggestion', profileStore.orgMetadata?.uri))
            return
          } else {
            // 报告正在生成
            if (reportData.value?.genstudysuggestion == "pending") {
              $router.replace(appendOrgPrefixUrl('/result/generating_studysuggestion', profileStore.orgMetadata?.uri))
              return
            }
          }

        }

        if (reportData.value?.accounttype != AccountType.STUDENT) {
            $router.replace(appendOrgPrefixUrl('/result/not_in_service', profileStore.orgMetadata?.uri))
            return
        }

        await getStudentPlanningReportData(profileStore.roleData?.accountid)
            .then(res => {
                reportData.value = res.data
            })

        await isUniversityGraduateEligible(reportData.value?.university as string)
            .then((data) => {
                console.log(data)
                isGraduateEligible.value = data
                console.log("isGraduateEligible =>", isGraduateEligible.value)

            })
    }
})
</script>

<style scoped>
/* table, td {
    border: 1px solid;
} */
td {
    background-color: #c9ecff;
}
table {
    border-collapse: separate;
}

.report > p {
    width: 70%;
    margin: auto;
    white-space: pre-line;
    line-height: 2rem;
    text-indent: 2rem;


}

.report >p >b {
        color: #2d7aa4;
    }

.report > .custom-image {
    width: 80%;
    margin: auto;
}

.report > h3 {
    margin-top: 2rem;
}

.report > h4,h5 {
    margin-top: 1rem;
}

span.kw {
    color: red;
    font-weight: 600;
}
</style>
