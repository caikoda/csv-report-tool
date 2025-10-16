
-- schema.sql
-- Мини-проект для PostgreSQL/ClickHouse-совместимого синтаксиса.

-- Таблицы
CREATE TABLE customers (
    customer_id   INT PRIMARY KEY,
    full_name     TEXT,
    region        TEXT,
    created_at    DATE
);

CREATE TABLE orders (
    order_id      INT PRIMARY KEY,
    customer_id   INT REFERENCES customers(customer_id),
    order_date    DATE,
    status        TEXT,
    amount        NUMERIC(12,2)
);

-- Примерные данные
INSERT INTO customers VALUES
(1, 'Alice Ivanova', 'Ural', '2024-01-10'),
(2, 'Boris Petrov',  'Siberia', '2024-02-15'),
(3, 'Chen Li',       'Ural', '2024-03-05'),
(4, 'Dmitry Orlov',  'Volga', '2024-03-20');

INSERT INTO orders VALUES
(101, 1, '2024-03-01', 'completed', 1200.00),
(102, 1, '2024-03-15', 'cancelled', 300.00),
(103, 2, '2024-03-20', 'completed', 850.00),
(104, 3, '2024-04-05', 'completed', 500.00),
(105, 3, '2024-04-20', 'completed', 700.00),
(106, 4, '2024-04-25', 'processing', 100.00);
