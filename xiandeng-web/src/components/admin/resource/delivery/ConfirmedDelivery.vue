<template>
    <div>
        <a-table :data-source="data" :columns="columns">
            
        </a-table>
    </div>
</template>

<script setup lang="ts">
import { listDelivery } from '@/api/request/deilvery';
import { useRequest } from 'vue-request';

const {data} = useRequest(listDelivery, {
    defaultParams: ['CONFIRMED']
})

const columns = [
    {
        title: '学生姓名',
        dataIndex: 'accountname'
    },
    {
        title: '商品名称',
        dataIndex: 'productname'
    },
    {
        title: '服务价格',
        dataIndex: 'price'
    },
    {
        title: '销售账号',
        dataIndex: 'accountname_2'
    },
    // {
    //     title: '操作',
    //    dataIndex: 'action',
    // }
 ]
</script>

<style lang="less" scoped>
</style>