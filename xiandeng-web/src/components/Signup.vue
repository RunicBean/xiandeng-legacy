
<template>
    <a-layout class="md:h-[100vh] bg-[url('https://dorian-personal-public.oss-cn-shenzhen.aliyuncs.com/xiandeng.net.cn/public/images/background.jpg?x-oss-process=image/resize,w_2000')]">
        <a-layout-header class="!p-0">
            <PortalHeader />
        </a-layout-header>

        <a-layout-content class="w-[100vw] md:h-full">
            <div class="w-full md:h-full flex items-center justify-center">
                <!-- box -->
                <div class="w-4/5 md:w-3/5 mt-10 mb-32 shadow-md rounded-xl">
                    <div class="flex">
                        <div class="md:w-1/2 w-0 bg-[url('https://dorian-personal-public.oss-cn-shenzhen.aliyuncs.com/xiandeng.net.cn/public/images/signup-box.jpg?x-oss-process=image/resize,w_1000')] bg-cover rounded-s-xl"></div>
                        <div class="md:w-1/2 w-full bg-white bg-opacity-60 rounded-e-xl">
                            <h1 class="px-6 py-6 text-2xl">注册</h1>
                            <div class="step-1 mx-6" v-show="activeStep == 0">

                                <a-form
                                ref="basicFormRef"
                                :model="basicForm"
                                :rules="basicRules"
                                :label-col="{ span: 8 }"
                                :wrapper-col="{ span: 16 }"
                                label-position="top"
                                size="default">

                                    <a-form-item label="手机号" size="default" name="phone" class="mb-2 md:mb-6">
                                        <a-input v-model:value="basicForm.phone" addon-before="+86">
                                            <!-- <template #prepend>+86</template> -->
                                        </a-input>
                                    </a-form-item>
                                    <a-form-item v-if="basicForm.accountType != 'STUDENT'" label="密码" size="default" name="password" class="mb-2 md:mb-6">
                                        <a-input-password v-model:value="basicForm.password" size="default" clearable ></a-input-password>
                                    </a-form-item>
                                    <a-form-item v-if="basicForm.accountType != 'STUDENT'" label="确认密码" size="default" name="checkPass" class="mb-2 md:mb-6">
                                        <a-input-password v-model:value="basicForm.checkPass" size="default" clearable ></a-input-password>
                                    </a-form-item>
                                    <a-form-item label="邮箱" name="email" class="mb-2 md:mb-6">
                                        <a-input v-model:value="basicForm.email" :validate-event="false"></a-input>
                                    </a-form-item>
                                    <a-form-item v-if="basicForm.accountType == 'STUDENT'" label="身份" size="default" name="role" class="mb-2 md:mb-6">
                                        <a-select v-model:value="basicForm.role">
                                            <a-select-option key="student" value="student">
                                                学生
                                            </a-select-option>
                                            <a-select-option key="guardian" value="guardian">
                                                家长
                                            </a-select-option>
                                        </a-select>
                                    </a-form-item>
                                    <a-form-item v-if="basicForm.accountType != 'STUDENT' && !isDependentAgentInvite()" label="机构名称" size="default" name="agentName" class="mb-2 md:mb-6">
                                        <a-input v-model:value="basicForm.agentName" size="default" clearable></a-input>

                                    </a-form-item>
                                    <a-form-item v-if="(basicForm.role == 'guardian' || basicForm.role == 'student') && !basicForm.existAccountId" label="学生姓名" size="default" name="gardStudentName" class="mb-2 md:mb-6">
                                        <a-input v-model:value="basicForm.gardStudentName" placeholder="" size="default" clearable></a-input>
                                    </a-form-item>
                                    <a-form-item v-if="basicForm.role == 'guardian'" label="与学生的关系" size="default" name="gardRelationship" class="mb-2 md:mb-6">
                                        <a-input v-model:value="basicForm.gardRelationship" placeholder="" size="default" clearable></a-input>
                                    </a-form-item>
                                    <a-form-item name="agreeTerms">
                                        <a-checkbox v-model:checked="basicForm.agreeTerms">我已阅读并同意<a @click="goToTerms">服务协议</a></a-checkbox>
                                    </a-form-item>
                                    <a-form-item class="mt-8 float-end">
                                        <a-button type="primary" @click="onSignup(basicFormRef)" :disabled="invalidInvitationCode">下一步</a-button>
                                    </a-form-item>
                                </a-form>
                            </div>

                            <div class="step-2 mx-6" v-show="activeStep == 1">
                                <div class="code h-full w-full max-w-48 max-h-48 mb-12">
                                    <p>请使用微信扫描二维码</p>
                                    <div v-if="qrcodeDisabled" class="absolute h-full w-full max-w-48 max-h-48 bg-gray-300 opacity-75"></div>
                                    <vue-qrcode v-if="url" :value="url" tag="img" style="height: 100%; width: 100%; max-width: 190px; max-height: 190px;"></vue-qrcode>

                                </div>
                                <!-- <a-form :model="agentForm" ref="agentFormRef" :rules="agentRules" label-width="80px" :inline="false" size="default">

                                    <a-form-item class="mt-8 float-end">
                                        <a-button type="primary" @click="onSignup(basicFormRef)">下一步</a-button>
                                    </a-form-item>
                                </a-form> -->

                            </div>

                        </div>
                    </div>
                </div>
            </div>
        </a-layout-content>
        <a-layout-footer class="bg-white bg-opacity-45 shadow-md fixed bottom-0 w-full">
            <PortalFooter copyname="研伴服务中心" />
        </a-layout-footer>

        <a-modal
            v-model:open="dialogVisible"
            title="请仔细阅读"
            width="90%"
        >
            <div class="quote mx-4 ps-4 border-l-4 border-gray-400">
                <p>⚠️ 已存在同名学员信息，请家长和学生不要重复注册。</p>
                <br>
                <p>ℹ️ 已注册的学员需通过在先登伴行公众号发送"<b>邀请成员</b>"，点击公众号回复的链接即可添加自己的孩子或家长。</p>
                <br>
                <p>补充说明：家长和学生应当归属于同一账号，共享所有服务、查询和报告信息。必须通过邀请学员的方式才能保证同一账号。若重复注册为不同账号，<b>可能导致付款后权限无法开通等问题</b>。</p>
                <p>若您确认不是重复注册，可点击继续。否则，请取消或关闭页面。</p>
                <p>如有疑问，请联系您的咨询师。</p>
            </div>
            <br>
            <p>如需加入账号，请选择：</p>
            <a-table
                :custom-row="customRow"
                :data-source="studentsWithSameName"
                :row-selection="rowSelection"
                :columns="studentsWithSameNameColumns"></a-table>

            <a-alert class="mt-3">
                <template #description>
                    <a-checkbox v-model:checked="dialogCheck">我已认真阅读以上说明，并确认继续创建新账号。</a-checkbox>
                </template>
            </a-alert>



            <template #footer>
            <div class="dialog-footer">
                <a-button @click="dialogVisible = false">取消</a-button>
                <a-button :disabled="!dialogCheck" type="default" @click="onAccountNameDuplicateContinue(undefined)">
                创建新账号
                </a-button>
                <a-button type="primary" :disabled="selectedDuplicateStudentIds.length == 0" @click="onAccountNameDuplicateContinue(selectedDuplicateStudentIds[0])">
                    加入已有账号
                </a-button>
            </div>
            </template>
        </a-modal>

        <!-- <a-drawer class="md:hidden" v-model:open="termsoverallVisible" title="用户协议">
            <TermsOverall />
        </a-drawer> -->
        <a-drawer size="large" placement="bottom" v-model:open="termsoverallVisible">
            <TermsOverall />
        </a-drawer>
    </a-layout>

</template>

<script setup lang="ts">
import {onMounted, ref} from 'vue';
import PortalHeader from '@/components/portal/segments/PortalHeader.vue';
import PortalFooter from '@/components/portal/segments/PortalFooter.vue';
import {useRoute, useRouter} from 'vue-router';
import {type FormInstance, message} from 'ant-design-vue';
import type {Rule} from 'ant-design-vue/es/form';
import {
    checkUserPhoneAvailable,
    getWechatAuthStatus, listStudentsWithSameName,
    // setJwtTokenSession,
    startWxQrcodeScan,
    // upstreamStudentCheck
} from '@/api/request/uam'
import {BasicForm} from '@/models/signup'
import {useProfileStore} from '@/stores/profile';
import {getInvitationCodeDetail} from '@/api/request/invitation';
import {AccountType, isStudent} from '@/models/account';
import {appendOrgPrefixUrl, buildWebUrl, isFromWechatClient} from '@/helpers/common';
import {UserRole} from '@/helpers/constants';
import {getTermsOverallSignedUrl} from '@/api/request/resource';
import TermsOverall from './TermsOverall.vue';
import {RequireRoleType} from "@/models/user.ts";

const basicFormRef = ref<FormInstance>()
const $route = useRoute()
const $router = useRouter()


// Basic Step - 0
const basicForm = ref<BasicForm>(new BasicForm)
basicForm.value.refcode = $route.params.refcode as string

// function emailPhoneValidator(rule: any, value: any, callback: any) {

//     if (basicForm.value.email === '' && basicForm.value.phone === '') {
//         callback(new Error("邮箱/手机号至少填写一个！"))
//     } else {
//         callback()
//     }
// }

const validatePhone = async (_rule: Rule, value: string) => {
    if (import.meta.env.MODE != 'development' && !/^1\d{10}$/.test(value)) {
        return Promise.reject("手机号格式不正确")
    }
    if (value == "") {return Promise.reject("号码不能为空")}
    try {
        const res = await checkUserPhoneAvailable(value)
        if (res.data.available) {
            return Promise.resolve()
        } else {
            return Promise.reject("号码已注册，请换一个尝试")
        }
    } catch(err: any) {
        return Promise.reject(err.response.data.message)
    }
}

const validatePass = async (_rule: Rule, value: string) => {

  if (value === '') {
    return Promise.reject('请输入密码')
  } else {
    // if (basicForm.value.checkPass !== '') {
    //   if (!basicFormRef.value) return
    //   try {
    //     await basicFormRef.value.validateFields('checkPass')
    //   }
    //   catch (err) {
    //     return Promise.reject("两次输入的密码不匹配")
    //   }

    // }
    return Promise.resolve()
  }
}
const validatePass2 = (_rule: Rule, value: string) => {
  if (value === '') {
    return Promise.reject('请再次输入密码')
  } else if (value !== basicForm.value.password) {
    return Promise.reject("两次输入的密码不匹配")
  } else {
    return Promise.resolve()
  }
}
const validateGuardianRelationship = (_rule: Rule, value: string) => {
  if (basicForm.value.role != UserRole.Guardian){return Promise.resolve()}
  if (value === '') {
    return Promise.reject('请输入必填项')
  } else {
    return Promise.resolve()
  }
}

const validateStudentName = (_rule: Rule, value: string) => {
  if (basicForm.value.role == UserRole.Agent){return Promise.resolve()}
  if (basicForm.value.existAccountId){return Promise.resolve()}
  if (value === '') {
    return Promise.reject('请输入必填项')
  } else {
    return Promise.resolve()
  }
}

const validateAgentData = (_rule: Rule, value: string) => {
  if (basicForm.value.accountType == AccountType.STUDENT){return Promise.resolve()}
  if (value === '') {
    return Promise.reject('请输入必填项')
  } else {
    return Promise.resolve()
  }
}

const validateAgreeTerms = (_rule: Rule, value: boolean) => {
  if (value) {
    return Promise.resolve()
  } else {
    return Promise.reject("请先同意服务条款")
  }
}

const basicRules: Record<string, Rule[]> = {
    phone: [{required: true, validator: validatePhone, trigger: "blur"}],
    password: [{required: true, validator: validatePass, trigger: "blur"}],
    checkPass: [{required: true, validator: validatePass2}],
    role: [{required: true}],
    gardRelationship: [{required: true, validator: validateGuardianRelationship}],
    gardStudentName: [{required: true, validator: validateStudentName}],
    agentName: [{required: true, validator: validateAgentData}],
    agreeTerms: [{validator: validateAgreeTerms}]
}

// Role Step - 1
// const agentForm = ref<AgentForm>({
//     province: "",
//     city: ""
// })

// function cityChange(value: any) {
//     console.log(value);

//     basicForm.value.province = value[0]
//     basicForm.value.city = value[1]
// }

// const selectedRegion = ref()

// const agentRules = ref({})



// Overall
const activeStep = ref<number>(0)

async function startWxLoginLogic(sessionId: string, userBasicForm: BasicForm ) {
    let inplaceRedirect = isFromWechatClient()
    await startWxQrcodeScan(
        sessionId,
        userBasicForm,
        'signup',
        inplaceRedirect,
        $route.params.refcode as string,
        undefined,
        $route.params.org_name as string
    )
    .then((res) => {


        if (inplaceRedirect) {
            url.value = res.data
        } else {
            url.value = buildWebUrl($router.resolve({
                name: 'code-scan',
                query: {
                    session_id: sessionId
                }
            }).fullPath)
        }
        console.log(url.value);

    })
    .catch((err) => {
        console.log(err.response.data.message);

    })
}

// let statusInterval: NodeJS.Timeout | null | undefined
// function stop() {
//     statusInterval && clearInterval(statusInterval)
// }

const studentsWithSameName = ref()
const studentsWithSameNameColumns = [
    {
        title: '学员姓名',
        dataIndex: 'accountname',
        key: 'accountname'
    },
    {
        title: '学员手机号',
        dataIndex: 'phone',
        key: 'phone'
    },
    {
        title: '家长',
        dataIndex: 'guardian',
        key: 'guardian'
    }
]
const selectedDuplicateStudentIds = ref<Array<string>>([])
function selectRow(record: any) {
    selectedDuplicateStudentIds.value = [record.id]
}
function customRow(record: any) {
    return {
        onclick() {
            selectRow(record)
        }
    }
}
const rowSelection = ref({
    type: 'radio',
    selectedRowKeys: selectedDuplicateStudentIds,
    onChange: (selectedRowKeys: any) => {
        selectedDuplicateStudentIds.value = selectedRowKeys
    }
})
function appendKeyFromId(li: Array<any>) {
    const data = []
    for (const student of li) {
        data.push({
            ...student,
            key: student.id
        })
    }
    return data
}
const dialogVisible = ref(false)
async function signupContinue(existAccountId?: string) {
    console.log(activeStep.value)

    if (existAccountId) {basicForm.value.existAccountId = existAccountId}
    await startWxLoginLogic(profStore.sessionId, basicForm.value)

    if (isFromWechatClient()) {
        window.location.replace(url.value)
    } else {
        activeStep.value += 1
        setInterval(async () => {
            let res = await getWechatAuthStatus(basicForm.value.accountType == AccountType.STUDENT ? RequireRoleType.STUDENT : RequireRoleType.AGENT, profStore.sessionId)
            if (res.data.state != "INIT") {
                qrcodeDisabled.value = true
            }
            // 扫码授权完成后跳转onboarding界面
            if (res.data.state == "AUTHORIZED") {
                if (basicForm.value.accountType != AccountType.STUDENT) {
                    await $router.replace(appendOrgPrefixUrl("/result/signup_and_login", $route.params.org_name))
                } else {
                    await $router.replace(appendOrgPrefixUrl("/result/signup_success", $route.params.org_name))
                }

            }
        }, 3000)
    }
}

const dialogCheck = ref(false)

async function onAccountNameDuplicateContinue(existAccountId?: string) {
    dialogVisible.value = false
    await signupContinue(existAccountId)
}
async function onSignup(formEl: FormInstance | undefined) {
    if (!formEl) return
    await formEl.validateFields()
    .then(async () => {
        console.log(basicForm.value.accountType);
        console.log(basicForm.value.role);
        console.log(isStudent(basicForm.value.accountType));

        if (basicForm.value.existAccountId) {
            await signupContinue(basicForm.value.existAccountId)
            return
        }

        if (basicForm.value.accountType == AccountType.STUDENT) {
            try {
                const checkResult = await listStudentsWithSameName(basicForm.value.gardStudentName)
                // const checkResult = await upstreamStudentCheck($route.params.refcode as string, basicForm.value.gardStudentName)
                if (checkResult.data) {
                    dialogVisible.value = true
                    studentsWithSameName.value = appendKeyFromId(checkResult.data)
                } else {
                    await signupContinue()
                }
            }
            catch {
                message.error("上游账户名校验失败")
            }
        }
        else {
            await signupContinue()
        }
    })
    .catch((err) => {
        console.log('error submit!', err)

    })
}

const profStore = useProfileStore()



const url = ref<any>()
const invalidInvitationCode = ref(false)
const termsOverallSignedUrl = ref("")

onMounted(async () => {
    console.log(profStore.sessionId);
    // console.log(($route.params.org_name).length)
    console.log(profStore.orgMetadata)
    console.log($route.params.refcode)
    getTermsOverallSignedUrl()
    .then((res) => {
        termsOverallSignedUrl.value = res.data
    })

    //
    if (isStudentInvite()) {
        basicForm.value.accountType = AccountType.STUDENT
        basicForm.value.existAccountId = $route.query.account_id as string
    } else if (isDependentAgentInvite()) {
        basicForm.value.accountType = AccountType.LV1_AGENT
        basicForm.value.inviteAgentRoleId = $route.query.role_id as string
        basicForm.value.inviteUserId = $route.query.user_id as string
        basicForm.value.existAccountId = $route.query.account_id as string
    } else {
        await getInvitationCodeDetail($route.params.refcode as string)
            .then((res) => {
                basicForm.value.accountType = res.data.createType as AccountType


                console.log(basicForm.value.accountType);
            })
            .catch(() => {
                if ($route.query.head != "c") {
                    invalidInvitationCode.value = true
                    message.error("邀请链接无效")
                }
            })
    }

    // DLYB-184
    if (basicForm.value.accountType == AccountType.STUDENT) {
        basicForm.value.password = "P@ssword"
        basicForm.value.checkPass = "P@ssword"
    }
})

const qrcodeDisabled = ref(false)
const termsoverallVisible = ref(false)

function goToTerms() {
    termsoverallVisible.value = true
    // $router.push({name: 'terms-overall'})
}
// watch(url, () => {
//     console.log(url.value);

// })

const isDependentAgentInvite = () => {
    return $route.params.refcode as string == "dep-agent-invite"
}

const isStudentInvite = () => {
    return $route.params.refcode as string == "student-invite"
}
</script>

<style scoped>
.el-header {
    padding: 0;
}

.a-layout-footer {
  /* position: fixed;  */
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100vw;
  bottom: 0;
  font-size: small;
  color: rgb(133, 133, 133);
  /* border-top: 1px solid black; */
  box-shadow: rgba(0, 0, 0, 0.24) 0px 3px 8px;
}
</style>
