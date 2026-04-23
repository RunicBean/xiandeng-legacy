
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
            <div class="h-12 my-3 flex items-center justify-between">
                <div class="space-x-2 ms-4 text-2xl font-bold">
                    <!-- <s v-if="selectedCoupon && productDetail" class="text-gray-400">¥{{ productDetail.finalprice }}</s> -->
                    <span v-if="productDetail" class="text-red-500">¥{{ productDetail.finalprice  }}</span>
                </div>
                <div class="flex items-center me-4">
                    <a-button type="primary" size="default" round @click="toNosigninNotice">付款</a-button>
                    
                </div>
            </div>
            
            
            
        </div>    
    </div>
    
    
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import {
  getProduct,
  GetProductRow,
  listProductImages,
  ListProductImagesResponse,
  ProductImage
} from "@/api/request/product.ts";

const $route = useRoute()
const $router = useRouter()

function toNosigninNotice() {
    $router.replace({
        name: 'noauth-notice',
    })
}

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

onMounted(async () => {
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