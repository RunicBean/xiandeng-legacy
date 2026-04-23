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
        
        
        
    </div>
</template>

<script setup lang="ts">
import {ref} from 'vue';
import { useRequest } from 'vue-request';
import { useRouter } from 'vue-router';
import {listPublishedProduct} from "@/api/request/product.ts";

const productList = ref([])

useRequest(listPublishedProduct, {
    onSuccess: (res) => {
        console.log(res.data);
        
        productList.value = res.data
    }
})

const $router = useRouter()

function goSkuDetailPage(prodId: string) {
    console.log(prodId);
    $router.push({name: "noauth-prod-detail", params: {
        productid: prodId
    }})
}

</script>

<style scoped>

</style>