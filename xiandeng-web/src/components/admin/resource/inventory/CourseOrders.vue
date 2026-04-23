<template>
    <div>
        <a-table :columns="columns" :data-source="data" :scroll="{ x: 1800 }" :pagination="{pageSize: 5}">
            <template #bodyCell="{ column, text, record }">
                <template v-if="column.dataIndex === 'status'">
                    <a-tag>{{ text }}</a-tag>
                </template>
                <template v-if="column.dataIndex === 'action'">
                    <div class="flex items-center space-x-2">
                        <a-button :disabled="!isStudentInventoryPaymentMethod(record.paymentmethod) || isDone(record.status)" @click="approveOrder(record.id)">
                            <div class="flex items-center space-x-1" :class="{'text-blue-700' : (isStudentInventoryPaymentMethod(record.paymentmethod) && !isDone(record.status))}">
                                <ScheduleOutlined />
                                <span>授权</span>
                            </div>
                        </a-button>
                        
                        <Dropdown type="default">
                            
                            <a-button>
                                <div class="flex items-center space-x-1 text-gray-500">
                                    <CaretDownOutlined />
                                    <span>更多</span>
                                </div>
                            </a-button>
                            <template #overlay>
                                <a-menu>
                                    <a-menu-item key="1" :disabled="!isStudentInventoryPaymentMethod(record.paymentmethod) || isDone(record.status)" @click="declineOrder(record.id)">
                                        <div class="flex items-center w-full space-x-2" :class="{ 'text-red-500': (isStudentInventoryPaymentMethod(record.paymentmethod) && !isDone(record.status))}">
                                            <CloseOutlined />
                                            <span>拒绝</span>
                                        </div>
                                    </a-menu-item>
                                    <a-menu-item key="2" :disabled="!isStudentInventoryPaymentMethod(record.paymentmethod)">
                                        <div class="flex items-center w-full space-x-2">
                                            <CloudUploadOutlined />
                                            <span>上传凭证</span>
                                        </div>
                                    </a-menu-item>
                                    <a-menu-item key="3" :disabled="!isStudentInventoryPaymentMethod(record.paymentmethod)">
                                        <div class="flex items-center w-full space-x-2">
                                            <MonitorOutlined />
                                            <span>查看凭证</span>
                                        </div>
                                    </a-menu-item>
                                    <a-menu-item 
                                    @click="startUpdatePrice(record.id)"
                                    key="4" 
                                    :disabled="!isStudentInventoryPaymentMethod(record.paymentmethod) && !isAgentInventoryPaymentMethod(record.paymentmethod)">
                                        <div class="flex items-center w-full space-x-2">
                                            <FormatPainterOutlined />
                                            <span>更新实付金额</span>
                                        </div>
                                    </a-menu-item>
                                </a-menu>
                            </template>
                            
                        </Dropdown>
                    </div>
                </template>
            </template>
        </a-table>

        <a-modal title="更新实付金额" v-model:open="updatePriceModal" @ok="confirmUpdatePrice">
            <a-form :model="updatePriceForm" ref="updatePriceFormRef" :rules="updatePriceRules">
                <a-form-item label="实付金额" name="actual_price">
                    <a-input v-model:value="updatePriceForm.actual_price" />
                </a-form-item>
                <!-- <a-form-item>
                    <a-button type="primary" @click="confirmUpdatePrice">更新</a-button>
                </a-form-item> -->
            </a-form>
        </a-modal>
    </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { Dropdown, notification } from 'ant-design-vue';
import { getInventoryCourseOrders } from '@/api/request/inventory';
import { useRequest } from 'vue-request';
// import dayjs from 'ant-design-vue/es/date-picker';
import dayjs from 'dayjs';
import { CaretDownOutlined, CloseOutlined, CloudUploadOutlined, FormatPainterOutlined, MonitorOutlined, ScheduleOutlined } from '@ant-design/icons-vue';
import { paySuccess, simpleDeclineOrder, updateOrderPrice } from '@/api/request/order';
import { includes } from 'lodash-es';

const emit = defineEmits([
    'updateOrder'
])
const {data, run: fetchData} = useRequest(getInventoryCourseOrders)

const columns = [
    {
        title: '订单号',
        dataIndex: 'id',
        width: 200
    },
    {
        title: '创建时间',
        dataIndex: 'createdat',
        customRender: ({text}: {text: string}) => {
            return dayjs(text).format('YYYY-MM-DD HH:mm:ss')
        },
        width: 200
    },
    {
        title: '学生姓名',
        dataIndex: 'accountname'  
    },
    {
        title: '商品名称',
        dataIndex: 'productname',
        width: 220
    },
    {
        title: '付款方式',
        dataIndex: 'paymentmethod'
    },
    {
        title: '状态',
        dataIndex: 'status'
    },
    {
        title: '销售代码',
        dataIndex: 'code'
    },
    {
        title: '优惠金额',
        dataIndex: 'discountamount'
    },
    {
        title: '实付金额',
        dataIndex: 'price'
    },
    {
        title: '凭证',
        dataIndex: 'proof'
    },
    {
        title: '操作',
        dataIndex: 'action',
        fixed: 'right',
        width: 200
        // scopedSlots: { customRender: 'action' }
    }
    
]

async function approveOrder(orderId: number) {
    await paySuccess(orderId)
    .then((_) => {
        // console.log(res.data)
        notification.success({
            message: '授权成功'
        })
        fetchData()
        emit('updateOrder', orderId)
    })
    .catch((err) => {
        notification.error({
            message: '授权失败',
            description: err.response.data.data
        })
    })
    
}

async function declineOrder(orderId: number) {
    await simpleDeclineOrder(orderId)
    .then((_) => {
        notification.success({
            message: '拒绝成功'
        })
        fetchData()
    })
    .catch((err) => {
        notification.error({
            message: '拒绝失败',
            description: err.response.data.data
        })
    })
}

function isStudentInventoryPaymentMethod(paymentMethod: string) {
    return paymentMethod === '库存-学员下单'
}
function isAgentInventoryPaymentMethod(paymentMethod: string) {
    return paymentMethod === '库存-代理直扣'
}

function isDone(status: string) {
    return includes(['已结算', '已拒绝'], status)
}

const updatePriceFormRef = ref()
const selectedOrderId = ref<number|null>(null)
const updatePriceModal = ref(false)
const updatePriceForm = ref({
    actual_price: ''
})
const updatePriceRules = {
    actual_price: [
        {
            required: true,
            message: '请输入实付金额'
        }
    ]
}

function startUpdatePrice(orderId: number) {
    selectedOrderId.value = orderId
    updatePriceModal.value = true
}

async function confirmUpdatePrice() {
    await updatePriceFormRef.value?.validate()
    updatePriceModal.value = false
    await updateOrderPrice(selectedOrderId.value as number, updatePriceForm.value.actual_price)
    .then(() => {
        notification.success({
            message: '更新成功'
        })
        fetchData()
    })
    .catch((err) => {
        
        notification.error({
            message: err.response.data.data
        })
    })
}

defineExpose({
    fetchData
})
</script>

<style scoped>

</style>