<template>
    <div>
        <AssociatePlanningReport v-if="isAssociate" :report-data="reportData" :is-graduate-eligible="isGraduateEligible" />
        <BachelorPlanningReport v-if="isBachelor" :report-data="reportData" :is-graduate-eligible="isGraduateEligible" />
    </div>
</template>

<script setup lang="ts">
import type {PlanningReportData} from "@/api/request/service.ts";
import {computed} from "vue";
import AssociatePlanningReport from "@components/common_components/planning/AssociatePlanningReport.vue";
import BachelorPlanningReport from "@components/common_components/planning/BachelorPlanningReport.vue";


const props = defineProps<{
    reportData?: PlanningReportData,
    isGraduateEligible: boolean
}>()

// 区分ASSOCIATE / BACHELOR
const isAssociate = computed(() => {
    if (!props.reportData) {return false}
    else {
        return props.reportData.degree === "ASSOCIATE"
    }
})

const isBachelor = computed(() => {
    if (!props.reportData) {return false}
    else {
        return props.reportData.degree === "BACHELOR"
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
    width: 70%;
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


span.kw {
    color: red;
    font-weight: 600;
}
</style>
