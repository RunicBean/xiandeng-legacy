package payment

type ProductParams struct {
	Id         string `json:"id" form:"id"`
	CouponCode string `json:"coupon_code" form:"coupon_code"`
}

type OrderCreateParams struct {
	StudentId     string // Student's Account Id
	Products      []ProductParams
	GeneralCoupon string
}

type PaymentCreateParams struct {
	OrderNumber int64
	Description string
	Note        string
	Payer       Payer
	NotifyUrl   string
}

type Payer struct {
	Type string
	Id   string
}
