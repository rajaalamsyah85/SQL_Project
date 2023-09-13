/* Music Store Project with SQL */

-- Case Study Set 1 Easy Level --
-- Q1: Who is the senior most employee based on job title?

SELECT *
FROM public.employee
ORDER BY levels DESC
LIMIT 1;

-- Q2: Which countries have the most Invoices?

SELECT COUNT(*) AS total_invoice, billing_country
FROM public.invoice
GROUP BY billing_country
ORDER BY total_invoice DESC;

-- Q3: What are top 3 values of total Invoices?

SELECT ROUND(total::numeric, 2) AS total
FROM public.invoice
ORDER BY total DESC
LIMIT 3;

-- Q4: Which city has the besst customers? We would like to throw a promotional Music Festival in the city 
-- we made the most money. Write a query that returns one city that has the highest sum of invoice totals. 
-- Return both the city name & sum of all invoice totals.

SELECT billing_city, ROUND(SUM(total)::numeric, 2) AS total_invoice
FROM public.invoice
GROUP BY billing_city
ORDER BY total_invoice DESC
LIMIT 1;

-- Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer.
-- Write a query that returns the person who has spent the most money.

SELECT c.customer_id, c.first_name, c.last_name, ROUND(SUM(i.total)::numeric, 2) AS total_invoice
FROM public.customer c
INNER JOIN public.invoice i
	ON i.customer_id = c.customer_id
GROUP BY c.customer_id
ORDER BY total_invoice DESC
LIMIT 1;


-- Case Study Set 2 Moderate Level --
-- Q1: Write query to return the email, first name, last name, and genre of all Rock Music listeners. 
-- Return your list ordered alphabetically by email starting A.

SELECT DISTINCT c.email, c.first_name, c.last_name
FROM public.customer c
INNER JOIN public.invoice i
	ON i.customer_id = c.customer_id
INNER JOIN public.invoice_line il
	ON i.invoice_id = il.invoice_id
WHERE track_id IN (
	SELECT track_id
	FROM public.track t
	INNER JOIN public.genre g
		ON g.genre_id = t.genre_id
	WHERE g.name LIKE 'Rock'
)
ORDER BY c.email;

--Optional

SELECT DISTINCT c.email, c.first_name, c.last_name, g.name
FROM public.customer c
INNER JOIN public.invoice i
	ON i.customer_id = c.customer_id
INNER JOIN public.invoice_line il
	ON i.invoice_id = il.invoice_id
INNER JOIN public.track t
	ON t.track_id = il.track_id
INNER JOIN public.genre g
	ON g.genre_id = t.genre_id
WHERE g.name LIKE 'Rock'
ORDER BY email;

-- Q2: Let's invite the artist who have written the most rock music in out dataset. 
-- Write a query that returns the Artist name and total track count of the top 10 rock hands.

SELECT art.artist_id, art.name, COUNT(art.artist_id) AS number_of_songs
FROM public.track t
INNER JOIN public.album al
	ON al.album_id = t.album_id
INNER JOIN public.artist art
	ON art.artist_id = al.artist_id
INNER JOIN public.genre g
	ON g.genre_id = t.genre_id
WHERE g.name LIKE 'Rock'
GROUP BY art.artist_id
ORDER BY number_of_songs DESC
LIMIT 10;

-- Q3: Return all the track names that have a song length longer than the average song length. 
-- Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first.	

SELECT name, milliseconds
FROM public.track
WHERE milliseconds > (
	SELECT AVG(milliseconds) AS avg_track_length
	FROM public.track
)
ORDER BY milliseconds DESC;


-- Case Study Set 3 Advanced Level --
-- Q1: Find how much amount spent by each customer on artists? 
-- Write a query to return customer name, artist name and total spent.

WITH best_selling_artist AS (
SELECT art.artist_id, art.name AS artist_name, ROUND(SUM(il.unit_price::numeric * il.quantity::numeric), 2) AS total_sales
FROM public.invoice_line il
INNER JOIN public.track t
	ON t.track_id = il.track_id
INNER JOIN public.album al
	ON al.album_id = t.album_id
INNER JOIN public.artist art
	ON art.artist_id = al.artist_id
INNER JOIN public.genre g
	ON g.genre_id = t.genre_id
GROUP BY 1
ORDER BY 3 DESC
LIMIT 1
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, ROUND(SUM(il.unit_price::numeric * il.quantity::numeric), 2) AS amount_spent
FROM public.invoice_line il
INNER JOIN public.invoice i
	ON i.invoice_id = il.invoice_id
INNER JOIN public.track t
	ON t.track_id = il.track_id
INNER JOIN public.album al
	ON al.album_id = t.album_id
INNER JOIN public.customer c
	ON c.customer_id = i.customer_id
INNER JOIN best_selling_artist bsa
	ON bsa.artist_id = al.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;

-- Q2: We want to find out the most popular mucis Genre for each country. 
-- We determine the most popular genre as the genre with the highest amount of purchases. 
-- Write a query that returns each country along with the top Genre.
-- For countries where the maximum number of purchases is shared return all Genres.

-- Using CTE (Common Table Expression)
WITH popular_genre AS (
SELECT COUNT(il.quantity) AS purchases, c.country, g.genre_id, g.name,
	ROW_NUMBER() OVER(PARTITION BY c.country ORDER BY COUNT(il.quantity) DESC) AS RowNo
FROM public.invoice_line il
INNER JOIN public.invoice i
	ON i.invoice_id = il.invoice_id
INNER JOIN public.customer c
	ON c.customer_id = i.customer_id
INNER JOIN public.track t
	ON t.track_id = il.track_id
INNER JOIN public.genre g
	ON g.genre_id = t.genre_id
GROUP BY 2,3,4
ORDER BY 2 ASC, 1 DESC
)
SELECT *
FROM popular_genre 
WHERE RowNo <= 1;

-- Using Recursive
WITH RECURSIVE
	sales_per_country AS (
		SELECT COUNT(*) AS purchases_per_genre, c.country, g.genre_id, g.name
		FROM public.invoice_line il
		INNER JOIN public.invoice i ON i.invoice_id = il.invoice_id
		INNER JOIN public.customer c ON c.customer_id = i.customer_id
		INNER JOIN public.track t ON t.track_id = il.track_id
		INNER JOIN public.genre g ON g.genre_id = t.genre_id
		GROUP BY 2,3,4
		ORDER BY 2
	),
	max_genre_per_country AS (
		SELECT MAX(purchases_per_genre) AS max_genre_number, country
		FROM sales_per_country
		GROUP BY 2
		ORDER BY 2
)
SELECT spc.* 
FROM sales_per_country spc
JOIN max_genre_per_country  mgpc
	ON spc.country = mgpc.country
WHERE spc.purchases_per_genre = mgpc.max_genre_number;


-- Q3: Write a query that determines the customer that has spent the most on music for each country. 
-- Write a query that returns the country along with top customer and how much they spent. 
-- For countries where the top amount spent is shared, provide all customers who spent this amount.

-- Using CTE (Common Table Expression)
WITH customer_with_country AS (
SELECT c.customer_id, c.first_name, c.last_name, i.billing_country, ROUND(SUM(i.total::numeric), 2) AS total_spending,
	ROW_NUMBER() OVER(PARTITION BY i.billing_country ORDER BY SUM(i.total) DESC) AS RowNo
FROM public.invoice i
INNER JOIN public.customer c
	ON c.customer_id = i.customer_id
GROUP BY 1,2,3,4
ORDER BY 4 ASC, 5 DESC
)
SELECT *
FROM customer_with_country
WHERE RowNo <= 1;

-- Using Recursive
WITH RECURSIVE
	customer_with_country AS (
		SELECT c.customer_id, c.first_name, c.last_name, i.billing_country, ROUND(SUM(i.total::numeric), 2) AS total_spending
		FROM public.invoice i
		INNER JOIN public.customer c ON c.customer_id = i.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 2,3 DESC
	),
	country_max_spending AS (
		SELECT billing_country, MAX(total_spending) AS max_spending
		FROM customer_with_country
		GROUP BY 1
)
SELECT cwc.billing_country, cwc.total_spending, cwc.first_name, cwc.last_name, cwc.customer_id
FROM customer_with_country cwc
INNER JOIN country_max_spending cms
	ON cms.billing_country = cwc.billing_country
WHERE cwc.total_spending = cms.max_spending
ORDER BY 1;
	