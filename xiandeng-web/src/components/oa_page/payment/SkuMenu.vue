<template>
    <div>
        <h3>商品列表</h3>
        <a-table :data-source="productList" :columns="[{key: 'product', dataIndex: 'product', title: '商品'}, {key: 'action', dataIndex: 'action', title: '操作'}]" border stripe :show-header="false" :pagination="false">
            <template #bodyCell="{ column, record }">
                <template v-if="column.key === 'product'">
                    <div class="description ms-3">
                        <div>{{ record.productname }}</div>
                        <div class="text-xs text-gray-400">{{ record.description }}</div>
                    </div>
                </template>
                <template v-else-if="column.key === 'action'">
                    <a-button type="primary" size="default" @click="goSkuDetailPage(record.id)">查看详情</a-button>
                </template>
            </template>
        </a-table>

        <a class="text-sm text-blue-700 ms-5 leading-10 underline underline-offset-4" @click="listPurchased">查看已购买产品</a>
        <a-drawer title="已购买商品" v-model:open="purchasedDrawerShow" placement="bottom" size="large"
            :destroy-on-close="true" :show-close="true" :wrapperClosable="true">
            <a-table :data-source="purchased" :columns="purchasedColumns" border stripe>

                <template #bodyCell="{ column, record }">
                    <template v-if="column.key === 'payat'">
                        {{ dayjs(record.payat).format("YYYY-MM-DD") }}
                    </template>
                </template>

            </a-table>

        </a-drawer>

    </div>
</template>

<script setup lang="ts">
import dayjs from 'dayjs';
import {ref} from 'vue';
import { useRequest } from 'vue-request';
import {useRoute, useRouter} from 'vue-router';
import {
  listMyPurchasableProduct,
  listMyPurchasedProduct,
  MyPurchasedProduct,
  MyPurchasedProductResponse
} from "@/api/request/product.ts";

const productList = ref([])

useRequest(listMyPurchasableProduct, {
    onSuccess: (res) => {
        console.log(res.data);

        productList.value = res.data
    }
})

const $router = useRouter()
const $route = useRoute()

function goSkuDetailPage(prodId: string) {
    console.log(prodId);
    $router.push($route.params.org_name ? {name: "org-prod-detail", params: {
        productid: prodId,
            org_name: $route.params.org_name
    }} : {name: "prod-detail", params: {
        productid: prodId,
        }})
}

const purchasedDrawerShow = ref(false)
const purchased = ref<Array<MyPurchasedProduct>>()
const purchasedColumns: Array<{dataIndex: string, title: string, key: string, width?: string}> = [
    {
        dataIndex: "productname",
        title: "商品",
        key: "productname"
    },
    {
        dataIndex: "payat",
        title: "购买时间",
        key: "payat"
    }
]
async function listPurchased() {
    await listMyPurchasedProduct()
    .then((res: MyPurchasedProductResponse) => {
        purchased.value = res.data
        console.log(purchased.value);

    })
    purchasedDrawerShow.value = true
}

</script>

<style scoped>

</style>
