<template>
    <div>
        <a-table v-if="data" :data-source="data" :columns="columns" border stripe>
            <template #bodyCell="{column, record}">
                <template v-if="column.key === 'createdat'">
                    {{ dayjs.tz(record.createdat, "Asia/Shanghai").format('YYYY-MM-DD HH:mm:ss') }}
                </template>
            </template>
        </a-table>
        
    </div>
</template>

<script setup lang="ts">
import { listLiuliustatements } from '@/api/request/order';
import dayjs from 'dayjs'
import { defineProps } from 'vue'
import { useRequest } from 'vue-request';
const props = defineProps<{
    orderId: number
}>()

const {data} = useRequest(listLiuliustatements, {
    defaultParams: [props.orderId]
})

const columns: Array<{key: string, title: string, dataIndex: string}> = [
    {key: "id", title: "结算id", dataIndex: "id"},
    {key: "paymentmethod", title: " 支付方式", dataIndex: "paymentmethod"},
    {key: "settleamount", title: "结算金额", dataIndex: "settleamount"},
    {key: "transactionamount", title: "交易金额", dataIndex: "transactionamount"},
    {key: "transactionid", title: "交易id", dataIndex: "transactionid"},
    {key: "createdat", title: "创建时间", dataIndex: "createdat"},
    
]
</script>

<style scoped>

</style>