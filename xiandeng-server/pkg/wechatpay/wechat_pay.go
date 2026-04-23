package wechatpay

import (
	"context"
	"encoding/json"
	"fmt"
	"github.com/wechatpay-apiv3/wechatpay-go/core"
	"github.com/wechatpay-apiv3/wechatpay-go/core/option"
	"github.com/wechatpay-apiv3/wechatpay-go/services/payments"
	"github.com/wechatpay-apiv3/wechatpay-go/services/payments/jsapi"
	wechat_pay_utils "github.com/wechatpay-apiv3/wechatpay-go/utils"
	"log"

	"xiandeng.net.cn/server/pkg/config"
	"xiandeng.net.cn/server/pkg/env"
	"xiandeng.net.cn/server/pkg/payment"
	timeutil "xiandeng.net.cn/server/pkg/utils/time_util"
)

type WechatPayEngine struct {
	client    *core.Client
	mchId     string
	mchApiKey string
	appId     string
}

//var _ payment.PaymentEngine = (*WechatPayEngine)(nil)

func (e *WechatPayEngine) CreatePayment(
	ctx context.Context,
	orderId int64,
	payingAmtInt64 int64,
	wechatOpenId string,
	params payment.PaymentCreateParams) (*payment.Intent, error) {

	// 微信Prepay
	var prepayId = ""
	if env.Active().IsPro() {
		svc := jsapi.JsapiApiService{Client: e.client}
		// 得到prepay_id，以及调起支付所需的参数和签名
		resp, _, err := svc.PrepayWithRequestPayment(ctx,
			jsapi.PrepayRequest{
				Appid:       core.String(e.appId),
				Mchid:       core.String(e.mchId),
				Description: core.String(params.Description),
				OutTradeNo:  core.String(fmt.Sprintf("%d", orderId)),
				Attach:      core.String("自定义数据说明"),
				NotifyUrl:   core.String(params.NotifyUrl),
				Amount: &jsapi.Amount{
					Total: &payingAmtInt64,
				},
				Payer: &jsapi.Payer{
					Openid: &wechatOpenId,
				},
			},
		)

		if err != nil {
			fmt.Println(params.Description)
			fmt.Println(params)
			fmt.Println(err.Error())
			return nil, fmt.Errorf("CreatePayment: create prepay error: %v", err)
		}

		prepayId = *resp.PrepayId
	} else {
		prepayId = "test-prepay-id"
	}

	return &payment.Intent{
		PrePayID: prepayId,
		OrderId:  orderId,
		Method:   payment.WechatPay,
	}, nil
}

func (e *WechatPayEngine) GetPaymentByOrderId(ctx context.Context, orderId int64) (*payments.Transaction, error) {
	if e.client == nil {
		return nil, fmt.Errorf("wechat pay client not initialized")
	}
	svc := jsapi.JsapiApiService{Client: e.client}
	paymentTxn, _, err := svc.QueryOrderByOutTradeNo(ctx, jsapi.QueryOrderByOutTradeNoRequest{
		OutTradeNo: core.String(fmt.Sprintf("%d", orderId)),
		Mchid:      &e.mchId,
	})
	if err != nil {
		newErr := fmt.Errorf("get payment by order id %d error: %x", orderId, err)
		fmt.Println(newErr.Error())
		return nil, newErr
	}
	return paymentTxn, nil
}

type SignResult struct {
	AppID     string `json:"app_id"`
	Nonce     string `json:"nonce"`
	Timestamp string `json:"timestamp"`
	Signature string `json:"signature"`
}

func (e *WechatPayEngine) Sign(prepayId string) (*SignResult, error) {
	timeStamp := fmt.Sprintf("%d", timeutil.NowInShanghai().Unix())
	nonce, _ := wechat_pay_utils.GenerateNonce()
	source := fmt.Sprintf("%s\n%s\n%s\nprepay_id=%s\n", e.appId, timeStamp, nonce, prepayId)
	mchPrivateKey, err := wechat_pay_utils.LoadPrivateKeyWithPath(config.WechatPayKeyPath)
	if err != nil {
		if env.Active().IsPro() {
			return nil, fmt.Errorf("load merchant private key error: %v", err)
		}
		return &SignResult{
			AppID:     e.appId,
			Nonce:     nonce,
			Timestamp: timeStamp,
			Signature: "test-signature",
		}, nil
	}
	s, err := wechat_pay_utils.SignSHA256WithRSA(source, mchPrivateKey)
	if err != nil {
		if env.Active().IsPro() {
			return nil, fmt.Errorf("sign error: %v", err)
		}
		s = "test-signature"
	}
	// sig, _ := e.client.Sign(ctx, source)
	// fmt.Print(sig)
	return &SignResult{
		AppID:     e.appId,
		Nonce:     nonce,
		Timestamp: timeStamp,
		Signature: s,
	}, nil
}

func (e *WechatPayEngine) VerifyAndDecrypt(notifyPayload NotifyPayload) (*payments.Transaction, error) {
	plainText, err := wechat_pay_utils.DecryptAES256GCM(
		e.mchApiKey,
		notifyPayload.Resource.AssociatedData,
		notifyPayload.Resource.Nonce,
		notifyPayload.Resource.Ciphertext,
	)
	if err != nil {
		return nil, fmt.Errorf("decrypt webhook data failed: %x", err)
	}
	var transactionData payments.Transaction
	err = json.Unmarshal([]byte(plainText), &transactionData)
	if err != nil {
		return nil, fmt.Errorf("decryptedData unmarshal error: %x", err)
	}
	return &transactionData, nil
}

func (e *WechatPayEngine) ClosePayment(ctx context.Context, orderId int64) error {
	if e.client == nil {
		return fmt.Errorf("wechat pay client not initialized")
	}

	svc := jsapi.JsapiApiService{Client: e.client}
	_, err := svc.CloseOrder(ctx, jsapi.CloseOrderRequest{
		OutTradeNo: core.String(fmt.Sprintf("%d", orderId)),
		Mchid:      &e.mchId,
	})
	if err != nil {
		return fmt.Errorf("close order api error: %x", err)
	}
	return nil
}

func NewWechatPayEngine(conf *config.Config) *WechatPayEngine {
	if !env.Active().IsPro() {
		return &WechatPayEngine{
			client:    nil,
			mchId:     conf.Payment.MchId,
			appId:     conf.Auth.WxAppID,
			mchApiKey: conf.Payment.MchAPIv3Key,
		}
	}

	// 使用 utils 提供的函数从本地文件中加载商户私钥，商户私钥会用来生成请求的签名
	mchPrivateKey, err := wechat_pay_utils.LoadPrivateKeyWithPath(config.WechatPayKeyPath)
	if err != nil {
		log.Fatal("load merchant private key error")
	}

	ctx := context.Background()
	// 使用商户私钥等初始化 client，并使它具有自动定时获取微信支付平台证书的能力
	opts := []core.ClientOption{
		option.WithWechatPayAutoAuthCipher(
			conf.Payment.MchId,
			conf.Payment.MchCertificateSerialNumber,
			mchPrivateKey,
			conf.Payment.MchAPIv3Key),
	}
	client, err := core.NewClient(ctx, opts...)
	if err != nil {
		log.Fatalf("new wechat pay client err:%s", err)
	}
	return &WechatPayEngine{
		client:    client,
		mchId:     conf.Payment.MchId,
		appId:     conf.Auth.WxAppID,
		mchApiKey: conf.Payment.MchAPIv3Key,
	}
}

//var (
//	once sync.Once
//	wpe  payment.PaymentEngine
//)
//
//func GetWechatPayEngine() payment.PaymentEngine {
//	once.Do(func() {
//		wpe = NewWechatPayEngine(config.GetConfig())
//	})
//	return wpe
//}
