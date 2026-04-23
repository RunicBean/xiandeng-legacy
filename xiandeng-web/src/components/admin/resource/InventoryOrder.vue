<template>
    <div>
        <h1>库存管理</h1>
        <a-row>
            <a-col :span="11">
                <a-form type="vertical" ref="inventoryOrderFormRef" :label-col="{span: 4}" :model="inventoryOrderForm" :rules="rules">
                    <a-form-item label="商品" name="product_id">
                        <!-- <a-input v-model:value="inventoryOrderForm.product_id" placeholder="商品" /> -->
                        <a-select v-model:value="inventoryOrderForm.product_id" @change="productChanged" placeholder="" clearable filterable>
                            <template v-for="item in products" :key="item.id">
                                <a-select-option v-if="Number(item.finalprice) > 0"
                                    :value="item.id">
                                    <div>
                                        <span>{{ item.productname }}</span>
                                        <span v-if="profileStore.hasPrivilege('agent_display_purchase_price')" class="float-end text-gray-400">进货价: {{ item.inventoryprice }}</span>
                                    </div>
                                    <div>{{ item.description }}</div>
                                </a-select-option>
                            </template>
                        </a-select>
                    </a-form-item>
                    <a-form-item label="数量" name="quantity">
                        <a-input-number v-model:value="inventoryOrderForm.quantity" class="w-full" />
                        <span class="text-sm" v-if="maxQuantity && inventoryOrderForm.type_check">使用余额最多可进货数量：{{ maxQuantity }}</span>
                        <span class="text-sm text-red-600" v-if="typeof maxQuantity != 'undefined' && maxQuantity == 0 && inventoryOrderForm.type_check">余额不足</span>
                    </a-form-item>
                    <a-form-item>
                        <a-checkbox class="float float-right" v-model:checked="inventoryOrderForm.type_check">使用余额进货</a-checkbox>
                    </a-form-item>
                    <a-form-item>
                        <a-button class="float float-right" type="primary" @click="submitOrder">进货</a-button>
                    </a-form-item>
                </a-form>
            </a-col>
            <a-col :span="2" class="flex justify-center"><a-divider class="h-full" type="vertical" /></a-col>
            <a-col :span="11">
                <a-table :columns="[
                    { title: '商品名称', dataIndex: 'productname' },
                    { title: '剩余库存', dataIndex: 'quantity' },
                    { title: '进货中', dataIndex: 'wip' },
                    { title: '已使用', dataIndex: 'used' },
                    { title: '操作', dataIndex: 'action' }
                ]" :dataSource="inventories" :pagination="{pageSize: 3}">
                    <template #bodyCell="{ column, record }">
                        <div v-if="column.dataIndex == 'action'">
                            <a-button type="primary" :disabled="!record.quantity" ghost @click="submitDistribute(record.productid)">分配</a-button>
                        </div>

                    </template>
                </a-table>
            </a-col>
        </a-row>
        <div>
            <InventoryDetails ref="inventoryDetailsRef" @update-course-orders="runListInventories" />
        </div>

        <a-modal v-model:open="paymentModalOpen" :footer="null">
            <template #title>
                <div class="flex items-center">
                    <div>付款
                        <span v-if="profileStore.hasPrivilege('agent_display_purchase_price')">(金额: <span class="text-red-500">{{ Number(productMap.get(inventoryOrderForm.product_id)?.inventoryprice) * (inventoryOrderForm.quantity??0) }}</span>）</span>
                    </div>

                </div>
            </template>
            <a-collapse v-model:activeKey="paymentMethodActiveKey" accordion @change="collapseChange">
                <a-collapse-panel key="card_offline" header="银行转账">
                    <CardOffline :amount="Number(productMap.get(inventoryOrderForm.product_id)?.inventoryprice) * (inventoryOrderForm.quantity??0)" />
                </a-collapse-panel>
                <a-collapse-panel key="contact_hq" header="线下联系总部">

                    <ContactHeadQuarter />
                </a-collapse-panel>
            </a-collapse>
        </a-modal>

        <a-modal v-model:open="distributeModalOpen" title="分配" @ok="submitDistributeForm">
            <div class="mb-2">分配给学生:</div>
            <a-select
                show-search
                :filter-option="false"
                @search="runListMyInvitedStudent"
                :options="students"
                :field-names="{label: 'accountname', value: 'accountid'}"
                v-model:value="distributeForm.student_id" placeholder="分配给学生" clearable filterable class="w-full"
            >
                <template #option="{accountname, phone}">
                    <div class="flex justify-between">
                        <div>{{ accountname }}</div>
                        <div>{{phone}}</div>
                    </div>
                </template>
<!--                <a-select-option v-for="item in students" :key="item.accountid" :value="item.accountid">-->
<!--                    <div class="flex justify-between">-->
<!--                        <div>{{ item.accountname }}</div>-->
<!--                        <div>{{item.phone}}</div>-->
<!--                    </div>-->
<!--                </a-select-option>-->
            </a-select>
        </a-modal>
    </div>
</template>

<script setup lang="ts">
import { onMounted, ref, watch } from 'vue'
import { listMyProductWithPrice, MyProductWithPrice } from '@/api/request/product';
import { InventoryOrderType } from '@/models/inventory';
import { createInventoryOrder, getMaxInventoryQuantity, listInventory, updateInventoryOrderPaymentMethod } from '@/api/request/inventory';
import { useRequest } from 'vue-request';
import { notification } from 'ant-design-vue';
import CardOffline from '@/components/payment_components/CardOffline.vue';
import ContactHeadQuarter from '@/components/payment_components/ContactHeadQuarter.vue';
import InventoryDetails from './inventory/InventoryDetails.vue';
import { listMyInvitedStudent } from '@/api/request/student';
import { generateSimpleOrderWithPaymentMethod } from '@/api/request/order';
import { PaymentMethod } from '@/models/payment';
import {useProfileStore} from "@/stores/profile.ts";

const profileStore = useProfileStore()
const products = ref<Array<MyProductWithPrice>>([])
const productMap = ref<Map<string, MyProductWithPrice>>(new Map())

onMounted(() => {
    listMyProductWithPrice()
    .then((res) => {
        products.value = res.data
        for (const prd of products.value) {
            productMap.value?.set(prd.id, prd)
        }
    })
})

const {data: inventories, run: runListInventories} = useRequest(listInventory)
const {data: maxQuantity, run: runGetMaxInventoryQuantity} = useRequest(getMaxInventoryQuantity, {
    manual: true
})

const inventoryDetailsRef = ref()
const inventoryOrderId = ref<string|null>()
const inventoryOrderFormRef = ref()
const inventoryOrderForm = ref<{
    product_id: string,
    quantity: number | null,
    type_check: boolean,
    type: InventoryOrderType
}>({
    product_id: '',
    quantity: null,
    type_check: false,
    type: InventoryOrderType.AGENT_TOPUP
})

watch(() => inventoryOrderForm.value.type_check, (val) => {
    inventoryOrderForm.value.type = val ? InventoryOrderType.FROM_BALANCE : InventoryOrderType.AGENT_TOPUP
})

function productChanged(value: string) {
    runGetMaxInventoryQuantity(value)
}

async function validateQuantity(_: any, value: number) {
    if (!maxQuantity.value) return Promise.resolve()
    if (value > maxQuantity.value && inventoryOrderForm.value.type_check) {
        return Promise.reject('最多可进货数量：' + maxQuantity.value)
    } else if (value <= 0) {
        return Promise.reject('数量必须大于0')
    } else {
        return Promise.resolve()
    }
}
const rules = {
    product_id: [
        { required: true, message: '请选择商品', trigger: 'blur' },
    ],
    quantity: [
        { required: true, message: '请输入数量', trigger: 'blur' },
        { validator: validateQuantity, trigger: 'blur' },
    ],
}

const paymentModalOpen = ref(false)
const paymentMethodActiveKey = ref()

async function collapseChange(key: string) {
    await updateInventoryOrderPaymentMethod(inventoryOrderId.value as string, key)
}

async function submitOrder() {
    try {
        await inventoryOrderFormRef.value.validateFields()
    } catch (e) {
        return
    }

    await createInventoryOrder(inventoryOrderForm.value.product_id, inventoryOrderForm.value.quantity as number, inventoryOrderForm.value.type)
    .then((res) => {
        console.log("created inventory order: " + res);

        inventoryOrderId.value = res
        if (inventoryOrderForm.value.type == InventoryOrderType.AGENT_TOPUP) {
            notification.success({
                message: '进货中',
                description: '进货审核中，付款后请耐心等待'
            })
            paymentModalOpen.value = true
        } else {
            notification.success({
                message: '进货成功',
                description: '进货成功，已自动扣款'
            })
        }
    })
    .catch((e) => {
        if (e.response.data.data == 'no rows in result set') {
            notification.info({
                message: '更新进货信息',
                description: '已存在进行中的进货申请，申请数量已更新。'
            })
            paymentModalOpen.value = true
            return
        }
        console.log(e.response.data.data);

        notification.error({
            message: '进货失败',
            description: e.response.data.data
        })
    })
    .finally(() => {
        runGetMaxInventoryQuantity(inventoryOrderForm.value.product_id)
        runListInventories()
    })
}

const distributeModalOpen = ref(false)
const distributeForm = ref({
    student_id: '',
    product_id: ''
})


const {data: students, run: runListMyInvitedStudent} = useRequest(listMyInvitedStudent, {
    debounceInterval: 500,
})
function submitDistribute(productId: string) {
    distributeForm.value.product_id = productId
    distributeModalOpen.value = true
}

function submitDistributeForm() {
    if (distributeForm.value.student_id == '') {
        notification.error({
            message: '请选择学生',
            description: '请选择学生'
        })
        return
    }
    generateSimpleOrderWithPaymentMethod(distributeForm.value.product_id, PaymentMethod.INVENTORY_AGENT, false, distributeForm.value.student_id)
    .then(() => {
        notification.success({
            message: '分配成功',
            description: '分配成功'
        })
        runListInventories()
        inventoryDetailsRef.value.updateAllData()

    })
    .catch((e) => {
        console.log(e.response.data.data);

        notification.error({
            message: '分配失败',
            description: e.response.data.data,
            duration: 3000
        })
    })
    .finally(() => {
        distributeModalOpen.value = false
    })
}
</script>

<style scoped>

</style>
