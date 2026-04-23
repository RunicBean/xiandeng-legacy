package payment

type PaymentMethod int

const (
	WechatPay PaymentMethod = iota
	AliPay
)

type Intent struct {
	PrePayID string        `json:"prepay_id" form:"prepay_id"`
	Method   PaymentMethod `json:"method" form:"method"`
	OrderId  int64         `json:"order_id" form:"order_id"`
}
