<template>
    <div>
        <!-- 此处是PC版筛选条件页 -->
        <a-card v-if="profileStore.windowSize as number >= WindowSize.Medium" shadow="always" :body-style="{ padding: '20px' }">
            <a-form :model="orderSearchQuery" ref="form" label-width="80px" layout="inline" size="default" class=" gap-y-6">
                <a-form-item label="学生姓名" size="default">
                    <a-input v-model:value="orderSearchQuery.student_name" placeholder="" size="default" clearable @change=""></a-input>
                </a-form-item>
                <a-form-item label="代理" size="default">
                    <a-input v-model:value="orderSearchQuery.agent_name" placeholder="" size="default" clearable @change=""></a-input>
                </a-form-item>
                <a-form-item label="商品名" size="default">
                    <a-input v-model:value="orderSearchQuery.product_name" placeholder="" size="default" clearable @change=""></a-input>
                </a-form-item>
                <a-form-item label="订单时间">
                    <a-range-picker
                        show-time
                        :locale="datePickerCNLocale"
                        range-separator="到"
                        start-placeholder="开始时间"
                        end-placeholder="结束时间"
                        size="default"
                        @clear="clearUpdateTime"
                        @change="changeUpdateTime"
                    />
                </a-form-item>
                
                <a-form-item label="实付金额">
                    <div class="flex space-x-3">
                        <div>
                            <a-input-number :controls="false" v-model:value="orderSearchQuery.price_range_start" placeholder="最小值" size="default" clearable @change=""></a-input-number>
                        </div>
                        <div>~</div>
                        <div>
                            <a-input-number :controls="false" v-model:value="orderSearchQuery.price_range_end" placeholder="最大值" size="default" clearable @change=""></a-input-number>
                        </div>
                        
                    </div>
                    
                </a-form-item>
                <a-form-item label="付款方式" size="default">
                    <a-select v-model:value="orderSearchQuery.payment_method" value-key="" placeholder="选择付款方式" clearable filterable @change="">
                        <a-select-option v-for="item in PaymentMethod"
                            :key="item"
                            :label="item"
                            :value="item">
                        </a-select-option>
                    </a-select>
                    
                </a-form-item>
                <a-form-item label="订单状态" size="default">
                    <a-select
                    v-model:value="orderSearchQuery.status_list"
                    mode="multiple"
                    collapse-tags
                    placeholder="选择状态"
                    >
                        <a-select-option
                            v-for="(item, index) in OrderFilterStatusMap"
                            :key="index"
                            :label="item.label"
                            :value="index"
                        >
                            <a-tag :color="item.color" size="small">{{ item.label }}</a-tag>
                            
                        </a-select-option>
                        <template #tag>
                            <a-tag v-for="statusValue in orderSearchQuery.status_list" :key="statusValue" :color="OrderStatusMap[statusValue as OrderStatus].color">{{ OrderStatusMap[statusValue as OrderStatus].label }}</a-tag>
                        </template>
                    </a-select>
                </a-form-item>
                
                
            </a-form>
            <a-form-item>
                <div class="flex mt-3 float-end space-x-3">
                    <a-button @click="initOrderSearchQuery">重置</a-button>
                    <a-button type="primary" @click="runSearchOrders">查询</a-button>
                </div>
                
            </a-form-item>
        </a-card>
        <!-- 此处是手机版筛选条件页 -->
        <a-button class="mb-3" v-if="profileStore.windowSize == WindowSize.Small" type="default" size="default" round @click="orderSearchDrawer = true">筛选条件</a-button>
        <hr class="mb-3">
        <a-drawer title="筛选条件" v-model:open="orderSearchDrawer" direction="rtl" size="90%"
            :before-close="runSearchOrders" :destroy-on-close="true" :show-close="true" :wrapperClosable="true">
            <a-form :model="orderSearchQuery" ref="form" label-width="80px" layout="inline" class="gap-y-3" size="default">
                <a-form-item label="学生姓名" size="default">
                    <a-input v-model:value="orderSearchQuery.student_name" placeholder="" size="default" clearable @change=""></a-input>
                </a-form-item>
                <a-form-item label="代理" size="default">
                    <a-input v-model:value="orderSearchQuery.agent_name" placeholder="" size="default" clearable @change=""></a-input>
                </a-form-item>
                <a-form-item label="商品名">
                    <a-input v-model:value="orderSearchQuery.product_name" placeholder="" size="default" clearable @change=""></a-input>
                </a-form-item>
                <a-form-item label="起始时间" class="w-4/5">
                    <a-date-picker
                        show-time
                        :locale="datePickerCNLocale"
                        popper-class="mobile-date-picker"
                        v-model:value="updateStartTime"
                        size="default"
                        @clear="orderSearchQuery.updateat_start = ''"
                        @change="changeStartTime"
                    />
                </a-form-item>
                <a-form-item label="结束时间" class="w-4/5">
                    <a-date-picker
                        show-time
                        :locale="datePickerCNLocale"
                        popper-class="mobile-date-picker"
                        v-model:value="updateEndTime"
                        size="default"
                        @clear="orderSearchQuery.updateat_end = ''"
                        @change="changeEndTime"
                    />
                </a-form-item>
                
                <a-form-item label="实付金额">
                    <div class="flex flex-col">
                        <div>
                            <a-input-number :controls="false" v-model:value="orderSearchQuery.price_range_start" placeholder="最小值" size="default" clearable @change=""></a-input-number>
                        </div>
                        <div>~</div>
                        <div>
                            <a-input-number :controls="false" v-model:value="orderSearchQuery.price_range_end" placeholder="最大值" size="default" clearable @change=""></a-input-number>
                        </div>
                        
                    </div>
                    
                </a-form-item>
                <a-form-item label="付款方式" size="default" class="w-4/5">
                    <a-select v-model:value="orderSearchQuery.payment_method" value-key="" placeholder="选择付款方式" clearable filterable @change="">
                        <a-select-option v-for="item in PaymentMethod"
                            :key="item"
                            :label="item"
                            :value="item">
                        </a-select-option>
                    </a-select>
                    
                </a-form-item>
                <a-form-item label="订单状态" size="default"  class="w-4/5">
                    <a-select
                    v-model:value="orderSearchQuery.status_list"
                    mode="multiple"
                    collapse-tags
                    placeholder="选择状态"
                    >
                        <a-select-option
                            v-for="(item, index) in OrderFilterStatusMap"
                            :key="index"
                            :label="item.label"
                            :value="index"
                        >
                            <a-tag :color="item.color" size="small"  effect="dark">{{ item.label }}</a-tag>

                        </a-select-option>
                        <template #tag>
                            <a-tag v-for="statusValue in orderSearchQuery.status_list" :key="statusValue" :color="OrderStatusMap[statusValue as OrderStatus].color">{{ OrderStatusMap[statusValue as OrderStatus].label }}</a-tag>
                        </template>
                    </a-select>
                </a-form-item>
                
                
            </a-form>
            <hr>
            <a-form-item class="flex justify-end mt-3 float-end">
                <a-button @click="initOrderSearchQuery">重置</a-button>
                <a-button type="primary" @click="runSearchOrders">查询</a-button>
            </a-form-item>
        </a-drawer>
        
        <a-table :data-source="sortOrdersByUpdateTime(filterOutInventoryOrders(filteredOrders))" :columns="columns" border stripe :custom-row="selectOrder" :show-header="false">
            <template #bodyCell="{column, record}">
                <template v-if="column.key == 'index'">
                    <a-table-column type="index" width="50" />
                </template>
                <template v-if="column.key == 'info'">
                    <a-descriptions v-if="profileStore.windowSize as number >= WindowSize.Medium">
                        <a-descriptions-item width="30%" label="学生">{{record.studentname}}</a-descriptions-item>
                        <a-descriptions-item width="40%" label="时间">{{ dayjs.tz(record.updatetime).format("YYYY-MM-DD HH:mm") }}</a-descriptions-item>
                        <a-descriptions-item width="20%" label="实付">{{ record.price }}</a-descriptions-item>
                        <a-descriptions-item label="代理">{{ record.agentname }}</a-descriptions-item>
                        <a-descriptions-item label="商品">
                            <a-tag size="small" v-for="(prd, index) in record.productlist" :key="index">{{ prd }}</a-tag>
                        </a-descriptions-item>
                        <a-descriptions-item label="状态">
                            <a-tag size="small" :color="OrderStatusMap[record.status as OrderStatus]?.color">{{ OrderStatusMap[record.status as OrderStatus]?.label }}</a-tag>
                        </a-descriptions-item>
                    </a-descriptions>
                    <!-- Mobile显示结果 -->
                    <div v-else>
                        <a-descriptions :column="2">
                            <a-descriptions-item label="学生">{{record.studentname}}</a-descriptions-item>
                            <a-descriptions-item label="代理">{{ record.agentname }}</a-descriptions-item>
                            
                            <a-descriptions-item label="实付">{{ record.price }}</a-descriptions-item>
                            <a-descriptions-item label="状态">
                                <a-tag size="small" :color="OrderStatusMap[record.status as OrderStatus]?.color">{{ OrderStatusMap[record.status as OrderStatus]?.label }}</a-tag>
                            </a-descriptions-item>
                        </a-descriptions>

                        <div>
                            <a-tag size="small" v-for="(prd, index) in record.productlist" :key="index">{{ prd }}</a-tag>
                        </div>
                        <div class="text-gray-400">{{ dayjs.tz(record.updatetime).format("YYYY-MM-DD HH:mm") }}</div>
                    </div>
                </template>
            </template>
        </a-table>
        
        <a-drawer title="订单详情" size="large" v-model:open="orderDetailDrawerShow" placement="bottom" 
            :destroy-on-close="true" :show-close="true" :wrapperClosable="true" :before-close="handleOrderDetailDrawerClose">
            <a-tabs v-model:activeKey="orderDetailDrawerName" class="demo-tabs">
                <!-- 编辑页 -->
                <a-tab-pane tab="编辑" key="edit">
                    <a-form :model="approveForm" ref="approveFormRef" layout="inline" class="gap-y-6" size="default" label-width="120px">
                        <a-form-item label="学生姓名" size="default" class="w-4/5 md:w-1/4">
                            <a-input v-bind:value="selectedOrderDetail?.studentname" placeholder="" size="default" disabled></a-input>
                        </a-form-item>
                        <a-form-item label="付款方式" size="default" class="w-4/5 md:w-1/4">
                            <a-select v-model:value="selectedOrderModifiedData.paymentmethod" value-key="" placeholder="选择付款方式" clearable filterable @change="">
                                <a-select-option v-for="item in PaymentMethod"
                                    :key="item"
                                    :label="item"
                                    :value="item">
                                </a-select-option>
                            </a-select>
                            
                        </a-form-item>
                        <a-form-item label="代理名" size="default" class="w-4/5 md:w-1/4">
                            <a-input v-bind:value="selectedOrderDetail?.agentname" placeholder="" size="default" disabled></a-input>
                        </a-form-item>
                        <a-form-item label="实付金额" size="default" class="w-4/5 md:w-1/4">
                            <a-input v-bind:value="selectedOrderDetail?.price" placeholder="" size="default" disabled></a-input>
                        </a-form-item>
                        <a-form-item label="商品" size="default" class="w-4/5 md:w-1/4">
                            <a-tag size="small" v-for="(prd, index) in selectedOrderDetail?.productlist" :key="index">{{ prd }}</a-tag>
                        </a-form-item>
                        <a-form-item label="订单号" size="default" class="w-4/5 md:w-1/4">
                            <a-input v-bind:value="selectedOrderDetail?.orderid" placeholder="" size="default" disabled></a-input>
                        </a-form-item>
                        <a-form-item label="时间" size="default" class="w-4/5 md:w-1/4">
                            <a-input v-bind:value="dayjs.tz(selectedOrderDetail?.updatetime).format('YYYY-MM-DD HH:mm')" placeholder="" size="default" disabled></a-input>
                        </a-form-item>
                        <a-form-item label="单独授权(不分账)" size="default" class="w-4/5 md:w-1/4">
                            <a-checkbox v-model:checked="selectedOrderModifiedData.revokePay" />
                        </a-form-item>
                        
                    </a-form>
                    <br>
                    <a-form>
                        <UploadDragger
                        v-model:file-list="fileList"
                        multiple
                        @change="onChange"
                        :before-upload="() => {return false}"
                        :max-count="4"
                        >
                            <p class="ant-upload-drag-icon">
                                <upload-outlined></upload-outlined>
                            </p>
                            <p class="ant-upload-text">拖拽文件或者<a>点击上传</a></p>
                            <p class="ant-upload-hint">
                                只接受小于500KB的文件.
                            </p>
                            
                        </UploadDragger>
                        <a-button class="mt-3 mb-3" color="success" @click="submitUpload">
                            上传
                        </a-button>
                        
                        <hr>
                        <div class="flex justify-end mt-3 float-end space-x-3">
                            <a-button v-if="selectedOrderDetail?.status != OrderStatus.SETTLED" @click="orderDetailDrawerShow = false">取消</a-button>
                            <a-button v-if="selectedOrderDetail?.status != OrderStatus.DECLINED && selectedOrderDetail?.status != OrderStatus.SETTLED && selectedOrderDetail?.status != OrderStatus.FAILED" danger type="primary" @click="declineOrder">拒绝</a-button>
                            <a-button v-if="selectedOrderDetail?.status != OrderStatus.DECLINED && selectedOrderDetail?.status != OrderStatus.SETTLED && selectedOrderDetail?.status != OrderStatus.FAILED && selectedOrderDetail?.status != OrderStatus.PAID" type="primary" @click="approveOrder(false)">授权订单</a-button>
                            <a-button v-if="selectedOrderDetail?.status == OrderStatus.CREATED || selectedOrderDetail?.status == OrderStatus.PAID" type="primary" @click="approveOrder(true)">强制结算</a-button>
                            <a-button v-if="[OrderStatus.PAID, OrderStatus.SETTLED].indexOf(selectedOrderDetail?.status as OrderStatus) >= 0" type="primary" @click="revokePay(true)">撤销分成(保留学生权限)</a-button>
                            <a-button v-if="[OrderStatus.PAID, OrderStatus.SETTLED].indexOf(selectedOrderDetail?.status as OrderStatus) >= 0" type="primary" @click="revokePay(false)">退款</a-button>
                        </div>
                    </a-form>
                </a-tab-pane>

                <!-- 凭证 -->
                <a-tab-pane tab="凭证" key="proof">
                    
                    
                    <a-table :data-source="orderProofList" :columns="[{key: 'name', dataIndex: 'name', title: '文件'}, {key: 'download', dataIndex: 'download', title: '下载'}]" stripe>
                        <template #bodyCell="{column, record}">
                            <template v-if="column.key == 'name'">
                                {{ record.name }}
                            </template>
                            <template v-if="column.key == 'download'">
                                <a target="_blank" :href="record.url"><a-button type="primary" size="small">下载</a-button></a>
                            </template>
                        </template>
                        
                        
                    </a-table>
                </a-tab-pane>

                <!-- 结算 -->
                <a-tab-pane tab="结算记录" key="settle-log" v-if="selectedOrderDetail?.paymentmethod == PaymentMethod.LIULIU_PAY">
                    <settle-log-section :order-id="selectedOrderDetail?.orderid as number"></settle-log-section>
                </a-tab-pane>
            </a-tabs>
            
        </a-drawer>
        
    </div>
</template>

<script setup lang="ts">
import dayjs from 'dayjs'
import timezone from 'dayjs/plugin/timezone'
import utc from 'dayjs/plugin/utc'
import datePickerCNLocale from 'ant-design-vue/es/date-picker/locale/zh_CN'
import { ref, onMounted } from 'vue';
import { WindowSize } from '@/helpers/constants';
import { useProfileStore } from '@/stores/profile';
import { AxiosError } from 'axios';
import {OrderStatus, OrderStatusMap, PaymentMethod, OrderFilterStatusMap} from '@/models/payment'
import {
  BodySearchOrders,
  confirmOfflineOrder,
  declineOfflineOrder,
  SearchOrderResult,
  searchOrders
} from "@/api/request/order.ts";
import { UploadOutlined } from '@ant-design/icons-vue';
import { revokePayment } from '@/api/request/payment';
import { listOrderProof, uploadOrderProof } from '@/api/request/system';
import { useRequest } from 'vue-request';
import SettleLogSection from './SettleLogSection.vue'
import { notification, message, UploadChangeParam, UploadFile, UploadDragger } from 'ant-design-vue';

dayjs.extend(utc)
dayjs.extend(timezone)
dayjs.tz.setDefault("Asia/Shanghai")

const emits = defineEmits(["stop-loading"])
const profileStore = useProfileStore()

const orderSearchQuery = ref<BodySearchOrders>(new BodySearchOrders)
orderSearchQuery.value.status_list = [OrderStatus.PENDING_CONFIRMATION, OrderStatus.CREATED]
onMounted(async () => {
    await runSearchOrders()
    emits("stop-loading")
})

function initOrderSearchQuery() {
    orderSearchQuery.value = new BodySearchOrders
    orderSearchQuery.value.status_list = [OrderStatus.PENDING_CONFIRMATION, OrderStatus.CREATED]
}

function changeUpdateTime(value: Array<Date>|null) {
    if (value == null) {
        clearUpdateTime()
        return
    }
    orderSearchQuery.value.updateat_start = dayjs(value[0]).format("YYYY-MM-DDTHH:mm:ss")
    orderSearchQuery.value.updateat_end = dayjs(value[1]).format("YYYY-MM-DDTHH:mm:ss")
    console.log(orderSearchQuery.value);
}

const updateStartTime = ref("")
function changeStartTime(value: Date|null) {
    if (value == null) {
        orderSearchQuery.value.updateat_start = ""
        return
    }
    orderSearchQuery.value.updateat_start = dayjs(value).format("YYYY-MM-DDTHH:mm:ss")
}

const updateEndTime = ref("")
function changeEndTime(value: Date|null) {
    if (value == null) {
        orderSearchQuery.value.updateat_end = ""
        return
    }
    orderSearchQuery.value.updateat_end = dayjs(value).format("YYYY-MM-DDTHH:mm:ss")
}
function clearUpdateTime() {
    orderSearchQuery.value.updateat_start = ""
    orderSearchQuery.value.updateat_end = ""
}

const columns = [
    {
        key: 'index',
        title: '序号',
        width: '50'
    },
    {
        key: 'info',
        title: '学生'
    }
]
const filteredOrders = ref<Array<SearchOrderResult>>([])
function sortOrdersByUpdateTime(orderList: SearchOrderResult[]|null|undefined): SearchOrderResult[] {
    if (!orderList) {return []}
    return orderList.sort((a, b) => {return dayjs(b.updatetime).diff(dayjs(a.updatetime))});
}

function filterOutInventoryOrders(orderList: SearchOrderResult[]|null|undefined): SearchOrderResult[] {
    if (!orderList) {return []}
    return orderList.filter((order) => {return order.paymentmethod != PaymentMethod.INVENTORY_AGENT && order.paymentmethod != PaymentMethod.INVENTORY_STUDENT})
}
function runSearchOrders() {
    searchOrders(orderSearchQuery.value)
    .then((res) => {
        filteredOrders.value = res.data
        console.log(filteredOrders.value);
        orderSearchDrawer.value = false
    })
}
const orderSearchDrawer = ref(false)

function selectOrder(record: SearchOrderResult) {
    return {
        onClick: () => {
            console.log(record);
            
            selectedOrderDetail.value = record
            loadOrderProofList(selectedOrderDetail.value.orderid)
            selectedOrderModifiedData.value.paymentmethod = selectedOrderDetail.value.paymentmethod
            orderDetailDrawerShow.value = true
        }
    }
}
const orderDetailDrawerShow = ref(false)
const selectedOrderDetail = ref<SearchOrderResult>()
const selectedOrderModifiedData = ref({
    paymentmethod: "",
    revokePay: false
})

const approveForm = ref()
async function declineOrder() {
  try {
    const res = await declineOfflineOrder(selectedOrderDetail.value?.orderid as number)
    notification.error({
      message: '已拒绝订单',
      description: '订单已拒绝' + res.data
    })
    orderDetailDrawerShow.value = false
    runSearchOrders()
  }
  catch (e) {
    if ((e as AxiosError).response?.data) {
      let respData = (e as AxiosError).response?.data
      notification.error({
        message: '拒绝失败',
        description: '订单拒绝失败，请将下面错误分享给管理员：\n' + (respData as any).data,
      })
    }

  }
}
async function approveOrder(forceSettle: boolean) {
    if (!selectedOrderDetail.value) {
        return}
    try {
        const res = await confirmOfflineOrder(selectedOrderDetail.value?.orderid, selectedOrderModifiedData.value.paymentmethod, selectedOrderModifiedData.value.revokePay, forceSettle)
        notification.success({
            message: '确认成功',
            description: '订单已确认' + res.data,
        })
        orderDetailDrawerShow.value = false
        runSearchOrders()
    }
    catch (e) {
      if ((e as AxiosError).response?.data) {
        let respData = (e as AxiosError).response?.data
        notification.error({
          message: '确认失败',
          description: '订单确认失败，请将下面错误分享给管理员：\n' + (respData as any).data,
        })
      }

    }
}

async function revokePay(keepEntitlement: boolean) {
    await revokePayment(selectedOrderDetail.value?.orderid as number, keepEntitlement)
    notification.success({
        message: '操作成功',
        description: `订单号：${selectedOrderDetail.value?.orderid}，${keepEntitlement? '已撤销分成，保留权限' : '已退款'}`,
    })
    orderDetailDrawerShow.value = false
    runSearchOrders()
}

const fileList = ref<Array<UploadFile>>([])

function onChange(info: UploadChangeParam) {
    const uploadFile = info.file
    if (uploadFile.size as number > 600000) {
        message.error('文件大小不能超过500kB')
        fileList.value.pop()
        return
    }
    console.log(uploadFile);
    
}

const submitUpload = async () => {
    const form = new FormData()
    for (let i = 0; i < fileList.value.length; i++) {
        form.append('file[]', fileList.value[i].originFileObj as File)
    }
    await uploadOrderProof(selectedOrderDetail.value?.orderid as number, form)
    .then(() => {
        notification.success({
            message: '上传成功',
            description: "",
        })
        loadOrderProofList(selectedOrderDetail.value?.orderid as number)
    })
    fileList.value = []

}

const orderDetailDrawerName = ref<string>("edit")
function handleOrderDetailDrawerClose(done: (cancel?: boolean) => void) {
    orderDetailDrawerName.value = "edit"
    done(false)
}

const {data: orderProofList, run: loadOrderProofList} = useRequest<Array<string>>(listOrderProof, {
    manual: true
})

</script>

<style>
.mobile-date-picker {
    max-width: 100vw !important;
    /* background-color: aliceblue !important; */
}
</style>