<template>
    <div class="login-container pt-40">
        <a-card class="box-card mx-auto" title="登录">
            <a-tabs v-model:activeKey="activeKey" type="border-card">
                <a-tab-pane key="1" tab="微信登录">
                    <h3 class="my-4">请使用微信扫描二维码</h3>
                    <div class="h-full w-full relative wx-qrcode-container">
                        <div v-if="wxQrcodeExpired" class="h-full w-full absolute flex flex-col items-center -mb-28 mt-12 z-50">
                            <RedoOutlined style="font-size: 40px;" />
                            <div>二维码已过期，请刷新页面。</div>
                        </div>
                        <vue-qrcode class="mx-auto h-full w-full max-w-40 max-h-40" :class="wxQrcodeExpired?'opacity-20 bg-slate-200':''" v-if="wxQrcodeUrl" :value="wxQrcodeUrl"></vue-qrcode>

                    </div>

                </a-tab-pane>
                <a-tab-pane key="2" tab="手机号密码登录">
                    <a-form
                    ref="loginFormRef"
                    :model="loginForm"
                    label-width="60px"
                    :label-col="{ span: 6 }"
                    >
                        <a-form-item label="手机号">
                            <a-input v-model:value="loginForm.phone" @keyup.enter="onSubmit" />
                        </a-form-item>
                        <a-form-item label="密码">
                            <a-input-password v-model:value="loginForm.password" show-password @keyup.enter="onSubmit" />
                        </a-form-item>
                        <a-button :loading="loginVerifyLoading" style="float: right; margin-bottom: 10px;" @click="onSubmit" type="primary">登录</a-button>
                    </a-form>
                </a-tab-pane>
            </a-tabs>

        </a-card>
    </div>
</template>

<script setup lang="ts">
import { onMounted, ref} from 'vue'
import {getWechatAuthStatus, login, setJwtTokenSession, startWxQrcodeScan} from '@/api/request/uam';
import {useProfileStore} from '@/stores/profile';
import {AuthStage, WechatAuthStatus} from '@/helpers/constants';
import {useRoute} from 'vue-router';
import {BasicForm} from '../models/signup';
import {notification} from 'ant-design-vue';
import {RedoOutlined} from '@ant-design/icons-vue';
import {RequireRoleType} from "@/models/user.ts";
import {usePermissionStore} from "@/stores/permission.ts";

// const [api, _] = notification.useNotification();

const {goNext} = defineProps<{
    goNext: () => void;
}>()
const activeKey = ref('1')
const route = useRoute()

const profileStore = useProfileStore()

interface LoginForm {
    phone: string
    password: string
}

const loginForm = ref<LoginForm>({
    phone: "",
    password: ""
})

const loginVerifyLoading = ref(false)
async function onSubmit() {
    loginVerifyLoading.value = true
    console.log(loginForm.value);

    login(loginForm.value.phone, loginForm.value.password, route.params.org_name as string)
    .then(()=> {
        stop()
        goNext()
    })
    .catch((err) => {
        console.log(err)
        notification.warning({
            message: '登录失败',
            description: err.response.data.message,
        })
        wxQrcodeExpired.value = true
        // ElNotification({
        //     title: '注意',
        //     message: err.response.data.message,
        //     type: 'warning',
        // })


    })
    .finally(() => {
        loginVerifyLoading.value = false
    })
}

let statusInterval: NodeJS.Timeout | null | undefined
function stop() {
    statusInterval && clearInterval(statusInterval)
}

const permitStore = usePermissionStore()
const wxQrcodeUrl = ref<string>()
const wxQrcodeExpired = ref(false)
onMounted(async () => {
    let basicForm: BasicForm = new BasicForm
    if (!permitStore.requireRole) {
        console.log("requireRole is missing");return}
    startWxQrcodeScan(
        profileStore.sessionId,
        basicForm,
        AuthStage.Login,
        false,
        undefined,
        permitStore.requireRole,
        route.params.org_name as string)
    .then((res) => {
        console.log(res.data);
        wxQrcodeUrl.value = res.data
    })

    setTimeout(() => {
        wxQrcodeExpired.value = true
        stop()
    }, 1000 * 60 * 5)

    // watchWechatAuthStatus(profileStore.sessionId, (event) => {
    //     console.log(event.data);

    //     receiveAuthStatus.value = JSON.parse(event.data)
    // })

    statusInterval = setInterval(async () => {
        const res = await getWechatAuthStatus(RequireRoleType.AGENT, profileStore.sessionId)
        console.log(res.data);
        if (res.data.state != WechatAuthStatus.Init) {
            qrcodeDisabled.value = true
        }
        if (res.data.state == WechatAuthStatus.Authorized) {
            stop()
            setJwtTokenSession(res.data.token)
            .then(() => {
                goNext()
            })
            .catch((err) => {
                stop()
                console.log(err.response.data.message);

            })
        } else if (res.data.state == WechatAuthStatus.Failed) {
            stop()
            notification.error({
                message: '登录错误',
                description: res.data.message,
            })
            wxQrcodeExpired.value = true
            // ElNotification({
            //     type: "error",
            //     title: "登录错误",
            //     message: value.message
            // })
        }
    }, 3000)
})

const qrcodeDisabled = ref(false)
// const receiveAuthStatus = ref()
// const {result: receiveAuthStatus} = watchWechatAuthStatus(profileStore.sessionId)
// watch(receiveAuthStatus, (value) => {
//     console.log("auth status", value);
//     if (value.state != WechatAuthStatus.Init) {
//         qrcodeDisabled.value = true
//     }
//     if (value.state == WechatAuthStatus.Authorized) {
//         setJwtTokenSession(value.token)
//         .then(() => {
//             goNext()
//         })
//         .catch((err) => {
//             console.log(err.response.data.message);

//         })
//     } else if (value.state == WechatAuthStatus.Failed) {
//         notification.error({
//             message: '登录错误',
//             description: value.message,
//         })
//         // ElNotification({
//         //     type: "error",
//         //     title: "登录错误",
//         //     message: value.message
//         // })
//     }
// })
</script>

<style scoped>

.login-container {
    height: 100vh;
    background: url('https://dorian-personal-public.oss-cn-shenzhen.aliyuncs.com/xiandeng.net.cn/public/images/login-image.jpg?x-oss-process=image/resize,w_1000') no-repeat;
    background-size: cover;
}

.box-card {
    width: 30vw;
}
</style>
