<script setup lang="ts">

import ItemRow from "./ItemRow.vue";
import {ref, onMounted} from "vue";

const props = defineProps(["dataL"])

const dataList = ref([])
const groupCountNumber = ref(0)
const groupCount = ref(0)

onMounted(() => {
    console.log(props.dataL)
    dataList.value = props.dataL
    groupCountNumber.value = dataList.value.length / 3
    groupCount.value = Number.isInteger(groupCountNumber.value) ? groupCountNumber.value : Math.floor(groupCountNumber.value) + 1
})


</script>

<template>
    <div>
        <template v-for="i in [...Array(groupCount).keys()]">
            <a-divider />
            <ItemRow :slice-numbers="[groupCount, i * 3, (i + 1) * 3 < dataList.length ? (i + 1) * 3 : dataList.length]" :data-list="dataList.slice(i * 3, (i + 1) * 3 < dataList.length ? (i + 1) * 3 : dataList.length)" />
        </template>
    </div>

</template>

<style scoped>

.ant-divider-horizontal {
    margin: 0;
}

h2 {
    margin: 10px 12px;
}
</style>