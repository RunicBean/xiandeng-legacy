<script setup lang="ts">
import { useThemeStore } from './stores/theme';
import locale from 'ant-design-vue/es/date-picker/locale/zh_CN';


// const locale = ElementPlusLocaleZhCn;
const themeStore = useThemeStore();


</script>

<template>
  <a-config-provider :locale="locale" :theme="{
    algorithm: themeStore.algorithm,
    // token: {
    //   colorPrimary: '#00b96b',
    // },
    components: {
      Layout: {
        colorBgHeader: themeStore.isDark ? '#000' : '#fff',
      },
    },
    }">
    <router-view></router-view>
  </a-config-provider>
  
</template>

<style scoped>
/* .logo {
  height: 6em;
  padding: 1.5em;
  will-change: filter;
  transition: filter 300ms;
}
.logo:hover {
  filter: drop-shadow(0 0 2em #646cffaa);
}
.logo.vue:hover {
  filter: drop-shadow(0 0 2em #42b883aa);
} */
</style>
