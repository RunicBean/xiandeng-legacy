
<template>
    <a-layout class="md:h-[100vh] bg-[url('https://dorian-personal-public.oss-cn-shenzhen.aliyuncs.com/xiandeng.net.cn/public/images/background.jpg?x-oss-process=image/resize,w_2000')]">
        <a-layout-header class="!p-0">
            <PortalHeader />
        </a-layout-header>
        
        <a-layout-content class="w-[100vw] md:h-full">
            <div class="w-full md:h-full flex items-center justify-center">
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
                                    
                                    <a-form-item label="手机号" size="default" name="phone">
                                        <a-input v-model:value="basicForm.phone" addon-before="+86">
                                        </a-input>
                                    </a-form-item>
                                    <a-form-item label="密码" size="default" name="password">
                                        <a-input-password v-model:value="basicForm.password" size="default" clearable ></a-input-password>
                                    </a-form-item>
                                    <a-form-item label="确认密码" size="default" name="checkPass">
                                        <a-input-password v-model:value="basicForm.checkPass" size="default" clearable ></a-input-password>
                                    </a-form-item>
                                    <a-form-item label="邮箱" name="email">
                                        <a-input v-model:value="basicForm.email" :validate-event="false"></a-input>
                                    </a-form-item>
                                    <a-form-item v-if="basicForm.accountType == 'STUDENT'" label="身份" size="default" name="role">
                                        <a-select disabled v-model:value="basicForm.role">
                                            <a-select-option key="student" value="student">
                                                学生
                                            </a-select-option>
                                            <a-select-option key="guardian" value="guardian">
                                                家长
                                            </a-select-option>
                                        </a-select>
                                    </a-form-item>
                                    <div class="flex space-x-6">
                                        <a-form-item v-if="basicForm.role == 'guardian' || basicForm.role == 'student'" label="学生姓名" size="default" name="gardStudentName">
                                            <a-input v-model:value="basicForm.gardStudentName" placeholder="" size="default" :disabled="basicForm.role == 'guardian'"></a-input>
                                        </a-form-item>
                                        <a-form-item v-if="basicForm.role == 'guardian'" label="与学生的关系" size="default" name="gardRelationship">
                                            <a-input v-model:value="basicForm.gardRelationship" placeholder="" size="default" clearable></a-input>
                                        </a-form-item>
                                    </div>
                                    
                                    <a-form-item class="mt-8 float-end">
                                        <a-button type="primary" @click="onSignup(basicFormRef)" :disabled="invalidAccountId">下一步</a-button>
                                    </a-form-item>
                                </a-form>
                            </div>
                            
                            <div class="step-2 mx-6" v-show="activeStep == 1">
                                <div class="code h-full w-full max-w-48 max-h-48">
                                    <div v-if="qrcodeDisabled" class="absolute h-full w-full max-w-48 max-h-48 bg-gray-300 opacity-75"></div>
                                    <vue-qrcode v-if="url" :value="url" style="height: 100%; width: 100%; max-width: 190px; max-height: 190px;"></vue-qrcode>
                                    
                                </div>
                                <a-form :model="agentForm" ref="agentFormRef" :rules="agentRules" label-width="80px" :inline="false" size="default">
                                    
                                    <a-form-item class="mt-8 float-end">
                                        <a-button type="primary" @click="onSignup(basicFormRef)">下一步</a-button>
                                    </a-form-item>
                                </a-form>
                                
                            </div>
                            
                        </div>
                    </div>
                </div>
            </div>
        </a-layout-content>
        <a-layout-footer class="bg-white bg-opacity-45 shadow-md fixed bottom-0 w-full">
            <PortalFooter copyname="研伴服务中心" />
        </a-layout-footer>
    </a-layout>
   
</template>

<script setup lang="ts">
import {onMounted, ref} from 'vue';
import PortalHeader from '@/components/portal/segments/PortalHeader.vue';
import PortalFooter from '@/components/portal/segments/PortalFooter.vue';
import {useRoute, useRouter} from 'vue-router';
// import { ElNotification, type FormInstance, type FormRules } from 'element-plus'
// import { pcTextArr } from 'element-china-area-data'
import {
    checkUserPhoneAvailable,
    getAccount,
    getWechatAuthStatus,
    setJwtTokenSession,
    startWxQrcodeScan
} from '@/api/request/uam'
import {AgentForm, BasicForm} from '@/models/signup'
import {useProfileStore} from '@/stores/profile';
import {AccountType} from '@/models/account';
import {buildWebUrl, isFromWechatClient} from '@/helpers/common';
import {UserRole} from '@/helpers/constants';
import {getStudentAttr} from "@/api/request/student.ts";
import {FormInstance, notification} from 'ant-design-vue';
import {Rule} from 'ant-design-vue/es/form';
import {RequireRoleType} from "@/models/user.ts";

const profStore = useProfileStore()

const basicFormRef = ref<FormInstance>()
const $route = useRoute()
const $router = useRouter()

const basicForm = ref<BasicForm>(new BasicForm)
basicForm.value.invitationAccountId = $route.query.account_id as string
basicForm.value.role = $route.query.invite_role as string

const invalidAccountId = ref(false)
onMounted(async () => {
    await getAccount($route.query.account_id as string)
    .then((res) => {
        basicForm.value.gardStudentName = res.accountname
    })
    .catch((_) => {
        notification.error({
            message: "错误",
            description: "无此账号！"
        })
        invalidAccountId.value = true
        throw new Error("无此账号！");
        
    })

    if (basicForm.value.role == UserRole.Student) {
        await getStudentAttr($route.query.account_id as string)
        .then((_) => {
            notification.error({
                message: "错误",
                description: "已存在学生角色！"
            })
            invalidAccountId.value = true
            throw new Error("已存在学生角色！");
        })
    }
    console.log(profStore.sessionId);
})

const qrcodeDisabled = ref(false)

// Basic Step - 0


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
    // if (!basicFormRef.value) return
    // await basicFormRef.value.validateFields('checkPass')
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
  if (value === '') {
    return Promise.reject('请输入必填项')
  } else {
    return Promise.resolve()
  }
}

const basicRules: Record<string, Rule[]> = {
    phone: [{required: true, validator: validatePhone, trigger: "blur"}],
    password: [{required: true, validator: validatePass, trigger: "blur"}],
    checkPass: [{required: true, validator: validatePass2}],
    role: [{required: true}],
    gardRelationship: [{required: true, validator: validateGuardianRelationship}],
    gardStudentName: [{required: true, validator: validateStudentName}]
}

// Role Step - 1
const agentForm = ref<AgentForm>({
    province: "",
    city: ""
})

// function cityChange(value: any) {
//     console.log(value);
    
//     basicForm.value.province = value[0]
//     basicForm.value.city = value[1]
// }

// const selectedRegion = ref()

const agentRules = ref({})



// Overall
const activeStep = ref<number>(0)

async function startWxLoginLogic(sessionId: string, userBasicForm: BasicForm ) {
    let inplaceRedirect = isFromWechatClient()
    await startWxQrcodeScan(sessionId, userBasicForm, 'signup', inplaceRedirect)
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

async function onSignup(formEl: FormInstance | undefined) {
    if (!formEl) return
    await formEl.validate()
    .then(async () => {
        console.log(activeStep.value)
        await startWxLoginLogic(profStore.sessionId, basicForm.value)
        
        if (isFromWechatClient()) {
            window.location.replace(url.value)
        } else {
            activeStep.value += 1
            setInterval(async () => {
                let res = await getWechatAuthStatus(RequireRoleType.STUDENT, profStore.sessionId)
                if (res.data.state != "INIT") {
                    qrcodeDisabled.value = true
                }
                // 扫码授权完成后跳转onboarding界面
                if (res.data.state == "AUTHORIZED") {
                    setJwtTokenSession(res.data.token)
                    if (basicForm.value.accountType == AccountType.STUDENT) {
                        $router.push({name: "portal_student-onboarding"})
                    }
                    
                }
            }, 3000)
        }

    })
}
const url = ref<any>()
</script>

<style scoped>
.el-header {
    padding: 0;
}

.el-footer {
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