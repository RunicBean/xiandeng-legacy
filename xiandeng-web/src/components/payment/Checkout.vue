<script setup lang="ts">
import {ref, defineProps} from "vue";
import {PaymentMethod, agentPaymentMethodList} from "@/models/payment.ts";
import OfflinePay from "@components/payment/OfflinePay.vue";

const props = defineProps({
  noticeType: String,
  notice: String,
  finalAmount: Number,
  paymentReference: String,
})
const paymentMethod = ref<PaymentMethod>()
const paymentDrawer = ref(false)
async function pay(methodName: PaymentMethod) {

  paymentMethod.value = methodName

  switch (methodName) {
    case PaymentMethod.WECHATPAY:
      break;
      // case PaymentMethod.WECHAT_OFFLINE:
      //     $router.push({name: 'payment-wechat-offline-qrcode', query: {amount: finalPrice.value.toString()}})
      //     break;
      // case PaymentMethod.ALIPAY_OFFLINE:

      //     // $router.push({name: 'payment-alipay-offline-qrcode', query: {amount: finalPrice.value.toString()}})
      //     break;
    default:
      paymentDrawer.value = true
      break;
  }
}

function closePaymentDrawer() {
  paymentDrawer.value = false
}

function paymentOfflineConfirm() {
  paymentDrawer.value = false
}

const columns = [
  {
    key: 'label',
    title: '付款方式'
  }
]

function rowClick(record: any) {
    return {
        onClick: () => {
            pay(record.name)
            console.log(record);
        },
    };
}
</script>

<template>
  <div>
    <h3 class="mt-8 mb-4">请选择付款方式</h3>

    <a-alert class="mx-6" v-if="props.notice" :closable="false" :message="props.notice" :type="props.noticeType" />

    <a-card class="mx-6 mt-8">
      <div class="mb-4">
        待支付金额: <span class="text-sky-500">{{finalAmount}}</span>
      </div>
      <a-table size="large" :data-source="agentPaymentMethodList" :columns="columns" :show-header="false" :pagination="false" :custom-row="rowClick">

        <template #bodyCell="{ column, record }">
          <template v-if="column.key == 'label'">
            <div class="flex justify-center">{{ record.label }}</div>
          </template>
        </template>

      </a-table>
    </a-card>

    <a-drawer v-model:open="paymentDrawer" placement="bottom" size="default" :with-header="false"
               :destroy-on-close="true" :show-close="true" :wrapperClosable="true">
      <offline-pay
          v-if="paymentMethod && paymentMethod != PaymentMethod.WECHATPAY"
          :amount="finalAmount"
          :payment-method="paymentMethod"
          :payment-reference="paymentReference as string"
          @click-cancel="closePaymentDrawer"
          @payment-confirm="paymentOfflineConfirm" />
    </a-drawer>
  </div>
</template>

<style scoped>

</style>