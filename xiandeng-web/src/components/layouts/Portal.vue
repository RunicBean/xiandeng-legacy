<template>
    <div class="portal-container">
      <a-layout class="h-[100vh]">
        <a-layout-header>
          <PortalHeader />
        </a-layout-header>
        
        <a-layout-content class="w-[100vw] h-full">
          <router-view></router-view>
        </a-layout-content>
        <a-layout-footer class="bg-white bg-opacity-45 shadow-md !fixed !bottom-0 h-12">
          <PortalFooter copyname="研伴文化" />
        </a-layout-footer>
      </a-layout>
    </div>
</template>

<script setup lang="ts">
import PortalHeader from '@/components/portal/segments/PortalHeader.vue'
import PortalFooter from '@/components/portal/segments/PortalFooter.vue'


</script>

<style scoped>

/* .el-main {
  display: flex;
} */
.ant-layout-header {
  padding: 0;
}
.ant-layout {
  font-family: "Noto Sans SC", system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
}
/* .portal-container {
  background: url("https://dorian-personal-public.oss-cn-shenzhen.aliyuncs.com/xiandeng.net.cn/public/images/portal-bg.jpg?x-oss-process=image/resize,w_1000") no-repeat;
  background-size: cover;
} */

.ant-layout-footer {
  /* position: fixed;  */
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100vw;
  bottom: 0;
  font-size: small;
  background-color: #fff;
  color: rgb(133, 133, 133);
  /* border-top: 1px solid black; */
  box-shadow: rgba(0, 0, 0, 0.24) 0px 3px 8px;
}
</style>