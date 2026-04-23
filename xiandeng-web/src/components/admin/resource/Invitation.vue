<template>
    <div class="h-full">
        <div class="flex items-center justify-between">
            <h1>邀请注册</h1>
            <div class="flex gap-x-4">
                <a-dropdown v-if="profileStore.hasPrivilege('agent_invite_user')">
                    <a-button>邀请用户</a-button>
                    <template #overlay>
                        <a-menu>
                            <a-menu-item key="1" @click="openInviteAgentWithoutStuAcctModal">
                                没有注册过学生账号
                            </a-menu-item>
                            <a-menu-item key="2" @click="openInviteAgentWithStuAcctModal">
                                注册过学生账号
                            </a-menu-item>
                        </a-menu>
                    </template>
                </a-dropdown>
                <a-modal v-model:open="showInviteAgentWithoutStuAcctModal" title="邀请用户">
                    <a-form>
                        <a-form-item v-if="existStudentAcct" label="选择学生账户">
                            <a-select
                                v-if="existStudentAcct"
                                show-search
                                :filter-option="false"
                                @search="runListMyInvitedStudent"
                                :options="students"
                                :field-names="{label: 'accountname', value: 'userid'}"
                                v-model:value="inviteAgentWithoutStuAcctForm.student_user_id" placeholder="学生账号" clearable filterable class="w-full"
                            >
                                <template #option="{accountname, phone}">
                                    <div class="flex justify-between">
                                        <div>{{ accountname }}</div>
                                        <div>{{phone}}</div>
                                    </div>
                                </template>
                            </a-select>
                        </a-form-item>

                        <a-form-item label="角色">
                            <a-radio-group v-model:value="inviteAgentWithoutStuAcctForm.role_id">
                                <a-radio v-for="value in inviteAgentWithoutStuAcctRoleOptions" :value="value.id">{{value.rolename_cn}}</a-radio>
                            </a-radio-group>
                        </a-form-item>
                    </a-form>
                    <vue-qrcode v-if="!existStudentAcct && inviteAgentWithoutStuAcctForm.role_id" class="max-w-40 max-h-40" :value="inviteSignupUrl"></vue-qrcode>
                    <template #footer>
                            <a-button v-if="existStudentAcct" type="primary" @click="runStudentJoinAgent">
                                继续
                            </a-button>
                            <a-button v-else-if="inviteAgentWithoutStuAcctForm.role_id" type="default" @click="copyToClipboard(inviteSignupUrl)">
                                复制二维码链接
                            </a-button>
                        </template>
                </a-modal>

                <a-button type="primary" @click="onAgentToStudent">
                    创建学员账号
                </a-button>


            </div>

        </div>
        <a-modal v-model:open="showAgentToStudentModal" title="创建学员账号" @ok="onAgentToStudentConfirm">
            <a-form class="flex flex-col gap-4" ref="agentToStudentFormRef" layout="inline" :model="agentToStudentForm" :rules="agentToStudentRules">
                <a-form-item label="学员账号姓名" name="accountName">
                    <a-input v-model:value="agentToStudentForm.accountName"></a-input>
                </a-form-item>
                <a-form-item label="角色" name="kind">
                    <a-radio-group v-model:value="agentToStudentForm.kind">
                        <a-radio-button value="student">学生</a-radio-button>
                        <a-radio-button value="guardian">家长</a-radio-button>
                    </a-radio-group>
                </a-form-item>
                <a-form-item label="与学员的关系" name="relationship" v-if="agentToStudentForm.kind == 'guardian'">
                    <a-input v-model:value="agentToStudentForm.relationship"></a-input>
                </a-form-item>
            </a-form>
        </a-modal>

        <template v-if="hasAgentCodePrivilege">
            <a-divider orientation="left">代理注册</a-divider>
            <div class="flex flex-wrap gap-4">
                <a-card v-for="(item, index) in assignedCodes" :key="index" shadow="hover" :title="resourceStore.entityTypeWordingMap[item.createType]">
                    <div class="qrcode">
                        <vue-qrcode class="max-w-40 max-h-40" :value="codeToLink(item.code)"></vue-qrcode>
                    </div>
                    <div class="link flex items-center space-x-2">
                        <a-input :value="codeToLink(item.code)" disabled>
                        </a-input>
                        <a-button size="small" @click="onCopyRefCode(item.code.trim())">
                            <CopyOutlined />
                        </a-button>
                    </div>


                </a-card>
            </div>
        </template>
        <a-divider orientation="left">学员注册</a-divider>
        <div class="flex flex-wrap gap-4">
            <a-card v-for="(item, index) in studentCodes" :key="index" shadow="hover" :title="resourceStore.entityTypeWordingMap[item.createType]">
                <div class="qrcode">
                    <vue-qrcode class="max-w-40 max-h-40" :value="codeToLink(item.code)"></vue-qrcode>
                </div>
                <div class="link flex items-center space-x-2">
                    <a-input :value="codeToLink(item.code)" disabled>
                    </a-input>
                    <a-button size="small" @click="onCopyRefCode(item.code.trim())">
                        <CopyOutlined />
                    </a-button>
                </div>


            </a-card>
        </div>
    </div>
</template>

<script setup lang="ts">
import { listInvitationCodes, type ListInvitationCodeResponse, InvitationCode, completeInvCode } from '@/api/request/invitation';
import {agentToStudent, getRoleOfUser, getRolesByAcctKind, type RoleData, studentJoinAgent} from '@/api/request/uam';
import {buildWebUrl, copyToClipboard} from '@/helpers/common';
import {AccountKind, AccountType, AccountTypeHierarchySerial} from '@/models/account';
import { useClipboard } from '@vueuse/core'
import { CopyOutlined } from '@ant-design/icons-vue'
import { message, notification } from 'ant-design-vue';
import { onMounted, ref, computed } from 'vue';
import {useRoute, useRouter} from 'vue-router';
import { useResourceStore } from '@/stores/resource';
import { useProfileStore } from '@/stores/profile';
import { Rule } from 'ant-design-vue/es/form';
import {useRequest} from "vue-request";
import {listMyInvitedStudent} from "@/api/request/student.ts";

const router = useRouter()
const route = useRoute()
const { copy } = useClipboard()
const resourceStore = useResourceStore()
const profileStore = useProfileStore()
// const invCode = ref("")
// const selectedAccountType = ref<AccountType>(AccountType.STUDENT)

const studentCodes = ref<Array<InvitationCode>>([])
const assignedCodes = ref<Array<InvitationCode>>([])

const roleData = ref<RoleData>()
const accountTypeSerial = ref<number|undefined>()
const hasAgentCodePrivilege = ref(false)

onMounted(async () => {
    await getRoleOfUser()
    .then((res) => {
        roleData.value = res.data
        accountTypeSerial.value = AccountTypeHierarchySerial.get(roleData.value?.accounttype as string)
        console.log(roleData.value?.accounttype);
        console.log(accountTypeSerial.value);


    })
    await completeInvCode()
    await listInvitationCodes()
    .then((res: ListInvitationCodeResponse) => {
        res.data.forEach((code: any) => {
            if (code.createType == AccountType.STUDENT) {
                studentCodes.value.push(code)
            } else {
                assignedCodes.value.push(code)
            }
        })
        // assignedCodes.value = res.data
        console.log(res.data);
        hasAgentCodePrivilege.value = profileStore.hasPrivilege('agent_invitation_code')
    })
})

// const signupUrl = ref("")
// function onGenerate() {
//     generateInvCode(selectedAccountType.value)
//     .then((res) => {

//         invCode.value = res.data
//         signupUrl.value = buildWebUrl(router.resolve({name: "signup", params: {refcode: invCode.value ? invCode.value : ""}}).fullPath)
//         window.location.reload()
//     })
// }

function codeToLink(refCode: string) {
    return buildWebUrl(router.resolve({name: route.params.org_name ? 'org-signup' : 'signup', params: {refcode: refCode, org_name: profileStore.orgMetadata?.uri}}).fullPath)
}
function onCopyRefCode(refCode: string) {
    copy(buildWebUrl(router.resolve({name: route.params.org_name ? 'org-signup' : 'signup', params: {refcode: refCode, org_name: profileStore.orgMetadata?.uri}}).fullPath))
    message.success('已成功复制注册链接!')
//     })
}

// 邀请
const showInviteAgentWithoutStuAcctModal = ref(false)
const inviteAgentWithoutStuAcctForm = ref<{role_id: string, student_user_id: string}>({
    role_id: '',
    student_user_id: ''
})

const inviteSignupUrl = computed(() => {
    const url = buildWebUrl(router.resolve({
        name: route.params.org_name ? 'org-signup' : 'signup',
        params: {
            refcode: 'dep-agent-invite',
            org_name: profileStore.orgMetadata?.uri
        },
        query: {
            account_id: profileStore.userProfile.accountId,
            user_id: profileStore.userProfile.id,
            role_id: inviteAgentWithoutStuAcctForm.value.role_id
        }
    }).fullPath)
    console.log(url)
    console.log(profileStore.hasPrivilege('agent_invitation_code'))
    return url
})
const existStudentAcct = ref(false)
const {data: students, run: runListMyInvitedStudent} = useRequest(listMyInvitedStudent, {
    debounceInterval: 500,
    manual: true,
})
async function runStudentJoinAgent() {
    await studentJoinAgent({
        account_id: profileStore.userProfile.accountId as string,
        role_id: inviteAgentWithoutStuAcctForm.value.role_id,
        user_id: inviteAgentWithoutStuAcctForm.value.student_user_id
    })
        .then(() => {
            message.success('加入成功')
        })
        .catch((e) => {
            message.error(e.response.data.data)
        })
    showInviteAgentWithoutStuAcctModal.value = false
}

const inviteAgentWithoutStuAcctRoleOptions = ref<Array<{id: string, rolename_cn: string}>>([])
async function retrieveRoles() {
    const data = await getRolesByAcctKind(profileStore.roleData?.accounttype == AccountType.HEAD_QUARTER? AccountKind.HQ:AccountKind.AGENT)
    inviteAgentWithoutStuAcctRoleOptions.value = data.filter((value) => {
        if (value.rolename_cn == '独立销售') {
            if (!profileStore.hasPrivilege('agent_invite_independent_sales')) {return false}
        }
        return true
    })
}
async function openInviteAgentWithoutStuAcctModal() {
    await retrieveRoles()
    existStudentAcct.value = false
    showInviteAgentWithoutStuAcctModal.value = true
}

async function openInviteAgentWithStuAcctModal() {
    runListMyInvitedStudent()
    await retrieveRoles()
    existStudentAcct.value = true
    showInviteAgentWithoutStuAcctModal.value = true
}

// 注册学生账户
const showAgentToStudentModal = ref(false)
const agentToStudentFormRef = ref()
interface agentToStudentFormSchema {
    accountName: string,
    kind: string,
    relationship?: string
}

function validateRelationship(_: Rule, value: string) {
    if (agentToStudentForm.value.kind == 'guardian') {
        if (!value) {
            return Promise.reject('请输入必填项')
        } else {
            return Promise.resolve()
        }
    } else {
        return Promise.resolve()
    }
}
const agentToStudentRules: Record<string, Rule[]> = {
    accountName: [
        {
            required: true,
            message: "请输入学员账号姓名"
        }
    ],
    kind: [
        {
            required: true,
            message: "请选择角色"
        }
    ],
    relationship: [
        {
            validator: validateRelationship,
            trigger: "blur",
            message: "请输入必填项"
        }
    ]
}
const agentToStudentForm = ref<agentToStudentFormSchema>({
    accountName: "",
    kind: "",
})
function onAgentToStudent() {
    showAgentToStudentModal.value = true
}
async function onAgentToStudentConfirm() {
    try {
        await agentToStudentFormRef.value.validateFields()
        await agentToStudent({
            account_name: agentToStudentForm.value.accountName,
            user_id: profileStore.userProfile.id as string,
            relationship: agentToStudentForm.value.relationship,
        })
        .then(() => {
            notification.success({
                message: "创建成功"
            })
        })
        .catch((e) => {
            notification.error({
                message: "创建失败",
                description: e.response.data.data
            })
        })
        .finally(() => {
            showAgentToStudentModal.value = false
        })

    } catch (e) {
        console.log(e);

    }

}


</script>

<style scoped>

</style>
