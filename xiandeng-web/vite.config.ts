import { defineConfig } from 'vite'
import path from 'path'
import vue from '@vitejs/plugin-vue'
import { visualizer } from "rollup-plugin-visualizer";
import viteCompression from 'vite-plugin-compression';
import importToCDN from 'vite-plugin-cdn-import';

const pathSrc = path.resolve(__dirname, 'src')

// https://vitejs.dev/config/
export default defineConfig({
  // build: {
  //   rollupOptions:{
  //     external: ['vue', 'element-plus', 'vue-demi', '@element-plus/icons-vue', 'ant-design-vue', '@ant-design/icons-vue', 'dayjs', 'dayjs/plugin/timezone', 'dayjs/plugin/utc'],
  //     plugins: [
  //         externalGlobals({
  //             vue: 'Vue',
  //             'element-plus': 'ElementPlus',
  //             'vue-demi': 'VueDemi',
  //             '@element-plus/icons-vue': 'ElementPlusIconsVue',
  //             'ant-design-vue': 'antd',
  //             // '@ant-design/icons-vue': 'antd',
  //             'dayjs': 'dayjs',
  //             'dayjs/plugin/timezone': 'dayjs/plugin/timezone',
  //             'dayjs/plugin/utc': 'dayjs/plugin/utc',
  //         }),
  //     ],
  //   }
  // },
  plugins: [
    vue(),
    viteCompression(),
    visualizer({
      gzipSize: true,
      brotliSize: true,
      emitFile: false,
      filename: "test.html", //分析图生成的文件名
      open:true //如果存在本地服务端口，将在打包后自动展示
    }),
    importToCDN({
      modules: [
        // 'dayjs',
          // {
          //     name: 'vue',
          //     var: 'Vue',
          //     path: 'https://testingcf.jsdelivr.net/npm/vue@3.5.10/dist/vue.runtime.global.prod.js',
          // },
          // {
          //   name: 'vue-router',
          //   var: 'VueRouter',
          //   path: 'https://testingcf.jsdelivr.net/npm/vue-router@4.4.5/dist/vue-router.global.min.js',
          // },
          // {
          //   name: 'axios',
          //   var: 'axios',
          //   path: 'https://testingcf.jsdelivr.net/npm/axios@1.7.7/dist/axios.min.js',
          // },
          // {
          //   name: 'dayjs',
          //   var: 'dayjs',
          //   path: [
          //     'https://testingcf.jsdelivr.net/npm/dayjs@1.11.13/dayjs.min.js',
          //     'https://testingcf.jsdelivr.net/npm/dayjs@1.11.13/plugin/customParseFormat.js',
          //     'https://testingcf.jsdelivr.net/npm/dayjs@1.11.13/plugin/weekday.js',
          //     'https://testingcf.jsdelivr.net/npm/dayjs@1.11.13/plugin/localeData.js',
          //     'https://testingcf.jsdelivr.net/npm/dayjs@1.11.13/plugin/weekOfYear.js',
          //     'https://testingcf.jsdelivr.net/npm/dayjs@1.11.13/plugin/weekYear.js',
          //     'https://testingcf.jsdelivr.net/npm/dayjs@1.11.13/plugin/advancedFormat.js',
          //     'https://testingcf.jsdelivr.net/npm/dayjs@1.11.13/plugin/quarterOfYear.js',
          //   ],
          // },
          // {
          //   name: 'ant-design-vue',
          //   var: 'antd',
          //   path: 'https://testingcf.jsdelivr.net/npm/ant-design-vue@4.2.5/dist/antd.min.js',
          //   css: 'https://testingcf.jsdelivr.net/npm/ant-design-vue@4.2.5/dist/reset.min.css',
          // },
          // {
          //   name: 'vue-request',
          //   var: 'VueRequest',
          //   path: 'https://testingcf.jsdelivr.net/npm/vue-request@2.0.4/dist/vue-request.min.js',
          // },
          // {
          //   name: 'lodash-es',
          //   var: '_',
          //   path: 'https://testingcf.jsdelivr.net/npm/lodash-es@4.17.21/lodash.min.js',
          // }
          // {
          //   name: '@ant-design/icons-vue',
          //   var: 'antd',
          //   path: 'https://testingcf.jsdelivr.net/npm/@ant-design/icons-vue@7.0.1/lib/index.min.js',
          // }
      ],
  }),
    // AutoImport({
    //   // Auto import functions from Vue, e.g. ref, reactive, toRef...
    //   // 自动导入 Vue 相关函数，如：ref, reactive, toRef 等
    //   imports: ['vue'],

    //   // Auto import functions from Element Plus, e.g. ElMessage, ElMessageBox... (with style)
    //   // 自动导入 Element Plus 相关函数，如：ElMessage, ElMessageBox... (带样式)
    //   // resolvers: [
    //   //   ElementPlusResolver(),

    //   //   // Auto import icon components
    //   //   // 自动导入图标组件
    //   //   IconsResolver({
    //   //     prefix: 'Icon',
    //   //   }),
    //   // ],

    //   dts: path.resolve(pathSrc, 'auto-imports.d.ts'),
    // }),
    // Components({
    //   resolvers: [
    //     // Auto register icon components
    //     // 自动注册图标组件
    //     // IconsResolver({
    //     //   enabledCollections: ['ep'],
    //     // }),
    //     // // Auto register Element Plus components
    //     // // 自动导入 Element Plus 组件
    //     // ElementPlusResolver(),
    //   ],

    //   dts: path.resolve(pathSrc, 'components.d.ts'),
    // }),

    // Icons({
    //   autoInstall: true,
    // }),
  ],
  resolve: {  
    alias: {  
      '@': path.resolve(__dirname, './src'),  
      '@assets': path.resolve(__dirname, './src/assets'),  
      '@components': path.resolve(__dirname, './src/components'),  
    }  
  },  
  server: {
    proxy: {
      '/server/api/v1': {
        target: 'http://127.0.0.1:8080',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/server/, ''),
      },
      '/ws/api/v1': {
        target: 'ws://127.0.0.1:8080',
        ws: true,
        rewrite: (path) => path.replace(/^\/ws/, ''),
      }
    }
  },
})
