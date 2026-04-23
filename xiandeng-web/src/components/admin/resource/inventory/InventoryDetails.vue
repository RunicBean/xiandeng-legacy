<template>
    <a-tabs v-model:activeKey="activeKey">
        <a-tab-pane key="1" tab="课程订单">
            <CourseOrders ref="courseOrdersRef" @updateOrder="updateOrder" />
        </a-tab-pane>
        <a-tab-pane key="2" tab="库存变化明细">
            <InventoryActivity ref="inventoryActivityRef" />
        </a-tab-pane>
    </a-tabs>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import CourseOrders from './CourseOrders.vue';
import InventoryActivity from './InventoryActivity.vue';

const activeKey = ref('1');

const emit = defineEmits(['updateCourseOrders']);

function updateOrder(order: any) {
  emit('updateCourseOrders', order);
}

const courseOrdersRef = ref();
const inventoryActivityRef = ref();
function updateAllData() {
    courseOrdersRef.value.fetchData();
    inventoryActivityRef.value.fetchData();
}

defineExpose({updateAllData})
</script>

<style scoped></style>