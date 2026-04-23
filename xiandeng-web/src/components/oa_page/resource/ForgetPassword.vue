<script setup lang="ts">
import { ref, onMounted } from 'vue'
import {useProfileStore} from "@/stores/profile.ts";
import {updatePassword} from "@/api/request/uam.ts";
import {notification} from "ant-design-vue";

const profStore = useProfileStore()
const formData = ref({
    password: '',
    confirm: ''
})
const formRef = ref()

const rules = {
    password: [
        { required: true, message: '请输入密码', trigger: 'blur' },
        // { min: 6, message: '密码长度不能小于6位', trigger: 'blur' }
    ],
    confirm: [
        { required: true, message: '请输入确认密码', trigger: 'blur' },
        // { min: 6, message: '密码长度不能小于6位', trigger: 'blur' },
        { validator: validator, message: '两次密码不一致'}
    ]
 }

function validator(_: any, value: string) {
    if (value === '') {
        return Promise.reject('请输入确认密码')
    } else if (value !== formData.value.password) {
        return Promise.reject("两次输入的密码不匹配")
    } else {
        return Promise.resolve()
    }
}

onMounted(() => {
    console.log(profStore.userProfile.id)
})

async function onSubmit() {
    console.log(formData.value)
    await formRef.value.validateFields()
        .then(() => {
            updatePassword(formData.value.password)
                .then((data) => {
                    notification.success({
                        message: '修改成功',
                        description: '请重新登录',
                        duration: 3,
                    })
                    setTimeout(() => {
                        window.location.href = data.redirect_url
                    }, 3000)
                })
                .catch((err) => {
                    notification.error({
                        message: '修改失败',
                        description: err.response.data.data,
                        duration: 3,
                    })
                })
        })
}
</script>

<template>
    <div class="w-2/3 mx-auto">
        <h1>忘记密码</h1>
        <a-form :model="formData" :rules="rules" ref="formRef">
            <a-form-item label="新密码" name="password">
                <a-input-password v-model:value="formData.password" />
            </a-form-item>
            <a-form-item label="确认密码" name="confirm">
                <a-input-password v-model:value="formData.confirm" />
            </a-form-item>
            <a-button type="primary" @click="onSubmit">提交</a-button>
        </a-form>
    </div>
</template>

<style scoped>

</style>
