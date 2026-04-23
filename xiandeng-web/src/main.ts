import { createApp, Plugin } from 'vue'
import './style.css'
// import './global-custom-theme.less'
// import 'element-plus/dist/index.css'
import App from './App.vue'
// import apolloClient from './api/client'
// import { DefaultApolloClient } from '@vue/apollo-composable'
import VueQrcode from '@chenfengyuan/vue-qrcode';

// import antd from 'ant-design-vue'
import {
  ConfigProvider,
  Card,
  Button,
  Avatar,
  Layout,
  LayoutContent,
  LayoutFooter,
  LayoutHeader,
  LayoutSider,
  Divider,
  Result,
  Modal,
  Steps,
  Step,
  Radio,
  RadioGroup,
  Tabs,
  TabPane,
  Tag,
  Menu,
  MenuDivider,
  MenuItem,
  Table,
  Form,
  FormItem,
  Input,
  InputNumber,
  InputPassword,
  Select,
  SelectOption,
  RangePicker,
  DatePicker,
  TimePicker,
  Checkbox,
  Drawer,
  Alert,
  Anchor,
  Image,
  Popconfirm,
  Tooltip,
  Row,
  Col,
  Statistic,
  Descriptions,
  DescriptionsItem,
  Collapse,
  CollapsePanel,
  Carousel,
  UploadDragger,
    List,
    Dropdown
} from 'ant-design-vue'

const antdPlugins = [
  ConfigProvider,
  Card,
  Button,
  Avatar,
  Layout,
  LayoutContent,
  LayoutFooter,
  LayoutHeader,
  LayoutSider,
  Divider,
  Result,
  Modal,
  Steps,
  Step,
  Radio,
  RadioGroup,
  Tabs,
  TabPane,
  Tag,
  Menu,
  MenuDivider,
  MenuItem,
  Table,
  Form,
  FormItem,
  Input,
  InputNumber,
  InputPassword,
  Select,
  SelectOption,
  RangePicker,
  DatePicker,
  TimePicker,
  Checkbox,
  Drawer,
  Alert,
  Anchor,
  Image,
  Popconfirm,
  Tooltip,
  Row,
  Col,
  Statistic,
  Descriptions,
  DescriptionsItem,
  Collapse,
  CollapsePanel,
  Carousel,
  UploadDragger,
    List,
    Dropdown
]
import router from './routes'
import { createPinia } from 'pinia'
import { forIn } from 'lodash-es';

const pinia = createPinia()
const app = createApp(App)
app.use(pinia)
forIn(antdPlugins, (plugin: Plugin) => app.use(plugin))
app.component(VueQrcode.name as string, VueQrcode)
// app.provide(DefaultApolloClient, apolloClient)
import {
  InteractionOutlined,
  RedoOutlined,
  UploadOutlined,
  EditOutlined,
  StarOutlined,
  HomeOutlined,
  AppstoreOutlined,
  LinkOutlined,
  UserOutlined,
  ContainerOutlined,
  AccountBookOutlined,
  CopyOutlined
} from '@ant-design/icons-vue'
app.use(router)
// app.use(antd)

// app.component(AntdIconsVue.FilterOutlined.name, AntdIconsVue.FilterOutlined)
const icons: any = {
  InteractionOutlined,
  RedoOutlined,
  UploadOutlined,
  EditOutlined,
  StarOutlined,
  HomeOutlined,
  AppstoreOutlined,
  LinkOutlined,
  UserOutlined,
  ContainerOutlined,
  AccountBookOutlined,
  CopyOutlined
}
for (const i in icons) {
    app.component(i, icons[i])
  }
app.mount('#app')
