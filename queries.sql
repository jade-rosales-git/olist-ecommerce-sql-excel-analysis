-- Olist E-Commerce Analysis: SQL queries (SQLite)
-- Author: Jade Rosales
-- Revenue = product price in R$, excluding shipping. Delivered orders only unless noted.


-- 1. Monthly revenue over time
WITH delivered_orders AS (
    SELECT order_id,
           strftime('%Y-%m', order_purchase_timestamp) AS month
    FROM orders
    WHERE order_status = 'delivered'
),
order_revenue AS (
    SELECT order_id, SUM(price) AS revenue
    FROM order_items
    GROUP BY order_id
)
SELECT d.month,
       ROUND(SUM(r.revenue), 2) AS revenue,
       COUNT(d.order_id) AS orders
FROM delivered_orders d
JOIN order_revenue r ON d.order_id = r.order_id
GROUP BY d.month
ORDER BY d.month;


-- 2. Top 10 product categories by revenue (all order statuses)
WITH item_categories AS (
    SELECT oi.price,
           p.product_category_name
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
),
category_revenue AS (
    SELECT product_category_name,
           SUM(price) AS revenue
    FROM item_categories
    GROUP BY product_category_name
)
SELECT COALESCE(t.product_category_name_english, c.product_category_name) AS category,
       ROUND(c.revenue, 2) AS revenue
FROM category_revenue c
LEFT JOIN category_translation t
       ON c.product_category_name = t.product_category_name
ORDER BY c.revenue DESC
LIMIT 10;


-- 3. Late deliveries vs average review score
WITH delivery_status AS (
    SELECT order_id,
           CASE
               WHEN date(order_delivered_customer_date) > date(order_estimated_delivery_date)
               THEN 'Late'
               ELSE 'On time'
           END AS delivery
    FROM orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date <> ''
),
order_reviews AS (
    SELECT order_id, AVG(review_score) AS score
    FROM reviews
    GROUP BY order_id
)
SELECT d.delivery,
       COUNT(*) AS orders,
       ROUND(AVG(r.score), 2) AS avg_review_score
FROM delivery_status d
JOIN order_reviews r ON d.order_id = r.order_id
GROUP BY d.delivery;


-- 4. Revenue by customer state
WITH order_revenue AS (
    SELECT order_id, SUM(price) AS revenue
    FROM order_items
    GROUP BY order_id
),
order_state AS (
    SELECT o.order_id, c.customer_state
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
)
SELECT s.customer_state,
       ROUND(SUM(r.revenue), 2) AS revenue,
       COUNT(*) AS orders
FROM order_state s
JOIN order_revenue r ON s.order_id = r.order_id
GROUP BY s.customer_state
ORDER BY revenue DESC;
