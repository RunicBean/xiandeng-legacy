<template>
    <div>
        <h1>提现信息管理</h1>
        <a-form 
        ref="withdrawMethodCreateRef"
        layout="inline" class="flex justify-between" :model="withdrawMethodCreateForm" :rules="withdrawMethodCreateRules">
            <a-form-item label="户名" name="accountname">
                <a-input v-model:value="withdrawMethodCreateForm.accountname"></a-input>
            </a-form-item>
            <a-form-item label="账号" name="accountnumber">
                <a-input v-model:value="withdrawMethodCreateForm.accountnumber"></a-input>
            </a-form-item>
            <a-form-item label="开户银行" name="bank">
                <a-input v-model:value="withdrawMethodCreateForm.bank"></a-input>
            </a-form-item>
            <a-form-item>
                <a-button type="primary" @click="submitCreate">添加</a-button>
            </a-form-item>
        </a-form>
        <a-divider />
        <a-table :columns="columns" :dataSource="data" :pagination="false">
            
            <template #bodyCell="{ column, record }: {column: TableColumnType, record: WithdrawMethod}">
                <template v-if="['bank', 'accountname', 'accountnumber'].includes(column.dataIndex as string)">
                    <div>
                        <a-input 
                        size="small"
                        v-if="editableData[record.id]"
                        v-model:value="editableData[record.id as string][column.dataIndex as string]" />
                        <template v-else>
                            {{ record[column.dataIndex as string] }}
                        </template>
                    </div>
                </template>
                <template v-if="column.key === 'action'">
                    <div class="flex space-x-2" v-if="editableData[record.id]">
                        <a-button size="small" type="primary" @click="save(editableData[record.id])">确认</a-button>
                        <a-popconfirm okText="确定" cancelText="取消" title="确认取消吗？" @confirm="cancel(record.id)">
                            <a-button ghost danger size="small">取消</a-button>
                        </a-popconfirm>
                    </div>
                    <div class="flex space-x-2" v-else>
                        <Button size="small" type="primary" ghost @click="edit(record.id)">修改</Button>
                        <Button size="small" type="default" danger class="text-red" @click="submitDelete(record.id)">删除</Button>
                    </div>
                </template>
            </template>
        </a-table>
    </div>
</template>

<script setup lang="ts">
import { cloneDeep } from 'lodash-es';
import { ref, UnwrapRef, reactive } from 'vue';
import { type WithdrawMethod, createWithdrawMethod, deleteWithdrawMethod, listWithdrawMethods, updateWithdrawMethod } from '@/api/request/profile';
import { WithdrawMethodType } from '@/models/withdraw';
import { Button, notification, TableColumnType } from 'ant-design-vue';
import { useRequest } from 'vue-request';
import { Rule } from 'ant-design-vue/es/form';
import { AxiosError } from 'axios';

const {data, run: runListWithdrawMethods} = useRequest<Array<WithdrawMethod>>(listWithdrawMethods, {
    defaultParams: [WithdrawMethodType.BANK],
})

const columns: TableColumnType[] = [
    {
        title: '户名',
        dataIndex: 'accountname',
        key: 'accountname',
    },
    {
        title: '账号',
        dataIndex: 'accountnumber',
        key: 'accountnumber',
    },
    {
        title: '开户银行',
        dataIndex: 'bank',
        key: 'bank',
    },
    {
        title: '操作',
        dataIndex: 'action',
        key: 'action',
        fixed: 'right',
        width: 100
        // customRender: (text: any, record: any) => {
        //     return h('span', [
        //         h(Button, { type: 'default' }, '修改'),
        //         h(Button, { type: 'default', danger: true, class: 'text-red' }, '删除'),
        //     ])
        // }
    }
    
]

const withdrawMethodCreateRef = ref()
const withdrawMethodCreateForm = ref({
    accountname: '',
    accountnumber: '',
    bank: '',
})
const withdrawMethodCreateRules = {
    accountname: [
        { required: true, message: '请输入户名', trigger: 'blur' },
    ],
    accountnumber: [
        { required: true, message: '请输入账号', trigger: 'blur' },
        { validator: validateAccountNumber, trigger: 'blur' }
    ],
    bank: [
        { required: true, message: '请输入开户银行', trigger: 'blur' },
    ]
}

async function validateAccountNumber(_rule: Rule, value: string) {
    const reg = /^\d{16,19}$/
    if (!reg.test(value)) {
      return Promise.reject('请输入正确的银行卡号')
    } else {
        return Promise.resolve()
    }
}
async function submitCreate() {
    try {
        await withdrawMethodCreateRef.value.validateFields()
    } catch (e) {
        return
    }
    await createWithdrawMethod(
        WithdrawMethodType.BANK, 
        withdrawMethodCreateForm.value.bank,
        withdrawMethodCreateForm.value.accountname, 
        withdrawMethodCreateForm.value.accountnumber, 
        )
    runListWithdrawMethods(WithdrawMethodType.BANK)
    withdrawMethodCreateForm.value = {
        accountname: '',
        accountnumber: '',
        bank: '',
    }
}

async function submitDelete(recordId: string) {
    await deleteWithdrawMethod(
        WithdrawMethodType.BANK, 
        recordId,
        )
    runListWithdrawMethods(WithdrawMethodType.BANK)
}

// Edit
const editableData: UnwrapRef<Record<string, WithdrawMethod>> = reactive({});

const edit = (key: string) => {
    if (!data.value) return
    editableData[key] = cloneDeep(data.value.filter((item: WithdrawMethod) => key === item.id)[0]);
};

const save = async (record: WithdrawMethod) => {
    await updateWithdrawMethod(
        WithdrawMethodType.BANK, 
        record.id,
        record.bank,
        record.accountname,
        record.accountnumber,
    )
    .catch((e: AxiosError<{data: string}>) => {
        console.log(e)
        notification.error({
            message: '修改失败',
            description: e.response?.data?.data,
        })
    })
    runListWithdrawMethods(WithdrawMethodType.BANK)
    delete editableData[record.id]
};
const cancel = (key: string) => {
  delete editableData[key];
};
</script>

<style scoped>

</style>