<template>
    <div>
        <h1>服务商订单</h1>
        <a-tabs>
            <a-tab-pane key="1" tab="未确认服务单">
                <UnconfirmDelivery />
            </a-tab-pane>
            <a-tab-pane key="2" tab="已确认服务单">
                <ConfirmedDelivery />
            </a-tab-pane>
        </a-tabs>
    </div>
</template>

<script setup lang="ts">
import ConfirmedDelivery from './delivery/ConfirmedDelivery.vue';
import UnconfirmDelivery from './delivery/UnconfirmDelivery.vue';



</script>

<style scoped>

</style>