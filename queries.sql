-- считает общее количество покупателей из таблицы customers
SELECT 
    COUNT(*) AS customers_count
FROM customers;

-- 1. Топ-10 продавцов по суммарной выручке
SELECT
    CONCAT(TRIM(e.first_name), ' ', TRIM(e.last_name)) AS seller,
    COUNT(s.sales_id) AS operations,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales s
INNER JOIN employees e ON s.sales_person_id = e.employee_id
INNER JOIN products p ON s.product_id = p.product_id
GROUP BY seller
ORDER BY income DESC
LIMIT 10;


-- 2. Продавцы с низкой средней выручкой
WITH seller_avg AS (
    SELECT
        CONCAT(TRIM(e.first_name), ' ', TRIM(e.last_name)) AS seller,
        FLOOR(AVG(p.price * s.quantity)) AS average_income
    FROM sales s
    INNER JOIN employees e ON s.sales_person_id = e.employee_id
    INNER JOIN products p ON s.product_id = p.product_id
    GROUP BY seller
),
overall_avg AS (
    SELECT AVG(average_income) AS avg_income_overall
    FROM seller_avg
)
SELECT
    seller,
    average_income
FROM seller_avg, overall_avg
WHERE average_income < avg_income_overall
ORDER BY average_income ASC;


-- 3. Дневная выручка продавцов, сортировка monday → sunday
SELECT
    CONCAT(TRIM(e.first_name), ' ', TRIM(e.last_name)) AS seller,
    LOWER(TRIM(TO_CHAR(s.sale_date, 'Day'))) AS day_of_week,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales s
INNER JOIN employees e ON s.sales_person_id = e.employee_id
INNER JOIN products p ON s.product_id = p.product_id
GROUP BY seller, day_of_week,
         -- Смещение: превращаем Monday=1 → 1, ..., Sunday=0 → 7
         (CASE WHEN EXTRACT(DOW FROM s.sale_date) = 0
               THEN 7
               ELSE EXTRACT(DOW FROM s.sale_date)
          END)
ORDER BY
    (CASE WHEN EXTRACT(DOW FROM s.sale_date) = 0
          THEN 7
          ELSE EXTRACT(DOW FROM s.sale_date)
     END),
    seller;


-- 1. Количество покупателей в возрастных категориях 16–25, 26–40, 40+
SELECT age_category, COUNT(*) AS age_count
FROM (
    SELECT
        CASE
            WHEN age BETWEEN 16 AND 25 THEN '16-25'
            WHEN age BETWEEN 26 AND 40 THEN '26-40'
            WHEN age > 40 THEN '40+'
        END AS age_category
    FROM customers
    WHERE age IS NOT NULL
      AND age >= 16
) t
GROUP BY age_category
ORDER BY
    CASE
        WHEN age_category = '16-25' THEN 1
        WHEN age_category = '26-40' THEN 2
        WHEN age_category = '40+' THEN 3
    END;

-- 2. Количество уникальных покупателей и месячная выручка
SELECT
    TO_CHAR(s.sale_date, 'YYYY-MM') AS selling_month,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales s
JOIN products p ON s.product_id = p.ProductId
GROUP BY selling_month
ORDER BY selling_month;


-- 3. Покупатели, чья первая покупка была акционной (цена = 0)
WITH first_sales AS (
    SELECT 
        s.customer_id,
        s.sales_id,
        s.sale_date,
        s.sales_person_id,
        s.product_id,
        ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.sale_date, s.sales_id) AS rn
    FROM sales s
)
SELECT
    c.first_name || ' ' || c.last_name AS customer,
    fs.sale_date,
    e.first_name || ' ' || e.last_name AS seller
FROM first_sales fs
INNER JOIN products p
    ON fs.product_id = p."ProductId"
INNER JOIN customers c
    ON fs.customer_id = c.customer_id
INNER JOIN employees e
    ON fs.sales_person_id = e.employee_id
WHERE fs.rn = 1          -- только первая покупка клиента
  AND p."Price" = 0       -- акционный товар (цена = 0)
ORDER BY fs.customer_id;