<template>
    <div>
        <h1>收支明细</h1>
        <!-- <a-menu mode="horizontal">
            <a-menu-item key="1">收入明细</a-menu-item>
            <a-menu-item key="2">提现记录明细</a-menu-item>
            <a-menu-item key="3">三单循环解锁查询</a-menu-item>
        </a-menu> -->
        <a-tabs>
            <a-tab-pane key="1">
                <template #tab>收支明细</template>
                <ActivityDetails />
            </a-tab-pane>
            <a-tab-pane key="2">
                <template #tab>提现记录明细</template>
                <WithdrawDetails />
            </a-tab-pane>
            <a-tab-pane key="3">
                <template #tab>三单循环解锁查询</template>
                <TripleAwardDetails />
            </a-tab-pane>
        </a-tabs>
    </div>
</template>

<script setup lang="ts">
import ActivityDetails from './ActivityDetails.vue';
import TripleAwardDetails from './TripleAwardDetails.vue';
import WithdrawDetails from './WithdrawDetails.vue';


</script>

<style scoped>

</style>