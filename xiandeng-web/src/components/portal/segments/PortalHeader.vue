<template>
    <div>
        <div class="w-full h-16 flex items-center shadow-sm">
            <div class="brand flex items-center ml-6">
                <img :src="profileStore.orgMetadata?.logourl" alt="Logo" class="h-8">
                <p class="ml-5">{{profileStore.orgMetadata?.sitename}}</p>
            </div>
        
        </div>
    </div>

</template>

<script setup lang="ts">
import {useProfileStore} from "@/stores/profile.ts";

const profileStore = useProfileStore()
</script>

<style scoped>
.el-header {
  padding: 0;
}
</style>