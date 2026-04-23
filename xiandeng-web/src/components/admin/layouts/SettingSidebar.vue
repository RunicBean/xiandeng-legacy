<template>
    <div>
        <a-menu
            :default-active="routeIndex"
            class="el-menu-vertical-demo"
            @open="handleOpen"
            @close="handleClose"
        >
            <a-menu-item index="user">
                <UserOutlined />
                <router-link :to="{name: 'adm-setting-user'}">用户管理</router-link>
            </a-menu-item>

            <el-sub-menu index="1">
            <template #title>
                <el-icon><location /></el-icon>
                <span>Navigator One</span>
            </template>
            <el-menu-item-group title="Group One">
                <el-menu-item index="1-1">item one</el-menu-item>
                <el-menu-item index="1-2">item two</el-menu-item>
            </el-menu-item-group>
            <el-menu-item-group title="Group Two">
                <el-menu-item index="1-3">item three</el-menu-item>
            </el-menu-item-group>
            <el-sub-menu index="1-4">
                <template #title>item four</template>
                <el-menu-item index="1-4-1">item one</el-menu-item>
            </el-sub-menu>
            </el-sub-menu>
            <el-menu-item index="2">
            <el-icon><menu /></el-icon>
            <span>Navigator Two</span>
            </el-menu-item>
            <el-menu-item index="3" disabled>
            <el-icon><document /></el-icon>
            <span>Navigator Three</span>
            </el-menu-item>
            <el-menu-item index="4">
            <el-icon><setting /></el-icon>
            <span>Navigator Four</span>
            </el-menu-item>
        </a-menu>
    </div>
</template>

<script setup lang="ts">
import { useRoute } from 'vue-router';
import { ref } from 'vue';
const route = useRoute()
const routeIndex = ref<string>(route.path.split('/')[3])
const handleOpen = (key: string, keyPath: string[]) => {
  console.log(key, keyPath)
}
const handleClose = (key: string, keyPath: string[]) => {
  console.log(key, keyPath)
}

</script>

<style scoped>

</style>