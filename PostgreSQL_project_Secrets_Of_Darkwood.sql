	/* Project "Secrets of Darkwood"
The aim of the project is to study the influence of the characteristics of players 
and their game characters on the purchase of in-game currency "paradise petals", 
as well as to evaluate the activity of players when making in-game purchases.
Selling "paradise petals" is the main source of income for the development team. 
The game team plans to attract paying players and promote the purchase of epic items through advertising. 

Several tasks needed to be solved:
- find out what proportion of players buy the in-game currency "paradise petals" for real money 
and whether the proportion of paying players depends on the character's race;
- study in detail how the purchase of epic items occurs in the game.

Author: Nikita Logunov
Date: 22.04.2025

*/

-- Part 1. Exploratory data analysis
-- Task 1. Study of the share of paying players

-- 1.1. Share of paying users for all data:
SELECT  users_total ,
		paying_users ,
		ROUND ( paying_users :: numeric / users_total , 2 ) AS paying_users_rate --calculation of the share of paying players from all users
FROM (
	SELECT COUNT ( id ) AS users_total , -- total number of players
		( SELECT COUNT ( id ) FROM fantasy .users​ WHERE payer = 1 ) AS paying_users --counting the number of paying players
	FROM fantasy .users​
) AS payers ;

-- 1.2. Share of paying users by character race:
WITH count_total_users AS (
	SELECT  race_id ,
			COUNT ( id ) AS total_users --calculation of the total number of players by character race
	FROM fantasy .users​
	GROUP BY race_id ),
count_paying_users AS (
	SELECT  race_id ,
			COUNT ( id ) AS paying_users --counting the number of paying players by character race
	FROM fantasy .users​
	WHERE payer = 1
	GROUP BY race_id
	ORDER BY paying_users DESC )
SELECT  t . race_id ,
		r . race ,
		p . paying_users ,
		t . total_users ,
		ROUND ( p . paying_users :: numeric / t . total_users , 3 ) AS paying_users_rate --calculation of the share of paying players by character race
FROM count_total_users AS t
FULL JOIN count_paying_users AS p using ( race_id )
LEFT JOIN fantasy . race AS r using ( race_id )
ORDER BY paying_users_rate DESC;		

-- Task 2. Research of in-game purchases
-- 2.1. Statistical indicators for the amount field
SELECT  COUNT (*) AS transactions_total , --total number of purchases
		SUM ( amount ) AS amount_total , --total cost of all purchases
		MIN ( amount ) AS min_amount , -- minimum
		MAX ( amount ) AS max_amount , -- and the maximum purchase amount
		ROUND ( AVG ( amount ):: numeric , 2 ) AS avg_amount , --average purchase price
		ROUND (( PERCENTILE_cont ( 0.5 ) WITHIN GROUP ( ORDER BY amount )):: numeric , 2 ) AS mediana_amount , -- median
		ROUND ( STDDEV ( amount ):: NUMERIC , 2 ) AS stand_dev_amount --standard deviation of purchase price
FROM fantasy . events ;

-- 2.2: Abnormal Zero Purchases:

WITH zero_cost_nums AS (
	SELECT ( SELECT count ( transaction_id ) FROM fantasy . events ) AS transactions_total , --calculates the total number of purchases
			COUNT ( transaction_id ) AS zero_cost_num --counting the number of purchases with zero cost
	FROM fantasy .events​
	WHERE amount = 0 )
SELECT  zero_cost_num ,
		zero_cost_num * 1.0 / transactions_total AS zero_cost_rate --calculation of the share of purchases with zero cost
FROM zero_cost_nums ;

-- 2.3: Comparative analysis of the activity of paying and non-paying players :
WITH transactions_by_users AS (
	SELECT  DISTINCT u . id ,
		u . payer ,
		COUNT ( e . transaction_id ) AS count_transaction , --counts the number of purchases of each player
		SUM ( e . amount ) AS sum_amount --calculating the amount of purchases for each player
	FROM fantasy .users​ AS u
	LEFT JOIN fantasy .events​ AS e using ( id )
	WHERE e . amount > 0 --we exclude zero purchases
	GROUP BY u.id , u.payer )​​​​
SELECT CASE WHEN payer = 1 THEN 'Paying'
		ELSE 'Non-paying'
		END AS user_status , --divide users into two groups depending on the payer field
		COUNT ( id ) AS user_num , --number of players in the group
		ROUND ( AVG ( count_transaction ), 2 ) AS avg_count_transaction , --average number of purchases per player per group
		ROUND ( AVG ( sum_amount ):: numeric , 2 ) AS avg_sum_amount --average total purchase value per player across the group
FROM transactions_by_users
GROUP BY user_status ;

-- 2.4: Popular Epic Items :
SELECT  i . item_code ,
		i . game_items ,
		COUNT ( e . item_code ) AS sold_item_count , --counts the number of epic items purchased
		ROUND ( COUNT ( e . item_code )* 1.0 / ( SELECT COUNT ( item_code ) FROM fantasy .events​ WHERE amount > 0 ), 7 ) AS rate_of_sold_item , --share of purchased epic items from the total quantity, excluding zero values
		ROUND ( COUNT ( DISTINCT e . id )* 1.0 / ( SELECT COUNT ( DISTINCT id ) FROM fantasy .events​ WHERE amount > 0 ), 7 ) AS rate_of_buying_users --the percentage of users who have purchased this epic item at least once
FROM fantasy items​ i
JOIN fantasy .events​ e using ( item_code )
WHERE e . amount > 0 --we exclude zero purchases
GROUP BY i . item_code , i . game_items --all calculations are conducted in the context of the category "epic items"
ORDER BY rate_of_buying_users DESC ;

-- Part 2. Solving ad hoc problems

-- Task 1. Dependence of players' activity on the character's race:
WITH count_users AS (
	SELECT  r . race_id ,
			r . race ,
			COUNT ( DISTINCT u . id ) AS count_users , --counts the number of players by race
			COUNT ( DISTINCT e . id ) AS count_buying_users  --counting the number of players who made a purchase, by race
	FROM fantasy .users​ u
	LEFT JOIN fantasy .events​ e using ( id )
	LEFT JOIN fantasy . race r using ( race_id )
	GROUP BY  r . race_id , r . race
),
count_paying_users AS (
	SELECT  u . race_id ,
			COUNT ( e . id ) AS paying_users_count --counting the number of paying customers
	FROM fantasy .users​ u
	LEFT JOIN fantasy .events​ e using ( id )
	WHERE u . payer = 1 -- filtering paying/non-paying
	GROUP BY u . race_id
),
count_users2 AS (
	SELECT  cu . race_id ,
			cu . race ,
			cu . count_users ,
			cu . count_buying_users ,
			ROUND ( cu . count_buying_users * 1.0 / cu . count_users , 3 ) AS rate_of_buying_users , --calculates the share of players who made a purchase from all players by race
			ROUND ( cpu . paying_users_count * 1.0 / cu . count_buying_users , 3 ) AS rate_of_payers_from_buying_users  --calculation of the share of paying players from players who made a purchase, by race
	FROM count_users cu
	LEFT JOIN count_paying_users cpu using ( race_id )
	ORDER BY rate_of_payers_from_buying_users DESC
),
transactions_by_users AS (
	SELECT  u . id ,
			u . race_id ,
			COUNT ( e . transaction_id ) AS count_transaction_id , -- counts the number of purchases for each player
			--AVG(e.amount)AS avg_amount, -- calculation of the average cost of purchasing a player
			SUM ( e . amount ) AS sum_amount --calculate the sum of all player purchases
	FROM fantasy .users​ u
	LEFT JOIN fantasy .events​ e using ( id )
	GROUP BY  u . id ,
			u . race_id
),
transactions_by_users2 AS (
	SELECT  race_id ,
			ROUND ( AVG ( count_transaction_id ):: numeric , 2 ) AS avg_transactions_by_user , -- calculation of the average number of purchases
			ROUND (( AVG ( sum_amount )/ AVG ( count_transaction_id )):: numeric , 2 ) AS avg_amount_by_user , -- calculation of the average purchase cost per player
			ROUND ( AVG ( sum_amount ):: numeric , 2 ) AS avg_sum_amount_by_user -- calculation of the average total cost of all purchases per player
	FROM transactions_by_users
	GROUP BY race_id -- all aggregations by race
)
SELECT  cu2 . race_id ,
		cu2 . race ,
		cu2 . count_users ,
		cu2 . count_buying_users ,
		cu2 . rate_of_buying_users ,
		cu2 . rate_of_payers_from_buying_users ,
		tbu . avg_transactions_by_user ,
		tbu . avg_amount_by_user ,
		tbu . avg_sum_amount_by_user
FROM count_users2 cu2
FULL JOIN transactions_by_users2 tbu USING ( race_id )
ORDER BY cu2 . rate_of_payers_from_buying_users DESC ;

-- Task 2: Purchase frequency
WITH days_between_transactions AS (
	SELECT  t1 .id,
			u .payer,
			COUNT ( t1.transaction_id ) AS count_transactions , --counts the number of purchases for each user
			AVG ( t1 .days_from_previous_transaction) AS avg_days_between_transactions --calculate the average number of days between purchases
	FROM ( SELECT id,
				transaction_id,
				date :: date , --cast to date type
				date :: date - LAG ( date :: date ) OVER ( PARTITION BY id ORDER BY date :: date ) AS days_from_previous_transaction --calculate the time interval in days before each previous purchase using the offset window function
		FROM fantasy.events
		WHERE amount > 0 --we exclude zero purchases
		GROUP BY id, transaction_id
		ORDER BY id) AS t1
		JOIN fantasy.users AS u USING (id)
		GROUP BY t1.id, u.payer
		HAVING COUNT (t1.transaction_id) >= 25 --we leave only players with 25 or more purchases
		ORDER BY avg_days_between_transactions
),
prepared_data AS (
	SELECT *,
			NTILE ( 3 ) OVER ( ORDER BY avg_days_between_transactions ASC ) AS frequency_group --we divide players into three approximately equal groups by the average number of days between purchases
	FROM days_between_transactions
),
payers_count AS (
	SELECT frequency_group,
			COUNT ( DISTINCT id) AS count_payers -- subset of the number of paying players in each group
	FROM prepared_data
	WHERE payer = 1 --we select paying players
	GROUP BY frequency_group
			
),
frequency_groups_noname AS (
	SELECT frequency_group,
		COUNT ( DISTINCT id) AS count_users, --number of players in each group
		count_payers, --number of paying players in each group
		ROUND (count_payers * 1.0 / COUNT ( DISTINCT id), 3 ) AS rate_of_payers_from_users, --share of paying players from the total number of players in the group
		ROUND ( AVG (count_transactions), 2 ) AS avg_count_transactions, --average number of purchases per player per group
		ROUND ( AVG (avg_days_between_transactions), 2 ) AS avg_days_between_transactions --average number of days between purchases by group
	FROM prepared_data AS pd
	LEFT JOIN payers_count pc USING (frequency_group)
	GROUP BY frequency_group, count_payers
)
SELECT  CASE WHEN frequency_group = 1 THEN 'high frequency'
			WHEN frequency_group = 2 THEN 'moderate frequency'
			ELSE 'low frequency'
		END AS frequency_group, --we name the groups by purchase frequency
		count_users,
		count_payers,
		rate_of_payers_from_users,
		avg_count_transactions,
		avg_days_between_transactions
FROM frequency_groups_noname ;

/*
Part 3. Conclusions and analytical comments

1. Results of the exploratory data analysis:

1.1 What is the proportion of paying players for the entire game and how does the character's race affect this indicator?
The share of paying users according to all data is 18%. In terms of character race, there are more paying players among characters of the Demon race - their share is 19.4%, but this is the smallest race. It is worthwhile to direct efforts to ensure that players choose this race more often.

1.2. How many in-game purchases were made and what can be said about their cost (minimum and maximum, is there a difference between the average and median, what is the spread of the data)?
A total of 1,307,678 in-game purchases were made for a total of 6,86,615,040. The minimum purchase value was 0, and the maximum was 486,615.1. The large difference between the average value (525.69) and the median (74.86) indicates that although the data range is very large (average deviation 2,517), half of the purchases do not exceed 74.86 in value.

1.3. Are there any abnormal purchases by value? If so, how many are there?
907 purchases with abnormal value were found. Their share among the total number of purchases is 0.069%.

1.4. How many players make in-game purchases and how actively? Compare the behavior of paying and non-paying players.
There are almost 5 times fewer paying players than non-paying ones. Paying players make an average of 16 purchases (~15%) less than non-paying ones, but the total cost of these purchases is on average 14% higher.

1.5. Are there any popular epic items that are purchased most often?
TOP 3 sales of epic items and the percentage of purchases of each item from the total number of purchases:
Book of Legends 77% - bought by 88% of players
Bag of Holding 21% - 87% of players bought
Necklace of Wisdom 1.1% - bought by 12% of players

2. Results of solving ad hoc problems

2.1. Is there a dependence between players' activity in making in-game purchases and the character's race?
The share of players making purchases from the total number of players practically does not depend on the race of the character. The most active buyers are “orcs” (63% of “orc” players buy epic items), although there are only 3% more buyers among them than among “demons” (60% of “demon” players make purchases, and among those making purchases, “demon” has the largest share of paying players - 32.3%). “Northman” characters spend the most on purchasing epic items. But Human is in the lead in the number of epic item purchases: an average of 75 purchases. While “demon” players buy only 47 items on average. It can be argued that playing as a Human is significantly more difficult (1.6 times more difficult) than as a “demon”.
The hypothesis that players' purchase of ethical items does not depend on their character's race has not been confirmed.

2.2 How often do players make purchases?
To divide players by purchase frequency, three groups were identified:
high frequency, moderate frequency, low frequency. The high frequency group averaged 3.3 days between purchases, which is 2.3 times more often than the moderate frequency group (7.5 days) and 4 times more often than the low frequency group (13.3 days).
Moreover, the average number of purchases per player in the high purchase frequency group is 390.7, which is 6.5 times more than in the moderate purchase frequency group (59), and 11.5 times more than in the low purchase frequency group (34).
In the high purchase frequency group, the share of paying players from the total number of players is higher (18.4%) than in the moderate and low purchase frequency groups (17.5% and 16.8%, respectively).

3. General conclusions and recommendations
You can make the game more difficult for the “Demon” race characters, then the “Demon” players (who have the highest share of those paying) will start buying more epic items and, therefore, buy more “paradise petals” currency for real money.
The top 3 most popular epic items can be made more expensive, and at the same time motivate players to buy other items more often.
To increase the number of paying players, you can create and promote new epic items that will make the game much easier, but which can only be purchased with real money. Or which will be expensive, and then players will have to buy more paradise petals.
“Northman” characters spend the most on purchasing epic items, it is possible to attract more users to play for these characters.

The most numerous race by the number of players buying items and by the number of items purchased is Human. We need to give them a discount or other offer to buy paradise petals for real money - to increase the share of paying users.

For players in a group with a high frequency of purchases, you can come up with a special offer or send out reminder notifications so that they enter the game even more often.
You can come up with an award for this group, a virtual medal “SUPER-PLAYER”, for example.
*/