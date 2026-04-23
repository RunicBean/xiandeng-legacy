<script setup lang="ts">
import {useRoute} from "vue-router";

const route = useRoute()
import {setProductCookie} from "@/api/request/uam.ts";


const StagingRouteDomainMap = new Map<string, string>([
    ['product', 'https://xiandeng-product-test.ai-toolsets.com']
])

const ProdRouteDomainMap = new Map<string, string>([
    ['product', 'https://product-admin.xiandeng.net.cn']
])

const prefix = import.meta.env.PROD ?
    ProdRouteDomainMap.get(route.query.domain as string) :
    StagingRouteDomainMap.get(route.query.domain as string)

setProductCookie()
    .then(() => {
        window.location.href = (`${prefix}${route.query.next as string}`)
    })

</script>

<template>
<div>
    正在跳转……
</div>
</template>

<style scoped>

</style>
