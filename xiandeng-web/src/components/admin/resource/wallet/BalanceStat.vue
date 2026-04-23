<template>
    <div>
        <h1>余额概览</h1>
        <!-- 余额概览主界面 -->
        <template v-for="item in items">
            <a-divider orientation="left">
                <div class="flex space-x-2 items-center justify-between w-96">
                    <div>{{ item.title }}</div>
                    <div v-if="withdraws" class="space-x-4">
                        <a-tooltip title="同时只能有一笔进行中的提现" v-if="!withdraws[item.key].no_pending">
                            <a-button type="primary" :disabled="!withdraws[item.key].no_pending">申请提现</a-button>
                        </a-tooltip>
                        <a-button v-else type="primary" :disabled="!withdraws[item.key].no_pending" @click="requestWithdraw(item.key)">申请提现</a-button>

                        <a-tooltip title="当前没有可撤销的提现订单" v-if="!withdraws[item.key].request_exist">
                            <a-button type="primary" :disabled="!withdraws[item.key].request_exist">撤销提现</a-button>
                        </a-tooltip>
                        <a-button v-else type="primary" :disabled="!withdraws[item.key].request_exist">撤销提现</a-button>
                    </div>

                </div>
            </a-divider>
            <a-row :gutter="16" class="mb-16">
                <a-col :span="8" v-for="child in item.children">
                    <a-card>
                        <a-statistic :title="child.title" :value="child.value??0" />
                    </a-card>
                </a-col>
            </a-row>
        </template>

        <!-- 申请提现抽屉 -->
        <a-drawer v-model:open="requestWithdrawDrawerOpen" title="申请提现" :footer="null">
            <div class="flex justify-between mb-4">
                <div class="text-gray-500">提现金额</div>
                <div class="text-md">单次提款上限 50,000 元</div>
            </div>
            <a-form :model="withdrawRequestForm" layout="vertical" :rules="withdrawRequestRules" ref="withdrawRequestFormRef">
                <a-form-item class="border-b border-blue-200" name="amount">
                    <div class="flex items-center space-x-3">
                        <div class="text-3xl">¥</div>
                        <a-input-number :max="maxAvailableWithdraw" :placeholder="`可提现金额${maxAvailableWithdraw}元`" class="text-lg w-2/3" :bordered="false" v-model:value="withdrawRequestForm.amount" size="large" :controls="false" :formatter="(value: any) => `${value}`.replace(/\B(?=(\d{3})+(?!\d))/g, ',')"/>
                        <a-button type="link" @click="withdrawRequestForm.amount = maxAvailableWithdraw"> 全部提现</a-button>
                    </div>

                </a-form-item>

                <a-collapse class="mt-24" v-model:activeKey="withdrawRequestForm.withdraw_method_category" accordion>
                    <a-collapse-panel key="1" header="联系总部线下提款">
                        <div class="px-4">
                            <ContactHeadQuarter />
                        </div>
                    </a-collapse-panel>
                    <a-collapse-panel key="2" header="提现至已绑定银行卡">
                        <a-form-item name="withdraw_method_id">
                            <a-radio-group v-model:value="withdrawRequestForm.withdraw_method_id" placeholder="请选择银行卡">

                            <a-radio v-for="(item, index) in (withdrawMethods??[])" :key="index" :value="item.id">{{ item.accountname }} {{ item.bank }} {{ item.accountnumber }}</a-radio>
                            <!-- <a-radio value="23">张三 工商银行 6222021001117388222</a-radio> -->
                        </a-radio-group>
                        </a-form-item>
                    </a-collapse-panel>
                    <a-collapse-panel key="3" header="提现至新银行卡">
                        <a-form-item label="户名" name="new_method_acct_name">
                            <a-input v-model:value="withdrawRequestForm.new_method_acct_name" placeholder="请输入收款人户名" />
                        </a-form-item>
                        <a-form-item label="账号" name="new_method_acct_number">
                            <a-input v-model:value="withdrawRequestForm.new_method_acct_number" placeholder="请输入收款人账号" />
                        </a-form-item>
                        <a-form-item label="开户行" name="new_method_bank_name">
                            <a-input v-model:value="withdrawRequestForm.new_method_bank_name" placeholder="请输入开户银行" />
                        </a-form-item>
                    </a-collapse-panel>
                </a-collapse>

                <a-form-item class="mt-24">
                    <a-button class="w-full" type="primary" @click="submitWithdrawRequest">确认提现</a-button>
                </a-form-item>
            </a-form>


        </a-drawer>
    </div>
</template>


<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { Balance, getBalance, getOngoingWithdraw } from '@/api/request/wallet'
import { useRequest } from 'vue-request';
import { createWithdrawMethod, listWithdrawMethods, WithdrawMethod } from '@/api/request/profile';
import { WithdrawMethodType, WithdrawType } from '@/models/withdraw';
import { Rule } from 'ant-design-vue/es/form';
import { createWithdraw } from '@/api/request/withdraw';
import { notification } from 'ant-design-vue';
import ContactHeadQuarter from '@/components/payment_components/ContactHeadQuarter.vue';
import {AxiosError} from "axios";


const balances = ref<Balance>()
onMounted(async () => {
    try {
        const balanceResult = await getBalance()
        console.log(balanceResult.data);
        balances.value = balanceResult.data
    }
    catch {
        console.log("getBalance error")
    }
})

const {data: withdrawMethods} = useRequest<Array<WithdrawMethod>>(listWithdrawMethods, {
    defaultParams: [WithdrawMethodType.BANK]
})

const {data: withdraws} = useRequest(getOngoingWithdraw)

const items = computed(() => {
    return [
    {
        key: WithdrawType.Balance,
        title: '基础余额信息',
        children: [
            { title: '余额', value: balances.value?.balance },
            { title: '剩余意向金', value: balances.value?.pendingreturn },
            { title: '提现中', value: withdraws.value?.balance.sum },
        ]
    },
    {
        key: WithdrawType.Partition,
        title: '分区余额',
        children: [
            { title: '左区余额', value: balances.value?.balanceleft },
            { title: '右区余额', value: balances.value?.balanceright },
            { title: '提现中', value: withdraws.value?.partition.sum },
        ]
    },
    {
        key: WithdrawType.Triple,
        title: '三单余额',
        children: [
            { title: '三单已解锁', value: balances.value?.balancetriple },
            { title: '三单未解锁', value: balances.value?.balancetriplelock },
            { title: '提现中', value: withdraws.value?.triple.sum },
        ]
    }
]
})

function requestWithdraw(withdrawType: WithdrawType) {

    requestingWithdrawType.value = withdrawType
    requestWithdrawDrawerOpen.value = true
}

const requestingWithdrawType = ref<string|WithdrawType>("")
const requestWithdrawDrawerOpen = ref(false)
const withdrawRequestFormRef = ref()
const withdrawRequestForm = ref<{
    amount: number|string,
    withdraw_method_id: string,
    withdraw_method_category: string,
    new_method_acct_name: string,
    new_method_acct_number: string,
    new_method_bank_name: string
}>({
    amount: "",
    withdraw_method_id: "",
    withdraw_method_category: "1",
    new_method_acct_name: "",
    new_method_acct_number: "",
    new_method_bank_name: ""
})

async function validateNewMethodInputs(_: any, value: string) {
    // console.log(rule);

    if (withdrawRequestForm.value.withdraw_method_category === "3") {
        if (value == '') return Promise.reject()
        return Promise.resolve()
    }
    return Promise.resolve()
}

async function validateWithdrawMethodId(_: any, value: string) {
    // console.log(rule);

    if (withdrawRequestForm.value.withdraw_method_category === "2") {
        if (value == '') return Promise.reject()
        return Promise.resolve()
    }
    return Promise.resolve()
}

const withdrawRequestRules: Record<string, Rule[]> = {
    new_method_acct_name: [
        { validator: validateNewMethodInputs, message: '请输入户名', trigger: 'blur' },
    ],
    new_method_acct_number: [
        { validator: validateNewMethodInputs, message: '请输入账号', trigger: 'blur' },
    ],
    new_method_bank_name: [
        { validator: validateNewMethodInputs, message: '请输入开户行', trigger: 'blur' },
    ],
    withdraw_method_id: [
        { validator: validateWithdrawMethodId, message: '请选择提现方式', trigger: 'blur' },
    ],
    amount: [
        { required: true, message: '请输入提现金额', trigger: 'blur' },
        { type: 'number', message: '请输入数字', trigger: 'blur' },
        { type: 'number', min: 1, message: '最低提现金额为1', trigger: 'blur' },
    ]
}

const maxAvailableWithdraw = computed(() =>{
    let available = 0
    switch (requestingWithdrawType.value) {
        case WithdrawType.Balance:
            available = balances.value?.balance ?? 0
            break
        case WithdrawType.Partition:
            available = Math.min(balances.value?.balanceleft ?? 0, balances.value?.balanceright ?? 0)
            break
        case WithdrawType.Triple:
            available = balances.value?.balancetriple ?? 0
            break
    }
    return Math.min(available, 50000)
})

function withdrawSuccessCallback() {
    notification.success({
        message: '提现申请成功',
        description: '提现申请成功，请等待审批'
    })
    window.location.reload()
    // requestWithdrawDrawerOpen.value = false
}

function withdrawFailedCallback(e: AxiosError<{data: string}>) {
    let msg = e.response?.data?.data
    // if (e.response?.status === 500) {msg = '服务器内部错误'}
    notification.error({
            message: '提现申请失败',
            description: `提现申请失败: ${msg}`
        })

        requestWithdrawDrawerOpen.value = false

}
async function submitWithdrawRequest() {
    // console.log(withdrawRequestForm.value);
    withdrawRequestFormRef.value.validateFields()
    console.log(withdrawRequestForm.value.withdraw_method_category);

    switch (withdrawRequestForm.value.withdraw_method_category) {
        case "":
            notification.warn({
                message: '提现申请失败',
                description: '请选择提现方式'
            })
            break
        case "1":
            await createWithdraw(null, requestingWithdrawType.value as WithdrawType, withdrawRequestForm.value.amount as number)
                .then(withdrawSuccessCallback)
                .catch(withdrawFailedCallback)

            break
        case "2":
            await createWithdraw(withdrawRequestForm.value.withdraw_method_id, requestingWithdrawType.value as WithdrawType, Number(withdrawRequestForm.value.amount))
                .then(withdrawSuccessCallback)
                .catch(withdrawFailedCallback)
            break
        case "3":
            const res = await createWithdrawMethod(WithdrawMethodType.BANK, withdrawRequestForm.value.new_method_bank_name, withdrawRequestForm.value.new_method_acct_name, withdrawRequestForm.value.new_method_acct_number)
            if (res.status === 201) {
                notification.error({
                    message: '提现申请失败',
                    description: '创建提现方式出错'
                })
                return
            }
            await createWithdraw(res.data.data, requestingWithdrawType.value as WithdrawType, withdrawRequestForm.value.amount as number)
                .then(withdrawSuccessCallback)
                .catch(withdrawFailedCallback)
    }
}
</script>

<style scoped>

</style>
