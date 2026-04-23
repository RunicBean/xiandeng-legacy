<script setup lang="ts">
import {useRequest} from "vue-request";
import {confirmInventoryOrder, listInventoriesForHQ, updateInventoryOrderStatus} from "@/api/request/inventory.ts";
import {
    CaretDownOutlined,
    CloseOutlined,
    CloudUploadOutlined,
    FormatPainterOutlined,
    MonitorOutlined, ScheduleOutlined
} from "@ant-design/icons-vue";
import {Dropdown, notification} from "ant-design-vue";

const {data, run: runListInventoriesForHQ} = useRequest(listInventoriesForHQ)

const columns = [
    {
        dataIndex: "createdat",
        key: "createdat",
        title: "创建时间",
    },
    {
        dataIndex: "id",
        key: "id",
        title: "库存订单号"
    },
    {
        dataIndex: "accountname",
        key: "accountname",
        title: "代理名"
    },
    {
        dataIndex: "productname",
        key: "productname",
        title: "商品"
    },
    {
        dataIndex: "unitprice",
        key: "unitprice",
        title: "单价"
    },
    {
        dataIndex: "quantity",
        key: "quantity",
        title: "数量"
    },
    {
        dataIndex: "totalprice",
        key: "totalprice",
        title: "总价"
    },
    {
        dataIndex: "proof",
        key: "proof",
        title: "凭证"
    },
    {
        dataIndex: "action",
        key: "action",
        title: "操作"
    }
]

async function approveOrder(id: string) {
    await confirmInventoryOrder(id)
        .then((_) => {
            // console.log(res.data)
            notification.success({
                message: '授权成功'
            })
            runListInventoriesForHQ()
        })
        .catch((err) => {
            notification.error({
                message: '授权失败',
                description: err.response.data.data
            })
        })
}

async function declineOrder(id: string) {
    await updateInventoryOrderStatus(id, "declined")
        .then((_) => {
            notification.success({
                message: '拒绝成功'
            })
            runListInventoriesForHQ()
        })
        .catch((err) => {
            notification.error({
                message: '拒绝失败',
                description: err.response.data.data
            })
        })
}
</script>

<template>
    <div>
        <h1>库存审批</h1>
        <a-card>

        </a-card>
        <a-table :data-source="data??[]" :columns="columns">
            <template #bodyCell="{column, record}">
                <template v-if="column.dataIndex === 'action'">
                    <div class="flex items-center space-x-2">
                        <a-button @click="approveOrder(record.id)">
                            <div class="flex items-center space-x-1 text-blue-700" >
                                <ScheduleOutlined />
                                <span>授权</span>
                            </div>
                        </a-button>

                        <Dropdown type="default">

                            <a-button>
                                <div class="flex items-center space-x-1 text-gray-500">
                                    <CaretDownOutlined />
                                    <span>更多</span>
                                </div>
                            </a-button>
                            <template #overlay>
                                <a-menu>
                                    <a-menu-item key="1" @click="declineOrder(record.id)">
                                        <div class="flex items-center w-full space-x-2 text-red-500">
                                            <CloseOutlined />
                                            <span>拒绝</span>
                                        </div>
                                    </a-menu-item>
                                    <a-menu-item key="2">
                                        <div class="flex items-center w-full space-x-2">
                                            <CloudUploadOutlined />
                                            <span>上传凭证</span>
                                        </div>
                                    </a-menu-item>
                                    <a-menu-item key="3">
                                        <div class="flex items-center w-full space-x-2">
                                            <MonitorOutlined />
                                            <span>查看凭证</span>
                                        </div>
                                    </a-menu-item>
                                    <a-menu-item
                                        key="4"
                                        >
                                        <div class="flex items-center w-full space-x-2">
                                            <FormatPainterOutlined />
                                            <span>更新实付金额</span>
                                        </div>
                                    </a-menu-item>
                                </a-menu>
                            </template>

                        </Dropdown>
                    </div>
                </template>
            </template>
        </a-table>
    </div>
</template>

<style scoped>

</style>