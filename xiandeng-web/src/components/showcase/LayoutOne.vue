<script setup lang="ts">
import MainImages from "./layoutOne/MainImages.vue";
import {onMounted, ref} from "vue";
import {getCompany} from "@/api/request/showcase";
import {useRoute, useRouter} from "vue-router";
import MainItems from "./layoutOne/MainItems.vue";

const route = useRoute()
const router = useRouter()
const companyName = ref("")
onMounted(() => {
  getCompany(route.params.companyPath as string)
        .then((res) => {
            companyName.value = res.data.name
            // document.title = companyName.value
        })
        .catch(() => {
            router.push({ name: 'not-found' })
        })
})
</script>

<template>
    <div class="body">
        <MainImages :company-name="companyName" />
        <MainItems :company-name="companyName" />
    </div>
</template>

<style scoped>
div {
    background-color: #fff;
}
</style>
