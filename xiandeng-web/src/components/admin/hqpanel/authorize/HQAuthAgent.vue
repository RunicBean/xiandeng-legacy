<template>
    <div>
        
        <a-table :data-source="filteredData" :columns="[{key: 'info', title: 'info', dataIndex: 'info'}]" style="width: 100%" :custom-row="selectRow" :show-header="false">
            <template #bodyCell="{column, record}">
                <template v-if="column.key == 'info'">
                    <a-descriptions>
                        <a-descriptions-item width="30%" label="代理名">{{ record.accountname }}</a-descriptions-item>
                        <a-descriptions-item width="30%" label="创建">{{ dayjs.tz(record.createdat).format("YYYY-MM-DD HH:mm")}}</a-descriptions-item>
                        <a-descriptions-item label="等级">{{ resourceStore.entityTypeWordingMap[record.type] }}</a-descriptions-item>
                        <a-descriptions-item v-if="record.targettype != null && record.targettype != ''" label="目标等级">{{ resourceStore.entityTypeWordingMap[record.targettype] }}</a-descriptions-item>
                        <a-descriptions-item label="类型">
                        <a-tag size="small" v-if="record.status == 'INIT'">加盟</a-tag>
                        <a-tag size="small" v-if="record?.status != 'INIT' && record.targettype != null && record.targettype != ''">升级</a-tag>
                        </a-descriptions-item>
                        <a-descriptions-item label="应付金额">
                        {{ record.pendingfee }}
                        </a-descriptions-item>
                    </a-descriptions>
                </template>
            </template>
            
        </a-table>

        <a-drawer title="授权代理" v-model:open="authorizeDrawerVisible"
            :destroy-on-close="true" :show-close="true" :wrapperClosable="true">
            <div class="mb-8">即将给以下代理分配新等级，是否继续？</div>
            <a-descriptions :column="1" bordered>
                <a-descriptions-item label="代理名">{{ selectedRow?.accountname }}</a-descriptions-item>
                <a-descriptions-item label="上级代理">{{ selectedRow?.upacctname }}</a-descriptions-item>
                <a-descriptions-item label="创建">{{ dayjs.tz(selectedRow?.createdat).format("YYYY-MM-DD HH:mm")}}</a-descriptions-item>
                <a-descriptions-item label="等级">{{ resourceStore.entityTypeWordingMap[selectedRow?.type as string] }}</a-descriptions-item>
                <a-descriptions-item v-if="selectedRow?.targettype != null && selectedRow?.targettype != ''" label="目标等级">{{ resourceStore.entityTypeWordingMap[selectedRow?.targettype] }}</a-descriptions-item>
                <a-descriptions-item label="类型">
                <a-tag size="small" v-if="selectedRow?.status == 'INIT'">加盟</a-tag>
                <a-tag size="small" v-if="selectedRow?.status != 'INIT' && selectedRow?.targettype != null && selectedRow?.targettype != ''">升级</a-tag>
                </a-descriptions-item>
                <a-descriptions-item label="应付金额">
                {{ selectedRow?.pendingfee }}
                </a-descriptions-item>
            </a-descriptions>
            <div class="demo-drawer__footer mt-12">
                <a-button @click="authorizeDrawerVisible = false">取消</a-button>
                <a-button type="primary" @click="confirmAuthorize(false)">
                确认
                </a-button>
            </div>
        </a-drawer>
        
        <a-modal
            v-model:open="pendingUpAgentsDialogVisible"
            title="注意"
            width="500"
            :before-close="handleClosePendingUpAgentsDialog"
        >
            <div class="mb-4">
                ⚠️ 该订单的上级代理有多个更早的未缴费加盟订单如下。如果继续操作，可能导致三单循环顺序错乱。请与上级代理确认核实后再操作！
            </div>
            <a-table :data-source="pendingAgents" :columns="[{key: 'upagent', title: '上级代理', dataIndex: 'upagent'}, {key: 'childagent', title: '加盟商', dataIndex: 'childagent'}, {key: 'ordercreatedat', title: '订单创建时间', dataIndex: 'ordercreatedat'}]" border stripe>
                <template #bodyCell="{column, record}">
                    <!-- <template v-if="column.key == 'upagent'">
                        {{ record.upagent }}
                    </template>
                    <template v-if="column.key == 'childagent'">
                        {{ record.childagent }}
                    </template> -->
                    <template v-if="column.key == 'ordercreatedat'">
                        {{ dayjs.tz(record.ordercreatedat).format("YYYY-MM-DD HH:mm") }}
                    </template>
                 </template>
            </a-table>
            <div class="mt-4">是否继续？</div>
            <template #footer>
                <div class="dialog-footer">
                    <a-button @click="handleClosePendingUpAgentsDialog">取消</a-button>
                    <a-button type="primary" @click="confirmAuthorize(true)">
                    确认
                    </a-button>
                </div>
            </template>
        </a-modal>
    </div>
</template>

<script setup lang="ts">
import { onMounted, ref, defineEmits } from 'vue'
import { AgentAccount, assignAgentAward, PendingAgent, pendingAgentsByFranchiseOrderId, searchAgents } from '@/api/request/agent';
import { useRequest } from 'vue-request';
import dayjs from 'dayjs'
import timezone from 'dayjs/plugin/timezone'
import utc from 'dayjs/plugin/utc'
import { notification } from 'ant-design-vue';
import { useResourceStore } from '@/stores/resource';

const resourceStore = useResourceStore()
dayjs.extend(utc)
dayjs.extend(timezone)
dayjs.tz.setDefault("Asia/Shanghai")


const emits = defineEmits(["stop-loading"])
onMounted(async () => {
    await resourceStore.updateEntityTypeWordingMap()
    emits("stop-loading")
})

const filteredData = ref<Array<AgentAccount>>([])
const {run: runSearchAgents} = useRequest<Array<AgentAccount>>(searchAgents, {
    onSuccess(data) {
        filteredData.value = data.filter(item => item.pendingfee != null && item.pendingfee != "0")
    },
    
})

function selectRow(record: AgentAccount) {
    return {
        onClick: () => {
            if (record.pendingfee == null || record.pendingfee == "0" || record.franchiseorderid == null) {
                notification.error({
                    message: "提示",
                    description: "该代理未找到加盟申请记录(franchiseorder)，无法授权",
                })
                return
            }
            selectedRow.value = record
            authorizeDrawerVisible.value = true
        }
    }

}

const selectedRow = ref<AgentAccount>()
const authorizeDrawerVisible = ref(false)
const pendingAgents = ref<Array<PendingAgent>>([])
async function confirmAuthorize(skipConfirm: boolean) {
    if (!skipConfirm) {
        const res = await pendingAgentsByFranchiseOrderId(selectedRow.value?.franchiseorderid as string)
        if (res && res.length > 0) {
            pendingAgents.value = res
            pendingUpAgentsDialogVisible.value = true
            return
        }
    }
    
    if (selectedRow.value) {
        assignAgentAward(selectedRow?.value.id as string)
        .then(() => {
            notification.success({
                message: "授权成功！"
            })
            authorizeDrawerVisible.value = false
            pendingUpAgentsDialogVisible.value = false
            runSearchAgents()
        })
        .catch((_) => {
            notification.error({
                message: "授权失败！请联系管理员。"
            })
        })
    }
    
}

const pendingUpAgentsDialogVisible = ref(false)
function handleClosePendingUpAgentsDialog() {
    pendingUpAgentsDialogVisible.value = false
    authorizeDrawerVisible.value = false
}
</script>

<style scoped>

</style>