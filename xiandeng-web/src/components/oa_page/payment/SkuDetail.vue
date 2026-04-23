
<template>
    <div class="w-full">
        <h3>{{ productDetail?.productname }}</h3>
        <!-- <p>{{ profileStore.userProfile }}</p> -->
        <div class="w-4/5 m-auto">
        <a-descriptions>
            <a-descriptions-item>{{ productDetail?.description }}</a-descriptions-item>
        </a-descriptions>
        </div>
        <div class="w-full flex flex-col items-center" v-for="(_, index) in productImageLists" :key="index">
            <a-image :preview="false" class="w-full" :src="productImageLists[index]" fit="fill"></a-image>
        </div>

        <!-- <div class="w-full" v-for="(item, index) in productImages" :key="index"><img class="w-4/5 mx-auto" :src="item.imageurl" alt=""></div> -->
        <div class="w-full h-[25vh]"></div>
        <div class="footer fixed">

            <a-collapse v-if="productDetail && productDetail.finalprice != 0" v-model:activeKey="paymentActiveKey" expandIconPosition="right" accordion>
                <!-- 模式二通路已隐藏 -->
                <!--
                <a-collapse-panel key="1" header="选择付款方式">
                    <div class="w-4/5 pt-3 mx-auto flex items-center justify-end space-x-3">
                        <div class="text-sm text-red-500">输入销售代码</div>
                        <a-input class="w-1/3" v-model:value="selectedCouponCode" size="default" clearable @blur="couponIdChange"></a-input>


                    </div>
                    <a-divider class="my-3"></a-divider>
                    <div class="h-12 my-3 flex items-center justify-between">
                        <div class="space-x-2 ms-4 text-2xl font-bold">
                            <span v-if="selectedCoupon && productDetail" class="text-gray-400">¥{{ productDetail.finalprice }}</span>
                            <span v-if="productDetail" class="text-red-500">¥{{ finalPrice  }}</span>
                        </div>
                        <div class="flex items-center me-4">
                            <a-button type="primary" size="default" round @click="showPaymentMethodDrawer">付款</a-button>

                        </div>
                    </div>
                </a-collapse-panel>
                -->
                <a-collapse-panel key="2" header="我已线下付款" v-if="!isHQUpAgent">
                    <div class="mb-4">
                        <p>请先与您的咨询师核实好已付款成功后再点击下方的确认按钮</p>
                        <a-button type="primary" size="default" round @click="confirmOfflinePayment" >确认已线下付款</a-button>
                    </div>

                </a-collapse-panel>
            </a-collapse>
            <div v-else class="h-12 my-3 flex items-center justify-between">
                <div class="space-x-2 ms-4 text-2xl font-bold">
                    <span v-if="selectedCoupon && productDetail" class="text-gray-400">¥{{ productDetail.finalprice }}</span>
                    <span v-if="productDetail" class="text-red-500">¥{{ finalPrice  }}</span>
                </div>
                <div class="flex items-center me-4">
                    <a-button type="primary" size="default" round @click="showPaymentMethodDrawer">付款</a-button>

                </div>
            </div>


        </div>
    </div>

    <a-drawer title="付款方式" v-model:open="paymentMethodDrawer" placement="bottom" size="auto"
         :destroy-on-close="true" :show-close="true" :wrapperClosable="true">
         <a-table size="large" :columns="[{key: 'name', dataIndex: 'name', title: 'name'}]" :data-source="enabledPaymentMethodList" border :show-header="false" :custom-row="customRowClick" :pagination="false">
            <template #bodyCell="{column, record}">
                <template v-if="column.dataIndex == 'name'">
                    <div class="flex justify-center">{{ record.label }}</div>
                </template>
            </template>

         </a-table>


    </a-drawer>

    <a-drawer v-model:open="paymentDrawer" size="100%" :with-header="false"
        :destroy-on-close="true" :show-close="true" :wrapperClosable="true">
        <offline-pay
            v-if="paymentMethod && paymentMethod != PaymentMethod.WECHATPAY"
            :amount="finalPrice"
            :payment-method="paymentMethod"
            :agent-code="upagent?.agentcode ? upagent.agentcode : ''"
            @click-cancel="closePaymentDrawer"
            @payment-confirm="paymentOfflineConfirm"></offline-pay>
    </a-drawer>
</template>

<script setup lang="ts">
// import { useProfileStore } from '@/stores/profile';
import {logMessage} from '@/api/request/system';
import { onBridgeReady} from '@/helpers/wechat_payment';
import { ref, onMounted, computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
// import { OFFICIAL_ACCOUNT_PAGE_URL } from '@/helpers/constants';
import { message } from 'ant-design-vue';
import OfflinePay from './OaOfflinePay.vue'
// import { useRequest } from 'vue-request';
// import { ElNotification, ElMessage } from 'element-plus';
import { paymentMethodList, PaymentMethod } from '@/models/payment';
import { Upagent, getUpagent } from '@/api/request/uam';
import {Coupon, getCoupon} from "@/api/request/coupon.ts";
import {createOrder, updateOrder, generateSimpleOrderWithPaymentMethod} from "@/api/request/order.ts";
import {
  getProduct,
  GetProductRow,
  listProductImages,
  ListProductImagesResponse,
  ProductImage
} from "@/api/request/product.ts";
import {closePayment, confirmPayment, createPrepay} from "@/api/request/wechatpay.ts";
import {useProfileStore} from "@/stores/profile.ts";
import {appendOrgPrefixUrl, appendOrgPrefixUrlWithQuery} from "@/helpers/common.ts";
import {AccountType} from "@/models/account.ts";
const profileStore = useProfileStore()

const $route = useRoute()
const $router = useRouter()

const productDetail = ref<GetProductRow>()
const productImages = ref<Array<ProductImage>>([])
const productImageLists = computed(() => {
    if (productImages.value == null) {return []}
    let l: Array<string> = []
    for (let index = 0; index < productImages.value.length; index++) {
        const element = productImages.value[index];
        l = [...l, element.imageurl]
    }
    return l
})

const upagent = ref<Upagent>({})
const isHQUpAgent = computed(() => {
    // return upagent.value.agentcode && upagent.value.agentcode == '00'
    return upagent.value.type && upagent.value.type.entitytype == AccountType.HEAD_QUARTER
})

onMounted(async () => {
    getUpagent()
    .then((res) => {
        upagent.value = res.data
    })
    // Get product detail (final price)
    await getProduct($route.params.productid as string)
    .then((res) => {
        productDetail.value = res.data
        listProductImages($route.params.productid as string)
        .then((res: ListProductImagesResponse) => {
            console.log(res.data);

            productImages.value = res.data
        })
    })
    .catch((err) => {
        alert(err.message)
    })
})

// 模式二通路支付方式（聚合二维码/银行转账）- 已隐藏
const mode2PaymentMethods = ['paymentmethodliuliupay', 'paymentmethodcardoffline', 'paymentmethodwechatoffline', 'paymentmethodalipayoffline']

const enabledPaymentMethodList = computed(() => {
    if (!upagent) {return []}
    let l: Array<{name: string, label: string, enableDbFlag: string}> = []
    for (let index = 0; index < paymentMethodList.length; index++) {
        const element = paymentMethodList[index];
        // 过滤掉模式二通路
        if (mode2PaymentMethods.indexOf(element.enableDbFlag) >= 0) {
            continue
        }
        if (upagent.value[element.enableDbFlag]) {
            l = [...l, element]
        }
    }
    return l
})

const selectedCoupon = ref<Coupon|undefined>()
const selectedCouponCode = ref<string>("")
const finalPrice = computed(() => {
    if (typeof productDetail.value == 'undefined') {return 0}
    if (selectedCoupon.value) {
        return productDetail.value.finalprice - selectedCoupon.value.discountamount
    } else {
        return productDetail.value.finalprice
    }

})

function couponIdChange() {
    // 如果更改了coupon，则重置ordernumber
    orderNumber.value = undefined

    // 判断coupon是否变成空字符串
    if (selectedCouponCode.value?.toString() == "") {
        selectedCouponCode.value = ""
        selectedCoupon.value = undefined
        return
    }
    getCoupon(selectedCouponCode.value?.toString() as string)
    .then((res) => {
        selectedCoupon.value = res.data
    })
    .catch((err) => {
        alert(err.message)
    })
}

const paymentMethodDrawer = ref(false)
const orderNumber = ref<number>()

async function handleZeroPriceProduct() {
    return new Promise(async (resolve, reject) => {
        let success = false
        let ret = ""
        await createOrder([{
                id: productDetail.value?.id as string,
                coupon_code: ""
            }], selectedCouponCode.value)
        .then(async () => {
            // alert("支付成功！后续服务可在公众号查看，跳转中…")
            // window.location.replace(OFFICIAL_ACCOUNT_PAGE_URL)
            success = true
            // orderNumber.value = res.data
            // await confirmOfflineOrder(orderNumber.value as number, PaymentMethod.GIFT, false)
            // .then((res) => {
            //     success = true
            //     ret = res.data
            // })
            // .catch((err) => {
            //     ret = `确认订单失败：${err.response.data.data}`
            // })
        })
        .catch((err) => {
            ret = `创建订单失败：${err.response.data.data}`
            // ret = err.response.data
        })
        if (success) {resolve(ret)}
        else {reject(ret)}
    })

}

const paymentActiveKey = ref("1")
// 先创建order，如果没出错就拉起payment method选择抽屉
async function showPaymentMethodDrawer() {
    // 如果 conversionaward 不等于 0，则验证销售代码
    if (Number(productDetail.value?.conversionaward) != 0) {
        // 验证销售代码
        if (selectedCouponCode.value?.toString() == "" || selectedCouponCode.value?.toString() == undefined) {
            message.error("请输入销售代码")
            return
        }
    }
    console.log(`former order: ${orderNumber.value}`);
    if (productDetail.value?.finalprice == 0) {
        try {
            await handleZeroPriceProduct()
            alert("支付成功！后续服务可在公众号查看，跳转中…")
            window.location.replace(profileStore.orgMetadata?.redirecturl as string)
            return
        }
        catch(err) {
            message.error(err as string)
            return
        }
    }

    // 判断是否存在已有订单，如果有则跳过创建步骤
    if (!orderNumber.value) {
        await createOrder([{
            id: productDetail.value?.id as string,
            coupon_code: ""
        }], selectedCouponCode.value)
        .then((res) => {
            orderNumber.value = res.data
            paymentMethodDrawer.value = true
            console.log(`new order: ${orderNumber.value}`);
        })
        .catch((err) => {
            message.error(err.response.data.data)
        })
    } else {
        paymentMethodDrawer.value = true
        console.log(`existing order: ${orderNumber.value}`);

    }

}

async function confirmOfflinePayment() {
    await generateSimpleOrderWithPaymentMethod(productDetail.value?.id as string, PaymentMethod.INVENTORY_STUDENT, true)
    .then((data) => {

        $router.replace(appendOrgPrefixUrlWithQuery('/result/payment_offline_success', $route.params.org_name, {order_id: data.orderid}))
    })
}

const prepayId = ref("")
const counter = ref(0)

const paymentMethod = ref<PaymentMethod>()
async function pay(methodName: PaymentMethod, methodLabel: string) {
    if (!orderNumber.value) {
        message.error("订单号不存在")
        return
    }
    console.log(methodName);

    logMessage(`支付：进入${methodLabel}页面`)

    // 更新订单的payment method field
    paymentMethod.value = methodName
    await updateOrder({
        payment_method_do_update: true,
        payment_method: methodName,
        payment_method_update_null: false,
        status_do_update: false,
        updatedat_to_now: true,
        order_id: orderNumber.value
    })

    switch (methodName) {
        case PaymentMethod.WECHATPAY:
            pay_wechatpay()
            break;
        // case PaymentMethod.WECHAT_OFFLINE:
        //     $router.push({name: 'payment-wechat-offline-qrcode', query: {amount: finalPrice.value.toString()}})
        //     break;
        // case PaymentMethod.ALIPAY_OFFLINE:

        //     // $router.push({name: 'payment-alipay-offline-qrcode', query: {amount: finalPrice.value.toString()}})
        //     break;
        default:
            paymentDrawer.value = true
            break;
    }
}

async function pay_wechatpay() {
    if (!orderNumber.value) {
        message.error("订单号不存在")
        return
    }
    let signData = {
        app_id: "",
        timestamp: "",
        nonce: "",
        signature: ""
    }
    await createPrepay(orderNumber.value as number)
    .then((res) => {
        logMessage(`前端接收到intent: ${res.data.intent}`)
        prepayId.value = res.data.intent.prepay_id
        signData = res.data.sign
    })
    .catch((err) => {
        // console.log(err.response.data.data);
        message.error(err.response.data.data)
        throw err
    })

    if (import.meta.env.PROD) {
        onBridgeReady({
            appId: signData.app_id,
            timeStamp: signData.timestamp,
            nonceStr: signData.nonce,
            prepayId: prepayId.value,
            paySign: signData.signature
        }, async (res) => {
            logMessage(JSON.stringify(res))
            logMessage(`当前orderid为: ${orderNumber.value}`)
            if (res.err_msg == "get_brand_wcpay_request:ok") {
                // 使用以上方式判断前端返回,微信团队郑重提示：
                //res.err_msg将在用户支付成功后返回ok，但并不保证它绝对可靠。
                while (counter.value < 15) {
                    const res = await confirmPayment(orderNumber.value as number)

                    if (res.data == 'NOTPAY') {
                        counter.value += 1
                    } else if (res.data == 'SUCCESS') {
                        alert("支付成功！")
                        window.location.replace(profileStore.orgMetadata?.redirecturl as string)
                        break
                    }
                }
            } else if (res.err_msg == "get_brand_wcpay_request:cancel") {
                closePayment(orderNumber.value as number)
                // 如果用户取消，则重置ordernumber，并且关闭paymentMethodDrawer
                paymentMethodDrawer.value = false
                orderNumber.value = undefined
                alert("已取消支付")
            } else if (res.err_msg == "get_brand_wcpay_request:fail") {
                closePayment(orderNumber.value as number)
                alert("支付失败")
            }
        })
    }

}

const paymentDrawer = ref(false)
async function closePaymentDrawer() {
    if (!orderNumber.value) {
        message.error("订单号不存在")
        return
    }
    // Set paymentmethod == null and updateat = now()
    await updateOrder({
        payment_method_do_update: false,
        payment_method_update_null: true,
        status_do_update: false,
        updatedat_to_now: true,
        order_id: orderNumber.value
    })
    paymentDrawer.value = false
}

async function paymentOfflineConfirm() {
    if (!orderNumber.value) {
        message.error("订单号不存在")
        return
    }
    // Set order status to 'pending_confirmation'
    await updateOrder({
        payment_method_do_update: false,
        payment_method_update_null: false,
        status_do_update: true,
        status: 'pending_confirmation',
        updatedat_to_now: true,
        order_id: orderNumber.value
    })
    $router.replace(appendOrgPrefixUrl('/result/payment_offline_success', $route.params.org_name))
}

function customRowClick(row: any) {
    return {
        onClick: () => {
            pay(row.name, row.label)
        }
    }

}

// Payment method 2: Offline pay
</script>

<style scoped>
.footer {
  align-items: center;
  width: 100vw;
  bottom: 0;
  font-size: small;
  color: rgb(133, 133, 133);
  box-shadow: rgba(0, 0, 0, 0.24) 0px 3px 8px;
  background-color: #fff;
  z-index: 2;
}

.example-image {
    position: relative;
  color: #475669;
  opacity: 0.75;
  line-height: 150px;
  height: 400px;
  margin: 10px;
  text-align: center;
  background: #9f9f9f;
  z-index: 1;
}

.el-input {
    width: 30%;
}

.el-drawer__body {
    padding: 0 !important;
}
</style>
