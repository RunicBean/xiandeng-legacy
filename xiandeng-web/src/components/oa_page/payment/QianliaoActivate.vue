
<template>
    <div class="flex flex-col items-center h-full justify-center">
        <a-card shadow="always" :body-style="{ padding: '20px' }">
            <template #title>
            <div>
                <span>请长按识别二维码激活课程</span>
            </div>
            </template>
            <vue-qrcode :value="qrcodeUrl" tag="img"></vue-qrcode>
        </a-card>
        
        
    </div>
</template>

<script lang="ts">
import {ref, computed} from 'vue'
import { listMyQianliaoCoupon } from '@/api/request/resource'
import {type RouteLocationRaw} from 'vue-router'
const coupons = ref<Array<{couponcode: string}>>([])
export default {
    async beforeRouteEnter() {
        let validated: boolean | RouteLocationRaw = false
        await listMyQianliaoCoupon()
        .then((res) => {
            coupons.value = res.data
            console.log(coupons.value);
            if (!coupons.value || coupons.value.length == 0) {
                validated = {name: 'result', params: {type: 'not_in_service'}}
            } else {
                validated = true
            }
        })
        console.log(validated);
        
        return validated
    },

    setup () {
        const qrcodeUrl = computed(() => {
            const base = "https://coupon.qlchat.com/wechat/page/send-coupon/vip?liveId=280000119424966&couponCode="
            return `${base}${coupons.value[0].couponcode}`
        })
        const couponData = coupons
        return {
            couponData,
            qrcodeUrl
        }
    }
    
}
</script>

<style scoped>

</style>