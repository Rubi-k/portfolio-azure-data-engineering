
-- Gold Validation Queries (MovieLens — Reduced Subset)

-- 1) Ratings volume by genre
SELECT genre, n_ratings, ROUND(avg_rating, 3) AS avg_rating
FROM gold_avg_rating_per_genre
ORDER BY avg_rating DESC, n_ratings DESC
LIMIT 50;

-- 2) Top movies per decade (sanity)
SELECT * FROM gold_top_movies_per_decade ORDER BY decade, rank;
