<template>
    <div>
        <a-result :title="`欢迎加入大家庭！`" sub-title="请选择代理类型">
            <template #icon>
                <ShareAltOutlined />
            </template>
            <template #extra>
                <a-button type="primary" size="default" @click="joinAgentDialogVisible = true">加盟</a-button>
            </template>
        </a-result>

        <a-modal title="加盟" v-model:open="joinAgentDialogVisible" @ok="submitJoinAgent" >
            <a-form ref="joinAgentFormRef" :model="joinAgentForm" :rules="{accounttype: {required: true, message: '请选择代理类型'}}" :label-col="{ span: 6 }" :wrapper-col="{ span: 18 }" autocomplete="off">
                <a-form-item label="代理类型" name="accounttype">
                    <a-select  v-model:value="joinAgentForm.accounttype">
                        <a-select-option value="HQ_AGENT">{{ resourceStore.entityTypeWordingMap["HQ_AGENT"] }}</a-select-option>
                        <a-select-option value="LV1_AGENT">{{ resourceStore.entityTypeWordingMap["LV1_AGENT"] }}</a-select-option>
                        <a-select-option value="LV2_AGENT">{{ resourceStore.entityTypeWordingMap["LV2_AGENT"] }}</a-select-option>
                    </a-select>
                </a-form-item>
            </a-form>
        </a-modal>

    </div>

</template>

<script setup lang="ts">
import { ShareAltOutlined } from '@ant-design/icons-vue'
import { useRouter } from 'vue-router'
import { ref, onMounted } from 'vue'
import { useResourceStore } from '@/stores/resource'    
import { studentToAgent } from '@/api/request/uam';
import { useProfileStore } from '@/stores/profile';
import { notification } from 'ant-design-vue';
const joinAgentDialogVisible = ref(false)
const joinAgentFormRef = ref()
const joinAgentForm = ref<{accounttype?: string}>({
})
const resourceStore = useResourceStore()
onMounted(async () => {
    await resourceStore.updateEntityTypeWordingMap()  
})

const $router = useRouter()
const profileStore = useProfileStore()
async function submitJoinAgent() {
    try {
        await joinAgentFormRef.value.validateFields()
        studentToAgent({
            account_name: profileStore.userProfile.accountName as string,
            entity_name: joinAgentForm.value.accounttype as string,
            user_id: profileStore.userProfile.id as string
        })
        .then(() => {
            $router.push('/result/signup_success')
        })
        .catch((e) => {
            notification.error({
                message: "加盟失败",
                description: e.response.data.data
            })
        })
        joinAgentDialogVisible.value = false
    }
    catch {
        
    }
}
</script>