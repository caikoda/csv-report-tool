

-- queries.sql
-- Набор запросов с JOIN, CTE и оконными функциями.

-- 1) Базовый JOIN: заказы с именем клиента
SELECT o.order_id, c.full_name, o.order_date, o.status, o.amount
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id;

-- 2) Агрегация по регионам (только завершённые заказы)
SELECT c.region, SUM(o.amount) AS revenue
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.status = 'completed'
GROUP BY c.region
ORDER BY revenue DESC;

-- 3) CTE: активные клиенты с выручкой > 1000
WITH revenue_per_customer AS (
  SELECT o.customer_id, SUM(o.amount) AS total_amount
  FROM orders o
  WHERE o.status = 'completed'
  GROUP BY o.customer_id
)
SELECT c.customer_id, c.full_name, rpc.total_amount
FROM revenue_per_customer rpc
JOIN customers c ON c.customer_id = rpc.customer_id
WHERE rpc.total_amount > 1000;

-- 4) Оконные функции: порядковый номер заказа клиента по дате
SELECT
  o.*,
  ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY o.order_date) AS order_seq
FROM orders o
ORDER BY o.customer_id, order_seq;

-- 5) Скользящая сумма по клиенту
SELECT
  o.customer_id,
  o.order_date,
  o.amount,
  SUM(o.amount) OVER (PARTITION BY o.customer_id ORDER BY o.order_date
                      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_amount
FROM orders o
WHERE o.status = 'completed'
ORDER BY o.customer_id, o.order_date;

-- 6) Топ-3 клиента по выручке с RANK()
WITH revenue AS (
  SELECT o.customer_id, SUM(o.amount) AS total_amount
  FROM orders o
  WHERE o.status = 'completed'
  GROUP BY o.customer_id
)
SELECT
  c.full_name,
  r.total_amount,
  RANK() OVER (ORDER BY r.total_amount DESC) AS rnk
FROM revenue r
JOIN customers c ON c.customer_id = r.customer_id
ORDER BY rnk
LIMIT 3;

-- 7) Средний чек по региону и отклонение клиента от среднего (WINDOW + JOIN)
WITH base AS (
  SELECT c.customer_id, c.region, SUM(CASE WHEN o.status='completed' THEN o.amount ELSE 0 END) AS amount
  FROM customers c
  LEFT JOIN orders o ON o.customer_id = c.customer_id
  GROUP BY c.customer_id, c.region
)
SELECT
  b.customer_id,
  b.region,
  b.amount,
  AVG(b.amount) OVER (PARTITION BY b.region) AS avg_region_amount,
  b.amount - AVG(b.amount) OVER (PARTITION BY b.region) AS diff_from_region_avg
FROM base b
ORDER BY b.region, b.amount DESC;
