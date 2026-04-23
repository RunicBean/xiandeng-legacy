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
                v-model:openKeys="openKeys"
                v-model:selectedKeys="selectedKeys"
                :items="items"
            ></a-menu>
        </a-config-provider>
        
    </div>
</template>

<script setup lang="ts">
import { useRoute, useRouter } from 'vue-router';
import { reactive, h, ref, onMounted } from 'vue';
import { getMenuItem } from '@/helpers/components';
import { AccountBookOutlined, EditOutlined, StarOutlined } from '@ant-design/icons-vue';
import type { ItemType } from 'ant-design-vue';

const route = useRoute()
const router = useRouter()

const selectedKeys = ref<string[]>([])
onMounted(() => {
    selectedKeys.value = [route.name as string]
})
const openKeys = ref<string[]>([])
const handleOpen = (event: any) => {
  console.log(event)
  router.push({name: event.key})
}
// const handleClose = (key: string, keyPath: string[]) => {
//   console.log(key, keyPath)
// }

const items: ItemType[] = reactive([
    // {
    //     key: 'authorize',
    //     label: '总部授权',
    //     icon: Star,
    //     children: [
    //         {
    //             key: 'authorize-student',
    //             label: '学生授权',  
    //         }
    //     ]
    // }
    getMenuItem('总部授权', 'adm-hqpanel-authorize-student', () => h(StarOutlined)),
    getMenuItem('代理编辑', 'adm-hqpanel-agent-editor', () => h(EditOutlined)),
    getMenuItem('库存审批', 'adm-hqpanel-inventory-approval', () => h(EditOutlined)),
    getMenuItem('调账管理', 'adm-hqpanel-adjustment', () => h(AccountBookOutlined)),
])
</script>

<style scoped>

</style>