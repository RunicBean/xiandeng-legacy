<template>
    <div>
        <!-- 此处是PC版筛选条件页 -->
        <a-card shadow="always" :body-style="{ padding: '20px' }">
            <a-form :model="balanceActivitySearchQuery" ref="form" label-width="80px" layout="inline" size="default">
                <a-form-item label="创建时间">
                    <a-range-picker
                        :locale="locale"
                        size="default"
                        @clear="clearCreateDates"
                        @change="changeCreateDates"
                    />
                </a-form-item>
                <a-form-item label="类型" size="default"  class="w-1/4">
                    <a-select v-model:value="balanceActivitySearchQuery.source" value-key="" placeholder="付款/提现" clearable filterable @change="">
                        <a-select-option value="付款">付款</a-select-option>
                        <a-select-option value="提现">提现</a-select-option>
                    </a-select>
                    
                </a-form-item>
                <a-form-item label="金额">
                    <div class="flex space-x-3">
                        <div>
                            <a-input-number :controls="false" v-model:value="balanceActivitySearchQuery.price_range_start" placeholder="最小值" size="default" clearable @change=""></a-input-number>
                        </div>
                        <div>~</div>
                        <div>
                            <a-input-number :controls="false" v-model:value="balanceActivitySearchQuery.price_range_end" placeholder="最大值" size="default" clearable @change=""></a-input-number>
                        </div>
                        
                    </div>
                    
                </a-form-item>
                <a-form-item label="商品" class="w-1/4">
                    <a-select mode="multiple" v-model:value="balanceActivitySearchQuery.product_list" value-key="" placeholder="" clearable filterable @change="">
                        <a-select-option v-for="item in products"
                            :key="item.id"
                            :value="item.productname">
                            {{item.productname}}
                        </a-select-option>
                    </a-select>
                    
                </a-form-item>
                
                <a-form-item label="ID" size="default">
                    <a-input v-model:value="balanceActivitySearchQuery.id" placeholder="订单/提现ID" size="default" clearable @change=""></a-input>
                    
                </a-form-item>
                
                
                <hr>
                <a-form-item class="flex justify-end mt-3 float-end">
                    <a-button @click="initSearchQuery">重置</a-button>
                    <a-button type="primary" @click="runSearch">查询</a-button>
                </a-form-item>
            </a-form>
            
        </a-card>

        <a-button class="mt-12 mb-3" type="primary" @click="downloadReport">导出</a-button>
        <a-table 
        :data-source="balanceActivityList" 
        :default-sort="{ prop: 'createdat', order: 'descending' }"
        :columns="columns"
        border stripe>
          <template #bodyCell="{column, record}">
            <template v-if="column.key === 'createdat'">
              {{dayjs(record.createdat).format('YYYY-MM-DD HH:mm:ss')}}
            </template>
          </template>
        </a-table>
    </div>
</template>

<script setup lang="ts">
import timezone from 'dayjs/plugin/timezone'
import utc from 'dayjs/plugin/utc'
import dayjs from 'dayjs'
import { ref, onMounted } from 'vue';
import {listProduct, Product} from "@/api/request/product.ts";
import {
    Balance,
  BalanceActivitySearchQuery,
  exportMyBalanceActivity,
//   exportMyBalanceActivity,
  getBalance,
  listMyBalanceActivity
} from "@/api/request/wallet.ts";
import locale from 'ant-design-vue/es/date-picker/locale/zh_CN';
// import BalanceStat from './balance/BalanceStat.vue'

dayjs.extend(utc)
dayjs.extend(timezone)

const balanceActivitySearchQuery = ref<BalanceActivitySearchQuery>(new BalanceActivitySearchQuery)
const createDate = ref("")
function changeCreateDates(value: Array<Date>|null) {
    if (value == null) {
        clearCreateDates()
        return
    }
    balanceActivitySearchQuery.value.createdat_start = dayjs(value[0]).format("YYYY-MM-DD")
    balanceActivitySearchQuery.value.createdat_end = dayjs(value[1]).format("YYYY-MM-DD")
}

function clearCreateDates() {
    createDate.value = ""
    balanceActivitySearchQuery.value.createdat_start = ""
    balanceActivitySearchQuery.value.createdat_end = ""
}

const balances = ref<Balance>()
const products = ref<Array<Product>>([])
onMounted(async () => {
    try {
        const balanceResult = await getBalance()
        console.log(balanceResult.data);
        balances.value = balanceResult.data
        
        const res = await listProduct()
        products.value = res.data
        console.log(products.value);

        await runSearch()
        
    }
    catch {
        console.log("listProduct error")
    }
})

async function initSearchQuery() {
    balanceActivitySearchQuery.value = new BalanceActivitySearchQuery
    clearCreateDates()
    await runSearch()
}

const balanceActivityList = ref<Array<any>>([])
async function runSearch() {
    // const res = await listBalanceActivity(balanceActivitySearchQuery.value)
    const res = await listMyBalanceActivity(balanceActivitySearchQuery.value)
    balanceActivityList.value = res.data
}
const columns: Array<{key: string, dataIndex: string, title: string, width?: number}> = [
    {
        key: "createdat",
        dataIndex: "createdat",
        title: "创建时间",
        // width: 200,
        
    },
    {
        key: "category",
        dataIndex: "category",
        title: "交易类型",
        // width: 200
    },
    {
        key: "relatedorder",
        dataIndex: "relatedorder",
        title: "订单号",
        // width: 100
    },
    {
        key: "source",
        dataIndex: "source",
        title: "项目",
        // width: 100
    },
    {
        key: "amount",
        dataIndex: "amount",
        title: "金额",
        // width:100
    },
    {
        key: "balanceafter",
        dataIndex: "balanceafter",
        title: "交易后余额",
        // width:100
    },
    {
        key: "balancetype",
        dataIndex: "balancetype",
        title: "余额类型"
    },
    {
        key: "salesprovider",
        dataIndex: "salesprovider",
        title: "加盟商/承销商"
    }
    ]

function downloadReport() {
  exportMyBalanceActivity(balanceActivitySearchQuery.value)
      .then((res) => {
        console.log(res.data)
        console.log(res.headers)
        const url = window.URL.createObjectURL(res.data);
        const link = document.createElement('a');
        link.href = url;
        link.setAttribute('download', res.headers["filename"]);
        document.body.appendChild(link);
        link.click();

        // 清理
        document.body.removeChild(link);
        window.URL.revokeObjectURL(url);
      })

}
</script>

<style scoped>

</style>