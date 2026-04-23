<script setup lang="ts">
import {onMounted, ref} from 'vue'
import Checkout from '@/components/payment/Checkout.vue';
import {useRoute} from "vue-router";
import {useRequest} from "vue-request";
import {getAccountSignupData, type Account} from "@/api/request/uam.ts";


const $route = useRoute()
onMounted(() => {
  console.log($route.query.account_id)
})

const accountData = ref<Account>()
useRequest<Account>(getAccountSignupData, {
  defaultParams: [$route.query.account_id as string],
  onSuccess: (data) => {
    console.log(data)
    accountData.value = data
  }
})

</script>

<template>
  <div>
    <checkout
        v-if="accountData"
        :notice="`您的账号${accountData.original_type == null || accountData.original_type == '' ? '激活' : '升级'}中，请确保完成付款。如有付款已完成或有其他疑问，请联系总部。`"
        notice-type="error"
        :final-amount="Number(accountData.pending_fee)"
        :payment-reference="accountData.account_name + '意向金'"
    />
    <a-button :href="$route.query.next" class="mt-6 mr-6 float-end" v-if="$route.query.next" type="primary">继续</a-button>
  </div>
</template>

<style scoped>

</style>