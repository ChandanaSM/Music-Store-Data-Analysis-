--    Musics Store Data


-- SELECT * FROM `music store data analysis`.album2;
-- SELECT * FROM `music store data analysis`.artist;
-- SELECT * FROM `music store data analysis`.customer;
-- SELECT * FROM `music store data analysis`.employee;
-- SELECT * FROM `music store data analysis`.genre;
-- SELECT * FROM `music store data analysis`.invoice;
-- SELECT * FROM `music store data analysis`.invoice_line;
-- SELECT * FROM `music store data analysis`.media_type;
-- SELECT * FROM `music store data analysis`.playlist;
-- SELECT * FROM `music store data analysis`.playlist_track;
-- SELECT * FROM `music store data analysis`.track;

--  Q1: Who is the senior most employee based on job title? 
SELECT title, last_name, first_name 
FROM `music store data analysis`.employee
ORDER BY levels DESC
LIMIT 1;

-- Q2: Which countries have the most Invoices?
SELECT COUNT(*) AS c, billing_country 
FROM `music store data analysis`.invoice
GROUP BY billing_country
ORDER BY c DESC

-- Q3: What are top 3 values of total invoice?
SELECT * FROM `music store data analysis`.invoice
ORDER BY total DESC
LIMIT 3;

-- Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
-- Write a query that returns one city that has the highest sum of invoice totals. 
-- Return both the city name & sum of all invoice totals
SELECT * FROM `music store data analysis`.invoice;

SELECT billing_city,SUM(total) AS InvoiceTotal
FROM `music store data analysis`.invoice
GROUP BY billing_city
ORDER BY InvoiceTotal DESC
LIMIT 1;

-- Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
-- Write a query that returns the person who has spent the most money

SELECT customer.customer_id, first_name, last_name, SUM(total) AS total_spending
FROM `music store data analysis`.customer
JOIN `music store data analysis`.invoice ON customer.customer_id = invoice.customer_id
GROUP BY customer.customer_id,first_name, last_name
ORDER BY total_spending DESC
LIMIT 1;

-- Q6: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
-- Return your list ordered alphabetically by email starting with A.

SELECT DISTINCT email,first_name, last_name
FROM `music store data analysis`.customer
JOIN `music store data analysis`.invoice ON customer.customer_id = invoice.customer_id
JOIN `music store data analysis`.invoice_line ON invoice.invoice_id = invoice_line.invoice_id
WHERE track_id IN(SELECT track_id FROM `music store data analysis`.track
JOIN `music store data analysis`.genre ON track.genre_id = genre.genre_id
WHERE genre.name LIKE 'Rock')
ORDER BY email;

-- Q7: Let's invite the artists who have written the most rock music in our dataset. 
-- Write a query that returns the Artist name and total track count of the top 10 rock bands.

SELECT artist.artist_id, artist.name,COUNT(artist.artist_id) AS number_of_songs
FROM `music store data analysis`.track
JOIN `music store data analysis`.album2 ON album2.album_id = track.album_id
JOIN `music store data analysis`.artist ON artist.artist_id = album2.artist_id
JOIN `music store data analysis`.genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY artist.artist_id,artist.name
ORDER BY number_of_songs DESC
LIMIT 10;

-- Q8: Return all the track names that have a song length longer than the average song length. 
-- Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first.

SELECT name,milliseconds
FROM `music store data analysis`.track
WHERE milliseconds > (
	SELECT AVG(milliseconds) AS avg_track_length
	FROM `music store data analysis`.track )
ORDER BY milliseconds DESC;

-- Q9: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent
WITH selling_artist AS (
	SELECT artist.artist_id AS artist_id, artist.name AS artist_name, SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales
	FROM `music store data analysis`.invoice_line
	JOIN `music store data analysis`.track ON track.track_id = invoice_line.track_id
	JOIN `music store data analysis`.album2 ON album2.album_id = track.album_id
	JOIN `music store data analysis`.artist ON artist.artist_id = album2.artist_id
	GROUP BY 1,2
	ORDER BY 3 DESC
	LIMIT 1
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, SUM(il.unit_price*il.quantity) AS amount_spent
FROM `music store data analysis`.invoice i
JOIN `music store data analysis`.customer c ON c.customer_id = i.customer_id
JOIN `music store data analysis`.invoice_line il ON il.invoice_id = i.invoice_id
JOIN `music store data analysis`.track t ON t.track_id = il.track_id
JOIN `music store data analysis`.album2 alb ON alb.album_id = t.album_id
JOIN selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;

-- Q10: Write a query that determines the customer that has spent the most on music for each country. 
-- Write a query that returns the country along with the top customer and how much they spent. 
-- For countries where the top amount spent is shared, provide all customers who spent this amount.

WITH Customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending,
	    ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo 
		FROM `music store data analysis`.invoice
		JOIN `music store data analysis`.customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 4 ASC,5 DESC)
SELECT * FROM Customter_with_country WHERE RowNo <= 1

-- Q11: find out the most popular music Genre for each country. We determine the most popular genre as the genre 
-- with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
-- the maximum number of purchases is shared return all Genres.

 WITH popular_genre AS 
(
    SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, genre.name, genre.genre_id, 
	ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo 
    FROM `music store data analysis`.invoice_line 
	JOIN `music store data analysis`.invoice ON invoice.invoice_id = invoice_line.invoice_id
	JOIN `music store data analysis`.customer ON customer.customer_id = invoice.customer_id
	JOIN `music store data analysis`.track ON track.track_id = invoice_line.track_id
	JOIN `music store data analysis`.genre ON genre.genre_id = track.genre_id
	GROUP BY 2,3,4
	ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM popular_genre WHERE RowNo <= 1