<template>
    <div>
        <h1 class="hidden md:block">考研就业参考</h1>
        <h2 class="mt-5 md:hidden">考研就业参考</h2>
        <a-card shadow="always" class="mx-4 md:mx-10">
            <a-form :model="jobRefForm" ref="jobRefFormRef" layout="inline" size="default" class="gap-y-4 flex">
                <a-form-item class="w-1/4 hidden md:block" label="学科门类">
                    <a-select v-model:value="jobRefForm.faculty" @change="facultyChange">
                        <a-select-option v-for="(item, index) in faculties" :key="index" :value="item">{{ item }}</a-select-option>
                    </a-select>
                </a-form-item>
                <a-form-item class="w-full block md:hidden">
                    <a-select placeholder="学科门类" v-model:value="jobRefForm.faculty" @change="facultyChange">
                        <a-select-option v-for="(item, index) in faculties" :key="index" :value="item">{{ item }}</a-select-option>
                    </a-select>
                </a-form-item>

                <a-form-item class="w-1/4 hidden md:block" label="二级学科">
                    <a-select v-model:value="jobRefForm.department" :disabled="!departmentFieldDisabled" @change="departmentChange">
                        <a-select-option v-for="(item, index) in departments" :key="index" :value="item">{{ item }}</a-select-option>
                    </a-select>
                </a-form-item>
                <a-form-item class="w-full block md:hidden">
                    <a-select placeholder="二级学科" v-model:value="jobRefForm.department" :disabled="!departmentFieldDisabled" @change="departmentChange">
                        <a-select-option v-for="(item, index) in departments" :key="index" :value="item">{{ item }}</a-select-option>
                    </a-select>
                </a-form-item>

                <a-form-item class="w-1/4 hidden md:block" label="专业">
                    <a-select v-model:value="jobRefForm.major" :disabled="!majorFieldDisabled" @change="selectMajor">
                        <a-select-option v-for="(item, index) in majors" :key="index" :value="item.code">{{ item.name }}</a-select-option>
                    </a-select>
                </a-form-item>
                <a-form-item class="w-full block md:hidden">
                    <a-select placeholder="专业" v-model:value="jobRefForm.major" :disabled="!majorFieldDisabled" @change="selectMajor">
                        <a-select-option v-for="(item, index) in majors" :key="index" :value="item.code">{{ item.name }}</a-select-option>
                    </a-select>
                </a-form-item>

                <a-form-item class="w-1/4 hidden md:block" label="企业名称">
                    <a-input v-model:value="jobRefForm.enterprise" :disabled="jobRefForm.major == ''" @keyup.enter="reloadEnterprises"></a-input>
                </a-form-item>
                <a-form-item class="w-full block md:hidden">
                    <a-input placeholder="企业名称" v-model:value="jobRefForm.enterprise" :disabled="jobRefForm.major == ''" @keyup.enter="reloadEnterprises"></a-input>
                </a-form-item>
                
            </a-form>
            <br>
            <div class="flex justify-end mt-3 float-end space-x-2">
                <a-button @click="reset">重置</a-button>
                <a-button type="primary" @click="reloadEnterprises">查询</a-button>
            </div>
        </a-card>

        <a-card v-if="jobRefForm.major != null" class="mt-12 mx-4 md:mx-10" shadow="always" :body-style="{ padding: '20px' }">
            <div class="mb-8">
                <h5 class="md:hidden mb-3">考研建议</h5>
                <div class="hidden md:block float float-left relative top-12 font-bold">考研建议</div>
                <div class="bg-blue-100 rounded-md py-7 md:py-10 px-5 md:px-10 m-auto w-full md:w-4/5">
                    <div class="md:line-clamp-none" :class="{'line-clamp-3': suggestionCollpased}">{{ suggestion }}</div>
                    <div class="md:hidden h-8 w-8 float float-right flex justify-center items-center cursor-pointer" @click="suggestionCollpaseToggle">
                        <CaretDownFilled v-if="suggestionCollpased" />
                        <CaretUpFilled v-else />
                    </div>
                    
                </div>
                
                <!-- <div class="line-clamp-3 md:line-clamp-none suggestion w-4/5 m-auto p-10 bg-blue-100 rounded-md">{{ suggestion }}</div> -->
                
            </div>
            <hr>
            
            <Spin :spinning="loading">
                
                <a-table v-if="enterpriseList" class="mt-8 hidden md:block" :data-source="enterpriseList?.data.data" :columns="enterpriseColumns" border stripe :pagination="pagination">
                    <template #bodyCell="{ column, record }">
                        <template v-if="column.key === 'index'">
                            <a-image :height="25" :src="`https://dorian-personal-public.oss-cn-shenzhen.aliyuncs.com/xiandeng.net.cn/public/images/logo/e${record.id}.webp?x-oss-process=image/resize,w_2000`" alt="" />
                        </template>
                        <template v-else-if="column.key === 'website'">
                            <a :href="record.website" target="_blank">{{ record.website }}</a>
                        </template>
                    </template>
                </a-table>

                <!-- mobile layout -->
                <a-table :show-header="false" v-if="enterpriseList" class="mt-8 md:hidden" :data-source="enterpriseList?.data.data" :columns="[{key: 'index', dataIndex: 'index', title: 'ID'}]" border stripe :pagination="mobilePagination">
                    <template #bodyCell="{ column, record }">
                        <template v-if="column.key === 'index'">
                            <div class="flex items-center">
                                <a-image :height="25" :src="`https://dorian-personal-public.oss-cn-shenzhen.aliyuncs.com/xiandeng.net.cn/public/images/logo/e${record.id}.webp?x-oss-process=image/resize,w_2000`" alt="" />
                                <div class="flex flex-col ml-2">
                                    <div>{{ record.name }}</div>
                                    <a @click="copyToClipboard(record.website)">招聘官网</a>
                                </div>
                            </div>
                            
                        </template>
                    </template>
                </a-table>
            </Spin>
            
            <!-- <div class="pagination float-end my-4">
                <a-pagination
                    background
                    @current-change="(page: number) => {enterprisePagination.currentPage = page}"
                    :current-page="enterprisePagination.currentPage"
                    :page-size="enterprisePagination.pageSize"
                    layout="total, prev, pager, next"
                    :total="enterprises.length">
                </a-pagination>
            </div> -->
        </a-card>
        
        
    </div>
</template>

<script setup lang="ts">
import { getPostgradSuggestion, listDepartmentByFaculty, listFaculty, listGoventerprise, listMajorByDepartment } from '@/api/request/resource';
import { copyToClipboard } from '@/helpers/common';
import { CaretDownFilled, CaretUpFilled } from '@ant-design/icons-vue';
import { Spin } from 'ant-design-vue';
import { onMounted, computed, ref } from 'vue';
import { usePagination } from 'vue-request';

const jobRefForm = ref({
    faculty: null,
    department: null,
    major: null,
    enterprise: null
})
const faculties = ref<Array<string>>([])
onMounted(async () => {
    await listFaculty()
    .then((res) => {
        faculties.value = res.data
    })
})
async function facultyChange(faculty: string) {
    jobRefForm.value.department = null
    departments.value = []
    jobRefForm.value.major = null
    majors.value = []
    await listDepartmentByFaculty(faculty)
    .then((res)  => {
        departments.value = res.data
    })
}

// 此 computed 属性根据 departments 列表的长度决定是否禁用某个字段。
// 当 departments 列表为空时，表示没有部门被选择，此时该字段不应该被禁用。
const departmentFieldDisabled = computed(() => {
  // 检查 departments 是否已定义且是一个数组
  if (!departments || !Array.isArray(departments.value)) {
    console.warn('departments is undefined or not an array');
    // 如果 departments 无效，为了安全性返回 false，具体返回值依据业务逻辑调整
    return false;
  }
  // 当 departments 列表不为空时，返回 true 表示该字段应该被禁用
  return departments.value.length > 0;
});
const departments = ref<Array<string>>([])
async function departmentChange(department: string) {
    jobRefForm.value.major = null
    majors.value = []
    await listMajorByDepartment(department)
    .then((res) => {
        majors.value = res.data
    })
}

const majorFieldDisabled = computed(() => {
    if (!majors || !Array.isArray(majors.value)) {
    console.warn('majors is undefined or not an array');
    // 如果 majors 无效，为了安全性返回 false，具体返回值依据业务逻辑调整
    return false;
  }
  // 当 majors 列表不为空时，返回 true 表示该字段应该被禁用
  return majors.value.length > 0;
})
const majors = ref<Array<{code: string, name: string}>>([])


// const page = ref(1)
// const pageSize = ref(10)
function selectMajor(majorCode: string) {
    getPostgradSuggestion(majorCode)
    .then((res) => {
        suggestion.value = res.data
    })
    loadEnterprises(jobRefForm.value.major??'', '', 1, 10)
}

const suggestion = ref()
const enterprises = ref([])
const enterpriseColumns: Array<{key: string, dataIndex: string, title: string, width?: string}> = [
    {key: "index", dataIndex: "index", title: "ID"},
    {key: "name", dataIndex: "name", title: "企业名称"},
    {key: "website", dataIndex: "website", title: "招聘官网"},
]

const {data: enterpriseList, current, pageSize, run: loadEnterprises, total, loading} = usePagination(listGoventerprise, {
    defaultParams: [jobRefForm.value.major??'', '', 1, 10],
    manual: true,
    pagination: {
        currentKey: 'page',
        pageSizeKey: 'pageSize',
        totalKey: 'data.totalCount',
    },
})

const pagination = computed(() => ({
    total: total.value,
    current: current.value,
    pageSize: pageSize.value,
    showTotal: (total: number) => `共${total}条`,
    onChange: onPageChange
}));

const mobilePagination = computed(() => ({
    size: 'small',
    total: total.value,
    current: current.value,
    pageSize: pageSize.value,
    showTotal: (total: number) => `共${total}条`,
    onChange: onPageChange
}));

function onPageChange(page: number, pageSize: number) {
    loadEnterprises(jobRefForm.value.major??'', jobRefForm.value.enterprise??'', page, pageSize)
}
// const enterprisePagination = ref({
//     currentPage: 1,
//     pageSize: 10
// })

// const paginatedData = computed(() => {
//     const start = (enterprisePagination.value.currentPage - 1) * enterprisePagination.value.pageSize;
//     const end = enterprisePagination.value.currentPage * enterprisePagination.value.pageSize;
//     console.log(enterprises.value.slice(start, end));
//     return enterprises.value.slice(start, end);
// })

function reloadEnterprises() {
    if (jobRefForm.value.major == '') {return}
    loadEnterprises(jobRefForm.value.major??'', jobRefForm.value.enterprise??'', 1, 10)
    // listGoventerprise(jobRefForm.value.major, entName, 1, 10)
    // .then((res) => {
    //     enterprises.value = res.data
    // })
}

function reset() {
    jobRefForm.value.faculty = null
    faculties.value = []
    jobRefForm.value.enterprise = null
    enterprises.value = []
    jobRefForm.value.department = null
    departments.value = []
    jobRefForm.value.major = null
    majors.value = []
}

const suggestionCollpased = ref(true)
function suggestionCollpaseToggle() {
    suggestionCollpased.value = !suggestionCollpased.value
}
</script>

<style scoped>
</style>