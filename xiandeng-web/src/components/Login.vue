<template>
    <LoginComponent :go-next="goNext" />
</template>

<script setup lang="ts">
import {computed} from 'vue'
import {useRoute, useRouter} from 'vue-router';
import LoginComponent from "@components/LoginComponent.vue";
import {setProductCookie} from "@/api/request/uam.ts";

// const [api, _] = notification.useNotification();

const route = useRoute()
const router = useRouter()

const myDefaultPathName = computed(() => {
    return route.params.org_name ? "org-adm-resource" : "adm-resource"
})

const goNext = () => {
    setProductCookie()
    const name = route.query.next ? route.query.next as string : myDefaultPathName.value as string
    const org_name = route.params.org_name ? route.params.org_name : undefined
    router.push({
        name,
        params: {
            org_name
        }
    })
}
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
