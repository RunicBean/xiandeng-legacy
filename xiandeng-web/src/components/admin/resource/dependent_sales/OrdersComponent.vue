<script setup lang="ts">
import {useRequest} from "vue-request";
import {batchSetOrderTags, deleteOrderTags} from "@/api/request/order.ts";
import dayjs from 'dayjs'
import { ref, computed, watch } from 'vue';
import {Order} from "@/models/order";
import { message } from 'ant-design-vue';

const props = defineProps<{
    // 父组件传递过来的值
    // ...
    title: string;
    listOrderFunction: () => Promise<{orders: Order[], meta: {tags: string[]}}>
}>()

const {data, refresh} = useRequest<{orders: Order[], meta: {tags?: string[]}}>(props.listOrderFunction)

// new type extend Order
type OrderWithTags = Order & {
    key: string;
};
const tagOptions = ref<{ text: string; value: string }[]>([]);
const tableData = ref<OrderWithTags[]>([]);
// 添加处理后的数据计算属性
watch(data, () => {
    if (!data.value) return [];
    console.log(data.value.meta.tags)
    if (data.value.meta.tags) {
        tagOptions.value = data.value.meta.tags.map((tag: string) => ({
            text: tag,
            value: tag
        }));
    } else {
        tagOptions.value = [];
    }
    tableData.value = data.value.orders.map((item: Order) => ({
        ...item,
        key: item.id
    }));
});

// const tagOptions = computed(() => {
//     if (!data.value) return [];
//     return
// });

const dateRange = ref<[dayjs.Dayjs | null, dayjs.Dayjs | null]>([null, null]);
const selectedRowKeys = ref<(string | number)[]>([]);

const onSelectChange = (newSelectedRowKeys: (string | number)[]) => {
    console.log(newSelectedRowKeys)
  selectedRowKeys.value = newSelectedRowKeys;
};

const rowSelection = {
  selectedRowKeys,
  onChange: onSelectChange,
};

const columns = computed(() => [
    {
        title: '创建时间',
        dataIndex: 'createdat',
        key: 'createdat',
        render: (text: string|null) => {
            return text ? dayjs(text).format('YYYY-MM-DD HH:mm:ss') : '-'
        },
        customFilterDropdown: true,
        onFilter: (value: string, record: any) => {
            if (!record.createdat || !value) return false;
            const [start, end] = value.split('|');
            const recordDate = dayjs(record.createdat);
            return recordDate.isAfter(dayjs(start)) && recordDate.isBefore(dayjs(end));
        }
    },
    {
        title: '订单号',
        dataIndex: 'id',
        key: 'id',
        customFilterDropdown: true,
        onFilter: (value: string, record: any) => record.id.toString().includes(value)
    },
    {
        title: '销售代表',
        dataIndex: 'nickname',
        key: 'nickname',
        customFilterDropdown: true,
        onFilter: (value: string, record: any) => record.nickname.includes(value)
    },
    {
        title: '状态',
        dataIndex: 'status',
        key: 'status',
        filters: [
            { text: '已结算', value: '已结算' },
            { text: '已拒绝', value: '已拒绝' },
            { text: '失败', value: '失败' },
            { text: '已创建', value: '已创建' },
            { text: '待确认', value: '待确认' },
            { text: '已付款', value: '已付款' },
            { text: '已退款', value: '已退款' },
            { text: '已撤销分佣', value: '已撤销分佣' },
        ],
        onFilter: (value: string, record: any) => record.status === value
    },
    {
        title: '支付方式',
        dataIndex: 'paymentmethod',
        key: 'paymentmethod',
        filters: [
            { text: '聚合二维码', value: '聚合二维码' },
            { text: '支付宝商家码', value: '支付宝商家码' },
            { text: '微信直连', value: '微信直连' },
            { text: '微信商家码', value: '微信商家码' },
            { text: '银行转账', value: '银行转账' },
            { text: '库存-代理直扣', value: '库存-代理直扣' },
            { text: '库存-学员下单', value: '库存-学员下单' },
            { text: '线下联系总部', value: '线下联系总部' },
            { text: '免费', value: '免费' },
        ],
        onFilter: (value: string, record: any) => record.paymentmethod === value

    },
    {
        title: '金额',
        dataIndex: 'price',
        key: 'price',
    },
    {
        title: '学员',
        dataIndex: 'accountname',
        key: 'accountname',
        customFilterDropdown: true,
        onFilter: (value: string, record: any) => record.accountname.includes(value)
    },
    {
        title: '支付时间',
        dataIndex: 'payat',
        key: 'payat',
        render: (text: string|null) => {
            return text ? dayjs(text).format('YYYY-MM-DD HH:mm:ss') : '-'
        }
    },
    {
        title: '产品名称',
        dataIndex: 'productname',
        key: 'productname',
    },
    {
        title: '标签',
        dataIndex: 'tags',
        key: 'tags',
        // customFilterDropdown: true,
        filters: tagOptions.value,
        onFilter: (value: string, record: any) => {
            // console.log(record.tags.includes(value))
            return record.tags && record.tags.includes(value)
        }
    }
])

const isTagModalVisible = ref(false);
const tagsInput = ref<string[]>([]);

const handleBatchSetTags = () => {
    isTagModalVisible.value = true;
};

const handleTagModalConfirm = async () => {
    try {
        const tags = tagsInput.value.map(tag => tag.trim()).filter(tag => tag);
        if (tags.length === 0) {
            message.warning('请输入至少一个标签');
            return;
        }

        await batchSetOrderTags(selectedRowKeys.value, tags);
        message.success('标签设置成功');
        isTagModalVisible.value = false;
        tagsInput.value = [];
        refresh();
    } catch (error) {
        message.error('设置标签失败');
    }
};

const handleTagModalCancel = () => {
    isTagModalVisible.value = false;
    tagsInput.value = [];
};

const handleBatchDeleteTags = async () => {
    await deleteOrderTags(selectedRowKeys.value);
    message.success('标签删除成功');
    refresh();
}
</script>

<template>
    <div>
        <div style="display: flex; justify-content: space-between; align-items: center;">
            <h1>{{title}}</h1>
            <div class="space-x-2">
                <a-button type="primary" @click="handleBatchSetTags" v-if="selectedRowKeys.length > 0">批量设置标签</a-button>
                <a-button type="primary" danger @click="handleBatchDeleteTags" v-if="selectedRowKeys.length > 0">批量删除标签</a-button>
            </div>
        </div>
        <a-table
            :columns="columns"
            :data-source="tableData"
            :row-selection="rowSelection"
            :pagination="{
                defaultPageSize: 5,
                showSizeChanger: true,
                showQuickJumper: true,
                pageSizeOptions: ['5', '10', '20', '50'],
                showTotal: (total: number) => `共 ${total} 条`
            }"
            :scroll="{ x: 1600 }"
        >
            <template #customFilterDropdown="{ setSelectedKeys, confirm, clearFilters, column }">
                <div v-if="column.dataIndex === 'createdat'" style="padding: 8px">
                    <a-range-picker
                        v-model:value="dateRange"
                        show-time
                        format="YYYY-MM-DD HH:mm:ss"
                        @ok="(dates: [dayjs.Dayjs | null, dayjs.Dayjs | null]) => {
                            if (dates) {
                                setSelectedKeys([dates[0]?.format('YYYY-MM-DD HH:mm:ss') + '|' + dates[1]?.format('YYYY-MM-DD HH:mm:ss')]);
                            }
                        }"
                        style="width: 300px"
                    />
                    <div style="margin-top: 8px">
                        <a-button
                            type="primary"
                            size="small"
                            style="margin-right: 8px"
                            @click="confirm"
                        >
                            确定
                        </a-button>
                    </div>
                </div>
                <div v-else style="padding: 8px">
                    <a-input
                        allowClear
                        @change="(e: any) => {
                            setSelectedKeys([e.target.value]);
                        }"
                    />
                    <div style="margin-top: 8px">
                        <a-button
                            type="primary"
                            size="small"
                            style="margin-right: 8px"
                            @click="confirm"
                        >
                            确定
                        </a-button>
                        <a-button
                            size="small"
                            @click="clearFilters({confirm: true})"
                        >
                            重置
                        </a-button>
                    </div>
                </div>
            </template>
            <template #bodyCell="{column, record}">
                <template v-if="column.render">
                    {{ column.render(record[column.dataIndex]) }}
                </template>
                <template v-else-if="column.key === 'tags'">
                    <span>
                    <a-tag
                        v-for="tag in record.tags"
                        :key="tag"
                        color="geekblue"
                    >
                        {{ tag }}
                    </a-tag>
                    </span>
                </template>
            </template>
        </a-table>
        <a-modal
            v-model:visible="isTagModalVisible"
            title="批量设置标签"
            @ok="handleTagModalConfirm"
            @cancel="handleTagModalCancel"
        >
            <p>请输入标签，可以输入多个标签</p>
            <a-select
                v-model:value="tagsInput"
                style="width: 100%"
                mode="tags"
                allowClear
            />
        </a-modal>
    </div>
</template>

<style scoped>

</style>
