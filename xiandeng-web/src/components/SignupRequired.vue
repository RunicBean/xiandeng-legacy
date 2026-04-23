<template>
    <div>
        <a-result v-if="resultDisplay" icon="warning" title="未注册">
            <template #subTitle>
                <p>您还未注册系统，无法使用此功能</p>
            </template>
        </a-result>
    </div>
</template>
<script setup lang="ts">
import { onBeforeMount, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';

const bypassMap = new Map<string, string>([
    ["/oa/prodmenu", "/oa-noauth/prodmenu"],
    ["/oa/proddetail", "/oa-noauth/proddetail"],
])
const resultDisplay = ref(false)
const router = useRouter()
const route = useRoute()
onBeforeMount(() => {
    if (bypassMap.has(route.query.next as string)) {
        router.replace(bypassMap.get(route.query.next as string) as string)
    } else {
        resultDisplay.value = true
    }
})
</script>

<style scoped>

</style>