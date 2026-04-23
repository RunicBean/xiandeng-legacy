<template>
    <div>
        <a-table :data-source="data" :columns="columns">
            <template #bodyCell="{column, record}">
                <a-popconfirm v-if="column.dataIndex === 'action'" :title="'请确保已和总部联系并知晓提供服务相关事项。'" ok-text="确认" cancel-text="取消" @confirm="confirmDeliveryOrder(record.id)">
                    <a-button v-if="column.dataIndex === 'action'" type="link">确认提供服务</a-button>
                </a-popconfirm>
            </template>
        </a-table>
    </div>
</template>

<script setup lang="ts">
import { confirmDelivery, listDelivery } from '@/api/request/deilvery';
import { useRequest } from 'vue-request';

const {data, run} = useRequest(listDelivery, {
    defaultParams: ['PENDING']
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
    {
        title: '操作',
       dataIndex: 'action',
    }
 ]

 async function confirmDeliveryOrder(deliveryId: string) {
    console.log(deliveryId)
    await confirmDelivery(deliveryId)
    run('PENDING')
 }
</script>

<style lang="less" scoped>
</style>