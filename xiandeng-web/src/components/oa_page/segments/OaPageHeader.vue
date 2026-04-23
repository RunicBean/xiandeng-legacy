<template>
    <div>
        <div class="w-full h-16 flex items-center">
            <div class="brand flex items-center">
                <img :src="profileStore.orgMetadata?.logourl" alt="Logo" class="h-8">
                <span class="ml-5">{{profileStore.orgMetadata?.sitename}}</span>
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
