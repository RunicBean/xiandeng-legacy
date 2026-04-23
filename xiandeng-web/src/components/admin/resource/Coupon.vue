<template>
    <a-config-provider :locale="locale">
        <div class="flex items-center justify-between">
            <h1>销售代码</h1>
            <a-button type="primary" size="large" @click="showCouponCreateDialog" class="me-10">创建销售代码</a-button>
            
        </div>
        
        <a-card shadow="always" :body-style="{ padding: '20px' }">
            <a-form :model="couponSearchQuery" ref="form" label-width="80px" layout="inline" size="default" class="gap-4">
                <a-form-item label="创建时间">
                    <a-range-picker
                        size="default"
                        :locale="locale"
                        @clear="clearCreateTime"
                        @change="changeCreateTime"
                    />
                </a-form-item>
                <a-form-item label="可用商品" class="w-1/3">
                    <a-select v-model:value="couponSearchQuery.product_ids" value-key="" placeholder="" mode="multiple" clearable filterable @change="">
                        <a-select-option v-for="item in products"
                            :key="item.id"
                            :value="item.id">
                            {{ item.productname }}
                        </a-select-option>
                    </a-select>
                </a-form-item>
                <a-form-item label="可用学员" class="w-1/4">
                    <a-select v-model:value="couponSearchQuery.student_ids" value-key="" placeholder="" mode="multiple" clearable filterable @change="">
                        <a-select-option v-for="item in students"
                            :key="item.accountid"
                            :value="item.accountid">
                            {{ (item.lastname as string + item.firstname as string) ? item.lastname as string + item.firstname as string : item.accountname as string }}
                        </a-select-option>
                    </a-select>
                </a-form-item>
                <a-form-item label="优惠金额" size="default">
                    <a-input v-model:value="couponSearchQuery.discount_amount" placeholder="" size="default" clearable @change=""></a-input>
                    
                </a-form-item>
                <a-form-item label="券码" size="default">
                    <a-input v-model:value="couponSearchQuery.code" placeholder="" size="default" clearable @change=""></a-input>
                    
                </a-form-item>
                <a-form-item label="最多次数" size="default">
                    
                    <a-input v-model:value="couponSearchQuery.max_count" placeholder="" size="default" clearable @change=""></a-input>
                    
                </a-form-item>
                <a-form-item label="有效状态" size="default" class="w-1/6">
                    <a-select v-model:value="selectedValidStatus" value-key="" placeholder="" clearable filterable @change="changeValidStatus">
                        <a-select-option :key="0" :value="0">-</a-select-option>
                        <a-select-option :key="1" :value="1">有效</a-select-option>
                        <a-select-option :key="2" :value="2">无效</a-select-option>
                    </a-select>
                    
                </a-form-item>
                
                
            </a-form>
            <br>
            <a-form-item class="flex justify-end mt-3 float-end">
                <div class="flex gap-4">
                    <a-button @click="resetCouponSearchQuery">重置</a-button>
                    <a-button type="primary" @click="runSearchCoupon">查询</a-button>
                </div>
            </a-form-item>
        </a-card>
        
        <a-table :data-source="couponList" :columns="columns" border stripe class="mt-10">
            <template #bodyCell="{ column, record }">
                <template v-if="column.key === 'createdat'">
                    {{ dayjs.tz(record.createdat, "Asia/Shanghai").format("YYYY-MM-DD HH:mm:ss") }}
                </template>
                <template v-if="column.key === 'productname'">
                    <a-tag v-if="productMap?.get(record.productid)?.productname" type="info" size="default" effect="dark">{{ productMap?.get(record.productid)?.productname }}</a-tag>
                    <a-tag v-else type="info" size="default" effect="dark">通用</a-tag>
                </template>
                <template v-if="column.key === 'studentid'">
                    <a-tag v-if="record.studentid">{{ studentMap?.get(record.studentid)?.accountname as string }}</a-tag>
                    <a-tag v-else>通用</a-tag>
                </template>
            </template>
            
            
        </a-table>
        <a-modal
        key="coupon"
        v-model:open="couponCreateVisable"
        title="创建销售代码"
        class="w-4/5 md:w-1/2"
        >
            <a-form :model="couponForm" :rules="couponFormRules" class="gap-4" ref="couponFormRef" label-width="80px" layout="vertical" size="default">
                <a-form-item label="可用商品" props="productid">
                    <a-select v-model:value="couponForm.productid" placeholder="" clearable filterable @change="selectProduct">
                        <a-select-option v-for="item in products"
                            :key="item.id"
                            :value="item.id">
                            <div>
                                <span>{{ item.productname }}</span>
                                <span class="float-end">零售价: {{ item.finalprice }}</span>
                            </div>
                            <div>{{ item.description }}</div>
                        </a-select-option>
                    </a-select>
                </a-form-item>

                <a-form-item label="可用学员">
                    <a-select v-model:value="couponForm.studentid" placeholder="" clearable filterable @clear="clearSelectedStudent" @change="selectStudent">
                        <a-select-option v-for="item in students"
                            :key="item.accountid"
                            :value="item.accountid">
                            {{ item.accountname }}
                        </a-select-option>
                    </a-select>
                </a-form-item>
                <a-form-item label="优惠支付价格" size="default" name="discountamount">
                    <a-input v-model:value="couponForm.discountamount" />
                </a-form-item>
                <a-form-item label="使用次数" size="default">
                    <a-input-number v-model:value="couponForm.maxcount" />
                </a-form-item>
                <a-form-item label="生效日期" size="default">
                    <a-date-picker
                        v-model:value="couponForm.effectstartdate"
                        type="date"
                        size="default"
                        value-format="YYYY-MM-DD"
                    />
                </a-form-item>
                <a-form-item label="失效日期" size="default">
                    <a-date-picker
                        v-model:value="couponForm.effectduedate"
                        type="date"
                        size="default"
                        value-format="YYYY-MM-DD"
                    />
                </a-form-item>
            </a-form>
            
            
            
            <template #footer>
            <div class="dialog-footer">
                <a-button @click="couponCreateVisable = false">取消</a-button>
                <a-button type="primary" @click="createCouponConfirm(couponFormRef)">
                确认
                </a-button>
            </div>
            </template>
        </a-modal>
    </a-config-provider>

    
</template>

<script setup lang="ts">

import dayjs from 'dayjs'
import timezone from 'dayjs/plugin/timezone'
import utc from 'dayjs/plugin/utc'
import {ref, onMounted} from 'vue'
// import { FormInstance } from 'element-plus';
import { AxiosError } from 'axios';
import {Coupon, CouponSearchQuery, createCoupon, CreateCouponBody, searchCoupon} from "@/api/request/coupon.ts";
import {listMyProductWithPrice, MyProductWithPrice} from "@/api/request/product.ts";
import {listMyInvitedStudent, Student} from "@/api/request/student.ts";
import { FormInstance, notification } from 'ant-design-vue';
import { Rule } from 'ant-design-vue/es/form';
import locale from 'ant-design-vue/es/date-picker/locale/zh_CN';
import 'dayjs/locale/zh-cn';

dayjs.locale('zh-cn');
dayjs.extend(utc)
dayjs.extend(timezone)
const selectedStudent = ref<Student>()
const students = ref<Array<Student>>([])
const studentMap = ref<Map<string, Student>>(new Map())

const selectedProduct = ref<MyProductWithPrice>()
const products = ref<Array<MyProductWithPrice>>([])
const productMap = ref<Map<string, MyProductWithPrice>>(new Map())
const couponCreateVisable = ref(false)

const couponList = ref<Array<Coupon>>([])
onMounted(async () => {
    await searchCoupon(couponSearchQuery.value)
    .then((res) => {
        couponList.value = res.data
    })
    listMyInvitedStudent()
    .then((data) => {
        if (!data) {
            students.value = []
        } else {
            students.value = data
        }
        
        for (const student of students.value) {
            studentMap.value?.set(student.accountid as string, student)
        }
        
    })
    listMyProductWithPrice()
    .then((res) => {
        products.value = res.data
        for (const prd of products.value) {
            productMap.value?.set(prd.id, prd)
        }
    })
})

const columns = [
    {
        key: "createdat",
        title: "创建时间",
        dataIndex: "createdat",
        width: 0
    },
    {
        key: "productname",
        title: "可用商品",
        dataIndex: "productname",
        width: 0
    },
    {
        key: "studentid",
        title: "可用学员",
        dataIndex: "studentid",
        width: 0
    },
    {
        key: "code",
        title: "券码",
        dataIndex: "code",
        width: 0
    },
    {
        key: "discountamount",
        title: "优惠金额",
        dataIndex: "discountamount",
        width: 0
    },
    {
        key: "maxcount",
        title: "最多使用次数",
        dataIndex: "maxcount",
        width: 0
    },
    {
        key: "effectstartdate",
        title: "有效期自",
        dataIndex: "effectstartdate",
        width: 0
    },
    {
        key: "effectenddate",
        title: "有效期至",
        dataIndex: "effectenddate",
        width: 0
    },
]

// Coupon Search
const couponSearchQuery = ref<CouponSearchQuery>({
    cur_agent: true,
    created_at: "",
})

function resetCouponSearchQuery() {
    couponSearchQuery.value = {
        cur_agent: true,
        created_at: "",
    }
    selectedValidStatus.value = 0
    runSearchCoupon()
}

function changeCreateTime(value: Array<Date>|null) {
    if (value == null) {
        clearCreateTime()
        return
    }
    couponSearchQuery.value.created_at_start = dayjs(value[0]).format("YYYY-MM-DD")
    couponSearchQuery.value.created_at_end = dayjs(value[1]).format("YYYY-MM-DD")
}
function clearCreateTime() {
    couponSearchQuery.value.created_at_start = ""
    couponSearchQuery.value.created_at_end = ""
}

const selectedValidStatus = ref(0)
function changeValidStatus(value: number) {
    switch (value) {
        case 0:
            couponSearchQuery.value.valid_only = false
            couponSearchQuery.value.expired_only = false
            break;
        case 1:
            couponSearchQuery.value.valid_only = true
            couponSearchQuery.value.expired_only = false
            break;
        case 2:
            couponSearchQuery.value.valid_only = false
            couponSearchQuery.value.expired_only = true
            break;
        default:
            couponSearchQuery.value.valid_only = false
            couponSearchQuery.value.expired_only = false
            break;
    }
}


function runSearchCoupon() {
    searchCoupon(couponSearchQuery.value)
    .then((res) => {
        couponList.value = res.data
    })
}
// Create Coupon
const couponFormRef = ref<FormInstance>()
const couponForm = ref<CreateCouponBody>(new CreateCouponBody)
const couponFormRules = ref<Record<string, Rule[]>>({
    discountamount: [{
        required: true
    }]
})

function selectProduct(prd_id: string) {
    products.value.forEach(element => {
        if (element.id == prd_id) {
            selectedProduct.value = element
        }
    });
}

function selectStudent(stu_id: string) {
    selectedStudent.value = studentMap.value.get(stu_id)
}

function clearSelectedStudent() {
    selectedStudent.value = undefined
}
// const minProductPrice = computed(() => {
//     if (!selectedProduct.value) return "0"
//     if (selectedProduct.value?.upoverwriteprice) {
//         return selectedProduct.value?.upoverwriteprice
//     } else {
//         return selectedProduct.value.updefaultprice
//     }
// })

function showCouponCreateDialog() {
    couponCreateVisable.value = true
}
async function createCouponConfirm(formRef: FormInstance | undefined) {
    if (!formRef) return
    await formRef.validate()
    .then(async () => {
        createCoupon(couponForm.value)
        .then((_) => {
            couponCreateVisable.value = false
            resetCouponSearchQuery()
        })
        .catch((err: AxiosError) => {
            notification.error({
                message: "创建失败",
                description: err.response?.data as string
            })
        })
    })
}
</script>

<style scoped>

</style>