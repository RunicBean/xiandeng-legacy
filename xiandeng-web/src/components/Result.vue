
<template>
    <div>
        <a-result v-if="resultType == 'account_taken'" status="warning" title="该账号已注册" sub-title="该账号已经注册！">
        </a-result>
        <a-result v-if="resultType == 'demo_forbidden'" status="warning" title="演示账号限制" sub-title="演示账号不支持此页面。">
        </a-result>
        <a-result v-if="resultType == 'payment_success'" status="success" title="支付成功" sub-title="支付成功，正在跳转...">
        </a-result>
        <a-result v-if="resultType == 'payment_offline_success'" status="success" title="支付成功" >
            <template #subTitle>
                <p>咨询师正在核实中，核实成功后会自动开启权限，请耐心等待。</p>
                <p v-if="$route.query.order_id">
                    订单号: {{ $route.query.order_id }} <a-button size="small" @click="copyToClipboard($route.query.order_id as string)">复制</a-button>
                </p>
            </template>
        </a-result>
        <a-result v-if="resultType == 'signup_success'" status="success" title="注册成功" sub-title="注册成功！可进行后续操作。">
        </a-result>
        <a-result v-if="resultType == 'signup_and_login'" status="success" title="注册成功" sub-title="注册成功！点击下方跳转登录页面。">
            <template #extra>
                <a-button key="console" type="primary" @click="() => $router.replace(appendOrgPrefixUrl('/login', $route.params.org_name))">前往登录页面</a-button>
            </template>
        </a-result>
        <a-result v-if="resultType == 'not_in_service'" status="warning" title="未购买此服务" sub-title="您还没有购买服务，可以联系先登社区老师哦！">
        </a-result>
        <a-result v-if="resultType == 'guardian_to_planning_page'" status="warning" title="缺少相关信息" sub-title="请先邀请学生注册，并填写调研问卷。">
        </a-result>
        <a-result v-if="resultType == 'generating_studysuggestion'" status="info" title="报告生成中" sub-title="正在生成报告内容，请稍后再来。">
        </a-result>
        <a-result v-if="resultType == 'unhandled_error'" status="error" title="发生异常" sub-title="发生未知异常，请联系先登社区老师哦！">
        </a-result>
        <a-result v-if="resultType == 'agent_not_upstream_partition'" status="warning" title="无法登录" sub-title="分区未设置，禁止登录。请联系邀请您的代理机构尽快处理。">
        </a-result>
        <a-result v-if="resultType == 'agent_closed'" status="warning" title="无法登录" sub-title="账户已关户，请联系总部。">
        </a-result>
        <a-result v-if="resultType == 'custom_warning'" status="warning" title="访问失败" :sub-title="$route.query.msg">
        </a-result>


    </div>
</template>

<script lang="ts" setup>
import { useRoute } from 'vue-router';
import {computed} from 'vue'
import {appendOrgPrefixUrl, copyToClipboard} from '@/helpers/common';
const $route = useRoute()

const resultType = computed(() => {
    return $route.params.type
})

</script>

<style lang="scss" scoped>

</style>
