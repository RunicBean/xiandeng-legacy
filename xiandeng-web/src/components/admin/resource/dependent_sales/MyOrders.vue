<script setup lang="ts">
import {listRestrictedOrdersByReferral} from "@/api/request/order.ts";
import OrdersComponent from "@components/admin/resource/dependent_sales/OrdersComponent.vue";

</script>

<template>
    <div>
        <OrdersComponent
            title="我的订单"
            :list-order-function="listRestrictedOrdersByReferral"
        />
    </div>
</template>

<style scoped>

</style>
