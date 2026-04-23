<script setup lang="ts">

import Item from "./Item.vue";
defineProps<{
    dataList: Array<{
        imagelink: string,
        extlink: string,
        title: string
    }>,
    sliceNumbers: Array<number>
}>()

</script>

<template>
    <a-row>
        <a-col :span="8" class="border-r">
            <Item
                :image-link="dataList[0].extlink"
                :image-url="dataList[0].imagelink"
                :title="dataList[0].title"

            />
        </a-col>

        <a-col :span="8" class="border-r">
            <template v-if="dataList.length > 1">
                <Item
                    :image-link="dataList[1].extlink"
                    :image-url="dataList[1].imagelink"
                    :title="dataList[1].title"
                />
            </template>

        </a-col>
        <a-col :span="8">
            <template v-if="dataList.length > 2">
                <Item
                    :image-link="dataList[2].extlink"
                    :image-url="dataList[2].imagelink"
                    :title="dataList[2].title"
                />
            </template>

        </a-col>
    </a-row>
</template>

<style scoped>
.ant-divider-vertical {
    height: 100%;
    margin: 0 -0.5px;
}

.el-divider--vertical {
  height: 100%;
  margin: 0 -0.5px;
}
</style>