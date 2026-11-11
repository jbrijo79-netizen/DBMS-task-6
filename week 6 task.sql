-- =====================================================================
-- Week 6: Product Review and Rating Management System
-- Dialect: MySQL 8.0.16+ (CHECK constraints are enforced)
-- =====================================================================

DROP DATABASE IF EXISTS ecommerce_db;
CREATE DATABASE ecommerce_db;
USE ecommerce_db;


-- ---------------------------------------------------------------------
-- 0. Existing modules (assumed structure; skip if you already have them)
-- ---------------------------------------------------------------------
CREATE TABLE Customer (
    Customer_ID    INT PRIMARY KEY,
    Customer_Name  VARCHAR(50) NOT NULL,
    Email          VARCHAR(100)
);

CREATE TABLE Product (
    Product_ID    INT PRIMARY KEY,
    Product_Name  VARCHAR(50) NOT NULL,
    Price         DECIMAL(10,2)
);

INSERT INTO Customer VALUES
(1, 'John',  'john@example.com'),
(2, 'Priya', 'priya@example.com'),
(3, 'Arun',  'arun@example.com');

INSERT INTO Product VALUES
(101, 'Laptop',     55000.00),
(102, 'Mobile',     20000.00),
(103, 'Headphones',  2500.00),
(104, 'Keyboard',    1200.00);   -- no reviews yet

-- ---------------------------------------------------------------------
-- 1 & 2. Review table with relationships and constraints
-- ---------------------------------------------------------------------
CREATE TABLE Review (
    Review_ID    VARCHAR(10)  PRIMARY KEY,
    Customer_ID  INT          NOT NULL,
    Product_ID   INT          NOT NULL,
    Rating       INT          NOT NULL,
    Review_Text  VARCHAR(500),
    Review_Date  DATE         NOT NULL,
    CONSTRAINT chk_rating CHECK (Rating BETWEEN 1 AND 5),
    CONSTRAINT fk_review_customer FOREIGN KEY (Customer_ID)
        REFERENCES Customer(Customer_ID),
    CONSTRAINT fk_review_product FOREIGN KEY (Product_ID)
        REFERENCES Product(Product_ID)
);

-- ---------------------------------------------------------------------
-- 3. Store customer feedback and ratings
-- ---------------------------------------------------------------------
INSERT INTO Review VALUES ('R101', 1, 101, 5, 'Excellent performance', '2026-11-01');
INSERT INTO Review VALUES ('R102', 2, 102, 4, 'Good battery life',     '2026-11-03');
INSERT INTO Review VALUES ('R103', 3, 101, 4, 'Fast but a bit heavy',  '2026-11-05');
INSERT INTO Review VALUES ('R104', 1, 102, 3, 'Average camera',        '2026-11-06');
INSERT INTO Review VALUES ('R105', 2, 103, 2, 'Sound quality is poor', '2026-11-08');
INSERT INTO Review VALUES ('R106', 3, 103, 1, 'Stopped working',       '2026-11-09');
INSERT INTO Review VALUES ('R107', 2, 101, 5, 'Worth the price',       '2026-11-10');

-- Update a review comment
UPDATE Review
SET Review_Text = 'Excellent performance and build quality'
WHERE Review_ID = 'R101';

-- Remove an inappropriate or invalid review
DELETE FROM Review WHERE Review_ID = 'R106';

-- CHECK constraint test (run separately; it should fail with error 3819)
-- INSERT INTO Review VALUES ('R108', 1, 101, 6, 'Invalid', '2026-11-10');

-- ---------------------------------------------------------------------
-- 4. Retrieve product review details
-- ---------------------------------------------------------------------

-- 4.1 All reviews for a product
SELECT p.Product_Name, r.Rating, r.Review_Text
FROM Product p
JOIN Review r ON p.Product_ID = r.Product_ID
WHERE p.Product_Name = 'Laptop';

-- 4.2 Customer name with their reviews
SELECT c.Customer_Name, p.Product_Name, r.Rating, r.Review_Text
FROM Review r
JOIN Customer c ON r.Customer_ID = c.Customer_ID
JOIN Product  p ON r.Product_ID  = p.Product_ID;

-- 4.3 Products having the maximum number of reviews
SELECT p.Product_Name, COUNT(*) AS Total_Reviews
FROM Product p
JOIN Review r ON p.Product_ID = r.Product_ID
GROUP BY p.Product_ID, p.Product_Name
HAVING COUNT(*) = (SELECT MAX(cnt)
                   FROM (SELECT COUNT(*) AS cnt
                         FROM Review GROUP BY Product_ID) t);

-- 4.4 Recent customer feedback (latest 5)
SELECT c.Customer_Name, p.Product_Name, r.Rating, r.Review_Text, r.Review_Date
FROM Review r
JOIN Customer c ON r.Customer_ID = c.Customer_ID
JOIN Product  p ON r.Product_ID  = p.Product_ID
ORDER BY r.Review_Date DESC
LIMIT 5;

-- 4.5 Reviews with rating above 4 (use >= 4 to include 4 stars)
SELECT p.Product_Name, r.Rating, r.Review_Text
FROM Review r
JOIN Product p ON r.Product_ID = p.Product_ID
WHERE r.Rating > 4;

-- ---------------------------------------------------------------------
-- 5. Average product ratings
-- ---------------------------------------------------------------------

-- 5.1 Average rating for each product
SELECT Product_ID, ROUND(AVG(Rating), 2) AS Avg_Rating
FROM Review
GROUP BY Product_ID;

-- 5.2 Number of reviews per product
SELECT Product_ID, COUNT(*) AS Review_Count
FROM Review
GROUP BY Product_ID;

-- 5.3 Highest-rated product(s)
SELECT p.Product_Name, ROUND(AVG(r.Rating), 2) AS Avg_Rating
FROM Product p
JOIN Review r ON p.Product_ID = r.Product_ID
GROUP BY p.Product_ID, p.Product_Name
HAVING AVG(r.Rating) = (SELECT MAX(a)
                        FROM (SELECT AVG(Rating) AS a
                              FROM Review GROUP BY Product_ID) t);

-- 5.4 Products with average rating above 4
SELECT p.Product_Name, ROUND(AVG(r.Rating), 2) AS Avg_Rating
FROM Product p
JOIN Review r ON p.Product_ID = r.Product_ID
GROUP BY p.Product_ID, p.Product_Name
HAVING AVG(r.Rating) > 4;

-- ---------------------------------------------------------------------
-- 6. Reports
-- ---------------------------------------------------------------------

-- Report 1: Product Rating Analysis
SELECT p.Product_Name,
       COUNT(r.Review_ID)      AS Number_of_Reviews,
       ROUND(AVG(r.Rating), 2) AS Average_Rating
FROM Product p
LEFT JOIN Review r ON p.Product_ID = r.Product_ID
GROUP BY p.Product_ID, p.Product_Name
ORDER BY Average_Rating DESC;

-- Report 2a: Most reviewed products
SELECT p.Product_Name, COUNT(*) AS Total_Reviews
FROM Product p
JOIN Review r ON p.Product_ID = r.Product_ID
GROUP BY p.Product_ID, p.Product_Name
ORDER BY Total_Reviews DESC;-

-- Report 2b: Highly rated products (average 4 or more)
SELECT p.Product_Name, ROUND(AVG(r.Rating), 2) AS Avg_Rating
FROM Product p
JOIN Review r ON p.Product_ID = r.Product_ID
GROUP BY p.Product_ID, p.Product_Name
HAVING AVG(r.Rating) >= 4;

-- Report 2c: Products requiring improvement (average below 3)
SELECT p.Product_Name, ROUND(AVG(r.Rating), 2) AS Avg_Rating
FROM Product p
JOIN Review r ON p.Product_ID = r.Product_ID
GROUP BY p.Product_ID, p.Product_Name
HAVING AVG(r.Rating) < 3;

-- Report 3a: Count of each star rating
SELECT Rating, COUNT(*) AS Total
FROM Review
GROUP BY Rating
ORDER BY Rating DESC;

-- Report 3b: 5-star, 4-star and low ratings in one row
SELECT SUM(Rating = 5)  AS Five_Star,
       SUM(Rating = 4)  AS Four_Star,
       SUM(Rating <= 2) AS Low_Ratings
FROM Review;

-- Report 3c: Number of low-rated products (average below 3)
SELECT COUNT(*) AS Low_Rated_Products
FROM (SELECT Product_ID
      FROM Review
      GROUP BY Product_ID
      HAVING AVG(Rating) < 3) t;