<template>
    <div>
        <h2 class="mt-5">央国企招聘信息</h2>
        <a-list :data-source="items">
            <template #renderItem="{item}">
                <div @click="openDetailDrawer(item.recruitid)" class="h-[15vh] border border-gray-200 flex items-center px-3 space-x-3">
                    <a-avatar icon="el-icon-user-solid" size="large" shape="square" :src="item.logourl" fit="fill"></a-avatar>
                    <div class="w-full flex flex-col items-start">
                        <div class="font-semibold text-gray-700">{{ item.companyname }}</div>
                        <div class="w-full flex items-center justify-between">
                            <div class="space-x-1">
                                <a-tag size="small" v-for="(city, index) in splitCityNameList(item.citynamelist)" :key="index" type="primary">{{ city }}</a-tag>
                            </div>
                            <div class="text-xs mt-1 text-gray-500">
                                最后更新：{{ parseUpdateTime(item.updatetime) }}
                            </div>
                        </div>
                    </div>
                </div>

            </template>
        </a-list>
<!--        <ul v-infinite-scroll="appendItems" infinite-scroll-distance="1" class="space-y-[-1px] h-[100vh]">-->
<!--            <li @click="openDetailDrawer(item.recruitid)" class="h-[15vh] border border-gray-200 flex items-center px-3 space-x-3" v-for="(item, index) in items" :key="index">-->
<!--                <a-avatar icon="el-icon-user-solid" size="large" shape="square" :src="item.logourl" fit="fill"></a-avatar>-->
<!--                <div class="w-full flex flex-col items-start">-->
<!--                    <div class="font-semibold text-gray-700">{{ item.companyname }}</div>-->
<!--                    <div class="w-full flex items-center justify-between">-->
<!--                        <div class="space-x-1">-->
<!--                            <a-tag size="small" v-for="(city, index) in splitCityNameList(item.citynamelist)" :key="index" type="primary">{{ city }}</a-tag>-->
<!--                        </div>-->
<!--                        <div class="text-xs mt-1 text-gray-500">-->
<!--                            最后更新：{{ parseUpdateTime(item.updatetime) }}-->
<!--                        </div>-->
<!--                    </div>-->
<!--                </div>-->
<!--            </li>-->
<!--        </ul>-->
        <div v-if="loading" class="w-full h-[64px] text-center leading-[64px] text-gray-500">正在加载...</div>
        <p v-if="noMore" class="w-full h-[64px] text-center leading-[64px] text-gray-500">到底啦</p>

        <a-drawer v-if="details" title="详细信息" v-model:open="detailDrawer" width="90%"
             :destroy-on-close="true" :show-close="true" :wrapperClosable="true">
            <a-descriptions
                class="margin-top"
                :title="details.companyname"
                :column="1"
                size="default"
                border
            >
                <template #extra>
                <a-avatar icon="el-icon-user-solid" size="default" shape="circle" :src="details.logourl" fit="fill"></a-avatar>

                </template>
                <a-descriptions-item min-width="80px">
                <template #label>
                    <div class="cell-item">
                    开始时间
                    </div>
                </template>
                {{ details.begintime }}
                </a-descriptions-item>
                <a-descriptions-item>
                <template #label>
                    <div class="cell-item">
                    结束时间
                    </div>
                </template>
                {{ details.endtime }}
                </a-descriptions-item>
                <a-descriptions-item>
                <template #label>
                    <div class="cell-item">
                    招聘地区
                    </div>
                </template>
                {{ details.citynamelist }}
                </a-descriptions-item>
                <a-descriptions-item>
                <template #label>
                    <div class="cell-item">
                    企业类型
                    </div>
                </template>
                <a-tag size="small">{{ details.companytype }}</a-tag>
                </a-descriptions-item>
                <a-descriptions-item>
                <template #label>
                    <div class="cell-item">
                    企业
                    </div>
                </template>
                {{ details.enterprisename }}
                </a-descriptions-item>
            </a-descriptions>
            <a-divider direction="horizontal" content-position="left"></a-divider>

            <a-descriptions
                class="margin-top"
                title="岗位信息"
                :column="1"
                size="default"
                border
            >
                <a-descriptions-item min-width="80px">
                <template #label>
                    <div class="cell-item">
                    岗位信息
                    </div>
                </template>
                {{ details.content }}
                </a-descriptions-item>
                <a-descriptions-item>
                <template #label>
                    <div class="cell-item">
                    招聘要求
                    </div>
                </template>
                {{ details.domesticstudent }}
                </a-descriptions-item>
                <a-descriptions-item>
                <template #label>
                    <div class="cell-item">
                    招聘要求(留学)
                    </div>
                </template>
                {{ details.overseasstudent }}
                </a-descriptions-item>
                <a-descriptions-item>
                <template #label>
                    <div class="cell-item">
                    投递地址
                    </div>
                </template>
                <a :underline="false" :href="details.url" target="_blank">{{ details.url }}</a>

                </a-descriptions-item>
            </a-descriptions>
        </a-drawer>

    </div>
</template>

<script setup lang="ts">
import dayjs from 'dayjs'
import 'dayjs/locale/zh-cn'
import relativeTime from 'dayjs/plugin/relativeTime'
import { listRecruitMenu, getRecruitDetail, type RecruitMenuItem, ListRecruitMenuResponse, RecruitDetail, GetRecruitDetailResponse } from '@/api/request/resource';
import { ref, onMounted } from 'vue';
const items = ref<Array<RecruitMenuItem>>([])
onMounted(async () => {
    console.log("run onMounted");
    window.addEventListener('scroll', onScroll);

    await listRecruitMenu(0, 10)
    .then((res: ListRecruitMenuResponse) => {
        items.value = res.data
    })


})

const loading = ref(false)
const noMore = ref(false)

const count = ref(10)
async function appendItems() {
    if (items.value.length == 0) {return}
    if (noMore.value) {return}
    console.log("appendItems from ", count.value);

    loading.value = true
    await listRecruitMenu(count.value, 10)
    .then((res: ListRecruitMenuResponse) => {
        if (!res.data) {noMore.value = true; return}
        items.value = [...items.value, ...res.data]
        count.value += 10
    })
    .finally (() => {
        loading.value = false
    })
}

function onScroll() {
    if (loading.value) return
    // 检测用户接近页面底部时，触发加载更多
    if ((window.innerHeight + window.scrollY) >= document.body.offsetHeight - 20) {
        console.log("reach to: ", window.innerHeight + window.scrollY)
        appendItems();
    }
}

function splitCityNameList(citynamelist: string) {
    let l = citynamelist.split(',')
    let newList
    if (l.length > 2) {
        newList = [l[0], l[1], l[2] + "..."]
    } else {
        newList = l
    }
    return newList
}

dayjs.locale('zh-cn')
dayjs.extend(relativeTime)
function parseUpdateTime(isoTime: string) {
    let d = dayjs(isoTime).subtract(8, 'hour')
    if (dayjs().diff(d, 'day') < 3) {
        return d.fromNow()
    } else {
        return d.format('MM-DD')
    }
}

// 详细信息界面

const detailDrawer = ref(false)
const details = ref<RecruitDetail>()
function openDetailDrawer(recruitId: number) {
    getRecruitDetail(recruitId)
    .then((res: GetRecruitDetailResponse) => {
        details.value = res.data
        detailDrawer.value = true
    })

}
</script>

<style scoped>

</style>
