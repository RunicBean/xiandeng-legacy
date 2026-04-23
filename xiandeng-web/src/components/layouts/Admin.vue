
<template>
    <div class="common-layout">
        <!-- <a-button @click="themeStore.switchDark">切换主题</a-button> -->
        <a-layout class="">
            <a-layout-header class="shadow-lg">
                <AdminHeader />


            </a-layout-header>
            <a-layout>
                <a-layout-sider class="!w-12 md:!w-48 shadow-md min-h-[100vh]" collapsed-width="50" collapsible :default-collapsed="profileStore.windowSize as number < WindowSize.Medium" :trigger="null">
                    <router-view name="SideBar"></router-view>
                </a-layout-sider>
                <a-layout-content class="mt-8">
                    <router-view name="Main"></router-view>
                </a-layout-content>
            </a-layout>
            <a-layout-footer class="!fixed !bottom-0 h-12 !bg-white w-full">
                <PortalFooter copyname="研伴文化" />
            </a-layout-footer>
        </a-layout>
    </div>
</template>

<script setup lang="ts">
import { useProfileStore } from '@/stores/profile';
import { WindowSize } from '@/helpers/constants';
import PortalFooter from '@/components/portal/segments/PortalFooter.vue'
import AdminHeader from '@/components/admin/layouts/AdminHeader.vue'
import {getUserViewPrivilege} from "@/api/request/uam.ts";
import {onMounted} from "vue";

const profileStore = useProfileStore()

onMounted(async () => {
    await getUserViewPrivilege("agent,hq")
            .then(data => profileStore.userViewPrivilege = data ? data : [])
})

</script>

<style scoped>
.el-container {
  font-family: "Noto Sans SC", system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
}

</style>
