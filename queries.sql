-- считает общее количество покупателей из таблицы customers
SELECT COUNT(*) AS customers_count
FROM customers;

-- 1. Топ-10 продавцов по суммарной выручке
SELECT 
    CONCAT(TRIM(e.first_name), ' ', TRIM(e.last_name)) AS seller,
    COUNT(s.sales_id) AS operations,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales AS s
INNER JOIN employees AS e
    ON s.sales_person_id = e.employee_id
INNER JOIN products AS p
    ON s.product_id = p.product_id
GROUP BY seller
ORDER BY income DESC
LIMIT 10;
