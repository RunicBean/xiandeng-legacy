<template>
    <div>
        <a-config-provider :theme="{
            components: {
                Menu: {
                    controlHeightLG: 48,
                    marginXXS: 10,
                }
            }
        }">
            <a-menu
                class="el-menu-vertical-demo"
                @click="handleOpen"
                :collapse="profStore.windowSize == WindowSize.Small"
                v-model:openKeys="openKeys"
                v-model:selectedKeys="selectedKeys"
                :items="items"
            >
            </a-menu>
        </a-config-provider>
    </div>
</template>

<script setup lang="ts">
// import { checkWindowSize } from '@/helpers/common';
import {WindowSize} from '@/helpers/constants';
// import { AccountType, isHQOrAgent } from '@/models/account';
import {useProfileStore} from '@/stores/profile';
import {h, onMounted, ref, computed} from 'vue';
import {useRoute, useRouter} from 'vue-router';
import {getMenuItem as getItem} from '@/helpers/components';

import {
    AccountBookOutlined,
    AppstoreOutlined, BarChartOutlined,
    ContainerOutlined,
    HomeOutlined,
    LinkOutlined,
    UserOutlined
} from '@ant-design/icons-vue';


const route = useRoute()
const router = useRouter()
const profStore = useProfileStore()
// function getItem(
//   label: VueElement | string,
//   key: string,
//   icon?: any,
//   children?: ItemType[],
//   type?: 'group',
// ): ItemType {
//   return {
//     key,
//     icon,
//     children,
//     label,
//     type,
//   } as ItemType;
// }



const handleOpen = ({ key }: { key: string }) => {
  console.log(key)
  router.push({name: key})
}


const items = computed(() => {
    return [
                getItem('首页', appendOrg('adm-home'), () => h(HomeOutlined)),
                getItem('邀请注册', appendOrg('adm-resource-invitation'), () => h(LinkOutlined)),
                profStore.getItemByPrivilegeOrNull(
                    "agent_myagent_menu",
                    getItem('我的代理', appendOrg('adm-myagents'), () => h(UserOutlined))),
                profStore.getItemByPrivilegeOrNull(
                    "agent_students_menu",
                    getItem('学员管理', appendOrg('adm-resource-student'), () => h(UserOutlined))),
                profStore.getItemByPrivilegeOrNull(
                    "agent_my_student_menu",
                    getItem('我的学员', appendOrg('adm-resource-my-student'), () => h(UserOutlined))),
                getItem('销售代码', appendOrg('adm-resource-coupon'), () => h(ContainerOutlined)),
                // getItem('调账管理', appendOrg('adm-resource-adjustment'), () => h(AccountBookOutlined)),
                profStore.getItemByPrivilegeOrNull(
                    "agent_orders_menu",
                    getItem('订单管理', appendOrg('adm-resource-dependent-sales-orders'), () => h(BarChartOutlined))),
                profStore.getItemByPrivilegeOrNull(
                    "agent_my_orders_menu",
                    getItem('我的订单', appendOrg('adm-resource-dependent-sales-myorders'), () => h(BarChartOutlined))),

                profStore.getItemByPrivilegeOrNull(
                    "agent_inventory_menu",
                    getItem('产品库存', appendOrg('adm-resource-inventory'), () => h(ContainerOutlined))),
                profStore.getItemByPrivilegeOrNull(
                    "agent_delivery_menu",
                    getItem('服务单', appendOrg('adm-resource-delivery'), () => h(ContainerOutlined))),
                getItem('结算详情', '#', () => h(AccountBookOutlined), [
                    profStore.getItemByPrivilegeOrNull(
                        "agent_balance_menu", getItem('余额概览', appendOrg('adm-resource-wallet-balance'))),
                    profStore.getItemByPrivilegeOrNull(
                        "agent_balance_detail_menu", getItem('收支明细', appendOrg('adm-resource-wallet-activity'))),
                ]),
                //   getItem('代理配置', 'adm-resource-a-config', () => h(SettingOutlined)),

                getItem('产品信息', 'sub2', () => h(AppstoreOutlined), [
                    profStore.getItemByPrivilegeOrNull(
                        "agent_my_planning_menu", getItem('我的学员规划报告', appendOrg('adm-resource-my-planning_report'))),
                    profStore.getItemByPrivilegeOrNull(
                        "agent_planning_menu", getItem('学员规划报告', appendOrg('adm-resource-planning_report'))),
                    getItem('考研就业参考', appendOrg('adm-resource-jobreference')),
                ]),

                { type: 'divider' },
                getItem('个人中心', 'profile', () => h(UserOutlined), [
                    getItem('提现信息管理', appendOrg('adm-resource-profile-withdrawmethod'))
                ]),
            ]
})
// const items = ref<ItemType[]>([])
const openKeys = ref<string[]>([])
const selectedKeys = ref<string[]>([])
onMounted(() => {
  selectedKeys.value = [route.name as string]
})

// const HQOrAgentOnly = computed(() => {
//     return profStore.roleData?.accounttype && isHQOrAgent(profStore.roleData.accounttype as AccountType)
// })

function appendOrg(route: string) {
    return profStore.orgMetadata?.id ? `org-${route}` : route
}

// const items: ItemType[] = reactive([
//
//
// ]);
</script>

