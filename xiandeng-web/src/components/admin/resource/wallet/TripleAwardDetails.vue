<template>
    <div>
        <a-table :data-source="tripleAwardDetails" :columns="columns" border stripe :scroll="{x: 1500}">
            <template #bodyCell="{ column, record }">
                <template v-if="column.dataIndex === 'action'">
                    <a-button v-if="record.unlockpendingreturn == 0" size="small" type="link" @click="viewUnlockDetail(record.id)">解锁明细</a-button>
                    <a-button v-else size="small" type="link" disabled>待解锁</a-button>
                </template>
            </template>
        </a-table>

        <a-modal v-model:open="unlockDetailModal" title="解锁明细" width="60%" :footer="null">
            <a-table :columns="unlockDetailColumns" :data-source="unlockDetails" :pagination="{pageSize: 5}">

            </a-table>
        </a-modal>
    </div>
</template>

<script lang="ts" setup>
import { listTripleAwardDetails, listTripleUnlockDetails } from '@/api/request/wallet';
import { useRequest } from 'vue-request';
import dayjs from 'dayjs';
import { ref } from 'vue';
import { notification } from 'ant-design-vue';

const {data: tripleAwardDetails} = useRequest(listTripleAwardDetails)
const columns = [
    {
        key: 'whichround',
        dataIndex: 'whichround',
        title: '第几轮',
        width: 75
    },
    {
        key: 'whichorder',
        dataIndex: 'whichorder',
        title: '第几单',
        width: 75
    },
    {
        key: 'childaccountname',
        dataIndex: 'childaccountname',
        title: '加盟商'
    },
    {
        key: 'targettype',
        dataIndex: 'targettype',
        title: '级别',
    },
    {
        key: 'amount',
        dataIndex: 'amount',
        title: '三单循环奖励金额'
    },
    {
        key: 'unlockcondition',
        dataIndex: 'unlockcondition',
        title: '解锁条件'
    },
    {
        key: 'unlockpendingreturn',
        dataIndex: 'unlockpendingreturn',
        title: '剩余解锁金额'
    },
    {
        key: 'createdat',
        dataIndex: 'createdat',
        title: '创建时间',
        customRender: ({text}: {text: string|null}) => {
            if (text == null) return '-'
            return dayjs(text).format('YYYY-MM-DD HH:mm:ss')
        },
    },
    {
        key: 'lastupdatedat',
        dataIndex: 'lastupdatedat',
        title: '最后售课时间',
        customRender: ({text}: {text: string|null}) => {
            if (text == null) return '-'
            return dayjs(text).format('YYYY-MM-DD HH:mm:ss')
        },
    },
    {
        key: 'action',
        dataIndex: 'action',
        title: '操作',
        fixed: 'right',
        width: 120,
    }
]

const unlockDetails = ref([])
const unlockDetailModal = ref(false)
async function viewUnlockDetail(sourceId: string) {
    await listTripleUnlockDetails(sourceId)
    .then((data) => {
        unlockDetails.value = data
        unlockDetailModal.value = true
    })
    .catch((err) => {
        notification.error({
            message: '错误',
            description: err.response.data.data
        })
    })
    
}
const unlockDetailColumns = [
    {
        key: 'createdat',
        title: '解锁时间',
        dataIndex: 'createdat',
        customRender: (text: string) => {
            return dayjs(text).format('YYYY-MM-DD HH:mm:ss')
        }
    },
    {
        key: 'amount',
        dataIndex: 'amount',
        title: '本次解锁金额'
    },
    {
        key: 'pendingamount',
        dataIndex: 'pendingamount',
        title: '剩余解锁金额'
    },
    {
        key: 'productname',
        dataIndex: 'productname',
        title: '课程'
    
    },
    {
        key: 'unlockcondition',
        dataIndex: 'unlockcondition',
        title: '解锁条件'
    },
    {
        key: 'childaccountname',
        dataIndex: 'childaccountname',
        title: '加盟商'
    },
]
</script>

<style scoped>

</style>