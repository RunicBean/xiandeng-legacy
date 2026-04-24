UPDATE datadictionary SET value='1800', "namespace"='award.factor' WHERE "key"='LV2_AGENT-LV2_AGENT-direct-award';
UPDATE datadictionary SET value='1800', "namespace"='award.factor' WHERE "key"='LV2_AGENT-LV1_AGENT-direct-award';
UPDATE datadictionary SET value='1800', "namespace"='award.factor' WHERE "key"='LV2_AGENT-HQ_AGENT-direct-award';
UPDATE datadictionary SET value='2400', "namespace"='award.factor' WHERE "key"='LV1_AGENT-LV2_AGENT-direct-award';
UPDATE datadictionary SET value='3000', "namespace"='award.factor' WHERE "key"='HQ_AGENT-LV2_AGENT-direct-award';
UPDATE datadictionary SET value='1440', "namespace"='award.factor' WHERE "key"='LV2_AGENT-award-x';
UPDATE datadictionary SET value='0.1', "namespace"='award.factor' WHERE "key"='award-mod-1';
UPDATE datadictionary SET value='0.4', "namespace"='award.factor' WHERE "key"='award-mod-2';
UPDATE datadictionary SET value='1', "namespace"='award.factor' WHERE "key"='award-mod-3';
UPDATE datadictionary SET value='0.09', "namespace"='award.factor' WHERE "key"='award-y-ratio';
UPDATE datadictionary SET value='1440', "namespace"='award.factor' WHERE "key"='LV2_AGENT-award-y';
UPDATE datadictionary SET value='6000', "namespace"='award.factor' WHERE "key"='LV2_AGENT-franchise-fee';
UPDATE datadictionary SET value='5400', "namespace"='award.factor' WHERE "key"='LV1_AGENT-LV1_AGENT-direct-award';
UPDATE datadictionary SET value='5400', "namespace"='award.factor' WHERE "key"='LV1_AGENT-HQ_AGENT-direct-award';
UPDATE datadictionary SET value='9000', "namespace"='award.factor' WHERE "key"='HQ_AGENT-LV1_AGENT-direct-award';
UPDATE datadictionary SET value='18000', "namespace"='award.factor' WHERE "key"='HQ_AGENT-HQ_AGENT-direct-award';
UPDATE datadictionary SET value='4320', "namespace"='award.factor' WHERE "key"='LV1_AGENT-award-x';
UPDATE datadictionary SET value='12960', "namespace"='award.factor' WHERE "key"='HQ_AGENT-award-x';
UPDATE datadictionary SET value='4320', "namespace"='award.factor' WHERE "key"='LV1_AGENT-award-y';
UPDATE datadictionary SET value='12960', "namespace"='award.factor' WHERE "key"='HQ_AGENT-award-y';
UPDATE datadictionary SET value='18000', "namespace"='award.factor' WHERE "key"='LV1_AGENT-franchise-fee';
UPDATE datadictionary SET value='54000', "namespace"='award.factor' WHERE "key"='HQ_AGENT-franchise-fee';
UPDATE datadictionary SET value='0.1', "namespace"='award.factor' WHERE "key"='award-z-ratio';
UPDATE datadictionary SET value='7', "namespace"='award.factor' WHERE "key"='award-extension-level';
UPDATE datadictionary SET value='600', "namespace"='award.factor' WHERE "key"='LV1_AGENT-x-unlock';
UPDATE datadictionary SET value='200', "namespace"='award.factor' WHERE "key"='LV2_AGENT-x-unlock';
UPDATE datadictionary SET value='1800', "namespace"='award.factor' WHERE "key"='HQ_AGENT-x-unlock';


-- Step 1: Drop the existing index
DROP INDEX IF EXISTS idx_namespace;

-- Step 2: Drop the existing primary key constraint
ALTER TABLE public.datadictionary
DROP CONSTRAINT datadictionary_pkey;

-- Step 3: Create a new primary key constraint with namespace and key
ALTER TABLE public.datadictionary
ADD CONSTRAINT datadictionary_pkey PRIMARY KEY (namespace, "key");


INSERT INTO datadictionary ("key", value, "namespace") VALUES('liuliupay', '聚合二维码', 'paymentmethod');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('alipay_offline', '支付宝商家码', 'paymentmethod');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('wechatpay', '微信直连', 'paymentmethod');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('wechat_offline', '微信商家码', 'paymentmethod');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('card_offline', '银行转账', 'paymentmethod');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('inventory_agent', '库存-代理直扣', 'paymentmethod');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('inventory_student', '库存-学员下单', 'paymentmethod');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('contact_hq', '线下联系总部', 'paymentmethod');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('gift', '免费', 'paymentmethod');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('balance', '余额', 'accountbalancetype');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('balanceleft', '左区余额', 'accountbalancetype');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('balanceright', '右区余额', 'accountbalancetype');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('balancetriplelock', '未解锁三单余额', 'accountbalancetype');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('balancetriple', '已解锁三单余额', 'accountbalancetype');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('pendingreturn', '剩余意向金', 'accountbalancetype');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('L', '左区', 'accountpartition');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('R', '右区', 'accountpartition');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('INIT', '未激活', 'accountstatus');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('ACTIVE', '已激活', 'accountstatus');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('CLOSED', '已关闭', 'accountstatus');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('pending', '待确认', 'inventoryorderstatus');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('declined', '已拒绝', 'inventoryorderstatus');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('paid', '已付款', 'inventoryorderstatus');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('settled', '已结算', 'inventoryorderstatus');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('hq_initiated', '总部发起', 'inventoryordertype');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('from_balance', '从余额扣除', 'inventoryordertype');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('agent_topup', '充值', 'inventoryordertype');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('balance', '余额提现', 'withdrawtype');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('partition', '分区奖提现', 'withdrawtype');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('triple', '三单奖提现', 'withdrawtype');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('declined', '已拒绝', 'orderstatus');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('failed', '失败', 'orderstatus');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('settled', '已结算', 'orderstatus');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('created', '已创建', 'orderstatus');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('pending_confirmation', '待确认', 'orderstatus');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('paid', '已付款', 'orderstatus');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('refunded', '已退款', 'orderstatus');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('uncommisioned', '已撤销分佣', 'orderstatus');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('REQUESTED', '已申请', 'withdrawtype');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('LOCKED', '已锁定', 'withdrawtype');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('RECALLED', '已撤销', 'withdrawtype');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('PAID', '已发放', 'withdrawtype');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('DECLINED', '已拒绝', 'withdrawtype');

