-- считает общее количество покупателей из таблицы customers
SELECT COUNT(*) AS customers_count
FROM customers;

-- 1. Топ-10 продавцов по суммарной выручке
SELECT
    CONCAT(TRIM(e.first_name), ' ', TRIM(e.last_name)) AS seller,
    COUNT(s.sales_id) AS operations,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales s
JOIN employees e ON s.sales_person_id = e.employee_id
JOIN products p ON s.product_id = p.product_id
GROUP BY seller
ORDER BY income DESC
LIMIT 10;


-- 2. Продавцы с низкой средней выручкой
WITH seller_avg AS (
    SELECT
        CONCAT(TRIM(e.first_name), ' ', TRIM(e.last_name)) AS seller,
        FLOOR(AVG(p.price * s.quantity)) AS average_income
    FROM sales s
    JOIN employees e ON s.sales_person_id = e.employee_id
    JOIN products p ON s.product_id = p.product_id
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
JOIN employees e ON s.sales_person_id = e.employee_id
JOIN products p ON s.product_id = p.product_id
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
