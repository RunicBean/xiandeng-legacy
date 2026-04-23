<template>
    <div>
        <a-alert class="mx-auto" type="warning" :closable="false" >
            <template #message>
                付款时请添加备注：<a-tag>{{ paymentReference }}</a-tag>
            </template>
        </a-alert>
        <div class="flex mx-auto mt-2 w-4/5">
            <a-image v-if="paymentMethod == PaymentMethod.ALIPAY_OFFLINE" src="/images/payment/alipay_qrcode.jpg" alt="" />
            <a-image v-if="paymentMethod == PaymentMethod.LIULIU_PAY" src="/images/payment/liuliupay_qrcode.jpg" alt="" />
            <a href="wxp://f2f0gnV21FRZ9Id1qGzgtx8ukrswIhVZJ3dfpVi4_TieuSg"><a-image v-if="paymentMethod == PaymentMethod.WECHAT_OFFLINE" src="/images/payment/wechat_qrcode.jpg" alt="" /></a>
        </div>
    </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { PaymentMethod } from '@/models/payment';
import { useProfileStore } from '@/stores/profile';

defineProps<{
    amount: any,
    paymentMethod: PaymentMethod,
}>()
const profileStore = useProfileStore()
const paymentReference = computed(() => {
    // DLYB-187 支付备注改为手机号后10位
    let commentSuffix
    if (profileStore.userProfile.phone) {
        commentSuffix = profileStore.userProfile.phone.length > 10 ? profileStore.userProfile.phone.substring(profileStore.userProfile.phone.length - 10) : profileStore.userProfile.phone
    }
    return commentSuffix
})
</script>