<template>
    <div>
        <h1>学员管理</h1>
        <a-table :data-source="students" :columns="columns" border stripe>
            <template #bodyCell="{column, record}">
                <template v-if="column.key === 'createdat'">
                    {{ dayjs.tz(record.createdat, "Asia/Shanghai").format('YYYY-MM-DD') }}
                </template>
                <template v-else-if="column.key === 'purchasedproduct'">
                    <a-tag v-for="item in record.purchasedproduct" :key="item" type="success" size="default" effect="dark">{{item}}</a-tag>
                </template>
                <template v-else-if="column.key === 'tags'">
                    <a-tag v-for="item in record.tags" :key="item" type="primary" size="default" effect="dark">{{item}}</a-tag>
                </template>
            </template>
        </a-table>

    </div>


</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue';
// import { FormInstance } from 'element-plus';
import timezone from 'dayjs/plugin/timezone'
import utc from 'dayjs/plugin/utc'
import dayjs from 'dayjs'
import {listStudentDetails, StudentDetail} from "@/api/request/student.ts";

dayjs.extend(utc)
dayjs.extend(timezone)

const students = ref<Array<StudentDetail>>([])
onMounted(async () => {
    const res = await listStudentDetails()
    students.value = res.data
})
const columns = [
    // {
    //     id: "studentid",
    //     label: "学生ID",
    //     width: 0
    // },
    {
        key: "studentname",
        dataIndex: "studentname",
        title: "学生姓名",
        width: 0
    },
    {
        key: "studentphone",
        dataIndex: "studentphone",
        title: "手机号",
        width: 0
    },
    {
        key: "studentwechatname",
        dataIndex: "studentwechatname",
        title: "微信名",
        width: 0
    },
    {
        key: "guardianphone",
        dataIndex: "guardianphone",
        title: "手机号(家长)",
        width: 0
    },
    {
        key: "guardianwechatname",
        dataIndex: "guardianwechatname",
        title: "微信名(家长)",
        width: 0
    },
    {
        key: "relationship",
        dataIndex: "relationship",
        title: "关系(家长)",
        width: 0
    },
    {
        key: "createdat",
        dataIndex: "createdat",
        title: "注册时间",
    },
    {
        key: "purchasedproduct",
        dataIndex: "purchasedproduct",
        title: "已购商品",
    },
    {
        key: "tags",
        dataIndex: "tags",
        title: "标签",
    }
]

</script>

<style scoped>

</style>
