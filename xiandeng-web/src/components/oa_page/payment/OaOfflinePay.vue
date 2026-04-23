
<template>
    <div class="flex flex-col items-center h-full justify-center">
        <a-card shadow="always" :body-style="{ padding: '10px' }">
            <!-- card header -->
            <template #title>
                <div>
                    支付信息
                    <!-- <span v-if="isLPM">请长按识别下方二维码，输入金额 <span class="text-red-500">{{ amount }}</span></span>
                    <div v-if="isCard">请打开网上银行，按照下面信息进行转账</div> -->
                </div>
            </template>

            <!-- card body -->
            <div v-if="isLPM">
                <span v-if="isLPM">请长按识别下方二维码，输入金额 <span class="text-red-500 font-bold">{{ amount }}</span></span>
                <APMOffline :amount="amount" :payment-method="paymentMethod" />
            </div>
            
            <div class="ms-4" v-if="isCard">
                <div v-if="isCard" class="font-bold">请打开网上银行，按照下面信息进行转账</div>
                <CardOffline :amount="amount" />
            </div>

            <!-- card footer -->
            <template #footer>
                <div class="flex justify-end space-x-4">
                    <a-button size="default" @click="clickCancel">返回</a-button>
                    <a-button type="primary" size="default" @click="clickConfirm">已支付</a-button>
                
                </div>
                
            </template>
        </a-card>
        
        <a-button v-if="profileStore.isGuardian()" class="fixed bottom-8 right-8" type="primary" round size="large" @click="inviteUserCodeDrawer = true">邀请学员绑定</a-button>
        <a-drawer title="邀请注册" v-model:open="inviteUserCodeDrawer" placement="bottom" size="large"
            :destroy-on-close="true" :show-close="true" :wrapperClosable="true">
            <InviteUserCode />
        </a-drawer>
        
    </div>
</template>

<script lang="ts" setup>
import { PaymentMethod } from '@/models/payment';
import { useProfileStore } from '@/stores/profile';
import { ref, defineProps, computed, defineEmits } from 'vue';
import InviteUserCode from '../resource/InviteUserCode.vue'
import CardOffline from '@/components/payment_components/CardOffline.vue';
import APMOffline from '@/components/payment_components/APMOffline.vue';

// import { setInviteType } from '@/models/user';
// import { useRoute } from 'vue-router';
// import { useRouter } from 'vue-router';

const profileStore = useProfileStore()
// const $router = useRouter()
// const amount = ref<string>()

const props = defineProps<{
    amount: any,
    paymentMethod: PaymentMethod,
    agentCode: string
}>()

const isCard = computed(() => {
    return props.paymentMethod == PaymentMethod.CARD_OFFLINE
})

const isLPM = computed(() => {
    return [
        PaymentMethod.ALIPAY_OFFLINE, 
        PaymentMethod.WECHAT_OFFLINE,
        PaymentMethod.LIULIU_PAY,
    ].indexOf(props.paymentMethod) >= 0
})


// const inviteUrl = computed(() => {
//     let inviteType = ''
//     inviteType = setInviteType(profileStore.roleData)
//     console.log(buildWebUrl(`/invite?account_id=${profileStore.roleData?.accountid}&invite_role=` + inviteType));
//     return buildWebUrl(`/invite?account_id=${profileStore.roleData?.accountid}&invite_role=` + inviteType)
// })

const inviteUserCodeDrawer = ref(false)

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