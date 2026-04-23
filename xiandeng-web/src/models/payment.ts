import { ElementInfoType } from "./common"

export enum PaymentMethod {
    WECHAT_OFFLINE = 'wechat_offline',
    ALIPAY_OFFLINE = 'alipay_offline',
    CARD_OFFLINE = 'card_offline',
    WECHATPAY = 'wechatpay',
    GIFT = 'gift',
    LIULIU_PAY = 'liuliupay',
    INVENTORY_STUDENT = 'inventory_student',
    INVENTORY_AGENT = 'inventory_agent',
}

export enum OrderStatus {
    CREATED = 'created',
    SETTLED = 'settled',
    FAILED = 'failed',
    DECLINED = 'declined',
    PAID = 'paid',
    PENDING_CONFIRMATION = 'pending_confirmation'
}

export const OrderStatusMap = {
    [OrderStatus.CREATED]: {
        label: '待支付',
        color: ElementInfoType.DEFAULT
    },
    [OrderStatus.PAID]: {
        label: '已支付',
        color: ElementInfoType.PROCESSING
    },
    [OrderStatus.SETTLED]: {
        label: '已结算',
        color: ElementInfoType.SUCCESS
    },
    [OrderStatus.FAILED]: {
        label: '失败',
        color: ElementInfoType.ERROR
    },
    [OrderStatus.PENDING_CONFIRMATION]: {
        label: '待确认',
        color: ElementInfoType.WARNING
    },
    [OrderStatus.DECLINED]: {
        label: '拒绝',
        color: ElementInfoType.ERROR,
    }
}

export const OrderFilterStatusMap = {
    [OrderStatus.CREATED]: {
        label: '待支付',
        color: ElementInfoType.DEFAULT
    },
    [OrderStatus.PAID]: {
        label: '已支付',
        color: ElementInfoType.PROCESSING
    },
    [OrderStatus.SETTLED]: {
        label: '已结算',
        color: ElementInfoType.SUCCESS
    },
    [OrderStatus.PENDING_CONFIRMATION]: {
        label: '待确认',
        color: ElementInfoType.WARNING
    },
    [OrderStatus.DECLINED]: {
        label: '拒绝',
        color: ElementInfoType.ERROR,
    }
}

export const paymentMethodList = [
    {
        name: PaymentMethod.WECHAT_OFFLINE,
        label: '微信商家码',
        enableDbFlag: 'paymentmethodwechatoffline'
    },
    {
        name: PaymentMethod.ALIPAY_OFFLINE,
        label: '支付宝商家码',
        enableDbFlag: 'paymentmethodalipayoffline'
    },
    {
        name: PaymentMethod.LIULIU_PAY,
        label: '聚合二维码',
        enableDbFlag: 'paymentmethodliuliupay'
    },
    {
        name: PaymentMethod.CARD_OFFLINE,
        label: '银行转账',
        enableDbFlag: 'paymentmethodcardoffline'
    },
    {
        name: PaymentMethod.WECHATPAY,
        label: '微信直连',
        enableDbFlag: 'paymentmethodwechatpay'
    },
]

export const agentPaymentMethodList = [
    // {
    //     name: PaymentMethod.LIULIU_PAY,
    //     label: '扫码支付',
    //     enableDbFlag: 'paymentmethodliuliupay'
    // },
    {
        name: PaymentMethod.CARD_OFFLINE,
        label: '银行卡转账',
        enableDbFlag: 'paymentmethodcardoffline'
    }
]