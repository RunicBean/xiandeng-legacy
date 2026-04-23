<template>
    <div>
        <a-table :columns="columns" :data-source="data" :pagination="{pageSize: 5}">
        </a-table>
    </div>
</template>

<script setup lang="ts">
import { getInventoryAcitivities } from '@/api/request/inventory';
import { useRequest } from 'vue-request';
import dayjs from 'dayjs';

const {data, run: fetchData} = useRequest(getInventoryAcitivities)
const columns = [
    {
        title: '创建时间',
        dataIndex: 'createdat',
        customRender: ({text}: {text: string}) => {
            return dayjs(text).format('YYYY-MM-DD HH:mm:ss')
        },
    },
    {
        title: '商品名称',
        dataIndex: 'productname',
    },
    {
        title: '变化数量',
        dataIndex: 'quantity',
    },
    {
        title: '调整后数量',
        dataIndex: 'quantityafter',
    },
    {
        title: '库存订单号',
        dataIndex: 'inventoryorderid',
    },
    {
        title: '订单号',
        dataIndex: 'orderid',
    }
]

defineExpose({fetchData})
</script>

<style scoped>

</style>