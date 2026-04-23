<script setup lang="ts">
import {watch, ref} from "vue";
import {listShowcaseItems} from "@/api/request/showcase";
import DetailedItems from "@/components/showcase/layoutOne/DetailedItems.vue";

const groupMap = ref({})
const isGroupMapUpdated = ref(false)
const props = defineProps({
    companyName: String
})
// const mainItemsContainer = ref(null)

function groupByGroupTitle(dataList: Array<{id: number, grouptitle: string}>) {
    let groupMap: any = {}
    for (let dataObj of dataList.sort((a, b) => a.id - b.id)) {
        if (Object.keys(groupMap).indexOf(dataObj.grouptitle) < 0) {
            groupMap[dataObj.grouptitle] = []
        }
        groupMap[dataObj.grouptitle].push(dataObj)
    }
    return groupMap
}

watch(() => props.companyName, (newName) => {
  listShowcaseItems(newName as string).then((res) => {
        groupMap.value = groupByGroupTitle(res.data)
    console.log(groupMap.value)
        isGroupMapUpdated.value = true


    })

})
</script>

<template>
    <div>
        <div v-if="isGroupMapUpdated"></div>
        <template v-for="(dataL, groupName) in groupMap">
            <h3>{{groupName}}</h3>
            <DetailedItems :data-l="dataL" class="mb-12" />
        </template>
    </div>
</template>

<style scoped>
</style>