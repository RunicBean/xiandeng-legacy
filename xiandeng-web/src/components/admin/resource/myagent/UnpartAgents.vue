<template>
    <div>
        <!-- 未分区代理 -->
        <a-card shadow="always" :body-style="{ padding: '20px' }">
            <template #title>
            <div>
                <span>未分区代理</span>
            </div>
            </template>
            <a-table :data-source="unpartData" border stripe :columns="columns" :scroll="{ x: 1000 }">
                <!-- <template #bodyCell="{column, record}">

                </template> -->
            </a-table>
        </a-card>
        
        <!-- 确认对话框 -->
        <a-modal
            v-model:open="partitionDialogVisible"
            title="确认分区"
            width="500"
        >
            <a-alert message="请注意!" type="warning">
                <template #description>
                    <div class="mt-4">提交分区后不可修改，请仔细核实！</div>
                </template>
            </a-alert>

            
            <a-divider direction="horizontal" content-position="left"></a-divider>
            
            <a-descriptions bordered :label-style="{width: '50%'}" :column="1" class="font-bold">
                <a-descriptions-item label="代理名">
                    {{ selectedRow.accountname }}
                </a-descriptions-item>
                <a-descriptions-item label="级别">
                    {{ resourceStore.entityTypeWordingMap[selectedRow.type] }}
                </a-descriptions-item>
                <a-descriptions-item label="目标分区">
                    <a-tag color="red" v-if="formattedPartitionForm == '左区'">{{ formattedPartitionForm }}</a-tag>
                    <a-tag color="blue" v-if="formattedPartitionForm == '右区'">{{ formattedPartitionForm }}</a-tag>
                </a-descriptions-item>
            </a-descriptions>
            <template #footer>
                <div class="dialog-footer">
                    <a-button @click="partitionDialogVisible = false">取消</a-button>
                    <a-button type="primary" @click="confirmUpdateAgentPartition(selectedRow.id, partitionForm)">
                    确认
                    </a-button>
                </div>
            </template>
        </a-modal>
    </div>
</template>

<script setup lang="ts">
import { listMyAgents, updateAgentPartition } from '@/api/request/agent';
import { useRequest } from 'vue-request';
import { computed, ref, h, onMounted } from 'vue';
import {Button, notification} from 'ant-design-vue'
import { useResourceStore } from '@/stores/resource';

const resourceStore = useResourceStore()

onMounted(async () => {
    await resourceStore.updateEntityTypeWordingMap()
})

const {data, run: runListMyAgents} = useRequest(listMyAgents)

const columns: Array<{
    key: string, 
    dataIndex: string, 
    title: string, 
    customRender?: ({text,record}: {text: string, record: any}) => string | VNode,
    fixed?: string,}> = [
    {key: "accountname", dataIndex: "accountname", title: "代理名"},
    {key: "status", dataIndex: "status", title: "账号状态"},
    {key: "type", dataIndex: "type", title: "等级", customRender: ({text}) => {
        // console.log(text);
        
        
        if (resourceStore.entityTypeWordingMap[text]) return resourceStore.entityTypeWordingMap[text] as string
        else return "未知"
    }},
    {key: "phone", dataIndex: "phone", title: "负责人手机号"},
    {key: "nickname", dataIndex: "nickname", title: "负责人微信昵称"},
    {key: "email", dataIndex: "email", title: "负责人邮箱"},
    {key: "partition", dataIndex: "partition", title: "分区", customRender: ({record}) => {
        console.log(record);
        
        return h('div', {class: "flex space-x-1"}, [
            h(Button, {type: 'default', disabled: record.status != 'ACTIVE', onClick: () => runPartition(record, 'L')}, [
                h('span', {class: "text-red-500"}, '左区')
            ]),
            h(Button, {type: 'default', disabled: record.status != 'ACTIVE', onClick: () => runPartition(record, 'R')}, [
                h('span', {class: "text-blue-500"}, '右区')
            ])
        ])
    }, fixed: 'right'}
]

const unpartData = computed(() => {
    return data.value?.filter((item: any) => (item.partition == null || item.partition == ""))
})

const partitionDialogVisible = ref(false)
const partitionForm = ref()
const formattedPartitionForm = computed(() => {
    switch (partitionForm.value) {
        case "L":
            return "左区"
            break;
        case "R":
            return "右区"
            break;
        default:
            return "错误"
            break;
    }
})
const selectedRow = ref()
const runPartition = (row: any, form: string) => {
    selectedRow.value = row
    partitionForm.value = form
    partitionDialogVisible.value = true
}

function reloadData() {
    runListMyAgents()
    // runListMyLeftPartitionAgents("L")
    // runListMyRightPartitionAgents("R")
}
const {run: runUpdateAgentPartition} = useRequest(updateAgentPartition, {
    manual: true,
    onSuccess: () => {
        notification.success({
            message: "修改成功",
        })
        partitionDialogVisible.value = false
        reloadData()
        emits("updateData")

    }
})

function confirmUpdateAgentPartition(accountId: string, partition: string) {
    runUpdateAgentPartition(accountId, partition)
    partitionDialogVisible.value = false
}

const emits = defineEmits(['updateData'])
</script>

<style scoped>

</style>