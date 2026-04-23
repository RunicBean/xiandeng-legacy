<template>
    <div class="w-full h-full footer flex justify-center items-center">
        <div>Powered by {{ copyname }}. <a href="https://beian.miit.gov.cn/" style="text-decoration: none;">辽ICP备2024022999号-1</a></div>
    </div>
</template>

<script setup lang="ts">
defineProps<{
    copyname: string
}>()
</script>

<style scoped>
</style>