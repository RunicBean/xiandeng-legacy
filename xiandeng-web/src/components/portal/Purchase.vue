
<template>
    <div>
        {{ profileStore.userProfile }}
    </div>
</template>

<script setup lang="ts">
import { useProfileStore } from '@/stores/profile';
const profileStore = useProfileStore()
</script>

<style scoped>

</style>