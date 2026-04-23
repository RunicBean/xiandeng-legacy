<template>
  <PlanningReport :report-data="reportData" :is-graduate-eligible="isGraduateEligible" />
</template>

<script setup lang="ts">
import {getStudentPlanningReportData, type PlanningReportData} from '@/api/request/service'
import {ref, onMounted} from 'vue'
import {useRoute, useRouter} from "vue-router";
import {isUniversityGraduateEligible} from "@/api/request/student.ts";
import {appendOrgPrefixUrl} from "@/helpers/common.ts";
import PlanningReport from "@components/common_components/planning/PlanningReport.vue";

const reportData = ref<PlanningReportData>()
const $route = useRoute()
const $router = useRouter()
const isGraduateEligible = ref(false)

onMounted(() => {
  getStudentPlanningReportData($route.params.account_id as string)
      .then((res) => {
        reportData.value = res.data
          isUniversityGraduateEligible(reportData.value?.university as string)
            .then((data) => {
                console.log(data)
                isGraduateEligible.value = data
                console.log("isGraduateEligible =>", isGraduateEligible.value)

            })
      })
      .catch(() => {
        $router.replace(appendOrgPrefixUrl("/result/unhandled_error", $route.params.org_name))
        return
      })
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
