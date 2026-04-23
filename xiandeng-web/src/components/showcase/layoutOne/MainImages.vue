<script setup lang="ts">
import {ref, watch} from "vue";
import {listShowcaseCarousel} from "@/api/request/showcase";

const props = defineProps({
    companyName: String
})

const dataList1 = ref<Array<{
  id: number,
  extlink: string,
  imagelink: string
}>>([])

watch(() => props.companyName, (newName) => {
  listShowcaseCarousel(newName as string).then((res) => {
        dataList1.value = res.data
    })
})

// onMounted(() => {
//   listShowcaseCarousel(props.companyName).then((res) => {
//     dataList1.value = res.data
//   })
// })

function modifyImageLink(imageLink: string) {
    if (imageLink.indexOf("uploads/") === 0) {
        return `api/${imageLink}`
    } else {
        return imageLink
    }
}


function click(redirectLink: string) {
    if (redirectLink === "") {
    } else {
        window.location.href = redirectLink
    }
}
</script>

<template>
<!--    <a-carousel autoplay>-->
<!--        <template v-for="d in dataList1">-->
<!--            <div>-->
<!--                <a @click="click(d.redirectLink)"><img :src="modifyImageLink(d.imageLink)" alt=""></a>-->
<!--            </div>-->
<!--        </template>-->
<!--    </a-carousel>-->
  <a-carousel arrow="always" autoplay>
    <div v-for="d in dataList1" :key="d.id">
      <a @click="click(d.extlink)"><img :src="modifyImageLink(d.imagelink)" alt=""></a>
<!--      <h3 class="small justify-center" text="2xl">{{ item }}</h3>-->
    </div>
  </a-carousel>
</template>

<style>
.el-carousel__container {
  width: 100%;
  height: 100% !important;
}

.el-carousel--horizontal {
  height: 35vh;
}
</style>