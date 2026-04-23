import {createRouter, createWebHistory} from 'vue-router'
import {
  requireAgentCheck,
  requireAuth,
  requireEntityMap,
  requireRole,
  requireRoleData,
  setupWindowSizeEvent
} from './guards'
import _ from 'lodash';
import {orgRoutes, routes} from "@/routes/routes.ts";
import {useProfileStore} from "@/stores/profile.ts";
import {getOrgMetadata} from "@/api/request/org.ts";
import {notification} from "ant-design-vue";
import {OFFICIAL_ACCOUNT_PAGE_URL} from "@/helpers/constants.ts";

// const orgRoutes: RouteRecordRaw[] = [
//   {
//     path: '/org/:org_name',
//     component: () => import('@/components/OrgView.vue'),
//     children: _.cloneDeep(routes).map(route => ({
//       ...route,
//       name: route.name ? `org-${route.name as string}` : route.name,
//       path: route.path.replace(/^\//, '') // 移除路径前的斜杠，使其成为相对路径
//     }))
//   }
// ]

// combine routes and orgRoutes
// const combinedRoutes = [...orgRoutes, ...routes]
// console.log(combinedRoutes)
  // 3. 创建路由实例并传递 `routes` 配置
  // 你可以在这里输入更多的配置，但我们在这里
  // 暂时保持简单
const router = createRouter({
    // 4. 内部提供了 history 模式的实现。为了简单起见，我们在这里使用 hash 模式。
    history: createWebHistory(),
    routes: [...routes, ...orgRoutes], // `routes: routes` 的缩写
  })

// router.beforeEach(to => {
//   if (to.path.startsWith('/org/')) {
//     console.log('add org routes')
//     for (const route of orgRoutes) {
//       router.addRoute(route)
//     }
//   } else {
//     console.log('add default routes')
//     for (const route of routes) {
//       router.addRoute(route)
//     }
//   }
//   return to.fullPath
// })
// add each route of orgroutes to router
// for (const route of orgRoutes) {
//   router.addRoute(route)
// }
router.beforeEach(to => {
    const profileStore = useProfileStore()
    if (to.path.startsWith('/org/')) {
        getOrgMetadata(to.params.org_name as string)
            .then((res) => {
                profileStore.orgMetadata = {...res.data, uri: to.params.org_name as string}
            })
    } else if (to.params.org_name && (to.params.org_name).length == 1) {
        getOrgMetadata(to.params.org_name[0] as string)
            .then((res) => {
                profileStore.orgMetadata = {...res.data, uri: to.params.org_name[0] as string}
            })
            .catch(err => {
                notification.error({
                    message: '获取机构元数据失败',
                    description: err.response.data.message,
                    duration: 0
                })
            })
    } else {
        profileStore.orgMetadata = {
            config: '',
            logourl: '/images/xiandeng-report-logo.png',
            sitename: '先登社区',
            redirecturl: OFFICIAL_ACCOUNT_PAGE_URL
        }
    }
})
router.beforeEach(requireRole) // 请求的是学生访问的页面还是代理访问的，后端使用
router.beforeEach(requireAuth) // 获取 auth 信息，前端使用
router.beforeEach(requireAgentCheck) // 检查 auth 中的 agent 信息，前端使用
router.beforeEach(requireRoleData) // 获取角色信息，前端使用
router.beforeEach(setupWindowSizeEvent)
router.beforeEach(requireEntityMap)

export default router

