<template>
    <div class="date-picker">
        <input
            type="date"
            v-model="dateValue"
            @change="handleDateChange"
        />
<!--        <p>选择的日期: {{ formattedDate }}</p>-->
    </div>
</template>

<script lang="ts">
import { ref, computed } from 'vue'

export default {
    name: 'DatePicker',
    props: {
        modelValue: {
            type: String,
            default: ''
        }
    },
    emits: ['update:modelValue'],
    setup(props, { emit }) {
        // 初始化日期值
        const initialDate = props.modelValue
        const dateValue = ref(initialDate)

        // 格式化日期显示
        const formattedDate = computed(() => {
            if (!dateValue.value) return '未选择'
            return dateValue.value
        })

        // 处理日期变化
        const handleDateChange = () => {
            emit('update:modelValue', dateValue.value)
        }

        return {
            dateValue,
            formattedDate,
            handleDateChange
        }
    }
}
</script>

<style scoped>


input[type="date"] {
    padding: 2px;
    border: 1px solid #ccc;
    border-radius: 4px;
    font-size: 16px;
}
</style>
