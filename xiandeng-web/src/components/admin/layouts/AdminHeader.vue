<template>
    <div class="flex items-center justify-between">
        <div class="flex items-center">
            <img
                style="width: 24px"
                :src="profileStore.orgMetadata?.logourl"
                alt="Element logo"
            />
            <div class="text-sm md:text-lg ml-3">{{profileStore.orgMetadata?.sitename}}管理平台</div>
        </div>
        <div class="flex items-center space-x-2">
            <div class="flex items-center space-x-4">
                <div class="flex items-center">
                    <img width="24" src="/images/diamond_flat.svg" alt="" />
                    {{ resourceStore.entityTypeWordingMap[profileStore.roleData?.accounttype as AccountType] }}
                </div>
                <a-tooltip v-if="profileStore.userProfile.agentCheck?.number == 100301 || upgradeConfirmed">
                    <template #title>
                        此用户已有升级目标
                    </template>
                    <a-button type="default" size="default" @click="goPayment" :loading="paymentModalLoading">升级中</a-button>

                </a-tooltip>
                <a-button v-else-if="profileStore.roleData?.accounttype !== AccountType.HQ_AGENT" type="default" size="default" @click="upgrade" :disabled="upgradeConfirmed">升级</a-button>
                <a-button v-else disabled type="default" size="default" @click="upgrade">已是最高等级</a-button>
            </div>
            <a-menu
                :selectedKeys="selectedKeys"
                class="el-menu-demo !hidden md:!flex"
                mode="horizontal"
                :ellipsis="false"
                @select="handleSelect"
                :items="items"
            >
            </a-menu>
        </div>

        <a-modal v-model:open="upgradeModalVisible" title="升级" okText="确认升级" cancelText="取消" @ok="confirmUpgrade">
            <p>请先联系总部明确权益变化细节。</p>
            <ContactHeadQuarter />
            <a-divider />
            <a-form :rules="targetTypeFormRules" :model="targetTypeFormModel" ref="targetTypeForm">
                <a-form-item name="targetAccountType" label="升级账号类型">
                    <a-select v-model:value="targetTypeFormModel.targetAccountType">
                        <template v-for="(item, _) in AgentAccountTypeHierarchySerial"><a-select-option v-if="item[1] < (accountTypeSerial as number)" :key="item[0]" :value="item[0]">{{ resourceStore.entityTypeWordingMap[item[0]] }}</a-select-option></template>

                    </a-select>
                </a-form-item>
            </a-form>

        </a-modal>

        <a-modal v-model:open="paymentModalVisible" title="付款" okText="确认付款" cancelText="取消" @ok="confirmPayment">
            <p>升级到<span class="text-red-500 font-bold">{{ targetTypeWording }}</span>中</p>
            <checkout
                v-if="accountData"
                :notice="`您的账号${accountData.original_type == null ? '激活' : '升级'}中，请确保完成付款。如有付款已完成或有其他疑问，请联系总部。`"
                notice-type="error"
                :final-amount="Number(accountData.pending_fee)"
                :payment-reference="accountData.account_name + '意向金'"
            />
        </a-modal>

        <a-modal v-model:open="updateNicknameModalVisible" title="修改昵称" okText="确认修改" cancelText="取消" @ok="confirmUpdateNickname">
            <a-form :rules="updateNicknameFormRules" :model="updateNicknameFormModel" ref="updateNicknameForm">
                <a-alert v-if="profileStore.userProfile.aliasName" type="info" :message="`原昵称：${profileStore.userProfile.aliasName}`" />
                <a-alert v-else type="info" message="未设置昵称，请设置。" />
                <a-divider />
                <a-form-item name="aliasName" label="新昵称">
                    <a-input v-model:value="updateNicknameFormModel.aliasName" />
                </a-form-item>
            </a-form>
        </a-modal>
    </div>
</template>

<script setup lang="ts">
import { useRoute } from 'vue-router';
import { ref, computed, h, onMounted } from 'vue';
import { useProfileStore } from '@/stores/profile';
import { buildBackendUrl } from '@/helpers/common';
import Checkout from '@/components/payment/Checkout.vue';
import { AccountType, AgentAccountTypeHierarchySerial, isHQ } from '@/models/account';
import { Avatar, FormInstance, MenuProps } from 'ant-design-vue';
import { Account, getAccountSignupData, updateNickname } from '@/api/request/uam';
import { upgradeAgent } from '@/api/request/agent';
import { useResourceStore } from '@/stores/resource';
import ContactHeadQuarter from '@/components/payment_components/ContactHeadQuarter.vue';
import { message } from 'ant-design-vue';

const resourceStore = useResourceStore()
const profileStore = useProfileStore()
const thisRoute = useRoute()

const selectedKeys = ref<string[]>([thisRoute.path.split('/')[2]])
const handleSelect = (key: string, keyPath: string[]) => {
  console.log(key, keyPath)
}


const logout = async () => {
    await fetch(buildBackendUrl("/auth/logout"))
    window.location.reload()
}

const HQOnly = computed(() => {
    return profileStore.roleData?.accounttype && isHQ(profileStore.roleData.accounttype as AccountType)
})

const items = ref<MenuProps['items']>([
//   {
//     key: 'mail',
//     // icon: () => h(),
//     label: h('div', {class: 'flex items-center h-full', innerHTML: logoHtmlContent}),
//     title: 'Navigation One',
//   },
  {
    key: 'resource',
    // icon: () => h(HomeOutlined),
    label: h('a', { href: profileStore.orgMetadata?.id ? `/org/${profileStore.orgMetadata.uri}/admin/resource/home` : '/admin' }, '后台资源'),
    title: '后台资源',
  },
]);

onMounted(() => {

    if (HQOnly.value) {
        items.value?.push({
            key: 'hqpanel',
            label: h('a', { href: '/admin/hqpanel/authorize/student' }, '总部面板'),
            title: '总部面板',
        })
    }
    items.value?.push({
        key: 'profile',
        label: h('div', {class: 'flex items-center space-x-2'}, [
            h('div', {class: 'name text-sm'}, profileStore.userProfile.aliasName || profileStore.userProfile.nickName),
            h(Avatar, {src: profileStore.userProfile.avatarUrl})
        ]),
        style: {
            display: 'flex',
            alignItems: 'center'
        },
        children: [
            {
                key: 'logout',
                label: '退出登录',
                title: '退出登录',
                onClick: logout
            },
            {
                key: 'updateNickname',
                label: '修改昵称',
                title: '修改昵称',
                onClick: openUpdateNicknameModal
            }
        ]
    })
})

// 升级对话框
const upgradeModalVisible = ref(false)
function upgrade() {
    upgradeModalVisible.value = true
}

const targetTypeForm = ref<FormInstance>()
const targetTypeFormModel = ref({
    targetAccountType: ""
})
const targetTypeFormRules = ref({
    targetAccountType: [{required: true, message: '请选择升级账号类型'}]
})
const targetTypeWording = computed(() => resourceStore.entityTypeWordingMap[targetTypeFormModel.value.targetAccountType as AccountType])
const confirmUpgradeLoading = ref(false)
const upgradeConfirmed = ref(false)
async function confirmUpgrade() {
    targetTypeForm.value?.validateFields().then(async () => {
        confirmUpgradeLoading.value = true
        console.log(targetTypeFormModel.value.targetAccountType)
        await upgradeAgent(targetTypeFormModel.value.targetAccountType as string, true)
        await getAccountSignupData(profileStore.userProfile.accountId as string).then(data => {
        accountData.value = data
            targetTypeFormModel.value.targetAccountType = data.target_type
        })
        upgradeModalVisible.value = false
        paymentModalVisible.value = true
        confirmUpgradeLoading.value = false
        upgradeConfirmed.value = true
    })
    .catch(error => {
        console.log(error)
    })
}

const accountTypeSerial = ref<number|undefined>(AgentAccountTypeHierarchySerial.get(profileStore.roleData?.accounttype as string))

// 付款对话框
const paymentModalLoading = ref(false)
const paymentModalVisible = ref(false)
async function confirmPayment() {
    paymentModalVisible.value = false
}

const accountData = ref<Account>()
async function goPayment() {
    paymentModalLoading.value = true
    await getAccountSignupData(profileStore.userProfile.accountId as string).then(data => {
        accountData.value = data
        targetTypeFormModel.value.targetAccountType = data.target_type
    })
    paymentModalVisible.value = true
    paymentModalLoading.value = false
}

const updateNicknameModalVisible = ref(false)
async function openUpdateNicknameModal() {
    updateNicknameModalVisible.value = true
}

const updateNicknameFormModel = ref({
    aliasName: ''
})
const updateNicknameFormRules = ref({
    aliasName: [{required: true, message: '请输入昵称'}]
})
const updateNicknameForm = ref<FormInstance>()
async function confirmUpdateNickname() {
    updateNicknameForm.value?.validateFields().then(async () => {
        await updateNickname(updateNicknameFormModel.value.aliasName)
        // profileStore.userProfile.aliasName = updateNicknameFormModel.value.aliasName
        updateNicknameModalVisible.value = false
        message.success('昵称修改成功')
        window.location.reload()
    })
    .catch(error => {
        console.log(error)
    })
}

</script>

<style scoped>

</style>
