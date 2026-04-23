<template>
    <div>
      <div v-if="$route.params.next == 'agent'">

      </div>
    </div>
</template>

<script setup lang="ts">
import {onMounted} from 'vue'
// import { OFFICIAL_ACCOUNT_PAGE_URL } from '@/helpers/constants';
import { useRoute, useRouter } from 'vue-router';
import {appendOrgPrefixUrl} from "@/helpers/common.ts";

const $route = useRoute()
const $router = useRouter()
onMounted(() => {
    switch ($route.params.next) {
        case "guardian":
            alert("账号已注册完毕！跳转至商品页...")
            // window.location.replace(OFFICIAL_ACCOUNT_PAGE_URL)
            $router.replace(appendOrgPrefixUrl("/oa/prodmenu", $route.params.org_name))
            break;
        case "student":
            alert("账号已注册完毕！跳转至商品页...")
            // alert("账号已注册完毕！即将跳转至调研报告页面，如需后续填写，可先关闭页面。")
            // $router.replace({name: "portal_student-onboarding"})
            $router.replace(appendOrgPrefixUrl("/oa/prodmenu", $route.params.org_name))
            break;
        case "agent":
            alert("账号已注册完毕！请完成付款...")
            $router.replace({name: $route.params.org_name ? "org-agent-checkout" : "agent-checkout", query: {
              account_id: $route.query.account_id
              },
                params: {
                  org_name: $route.params.org_name
                }
            })
            break;
        default:
            break;
    }

})
</script>

<style scoped>

</style>
