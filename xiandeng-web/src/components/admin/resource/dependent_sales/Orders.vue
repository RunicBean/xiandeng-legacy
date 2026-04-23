<script setup lang="ts">
import {listRestrictedOrders} from "@/api/request/order.ts";
import OrdersComponent from "@components/admin/resource/dependent_sales/OrdersComponent.vue";

</script>

<template>
    <div>
        <OrdersComponent
            title="订单管理"
            :list-order-function="listRestrictedOrders"
        />
    </div>
</template>

<style scoped>

</style>
