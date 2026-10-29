SELECT * FROM olist.category_translation
ORDER BY product_category_name ASC;


SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'olist'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;



SELECT
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'olist'
  AND table_name IN (
      'category_translation',
      'customers',
      'order_items',
      'order_payments',
      'order_reviews',
      'orders',
      'products',
      'sellers'
  )
ORDER BY
    table_name,
    ordinal_position;





-- How many repeat orders have been successfully delivered, and what are their order dates and customer IDs?

WITH ranked_orders AS (
    SELECT
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp,
        o.order_status,
        ROW_NUMBER() OVER (
            PARTITION BY c.customer_unique_id
            ORDER BY o.order_purchase_timestamp ASC, o.order_id ASC
        ) AS row_num
    FROM olist.orders AS o
    JOIN olist.customers AS c
        ON o.customer_id = c.customer_id
),

first_orders AS (
    SELECT
        ro.customer_unique_id,
        ro.order_id,
        ro.order_status,
        ro.order_purchase_timestamp,
        ro.row_num
    FROM ranked_orders AS ro
    WHERE ro.row_num = 1
),

repeat_order AS (
    SELECT
        ro.customer_unique_id,
        ro.order_id,
        ro.order_status,
        ro.order_purchase_timestamp,
        ro.row_num
    FROM ranked_orders AS ro
    WHERE ro.row_num > 1
)

SELECT
    repo.customer_unique_id,
    repo.order_id,
    repo.order_status,
    repo.order_purchase_timestamp,
    repo.row_num
FROM repeat_order AS repo
WHERE repo.order_status = 'delivered'
ORDER BY repo.customer_unique_id, repo.row_num;




-- What are the statuses of first orders that were not successfully delivered, and how many orders fall into each status?

WITH ranked_orders AS(
SELECT 
	c.customer_unique_id,
	o.order_id,
	o.order_purchase_timestamp,
	o.order_status,
	ROW_NUMBER() OVER(PARTITION BY c.customer_unique_id ORDER BY o.order_purchase_timestamp ASC) AS row_num
FROM olist.orders AS o
JOIN olist.customers AS c
	ON o.customer_id = c.customer_id
),
first_orders AS(
SELECT 
	ro.customer_unique_id,
	ro.order_id,
	ro.order_status,
	ro.order_purchase_timestamp,
	ro.row_num
FROM ranked_orders AS ro
WHERE row_num = 1
)
SELECT
    COUNT(*) AS total_first_orders,
    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
    ) AS delivered_first_orders,
	ROUND(100.0 * COUNT(*) FILTER (WHERE order_status = 'delivered') / COUNT(*), 2) AS successfully_delivered
FROM first_orders AS fo;





WITH ranked_orders AS (
    SELECT
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp,
        o.order_status,
        ROW_NUMBER() OVER (
            PARTITION BY c.customer_unique_id
            ORDER BY o.order_purchase_timestamp ASC, o.order_id ASC
        ) AS row_num
    FROM olist.orders AS o
    JOIN olist.customers AS c
        ON o.customer_id = c.customer_id
),
first_orders AS (
    SELECT
        customer_unique_id,
        order_id,
        order_purchase_timestamp,
        order_status
    FROM ranked_orders
    WHERE row_num = 1
)
SELECT
    COUNT(*) AS total_first_orders,
    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
    ) AS delivered_first_orders,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE order_status = 'delivered'
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS successfully_delivered
FROM first_orders;



-- What are the statuses of first orders that were not successfully delivered, and how many first orders fall into each status?


WITH ranked_orders AS(
SELECT 
	c.customer_unique_id,
	o.order_status,
	o.order_purchase_timestamp,
	ROW_NUMBER() OVER(PARTITION BY c.customer_unique_id ORDER BY o.order_purchase_timestamp ASC, o.order_id ASC) AS row_num
FROM olist.orders AS o
JOIN olist.customers AS c
	ON o.customer_id = c.customer_id
),
first_orders AS(
SELECT 
    ro.customer_unique_id,
    ro.order_status,
    ro.order_purchase_timestamp,
    ro.row_num
FROM ranked_orders AS ro
WHERE ro.row_num = 1
)
SELECT
	fo.order_status,
	COUNT(order_status) AS status_count
FROM first_orders AS fo
WHERE order_status != 'delivered'
GROUP BY order_status;





-- How does the monthly first-order cohort retention rate change over time?

WITH ranked_orders AS (
    SELECT
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp,
        o.order_status,
        ROW_NUMBER() OVER (
            PARTITION BY c.customer_unique_id
            ORDER BY o.order_purchase_timestamp ASC, o.order_id ASC
        ) AS row_num
    FROM olist.orders AS o
    JOIN olist.customers AS c
        ON o.customer_id = c.customer_id
),

monthly_first_order AS (
    SELECT
        customer_unique_id,
        DATE_TRUNC('month', order_purchase_timestamp) AS first_order_month
    FROM ranked_orders
    WHERE row_num = 1
      AND order_status = 'delivered'
),

customer_orders AS (
    SELECT
        c.customer_unique_id,
        DATE_TRUNC('month', o.order_purchase_timestamp) AS order_month,
        mfo.first_order_month
    FROM olist.orders AS o
    JOIN olist.customers AS c
        ON o.customer_id = c.customer_id
    JOIN monthly_first_order AS mfo
        ON c.customer_unique_id = mfo.customer_unique_id
    WHERE o.order_status = 'delivered'
),

customer_cohort_age AS (
    SELECT
        customer_unique_id,
        order_month,
        first_order_month,
        (
            EXTRACT(YEAR FROM order_month)
            - EXTRACT(YEAR FROM first_order_month)
        ) * 12
        +
        (
            EXTRACT(MONTH FROM order_month)
            - EXTRACT(MONTH FROM first_order_month)
        ) AS cohort_age
    FROM customer_orders
),

cohort_size AS (
    SELECT
        first_order_month,
        COUNT(*) AS cohort_size
    FROM monthly_first_order
    GROUP BY first_order_month
)

SELECT
    cca.first_order_month,
    cca.cohort_age,
    COUNT(DISTINCT cca.customer_unique_id) AS active_customers,
    cs.cohort_size,
    ROUND(
        COUNT(DISTINCT cca.customer_unique_id) * 100.0
        / NULLIF(cs.cohort_size, 0),
        2
    ) AS retention_rate
FROM customer_cohort_age AS cca
JOIN cohort_size AS cs
    ON cca.first_order_month = cs.first_order_month
GROUP BY
    cca.first_order_month,
    cca.cohort_age,
    cs.cohort_size
ORDER BY
    cca.first_order_month,
    cca.cohort_age;





SELECT
    COUNT(DISTINCT customer_unique_id) AS customers_with_orders
FROM olist.customers;




SELECT
    COUNT(DISTINCT c.customer_unique_id) AS customers_with_orders
FROM olist.customers AS c
JOIN olist.orders AS o
    ON c.customer_id = o.customer_id;


































































