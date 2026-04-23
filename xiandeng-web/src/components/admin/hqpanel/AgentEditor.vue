<template>
    <div>
        <h1>代理编辑</h1>
        <a-card>
            <a-form :model="searchParams" :label-col="{ span: 6 }" :wrapper-col="{ span: 18 }">
                <a-form-item label="账号名称">
                    <a-input v-model:value="searchParams.account_name_like" placeholder="请输入账号名称"></a-input>
                </a-form-item>
                <a-form-item label="电话">
                    <a-input v-model:value="searchParams.phone_like" placeholder="请输入电话号码"></a-input>
                </a-form-item>
                <a-form-item label="邮箱">
                    <a-input v-model:value="searchParams.email_like" placeholder="请输入邮箱地址"></a-input>
                </a-form-item>
                <a-form-item>
                    <a-button type="primary" @click="fetchAgents">搜索</a-button>
                    <a-button style="margin-left: 8px" @click="resetSearch">重置</a-button>
                </a-form-item>
            </a-form>
        </a-card>

        <a-card style="margin-top: 16px">
            <a-table
                :data-source="agents"
                :columns="columns"
                :loading="loading"
                :pagination="pagination"
                @change="handleTableChange"
                row-key="accountid"
            >
                <template #bodyCell="{ column, record }">
                    <template v-if="column.key === 'action'">
                        <a-button type="link" @click="editAgent(record)">编辑</a-button>
                    </template>
                </template>
            </a-table>
        </a-card>

        <a-drawer
            v-model:open="dialogVisible"
            :title="`编辑代理信息`"
            width="500px"
            placement="right"
        >
            <a-form
                :model="currentRow"
                :label-col="{ span: 6 }"
                :wrapper-col="{ span: 18 }"
                layout="vertical"
            >
                <a-tag class="mb-2">Org: {{currentRow.orguri? currentRow.orguri : 'default'}}</a-tag>
                <a-form-item label="账号ID">
                    <a-input-group compact>
                        <a-input
                            v-model:value="currentRow.accountid"
                            placeholder="账号ID"
                            readonly
                            style="width: calc(100% - 80px)"
                        ></a-input>
                        <a-button
                            type="primary"
                            @click="copyAccountId"
                            style="width: 80px"
                        >
                            复制
                        </a-button>
                    </a-input-group>
                </a-form-item>
                <a-form-item label="账号名称">
                    <a-input v-model:value="currentRow.accountname" placeholder="请输入账号名称"></a-input>
                </a-form-item>
                <a-form-item label="状态">
                    <a-select v-model:value="currentRow.status" placeholder="请选择状态">
                        <a-select-option value="INIT">INIT</a-select-option>
                        <a-select-option value="ACTIVE">ACTIVE</a-select-option>
                        <a-select-option value="CLOSED">CLOSED</a-select-option>
                    </a-select>
                </a-form-item>
                <a-form-item label="分区">
                    <a-select v-model:value="currentRow.partition" placeholder="请选择分区">
                        <a-select-option value="L">L</a-select-option>
                        <a-select-option value="R">R</a-select-option>
                    </a-select>
                </a-form-item>
                <a-form-item label="类型">
                    <a-select v-model:value="currentRow.type" placeholder="请选择类型">
                        <a-select-option value="HQ_AGENT">HQ_AGENT</a-select-option>
                        <a-select-option value="LV1_AGENT">LV1_AGENT</a-select-option>
                        <a-select-option value="LV2_AGENT">LV2_AGENT</a-select-option>
                    </a-select>
                </a-form-item>
                <a-form-item>
                    <a-checkbox v-model:checked="currentRow.demo_flag">开启Demo账号</a-checkbox>
                </a-form-item>
                <div class="pb-2">Demo 账号 Account id</div>
                <a-form-item>
                    <a-input v-model:value="currentRow.demo_account"></a-input>
                </a-form-item>
                <a-alert>
                    <template #description>
                        本部请填写ID: xxx <br>
                        聆鹿请填写ID: xxx <br>
                        全唯请填写ID: xxx
                    </template>
                </a-alert>
            </a-form>
            <template #footer>
                <div style="text-align: right">
                    <a-button @click="dialogVisible = false">取消</a-button>
                    <a-button type="primary" @click="saveChanges" style="margin-left: 8px">保存</a-button>
                </div>
            </template>
        </a-drawer>
    </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { searchAgentsWithAttributes, updateAgentByHQ, type SearchAgentsWithAttributesRow, type QuerySearchAgentsWithAttributes } from '@/api/request/agent'
import { message } from 'ant-design-vue'
import { AxiosError } from 'axios'

const agents = ref<SearchAgentsWithAttributesRow[]>([])
const searchParams = ref<QuerySearchAgentsWithAttributes>({})
const loading = ref(false)
const dialogVisible = ref(false)
const currentRow = ref<SearchAgentsWithAttributesRow>({
    accountname: '',
    status: '',
    partition: '',
    accountid: '',
    createdat: '',
    type: ''
})

const pagination = ref({
    current: 1,
    pageSize: 10,
    total: 0,
    showSizeChanger: true,
    showQuickJumper: true,
    showTotal: (total: number, range: [number, number]) => `第 ${range[0]}-${range[1]} 条，共 ${total} 条`
})

const columns = [
    {
        title: '账号名称',
        dataIndex: 'accountname',
        key: 'accountname',
        width: 150
    },
    {
        title: '创建时间',
        dataIndex: 'createdat',
        key: 'createdat',
        width: 180
    },
    {
        title: '状态',
        dataIndex: 'status',
        key: 'status',
        width: 100
    },
    {
        title: '分区',
        dataIndex: 'partition',
        key: 'partition',
        width: 120
    },
    {
        title: '类型',
        dataIndex: 'type',
        key: 'type',
        width: 100
    },
    {
        title: '操作',
        key: 'action',
        width: 100,
        fixed: 'right'
    }
]

const fetchAgents = async () => {
    loading.value = true
    try {
        const response = await searchAgentsWithAttributes(searchParams.value)
        agents.value = response
        pagination.value.total = response.length
    } catch (error) {
        message.error('获取代理数据失败')
    } finally {
        loading.value = false
    }
}

const resetSearch = () => {
    searchParams.value = {}
    pagination.value.current = 1
    fetchAgents()
}

const editAgent = (record: SearchAgentsWithAttributesRow) => {
    currentRow.value = { ...record }
    dialogVisible.value = true
}

const handleTableChange = (pag: any) => {
    pagination.value.current = pag.current
    pagination.value.pageSize = pag.pageSize
    fetchAgents()
}

const copyAccountId = async () => {
    const accountId = currentRow.value.accountid
    if (!accountId) {
        message.error('账号ID为空')
        return
    }

    try {
        await navigator.clipboard.writeText(accountId)
        message.success('账号ID已复制到剪贴板')
    } catch (error) {
        // 如果 clipboard API 不可用，使用传统方法
        const textArea = document.createElement('textarea')
        textArea.value = accountId
        document.body.appendChild(textArea)
        textArea.select()
        document.execCommand('copy')
        document.body.removeChild(textArea)
        message.success('账号ID已复制到剪贴板')
    }
}

const saveChanges = async () => {
    try {
        if (!currentRow.value.accountid) {
            message.error('账号ID不能为空')
            return
        }
        console.log(currentRow.value.demo_flag)
        await updateAgentByHQ(
            currentRow.value.accountid,
            currentRow.value.partition || undefined,
            currentRow.value.accountname,
            currentRow.value.type || undefined,
            currentRow.value.status || undefined,
            currentRow.value.demo_flag || false,
            currentRow.value.demo_account || undefined,
        )

        message.success('保存成功')
        dialogVisible.value = false
        fetchAgents() // 刷新数据
    } catch (error) {
        message.error(`保存失败: ${(error as AxiosError<{data: any}>)?.response?.data.data}` )
        console.error('更新代理信息失败:', (error as AxiosError<{data: any}>)?.response?.data)
    }
}

onMounted(() => {
    fetchAgents()
})
</script>

<style scoped>
.ant-card {
    margin-bottom: 16px;
}

.ant-form-item {
    margin-bottom: 16px;
}
</style>
