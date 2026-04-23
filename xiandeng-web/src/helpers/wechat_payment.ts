export class WxRes {
    err_msg: string;
    constructor(err_msg: string) {
        this.err_msg = err_msg;
    }
}

export interface WxBridgeData {
    appId: string;
    timeStamp: string;
    nonceStr: string;
    prepayId: string;
    paySign: string;
}

export function onBridgeReady(data: WxBridgeData, cb: (res: WxRes) => void) {
    WeixinJSBridge.invoke('getBrandWCPayRequest', {
        "appId": `${data.appId}`,     //公众号ID，由商户传入     
        "timeStamp": `${data.timeStamp}`,     //时间戳，自1970年以来的秒数     
        "nonceStr": `${data.nonceStr}`,      //随机串     
        "package": `prepay_id=${data.prepayId}`,
        "signType": "RSA",     //微信签名方式：     
        "paySign": `${data.paySign}` //微信签名 
    }, cb);
}

export function verifyPayment() {
    
}