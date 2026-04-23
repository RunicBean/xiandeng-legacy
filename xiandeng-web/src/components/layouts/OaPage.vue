<template>
    <div class="portal-container">
      <a-layout class="">
        <a-layout-header class="shadow-md">
          <router-view name="oa_header"></router-view>
        </a-layout-header>
        <div class="w-[100vw] h-full">
          <router-view></router-view>
        </div>
        <!-- <a-layout-content class="w-[100vw] h-full">
          <router-view></router-view>
        </a-layout-content>
        <a-layout-footer>
          <PortalFooter copyname="研伴文化" />
        </a-layout-footer> -->
      </a-layout>
      
    </div>
</template>

<script setup lang="ts">


</script>

<style scoped>

/* .el-main {
  display: flex;
} */
.el-header {
  padding: 0;
}
.el-container {
  font-family: "Noto Sans SC", system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
}
/* .portal-container {
  background: url("https://dorian-personal-public.oss-cn-shenzhen.aliyuncs.com/xiandeng.net.cn/public/images/portal-bg.jpg?x-oss-process=image/resize,w_1000") no-repeat;
  background-size: cover;
} */


</style>