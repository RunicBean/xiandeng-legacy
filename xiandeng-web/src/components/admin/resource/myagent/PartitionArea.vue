<template>
    <div>
        <a-card shadow="always" :body-style="{ padding: '20px' }">
            <!-- <template #title>
            <div class="space-x-1">
                <span>{{ partitionWording }}</span>
                <a-button class="float float-end" type="primary" size="default" @click="partitionDetailShow('L')">查看详情</a-button>
            </div>
            </template> -->
            <a-table
                :data-source="partSevenLevelAgents?partSevenLevelAgents:[]"
                border stripe
                :columns="partSevenLevelAgentsColumns"
                :scroll="{ x: 1000, y: 300 }">
                <template #bodyCell="{column, record}">
                    <template v-if="column.dataIndex == 'action'">
                        <a-button type="link"  size="small" @click="partitionDetailShow(record.account_id)">业绩详情</a-button>
                    </template>
                </template>
            </a-table>
            
        </a-card>

        <a-modal
            title="业绩详情"
            v-model:open="partitionDetailDialogVisible"
            :footer="null"
            width="70%"
        >
            <a-table :data-source="myPartitionAgentsData" border stripe :columns="myPartitionAgentsColumn" />
            
        </a-modal>
    </div>
</template>

<script setup lang="ts">
import { listSevenLevelAgents, listSubAgentDetails } from '@/api/request/agent';
import dayjs from "dayjs";
import { Partition } from '@/models/account'
import { useRequest } from 'vue-request';
import { ref, defineProps } from 'vue'
const props = defineProps({
    partition: {
        type: String,
        default: 'L'
    }
})

const partSevenLevelAgentsColumns = [
    {title: '账户名', dataIndex: 'account_name', width: '120'},
    {title: '级别', dataIndex: 'level', width: '100'},
    {title: '直属下属', dataIndex: 'direct_child', width: '100'},
    {title: '业绩', dataIndex: 'pv', width: '150'},
    {title: '负责人微信昵称', dataIndex: 'nickname'},
    {title: '负责人手机', dataIndex: 'phone'},
    {title: '负责人邮箱', dataIndex: 'email'},
    {title: '操作', dataIndex: 'action'},
]
const {data: partSevenLevelAgents, run: runListSevenLevelAgents} = useRequest(listSevenLevelAgents, {
    defaultParams: [Partition[props.partition as keyof typeof Partition], true]
})
// onMounted(() => {
//     listSevenLevelAgents(Partition[props.partition as keyof typeof Partition], true)
// })

// const partitionWording = computed(() => {
//     return props.partition == 'L' ? '左区' : '右区'
// })

const myPartitionAgentsColumn: Array<{key: string, dataIndex: string, title: string, width?: string, customRender?: ({text,record,index}: {text: string, record: any, index: number}) => string | VNode}> = [
    {key: "accountname", dataIndex: "accountname", title: "代理名"},
    {key: "level", dataIndex: "level", title: "级别"},
    {key: "createdat", dataIndex: "createdat", title: "业绩创建时间", customRender: ({text}: {text: string|null}) => {
            if (text == null) return '-'
            return dayjs(text).format('YYYY-MM-DD HH:mm')
        },
    },
    {key: "productname", dataIndex: "productname", title: "产品名"},
    {key: "amount", dataIndex: "amount", title: "业绩", customRender: ({text}) => {
        if (text == null) return '0'
        else return text
    }}
]

const {data: myPartitionAgentsData, run: runListMyPartitionAgents} = useRequest(listSubAgentDetails, {
    manual: true
})

function partitionDetailShow(agent_account_id: string) {
    partitionDetailDialogVisible.value = true
    runListMyPartitionAgents(agent_account_id, true)
}
const partitionDetailDialogVisible = ref(false)

defineExpose({runListSevenLevelAgents})
</script>

<style scoped>

</style>