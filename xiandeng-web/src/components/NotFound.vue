<template>
    <div class="h-[100vh] flex flex-col items-center justify-center">
        <a-result status="404" title="404" sub-title="找不到页面">
            
            <template #extra>
                <a-button type="primary" size="default" @click="home">返回首页</a-button>
            </template>
        </a-result>
    </div>
</template>

<script setup lang="ts">
import { useRouter } from 'vue-router';

const router = useRouter()
function home() {
    router.push({name: "construction"})
}
</script>

<style scoped>
</style>