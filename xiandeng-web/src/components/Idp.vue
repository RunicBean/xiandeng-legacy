<template>
    <LoginComponent :go-next="goNext" />
</template>

<script setup lang="ts">
import {useRoute, useRouter} from 'vue-router';
import LoginComponent from "@components/LoginComponent.vue";

// const [api, _] = notification.useNotification();

const route = useRoute()
const router = useRouter()

const goNext = () => {
    router.push({
        name: 'forwarder',
        query: {
            domain: route.query.domain,
            next: route.query.next,
            org_name: route.params.org_name
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
