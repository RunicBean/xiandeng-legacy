ALTER TABLE public.agentattribute ADD PaymentMethodWechatOffline boolean NOT NULL DEFAULT true;
ALTER TABLE public.agentattribute ADD PaymentMethodAlipayOffline boolean NOT NULL DEFAULT true;
ALTER TABLE public.agentattribute ADD PaymentMethodCardOffline boolean NOT NULL DEFAULT true;
ALTER TABLE public.agentattribute ADD PaymentMethodWechatPay boolean NOT NULL DEFAULT true;
