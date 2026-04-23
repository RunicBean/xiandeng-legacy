<template>
    <div>
        <a-card class="m-auto w-2/3 mt-[50%] flex flex-col items-center" shadow="always" :body-style="{ padding: '40px 20px' }">
            <template #title>
                <div>
                    <span class="text-xl font-medium">用户信息授权</span>
                </div>
            </template>
            为了更好地提供服务，请授权用户信息。
            <a-button class="mt-10 w-full" type="primary" size="large" @click="onStartAuth">授权</a-button>
            
        </a-card>
        
    </div>
</template>

<script setup lang="ts">
import { useRoute  } from 'vue-router';
import { onMounted, ref } from 'vue';
import { getRedirectUrl } from '@/api/request/uam';

const $route = useRoute()
const sessionId = $route.query.session_id as string

const redirectUrl = ref("")
onMounted(async () => {
    await getRedirectUrl(sessionId)
    .then((res) => {
        redirectUrl.value = res.data
    })
})

function onStartAuth() {
    window.location.replace(redirectUrl.value)
}
</script>

<style scoped>

</style>