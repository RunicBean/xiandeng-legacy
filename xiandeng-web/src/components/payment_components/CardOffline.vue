<template>
    <div>
        <a-descriptions :column="1">
            <a-descriptions-item label="银行">招商银行</a-descriptions-item>
            <a-descriptions-item label="银行卡号">
                <div class="space-x-2">
                    <span>6214 8342 0440 8919</span>
                    <a-button size="small" type="default" :underline="false" @click="copyToClipboard('6214834204408919')">复制卡号</a-button>
                </div>
            </a-descriptions-item>
            <a-descriptions-item label="户名">
                <div class="space-x-2">
                    <span>许兰峰</span>
                    <a-button size="small" type="default" :underline="false" @click="copyToClipboard('许兰峰')">复制户名</a-button>
                </div>
            </a-descriptions-item>
            <a-descriptions-item v-if="amount" label="金额"><span class="text-red-500 font-bold">{{ amount }}</span></a-descriptions-item>
            <a-descriptions-item v-if="amount" label="备注">
                <a-tag size="small">{{ paymentReference }}</a-tag>
            </a-descriptions-item>
        </a-descriptions>
    </div>
</template>
<script setup lang="ts">
import { computed } from 'vue';
import { copyToClipboard } from '@/helpers/common';
import { useProfileStore } from '@/stores/profile';

defineProps<{
    amount: number|null
}>()
const profileStore = useProfileStore()
const paymentReference = computed(() => {
    // DLYB-187 支付备注改为手机号后10位
    let commentSuffix
    if (profileStore.userProfile.phone) {
        commentSuffix = profileStore.userProfile.phone.length > 10 ? profileStore.userProfile.phone.substring(profileStore.userProfile.phone.length - 10) : profileStore.userProfile.phone
    }
    return commentSuffix
})
</script>
<style></style>