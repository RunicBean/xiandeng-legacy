package wechatpay

var (
	OrderStatusCreated string = "created" // 初始化创建，创建prepay
	OrderStatusPending string = "pending" // 正在试图调起支付
	OrderStatusSuccess string = "success" // 成功
	OrderStatusFailed  string = "failed"  // 其他情况均为失败，无重试
	OrderStatusRefund  string = "refund"
)

var (
	PaymentMethodWechatPay string = "wechatpay"
)

type NotifyPayloadResource struct {
	OriginalType   string `json:"original_type"`
	Algorithm      string `json:"algorithm"`
	Ciphertext     string `json:"ciphertext"`
	AssociatedData string `json:"associated_data"`
	Nonce          string `json:"nonce"`
}

type NotifyPayload struct {
	Id           string                `json:"id"`
	CreateTime   string                `json:"create_time"`
	ResourceType string                `json:"resource_type"`
	EventType    string                `json:"event_type"`
	Summary      string                `json:"summary"`
	Resource     NotifyPayloadResource `json:"resource"`
}

var (
	TradeStateSuccess string = "SUCCESS"
	TradeStateRefund  string = "REFUND"
	TradeStateNotpay  string = "NOTPAY"
	TradeStateClosed  string = "CLOSED"
)
