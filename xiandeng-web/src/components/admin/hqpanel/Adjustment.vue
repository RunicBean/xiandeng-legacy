<template>
    <a-config-provider :locale="locale">
        <div class="flex items-center justify-between mb-6">
            <h1 class="text-2xl font-bold">调账页面</h1>
        </div>

        <!-- 创建调账表单 -->
        <a-card shadow="always" :body-style="{ padding: '20px' }" class="mb-6">
            <h2 class="text-lg font-semibold mb-4">新建调账</h2>
            <a-form 
                :model="adjustmentForm" 
                :rules="formRules" 
                ref="formRef" 
                label-width="100px" 
                layout="inline" 
                size="default"
                class="max-w-full"
            >
                <a-form-item label="账号ID" name="account_id" required>
                    <a-input 
                        v-model:value="adjustmentForm.account_id" 
                        placeholder="请输入accountid" 
                        size="default" 
                        clearable
                        style="width: 200px"
                    />
                </a-form-item>
                
                <a-form-item label="金额" name="amount" required>
                    <a-input 
                        v-model:value="adjustmentForm.amount" 
                        placeholder="请输入调整金额" 
                        size="default" 
                        clearable
                        style="width: 150px"
                    />
                </a-form-item>
                
                <a-form-item label="余额类型" name="balance_type" required>
                    <a-select 
                        v-model:value="adjustmentForm.balance_type" 
                        placeholder="请选择余额类型" 
                        size="default" 
                        clearable
                        style="width: 180px"
                    >
                        <a-select-option 
                            v-for="option in BALANCE_TYPE_OPTIONS" 
                            :key="option.value" 
                            :value="option.value"
                        >
                            {{ option.label }}
                        </a-select-option>
                    </a-select>
                </a-form-item>
                
                <a-form-item label="说明" name="notes" required>
                    <a-textarea 
                        v-model:value="adjustmentForm.notes" 
                        placeholder="请输入调整详细说明" 
                        size="default" 
                        :rows="1"
                        clearable
                        style="width: 250px"
                    />
                </a-form-item>
                
                <a-form-item>
                    <a-button 
                        type="primary" 
                        size="default" 
                        @click="handleSubmit"
                        :loading="submitting"
                    >
                        新建调账
                    </a-button>
                </a-form-item>
            </a-form>
        </a-card>

        <!-- 调账记录列表 -->
        <a-card shadow="always" :body-style="{ padding: '20px' }">
            <h2 class="text-lg font-semibold mb-4">调账记录</h2>
            
            <!-- 搜索筛选表单 -->
            <a-form 
                :model="searchForm" 
                layout="inline" 
                size="default"
                class="mb-4"
            >
                <a-form-item label="账号名称">
                    <a-input 
                        v-model:value="searchForm.accountname" 
                        placeholder="请输入账号名称" 
                        size="default" 
                        clearable
                        style="width: 150px"
                    />
                </a-form-item>
                
                <a-form-item label="余额类型">
                    <a-select 
                        v-model:value="searchForm.balancetype" 
                        placeholder="请选择余额类型" 
                        size="default" 
                        clearable
                        style="width: 150px"
                    >
                        <a-select-option 
                            v-for="option in BALANCE_TYPE_OPTIONS" 
                            :key="option.value" 
                            :value="option.value"
                        >
                            {{ option.label }}
                        </a-select-option>
                    </a-select>
                </a-form-item>
                
                <a-form-item label="操作用户">
                    <a-input 
                        v-model:value="searchForm.nickname" 
                        placeholder="请输入操作用户" 
                        size="default" 
                        clearable
                        style="width: 150px"
                    />
                </a-form-item>
                
                <a-form-item label="调整金额">
                    <a-input-number
                        v-model:value="searchForm.amountMin"
                        placeholder="最小金额"
                        size="default"
                        style="width: 120px"
                        :precision="2"
                    />
                    <span class="mx-2">至</span>
                    <a-input-number
                        v-model:value="searchForm.amountMax"
                        placeholder="最大金额"
                        size="default"
                        style="width: 120px"
                        :precision="2"
                    />
                </a-form-item>
                
                <a-form-item label="创建时间">
                    <a-range-picker
                        v-model:value="searchForm.dateRange"
                        size="default"
                        :locale="locale"
                        style="width: 240px"
                    />
                </a-form-item>
                
                <a-form-item>
                    <a-button 
                        type="primary" 
                        @click="handleSearch"
                        :loading="loading"
                        class="mr-2"
                    >
                        搜索
                    </a-button>
                    <a-button @click="handleReset">
                        重置
                    </a-button>
                </a-form-item>
            </a-form>
            
            <div class="text-sm text-orange-600 mb-4 p-3 bg-orange-50 rounded">
                表格header可筛选、排序，表格语句参见:DLYB-180
            </div>
            
            <a-table 
                :data-source="filteredRecords" 
                :columns="columns" 
                :loading="loading"
                border 
                stripe 
                class="mt-4"
                :pagination="{
                    pageSize: 20,
                    showSizeChanger: true,
                    showQuickJumper: true,
                    showTotal: (total: number, range: [number, number]) => `第 ${range[0]}-${range[1]} 条，共 ${total} 条`
                }"
                @change="handleTableChange"
            >
                <template #bodyCell="{ column, record }">
                    <template v-if="column.key === 'createdat'">
                        {{ formatDateTime(record.createdat) }}
                    </template>
                    <template v-if="column.key === 'balancetype'">
                        {{ getBalanceTypeLabel(record.balancetype) }}
                    </template>
                    <template v-if="column.key === 'amount'">
                        <span :class="parseFloat(record.amount) >= 0 ? 'text-green-600' : 'text-red-600'">
                            {{ parseFloat(record.amount) >= 0 ? '+' : '' }}{{ record.amount }}
                        </span>
                    </template>
                    <template v-if="column.key === 'balanceafter'">
                        <span class="font-medium">{{ record.balanceafter || '-' }}</span>
                    </template>
                </template>
            </a-table>
        </a-card>
    </a-config-provider>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, computed } from 'vue';
import { message } from 'ant-design-vue';
import { insertAdjustment, listAdjustmentRecords, type AdjustmentForm, type AdjustmentRecord, BALANCE_TYPE_OPTIONS } from '@/api/request/adjustment';
import dayjs from 'dayjs';
import 'dayjs/locale/zh-cn';
import timezone from 'dayjs/plugin/timezone';
import utc from 'dayjs/plugin/utc';

dayjs.extend(utc);
dayjs.extend(timezone);
dayjs.locale('zh-cn');

const locale = {
    locale: 'zh-cn'
};

// 表单数据
const adjustmentForm = reactive<AdjustmentForm>({
    account_id: '',
    amount: '',
    balance_type: '',
    notes: ''
});

// 表单验证规则
const formRules = {
    account_id: [
        { required: true, message: '请输入账号ID', trigger: 'blur' }
    ],
    amount: [
        { required: true, message: '请输入调整金额', trigger: 'blur' },
        { pattern: /^-?\d+(\.\d{1,2})?$/, message: '请输入正确的金额格式', trigger: 'blur' }
    ],
    balance_type: [
        { required: true, message: '请选择余额类型', trigger: 'change' }
    ],
    notes: [
        { required: true, message: '请输入调整说明', trigger: 'blur' }
    ]
};

// 响应式数据
const formRef = ref();
const submitting = ref(false);
const loading = ref(false);
const adjustmentRecords = ref<AdjustmentRecord[]>([]);

// 搜索表单数据
const searchForm = reactive({
    accountname: '',
    balancetype: '',
    nickname: '',
    amountMin: null as number | null,
    amountMax: null as number | null,
    dateRange: null as [string, string] | null,
});

// 过滤后的记录
const filteredRecords = computed(() => {
    let records = adjustmentRecords.value;
    
    // 按账号名称筛选
    if (searchForm.accountname) {
        records = records.filter(record => 
            record.accountname?.toLowerCase().includes(searchForm.accountname.toLowerCase())
        );
    }
    
    // 按余额类型筛选
    if (searchForm.balancetype) {
        console.log(records);
        
        console.log(searchForm.balancetype);
        
        records = records.filter(record => record.balancetype === searchForm.balancetype);
    }

    // 按操作用户筛选
    if (searchForm.nickname) {
        records = records.filter(record => 
            record.nickname?.toLowerCase().includes(searchForm.nickname.toLowerCase())
        );
    }

    // 按调整金额筛选
    if (searchForm.amountMin !== null && searchForm.amountMin !== undefined) {
        records = records.filter(record => parseFloat(record.amount) >= searchForm.amountMin!);
    }
    if (searchForm.amountMax !== null && searchForm.amountMax !== undefined) {
        records = records.filter(record => parseFloat(record.amount) <= searchForm.amountMax!);
    }
    
    // 按日期范围筛选
    if (searchForm.dateRange && searchForm.dateRange.length === 2) {
        const startDate = dayjs(searchForm.dateRange[0]);
        const endDate = dayjs(searchForm.dateRange[1]);
        records = records.filter(record => {
            const recordDate = dayjs(record.createdat);
            return recordDate.isAfter(startDate) && recordDate.isBefore(endDate);
        });
    }
    
    return records;
});

// 表格列定义
const columns = [
    {
        title: '创建时间',
        dataIndex: 'createdat',
        key: 'createdat',
        sorter: (a: AdjustmentRecord, b: AdjustmentRecord) => {
            const dateA = dayjs(a.createdat);
            const dateB = dayjs(b.createdat);
            if (dateA.isBefore(dateB)) return -1;
            if (dateA.isAfter(dateB)) return 1;
            return 0;
        },
        width: 180,
    },
    {
        title: '账号',
        dataIndex: 'accountname',
        key: 'accountname',
        width: 120,
        // filters: [],
        // filterSearch: true,
        // onFilter: (value: string, record: AdjustmentRecord) => 
        //     record.accountname?.toLowerCase().includes(value.toLowerCase())
    },
    {
        title: '余额类型',
        dataIndex: 'balancetype',
        key: 'balancetype',
        width: 150,
        // filters: BALANCE_TYPE_OPTIONS.map(option => ({
        //     text: option.label,
        //     value: option.value
        // })),
        // onFilter: (value: string, record: AdjustmentRecord) => record.balancetype === value
    },
    {
        title: '调整金额',
        dataIndex: 'amount',
        key: 'amount',
        width: 120,
        sorter: (a: AdjustmentRecord, b: AdjustmentRecord) => {
            const amountA = parseFloat(a.amount);
            const amountB = parseFloat(b.amount);
            if (amountA < amountB) return -1;
            if (amountA > amountB) return 1;
            return 0;
        },
        // filters: [
        //     { text: '正数', value: 'positive' },
        //     { text: '负数', value: 'negative' }
        // ],
        // onFilter: (value: string, record: AdjustmentRecord) => {
        //     if (value === 'positive') return parseFloat(record.amount) >= 0;
        //     if (value === 'negative') return parseFloat(record.amount) < 0;
        //     return true;
        // }
    },
    {
        title: '调整后余额',
        dataIndex: 'balanceafter',
        key: 'balanceafter',
        width: 120,
        sorter: (a: AdjustmentRecord, b: AdjustmentRecord) => {
            const balanceA = parseFloat(a.balanceafter || '0');
            const balanceB = parseFloat(b.balanceafter || '0');
            if (balanceA < balanceB) return -1;
            if (balanceA > balanceB) return 1;
            return 0;
        }
    },
    {
        title: '说明',
        dataIndex: 'notes',
        key: 'notes',
        ellipsis: true,
        // filters: [],
        // filterSearch: true,
        // onFilter: (value: string, record: AdjustmentRecord) => 
        //     record.notes.toLowerCase().includes(value.toLowerCase())
    },
    {
        title: '操作用户',
        dataIndex: 'nickname',
        key: 'nickname',
        width: 120,
        // filters: [],
        // filterSearch: true,
        // onFilter: (value: string, record: AdjustmentRecord) => 
        //     record.nickname?.toLowerCase().includes(value.toLowerCase())
    }
];

// 获取余额类型标签
const getBalanceTypeLabel = (value: string) => {
    const option = BALANCE_TYPE_OPTIONS.find(opt => opt.value === value);
    return option ? option.label : value;
};

// 格式化日期时间
const formatDateTime = (dateStr: string) => {
    return dayjs.tz(dateStr, "Asia/Shanghai").format("YYYY-MM-DD HH:mm:ss");
};

// 提交表单
const handleSubmit = async () => {
    try {
        await formRef.value.validate();
        submitting.value = true;
        
        await insertAdjustment(adjustmentForm)
        .then(() => {
            message.success('调账创建成功');
            // 重置表单
            Object.assign(adjustmentForm, {
                account_id: '',
                amount: '',
                balance_type: '',
                notes: ''
            });
            formRef.value.resetFields();
            // 刷新列表
            loadAdjustmentRecords();
        })
        .catch(() => {
            message.error('调账创建失败');
        })
    } catch (error) {
        console.error('提交失败:', error);
        message.error('提交失败，请检查表单');
    } finally {
        submitting.value = false;
    }
};

// 加载调账记录
const loadAdjustmentRecords = async () => {
    try {
        loading.value = true;
        await listAdjustmentRecords()
        .then((response) => {
            adjustmentRecords.value = response.data;
        })
        .catch(err => {
            message.error(err.data.message || '获取调账记录失败');
        })
    } catch (error) {
        console.error('加载失败:', error);
        message.error('加载调账记录失败');
    } finally {
        loading.value = false;
    }
};

// 处理搜索
const handleSearch = async () => {
    // 本地搜索，不需要重新请求API
    // 这里可以添加后端搜索逻辑如果需要的话
};

// 处理重置
const handleReset = () => {
    searchForm.accountname = '';
    searchForm.balancetype = '';
    searchForm.nickname = '';
    searchForm.amountMin = null;
    searchForm.amountMax = null;
    searchForm.dateRange = null;
};

// 处理表格排序或分页变化
const handleTableChange = (pagination: any, filters: any, sorter: any) => {
    console.log('表格变化:', { pagination, filters, sorter });
    // 这里可以添加后端排序和分页逻辑如果需要的话
};

// 组件挂载时加载数据
onMounted(() => {
    loadAdjustmentRecords();
});
</script>

<style scoped>
.ant-form-item {
    margin-bottom: 16px;
}

.ant-card {
    border-radius: 8px;
}

.ant-table {
    border-radius: 8px;
}
</style> 