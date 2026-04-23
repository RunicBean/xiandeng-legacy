<template>
    <div class="flex flex-col items-center h-full justify-center">
        <a-card shadow="always" :body-style="{ padding: '20px' }">
            <template #title>
            <div>
                <span>请将二维码发送给邀请用户注册</span>
            </div>
            </template>
            <vue-qrcode class="mx-auto" v-if="roleData" :value="inviteUrl" tag="img"></vue-qrcode>
        </a-card>


    </div>
</template>

<script lang="ts" setup>
import {ref, onMounted} from 'vue'
import { getRoleOfUser, type RoleData } from '@/api/request/uam';
import {appendOrgPrefixUrl, buildWebUrl} from '@/helpers/common';
// import {AccountType} from "@/models/account.ts";
import {useRoute} from 'vue-router';

const $route = useRoute()
// const $router = useRouter()
const roleData = ref<RoleData>()
// const studentExists = ref<boolean>(false)
const inviteUrl = ref()
onMounted(() => {
    getRoleOfUser()
    .then((res) => {
        console.log(res.data);
        roleData.value = res.data
        // if (roleData.value?.usertype != AccountType.STUDENT) {
        //     $router.replace({name: ($route.params.org_name ? "org-result" : "result"), params: {type: "custom_warning", org_name: $route.params.org_name}, query: {msg: "本功能仅对学员本人开放"}})
        // }
        // inviteType.value = setInviteType(roleData.value)
        console.log(buildWebUrl(appendOrgPrefixUrl(`/signup/student-invite?account_id=${roleData?.value?.accountid}`, $route.params.org_name)));
        inviteUrl.value = buildWebUrl(appendOrgPrefixUrl(`/signup/student-invite?account_id=${roleData?.value?.accountid}`, $route.params.org_name))
    })
})

// function setInviteType(roleData: RoleData|undefined) {
//     if (!roleData) {return "invalid"}
//     if (roleData.accounttype == "AGENT") {
//         return "agent"
//     }
//     if (isUserGuardian(roleData.usertype as UserRoleType)) {
//         if (roleData.existstudent) {
//             studentExists.value = true
//             return "exist"
//         } else {
//             return "student"
//         }
//     } else if (isUserStudent(roleData.usertype as UserRoleType)) {
//         return "guardian"
//     } else {
//         return "agent"
//     }
// }
</script>
