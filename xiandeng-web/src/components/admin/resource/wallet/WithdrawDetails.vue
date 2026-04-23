<template>
    <a-table :data-source="withdraws" :columns="columns" :scroll="{x: 1000}">
    </a-table>
</template>

<script lang="ts" setup>
import { listWithdraws } from '@/api/request/withdraw';
import { useRequest } from 'vue-request';

const {data: withdraws} = useRequest(listWithdraws, {
    defaultParams: [{
        current_user: true
    }]
})

const columns = [
    {
        title: 'ID',
        dataIndex: 'id'
    },
    {
        title: '金额',
        dataIndex: 'amount'
    },
    {
        title: '状态',
        dataIndex: 'status'
    },
    {
        title: '创建时间',
        dataIndex: 'createdat'
    },
    {
        title: '提现类型',
        dataIndex: 'type'
    },
    {
        title: '代理',
        dataIndex: 'accountname'
    },
    {
        title: '提现户名',
        dataIndex: 'withdrawaccountname',
    },
    {
        title: '提现账户',
        dataIndex: 'withdrawaccountnumber'
    },
    {
        title: '提现银行',
        dataIndex: 'withdrawbank'
    }
]
</script>

<style scoped lang="less"></style>