import { theme } from 'ant-design-vue';
// import { ThemeConfig } from 'ant-design-vue/es/config-provider/context';
import { defineStore } from 'pinia';
import { computed, ref, watch } from 'vue';

export const useThemeStore = defineStore('theme', () => {
    const algorithm = computed(() => {
        return isDark.value ? theme.darkAlgorithm : theme.defaultAlgorithm;
    });
    const isDark = ref(false);
    function switchDark() {
        isDark.value = !isDark.value;
    }

    // Component Token
    const layoutColorBgHeader = ref('#fff')
    watch(isDark, (newVal) => {
        layoutColorBgHeader.value = newVal ? '#000' : '#fff'
    })
    return {
        isDark,
        algorithm,
        switchDark,
        layoutColorBgHeader,
    }
})
// const algorithm = ref(theme.defaultAlgorithm);
// const antdConfig: ConfigProviderProps = {
//   locale: {
//     locale: 'zh-cn',
//     Pagination: {
//       items_per_page: '条/页',
//       jump_to: '跳至',
//       jump_to_confirm: '确定',
//       page: '页',
//       prev_page: '上一页',
//       next_page: '下一页',
//       prev_5: '向前 5 页',
//       next_5: '向后 5 页',
//       prev_3: '向前 3 页',
//       next_3: '向后 3 页',
//     },
//     // 其他本地化配置
//   },
//   theme: {
    
//     colorPrimary: '#1890ff',
//     linkColor: '#1890ff',
//     successColor: '#52c41a',
//     warningColor: '#faad14',
//     errorColor: '#f5222d',
//     fontSizeBase: '14px',
//     headingColor: 'rgba(0, 0, 0, 0.85)',
//     textColor: 'rgba(0, 0, 0, 0.65)',
//     textColorSecondary: 'rgba(0, 0, 0, 0.45)',
//     disabledColor: 'rgba(0, 0, 0, 0.25)',
//     borderRadiusBase: '4px',
//     borderColorBase: '#d9d9d9',
//     boxShadowBase: '0 2px 8px rgba(0, 0, 0, 0.15)',
//   },
// };

// export default antdConfig;
