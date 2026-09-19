select 1;
SELECT version();
SELECT current_database();	
    CREATE SCHEMA IF NOT EXISTS core;

    SELECT schema_name
    FROM information_schema.schemata
    WHERE schema_name = 'core';
    
    SET search_path TO core, public;
    
    CREATE TABLE IF NOT EXISTS core.categories (
    category_id         VARCHAR(10) PRIMARY KEY,
    category_name       VARCHAR(120) NOT NULL,
    parent_category_id  VARCHAR(10),
    created_at          TIMESTAMPTZ NOT NULL,
    updated_at          TIMESTAMPTZ NOT NULL,

    CONSTRAINT fk_categories_parent
        FOREIGN KEY (parent_category_id)
        REFERENCES core.categories(category_id),

    CONSTRAINT chk_categories_updated_at
        CHECK (updated_at >= created_at)
);

CREATE TABLE IF NOT EXISTS core.customers (
    customer_id         VARCHAR(12) PRIMARY KEY,
    full_name           VARCHAR(150) NOT NULL,
    email               VARCHAR(200) NOT NULL,
    phone               VARCHAR(30),
    city                VARCHAR(100),
    customer_segment    VARCHAR(30) NOT NULL,
    status              VARCHAR(20) NOT NULL,
    source_system       VARCHAR(50) NOT NULL DEFAULT 'unknown',
    ingested_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at          TIMESTAMPTZ NOT NULL,
    updated_at          TIMESTAMPTZ NOT NULL,

    CONSTRAINT uq_customers_email
        UNIQUE (email),

    CONSTRAINT chk_customers_status
        CHECK (status IN ('active', 'inactive')),

    CONSTRAINT chk_customers_updated_at
        CHECK (updated_at >= created_at)
);




CREATE TABLE IF NOT EXISTS core.products (
    product_id          VARCHAR(12) PRIMARY KEY,
    category_id         VARCHAR(10) NOT NULL,
    product_name        VARCHAR(200) NOT NULL,
    unit_price          NUMERIC(14,2) NOT NULL,
    cost_price          NUMERIC(14,2) NOT NULL,
    status              VARCHAR(20) NOT NULL,
    source_system       VARCHAR(50) NOT NULL DEFAULT 'unknown',
    ingested_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at          TIMESTAMPTZ NOT NULL,
    updated_at          TIMESTAMPTZ NOT NULL,

    CONSTRAINT fk_products_category
        FOREIGN KEY (category_id)
        REFERENCES core.categories(category_id),

    CONSTRAINT chk_products_unit_price
        CHECK (unit_price >= 0),

    CONSTRAINT chk_products_cost_price
        CHECK (cost_price >= 0),

    CONSTRAINT chk_products_status
        CHECK (status IN ('active', 'inactive', 'discontinued')),

    CONSTRAINT chk_products_updated_at
        CHECK (updated_at >= created_at)
);



CREATE TABLE IF NOT EXISTS core.orders (
    order_id            VARCHAR(12) PRIMARY KEY,
    customer_id         VARCHAR(12) NOT NULL,
    order_date          TIMESTAMPTZ NOT NULL,
    status              VARCHAR(20) NOT NULL,
    shipping_city       VARCHAR(100),
    channel             VARCHAR(20) NOT NULL,
    order_total         NUMERIC(14,2) NOT NULL,
    source_system       VARCHAR(50) NOT NULL DEFAULT 'unknown',
    ingested_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at          TIMESTAMPTZ NOT NULL,
    updated_at          TIMESTAMPTZ NOT NULL,

    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES core.customers(customer_id),

    CONSTRAINT chk_orders_status
        CHECK (
            status IN (
                'pending',
                'confirmed',
                'shipped',
                'completed',
                'cancelled'
            )
        ),

    CONSTRAINT chk_orders_channel
        CHECK (channel IN ('web', 'mobile_app', 'social')),

    CONSTRAINT chk_orders_total
        CHECK (order_total >= 0),

    CONSTRAINT chk_orders_updated_at
        CHECK (updated_at >= created_at)
);


CREATE TABLE IF NOT EXISTS core.order_items (
    order_item_id       VARCHAR(16) PRIMARY KEY,
    order_id            VARCHAR(12) NOT NULL,
    product_id          VARCHAR(12) NOT NULL,
    quantity            INTEGER NOT NULL,
    unit_price          NUMERIC(14,2) NOT NULL,
    discount_amount     NUMERIC(14,2) NOT NULL DEFAULT 0,
    source_system       VARCHAR(50) NOT NULL DEFAULT 'unknown',
    ingested_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at          TIMESTAMPTZ NOT NULL,
    updated_at          TIMESTAMPTZ NOT NULL,

    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id)
        REFERENCES core.orders(order_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id)
        REFERENCES core.products(product_id),

    CONSTRAINT chk_order_items_quantity
        CHECK (quantity > 0),

    CONSTRAINT chk_order_items_unit_price
        CHECK (unit_price >= 0),

    CONSTRAINT chk_order_items_discount
        CHECK (discount_amount >= 0),

    CONSTRAINT chk_order_items_discount_vs_gross
        CHECK (discount_amount <= unit_price * quantity),

    CONSTRAINT chk_order_items_updated_at
        CHECK (updated_at >= created_at)
);

CREATE TABLE IF NOT EXISTS core.payments (
    payment_id          VARCHAR(12) PRIMARY KEY,
    order_id            VARCHAR(12) NOT NULL,
    payment_date        TIMESTAMPTZ NOT NULL,
    payment_method      VARCHAR(30) NOT NULL,
    payment_status      VARCHAR(20) NOT NULL,
    amount              NUMERIC(14,2) NOT NULL,
    source_system       VARCHAR(50) NOT NULL DEFAULT 'unknown',
    ingested_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at          TIMESTAMPTZ NOT NULL,
    updated_at          TIMESTAMPTZ NOT NULL,

    CONSTRAINT fk_payments_order
        FOREIGN KEY (order_id)
        REFERENCES core.orders(order_id),

    CONSTRAINT chk_payments_method
        CHECK (
            payment_method IN (
                'cash',
                'bank_transfer',
                'card',
                'e_wallet'
            )
        ),

    CONSTRAINT chk_payments_status
        CHECK (
            payment_status IN (
                'pending',
                'success',
                'failed',
                'refunded'
            )
        ),

    CONSTRAINT chk_payments_amount
        CHECK (amount >= 0),

    CONSTRAINT chk_payments_updated_at
        CHECK (updated_at >= created_at)
);


CREATE INDEX IF NOT EXISTS idx_products_category
    ON core.products(category_id);

CREATE INDEX IF NOT EXISTS idx_orders_customer
    ON core.orders(customer_id);

CREATE INDEX IF NOT EXISTS idx_orders_date
    ON core.orders(order_date);

CREATE INDEX IF NOT EXISTS idx_orders_status
    ON core.orders(status);

CREATE INDEX IF NOT EXISTS idx_order_items_order
    ON core.order_items(order_id);

CREATE INDEX IF NOT EXISTS idx_order_items_product
    ON core.order_items(product_id);

CREATE INDEX IF NOT EXISTS idx_payments_order
    ON core.payments(order_id);

CREATE INDEX IF NOT EXISTS idx_payments_date
    ON core.payments(payment_date);

-- Bước 13: Check các bảng

SELECT
    table_schema,
    table_name
FROM information_schema.tables
WHERE table_schema = 'core'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Đếm số bảng
SELECT COUNT(*) AS number_of_tables
FROM information_schema.tables
WHERE table_schema = 'core'
  AND table_type = 'BASE TABLE';

-- check tồn tại
SELECT
    to_regclass('core.categories')  AS categories,
    to_regclass('core.customers')   AS customers,
    to_regclass('core.products')    AS products,
    to_regclass('core.orders')      AS orders,
    to_regclass('core.order_items') AS order_items,
    to_regclass('core.payments')    AS payments;

-- Bước 14: Check FK
SELECT
    tc.table_name,
    kcu.column_name,
    ccu.table_name  AS referenced_table,
    ccu.column_name AS referenced_column
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
   AND tc.constraint_schema = kcu.constraint_schema
JOIN information_schema.constraint_column_usage ccu
    ON tc.constraint_name = ccu.constraint_name
   AND tc.constraint_schema = ccu.constraint_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'core'
ORDER BY tc.table_name, kcu.column_name;

-- Bước 15: Check Index
SELECT
    tablename,
    indexname
FROM pg_indexes
WHERE schemaname = 'core'
ORDER BY tablename, indexname;

-- Bước 16: Check Constrain
INSERT INTO core.customers (
    customer_id,
    full_name,
    email,
    customer_segment,
    status,
    created_at,
    updated_at
)
VALUES (
    'CUS_TEST',
    'Test User',
    'test@example.com',
    'Standard',
    'wrong_status',
    now(),
    now()
);

-- Bước 17: CHeck FK
INSERT INTO core.orders (
    order_id,
    customer_id,
    order_date,
    status,
    channel,
    order_total,
    created_at,
    updated_at
)
VALUES (
    'ORD_TEST',
    'CUS_NOT_EXIST',
    now(),
    'pending',
    'web',
    100000,
    now(),
    now()
);

-- check Select
    SELECT * FROM core.customers LIMIT 5;
