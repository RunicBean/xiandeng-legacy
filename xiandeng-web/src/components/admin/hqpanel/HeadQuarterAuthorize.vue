<template>
    <div>
        <h1>总部授权</h1>
        <a-tabs v-model:activeKey="activeName" @change="handleClick">
            <a-tab-pane key="adm-hqpanel-authorize-student" tab="学生"></a-tab-pane>
            <a-tab-pane key="adm-hqpanel-authorize-agent" tab="代理"></a-tab-pane>
        </a-tabs>
        <router-view @stop-loading="stopLoading" />
    </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { message } from 'ant-design-vue'

const $route = useRoute()
const $router = useRouter()

const activeName = ref($route.name as string)

const loading = ref(false)
function startLoading() {
    loading.value = true
    message.loading('加载中，请等待……', 0)
}

function stopLoading() {
    loading.value = false
    message.destroy()
}

async function handleClick(key: string) {
    startLoading()
    await $router.push({ name: key })
    stopLoading()
}

onMounted(() => {
    console.log($route)
})
</script>

<style>
.mobile-date-picker {
    max-width: 100vw !important;
}
</style>