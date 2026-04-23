<template>
    <div>
        <a-result v-if="!$route.params.org_name">
            <h4>先登社区是邀请制，请联系你的邀请老师获取注册二维码。</h4>
<!--            <template #title> </template>-->
<!--            <template #subTitle>-->
<!--                <h5>先登社区是邀请制，请联系你的邀请老师获取注册二维码。</h5>-->
<!--&lt;!&ndash;                <p>感谢您关注【先登社区】大学规划陪跑社区。</p>&ndash;&gt;-->
<!--&lt;!&ndash;                <p>我们的社区是注册邀请制，系统检测到您尚未通过邀请码进行注册。</p>&ndash;&gt;-->
<!--&lt;!&ndash;                <p>为保证您的权益，请先联系【先登社区】在您所在地的分支工作室，获取邀请码进行注册。</p>&ndash;&gt;-->
<!--&lt;!&ndash;                <br>&ndash;&gt;-->
<!--&lt;!&ndash;                <p>若您所在地尚无分支工作室，或者不清楚所在地是否有工作室，可以联系【先登社区】总部教务人员，获取您所在地工作室邀请码进行注册。或者直接获取【先登社区】总部邀请码进行注册。</p>&ndash;&gt;-->
<!--            </template>-->

<!--            <template #extra>-->
<!--                <img class="w-full" src="https://dorian-personal-public.oss-cn-shenzhen.aliyuncs.com/xiandeng.net.cn/public/images/hqcontact.png?x-oss-process=image/resize,w_2000" alt="">-->
<!--            </template>-->
        </a-result>

        <a-result v-else-if="$route.params.org_name == 'linglu'">
            <template #subTitle>
                <p>感谢您关注【聆鹿前程】大学规划陪跑社区。</p>
                <p>我们的社区是注册邀请制，系统检测到您尚未通过邀请码进行注册。</p>
                <p>请先联系【聆鹿前程】在您所在地的分支工作室，获取邀请码进行注册。</p>
                <br>
                <p>若您所在地尚无分支工作室，或者不清楚所在地是否有工作室，可以联系【聆鹿前程】总部教务人员，获取您所在地工作室邀请码进行注册。或者直接获取【聆鹿前程】总部邀请码进行注册。</p>
            </template>
        </a-result>
    </div>
</template>

<script setup lang="ts">
import {useRoute} from "vue-router";

const $route = useRoute()



</script>

<style scoped>

</style>
