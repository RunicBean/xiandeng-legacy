<script setup lang="ts">
import { calcSumPv } from '@/api/request/agent';

import { useRequest } from 'vue-request';
import { ref, onMounted } from 'vue';
import UnpartAgents from './myagent/UnpartAgents.vue'
import PartitionArea from './myagent/PartitionArea.vue'
import { Partition } from '@/models/account';

// 左区信息
// const {data: lData, run: runListMyLeftPartitionAgents} = useRequest(listMyPartitionAgents, {
//     defaultParams: ["L"]
// })

// const lSum = computed(() => {
//     if (!lData.value) return 0
//     return lData.value.reduce((acc: any, cur: any) => cur.sum ? acc + Number(cur.sum) : 0, 0)
// })

const selectedKeys = ref<Array<Partition>>([Partition.L])

const {run: runCalcSumPv} = useRequest(calcSumPv, {
    onSuccess: (data) => {
        sumPv.value = data
    }
})

const sumPv = ref({
    L: 0,
    R: 0
})
onMounted(() => {
    runCalcSumPv()
    console.log(sumPv);
    
})

const leftPartitionAreaRef = ref()
const rightPartitionAreaRef = ref()
function updateDataEvent() {
    if (sumPv && selectedKeys.value[0] == 'L') {
        leftPartitionAreaRef.value.runListSevenLevelAgents(Partition.L, true)
    } else if (sumPv && selectedKeys.value[0] == 'R') {
        rightPartitionAreaRef.value.runListSevenLevelAgents(Partition.R, true)
    }
}
// function changePartition({key}: {key: string}) {
//     console.log(key);
    
// }
</script>

<template>
    <div>
        <h1>代理分区</h1>

        <!-- 未分区代理 -->
        <UnpartAgents @update-data="updateDataEvent" />

        <a-divider direction="horizontal">
            分区业绩
            
            
            <!-- (总：<span class="text-red-500">左区：{{ sumPv?.L }}</span> | <span class="text-blue-500">右区：{{ sumPv?.R }}</span>) -->
        </a-divider>
        <a-menu v-model:selectedKeys="selectedKeys" mode="horizontal" class="flex">
                    <a-menu-item :key="Partition.L">
                        <span class="text-red-500 font-bold">左区(分区业绩：{{ sumPv.L }})</span>
                        <!-- <span>({{ sumPv?.L }})</span> -->
                    </a-menu-item>
                    <a-menu-item :key="Partition.R">
                        <span class="text-blue-500 font-bold">右区(分区业绩：{{ sumPv.R }})</span>
                        <!-- <span>({{ sumPv?.R }})</span> -->
                    </a-menu-item>
            </a-menu>
        
        
        <PartitionArea ref="leftPartitionAreaRef" v-if="sumPv && selectedKeys[0] == 'L'" partition="L" />
        <PartitionArea ref="rightPartitionAreaRef" v-if="sumPv && selectedKeys[0] == 'R'" partition="R" />

        
        
        
    </div>
</template>

<style scoped>
</style>