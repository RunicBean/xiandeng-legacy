
<template>
    <div class="flex flex-col items-center h-full justify-center">
        <a-card class="w-full lg:w-2/5" shadow="always" :body-style="{ padding: '10px' }">
            <!-- card header -->
            <template #title>
                支付信息
            </template>

            <!-- card body -->
            <div v-if="isLPM">
                <span v-if="isLPM" class="font-bold">请长按识别下方二维码，输入金额 <span class="text-red-500">{{ amount }}</span></span>
                <a-alert class="mx-auto" type="warning">付款时请添加备注：{{ paymentReference }}</a-alert>
                <div class="flex mx-auto mt-2 w-4/5">
                    <img v-if="paymentMethod == PaymentMethod.ALIPAY_OFFLINE" src="/images/payment/alipay_qrcode.jpg" alt="">
                    <a href="wxp://f2f0gnV21FRZ9Id1qGzgtx8ukrswIhVZJ3dfpVi4_TieuSg"><img v-if="paymentMethod == PaymentMethod.WECHAT_OFFLINE" src="/images/payment/wechat_qrcode.jpg" alt=""></a>
                </div>
            </div>
            
            <div class="ms-4" v-if="isCard">
                <span v-if="isCard" class="font-bold">请打开网上银行，按照下面信息进行转账</span>
                <a-descriptions :column="1">
                    <a-descriptions-item label="银行">招商银行</a-descriptions-item>
                    <a-descriptions-item label="银行卡号">
                        <div class="space-x-2">
                            <span>6214 8342 0440 8919</span>
                            <a-button size="small" type="default" :underline="false" @click="copyToClipboard('6214834204408919')">复制卡号</a-button>
                        </div>
                    </a-descriptions-item>
                    <a-descriptions-item label="户名">
                        <div class="space-x-2">
                            <span>许兰峰</span>
                            <a-button size="small" type="default" :underline="false" @click="copyToClipboard('许兰峰')">复制户名</a-button>
                        </div>
                    </a-descriptions-item>
                    <a-descriptions-item label="金额"><span class="text-red-500 font-bold">{{ amount }}</span></a-descriptions-item>
                    <a-descriptions-item label="备注">
                        <a-tag size="small">{{ paymentReference }}</a-tag>
                    </a-descriptions-item>
                </a-descriptions>
            </div>

            <!-- card footer -->
            <template #footer>
                <div class="flex justify-end space-x-4">
                    <a-button type="primary" size="default" @click="clickCancel">返回</a-button>
                    <a-button type="primary" size="default" @click="clickConfirm">已支付</a-button>
                
                </div>
                
            </template>
        </a-card>
        <!--    For example guardian button    -->
        <slot name="extra-button"></slot>

        
    </div>
</template>

<script lang="ts" setup>
import { PaymentMethod } from '@/models/payment';
import { defineProps, computed, defineEmits } from 'vue';
import { copyToClipboard } from '@/helpers/common';


const props = defineProps<{
    amount: any,
    paymentMethod: PaymentMethod,
    paymentReference: string
}>()

const isCard = computed(() => {
    return props.paymentMethod == PaymentMethod.CARD_OFFLINE
})

const isLPM = computed(() => {
    return [
        PaymentMethod.ALIPAY_OFFLINE, 
        PaymentMethod.WECHAT_OFFLINE,
        PaymentMethod.LIULIU_PAY
    ].indexOf(props.paymentMethod) >= 0
})


// const inviteUrl = computed(() => {
//     let inviteType = ''
//     inviteType = setInviteType(profileStore.roleData)
//     console.log(buildWebUrl(`/invite?account_id=${profileStore.roleData?.accountid}&invite_role=` + inviteType));
//     return buildWebUrl(`/invite?account_id=${profileStore.roleData?.accountid}&invite_role=` + inviteType)
// })

const emit = defineEmits<{
    clickCancel: [],
    paymentConfirm: []
}>()

const clickCancel = () => {
  emit('clickCancel')
}

const clickConfirm = () => {
    emit('paymentConfirm')
}

// amount.value = $route.query.amount as string

</script>

<style>
.h {
    color: #57a7f2;
}
</style>