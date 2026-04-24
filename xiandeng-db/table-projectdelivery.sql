-- DROP TABLE public.projectdelivery;

CREATE TABLE projectdelivery (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    orderproductid BIGINT,
    deliveryaccount UUID,
    price NUMERIC(8,2),
    status VARCHAR(255) DEFAULT 'PENDING',
    source VARCHAR(255),
    assignmode VARCHAR(255), 
    starttime TIMESTAMP,
    endtime TIMESTAMP,
    createdat TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text),
    updatedat TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text),
    
    -- Foreign Key constraints
    CONSTRAINT fk_orderproductid FOREIGN KEY (orderproductid) REFERENCES orderproduct(id),
    CONSTRAINT fk_deliveryaccount FOREIGN KEY (deliveryaccount) REFERENCES account(id)
);

-- Add comments to columns
COMMENT ON COLUMN projectdelivery.price IS 'The price of the delivery service';

COMMENT ON COLUMN projectdelivery.status IS 'The current status of the project delivery.
PENDING：初始状态，服务商没有确认提供服务，不分账。
CONFIRMED: 服务商确认提供服务，执行分账。';

COMMENT ON COLUMN projectdelivery.assignmode IS 'The mode of assignment; 
AUTO：直接指定服务提供账号,push mode
MANUAL: 由服务商手动拉取，status直接变为CONFIRMED';

COMMENT ON COLUMN projectdelivery.source IS 'PRODUCT:由下单的商品创建的记录
HEADQUARTER：由总部创建的记录';
