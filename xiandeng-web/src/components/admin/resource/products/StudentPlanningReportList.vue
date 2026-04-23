<template>
    <div>
        <h1>规划报告</h1>

        <a-table :data-source="students" :columns="columns" stripe border>
          <template #bodyCell="{ column, record }">
            <template v-if="column.key === 'createdat'">
              {{ dayjs(record.createdat).format("YYYY-MM-DD") }}
            </template>
            <template v-else-if="column.key === 'purchased'">
              <a-tag type="success" v-if="record.purchased">已授权</a-tag>
              <a-tag type="danger" v-else>未授权</a-tag>
            </template>
            <template v-else-if="column.key === 'filled'">
              <a-tag type="success" v-if="record.filled">已填写</a-tag>
              <a-tag type="danger" v-else>未填写</a-tag>
            </template>
            <template v-else-if="column.key === 'generated'">
              <a-tag type="warning" v-if="record.generated == 'pending'">生成中</a-tag>
              <a-tag type="success" v-else-if="record.generated">就绪</a-tag>
              <a-tag type="danger" v-else>无</a-tag>
            </template>
            <template v-else-if="column.key === 'report'">
              <a-button
                  type="primary"
                  size="small"
                  @click="openPlanningDetailPage(record.studentid)"
                  :disabled="!record.purchased || !record.filled || record.generated != 'done'"
              >进入</a-button>
            </template>
          </template>
        </a-table>
    </div>
</template>

<script setup lang="ts">
import {ref, onMounted} from 'vue'
import dayjs from 'dayjs';
import {listStudentForPlanning} from "@/api/request/student.ts";
import {useRoute, useRouter} from 'vue-router';
import {appendOrgPrefixUrl} from "@/helpers/common.ts";
const $router = useRouter()
const $route = useRoute()

// const searchStudentForm = ref<SearchStudentBody>(new SearchStudentBody)
//
// const createDate = ref("")
// function changeCreateDates(value: Array<Date>|null) {
//     if (value == null) {
//         clearCreateDates()
//         return
//     }
//     searchStudentForm.value.createdatfrom = dayjs(value[0]).format("YYYY-MM-DD")
//     searchStudentForm.value.createdatto = dayjs(value[1]).format("YYYY-MM-DD")
// }
//
// function clearCreateDates() {
//     createDate.value = ""
//     searchStudentForm.value.createdatfrom = ""
//     searchStudentForm.value.createdatto = ""
// }
//
// const filteredStudents = computed(() => {
//     return students.value
// })

const students = ref([])
function runSearch() {
    listStudentForPlanning().then(res => {
        console.log(res)
        students.value = res.data
    })
}

onMounted(() => {
    runSearch()
})

const columns = [
    {
        key: "createdat",
        dataIndex: "createdat",
        title: "创建时间"
    },
    {
        key: "studentname",
        dataIndex: "studentname",
        title: "学生姓名"
    },
    {
        key: "purchased",
        dataIndex: "purchased",
        title: "授权"
    },
    {
        key: "filled",
        dataIndex: "filled",
        title: "填写状态"
    },
    {
        key: "generated",
        dataIndex: "generated",
        title: "报告状态"
    },
    {
        key: "report",
        dataIndex: "report",
        title: "报告页"
    }
]

function openPlanningDetailPage(studentId: string) {

  const routeData = $router.resolve(appendOrgPrefixUrl(`/planning-report-detail/${studentId}`, $route.params.org_name))
  window.open(routeData.href, '_blank');
}
</script>

<style scoped>

</style>
