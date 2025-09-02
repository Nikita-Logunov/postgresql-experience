/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: Никита Логунов
 * Дата: 22.04.2025
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:
SELECT  users_total,
		paying_users,
		ROUND(paying_users::numeric / users_total, 2) AS paying_users_rate --расчет доли платящих игроков из всех пользователей
FROM (
	SELECT COUNT(id) AS users_total, --подсчет общего кол-ва игроков
		(SELECT COUNT(id) FROM fantasy.users WHERE payer = 1) AS paying_users --подсчет количесва платящих игроков
	FROM fantasy.users
) AS payers;

-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
WITH count_total_users AS (
	SELECT  race_id,
			COUNT(id) AS total_users --подсчет общего кол-ва игроков в разрезе расы персонажа
	FROM fantasy.users
	GROUP BY race_id),
count_paying_users AS (
	SELECT  race_id,
			COUNT(id) AS paying_users --подсчет количесва платящих игроков в разрезе расы персонажа
	FROM fantasy.users
	WHERE payer = 1
	GROUP BY race_id
	ORDER BY paying_users DESC)
SELECT  t.race_id,
		r.race,
		p.paying_users,
		t.total_users,
		ROUND(p.paying_users::numeric / t.total_users, 3) AS paying_users_rate --расчет доли платящих игроков в разрезе расы персонажа
FROM count_total_users AS t
FULL JOIN count_paying_users AS p using(race_id)
LEFT JOIN fantasy.race AS r using(race_id)
ORDER BY paying_users_rate DESC;		

-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:
SELECT  COUNT(*) AS transactions_total, --общее количество покупок
		SUM(amount) AS amount_total, --суммарная стоимость всех покупок
		MIN(amount) AS min_amount, -- минимальная
		MAX(amount) AS max_amount, -- и максимальная стоимость покупки
		ROUND(AVG(amount)::numeric, 2) AS avg_amount, --среднее значение стоимости покупки
		ROUND((PERCENTILE_cont(0.5) WITHIN GROUP (ORDER BY amount))::numeric, 2) AS mediana_amount, -- медиана 
		ROUND(STDDEV(amount)::NUMERIC, 2) AS stand_dev_amount --стандартное отклонение стоимости покупки
FROM fantasy.events;

-- 2.2: Аномальные нулевые покупки:
WITH zero_cost_nums AS (
	SELECT  (SELECT count(transaction_id) FROM fantasy.events) AS transactions_total, --подсчет общего кол-ва покупок
			COUNT(transaction_id) AS zero_cost_num --подсчет  кол-ва покупок с нулевой стоимотью
	FROM fantasy.events
	WHERE amount = 0)
SELECT  zero_cost_num,
		zero_cost_num * 1.0 / transactions_total AS zero_cost_rate --расчет доли покупок с нулевой стоимостью
FROM zero_cost_nums;

-- 2.3: Сравнительный анализ активности платящих  и неплатящих игроков:
WITH transactions_by_users AS (
	SELECT  DISTINCT u.id,
		u.payer,
		COUNT(e.transaction_id) AS count_transaction, --подсчет кол-ва покупок каждого игрока
		SUM(e.amount) AS sum_amount --подсчет суммы покупок каждого игрока
	FROM fantasy.users AS u
	LEFT JOIN fantasy.events AS e using(id)
	WHERE e.amount > 0 --исключаем нулевые покупки
	GROUP BY u.id, u.payer)
SELECT CASE WHEN payer = 1 THEN 'Paying'
		ELSE 'Non-paying'
		END AS user_status, --разделяем пользователей на две группы в зависимости от поля payer
		COUNT(id) AS user_num, --количество игроков в разрезе группы
		ROUND(AVG(count_transaction), 2) AS avg_count_transaction, --среднее кол-во покупок на игрока в разрезе группы
		ROUND(AVG(sum_amount)::numeric, 2) AS avg_sum_amount --среднняя суммарная стоимость покупок на игрока в разрезе группы
FROM transactions_by_users
GROUP BY user_status;

-- 2.4: Популярные эпические предметы:
SELECT  i.item_code,
		i.game_items,
		COUNT(e.item_code) AS sold_item_count, --подсчет количества купленных эпических предметов
		ROUND(COUNT(e.item_code)*1.0 / (SELECT COUNT(item_code) FROM fantasy.events WHERE amount > 0), 7) AS rate_of_sold_item, --доля купленных эпических предметов от общего кол-ва за исключением нулевых значений
		ROUND(COUNT(DISTINCT e.id)*1.0 / (SELECT COUNT(DISTINCT id) FROM fantasy.events WHERE amount > 0), 7) AS rate_of_buying_users --доля пользователей, которые хоть раз купили этот эпический предмет
FROM fantasy.items i
JOIN fantasy.events e using(item_code)
WHERE e.amount > 0 --исключаем нулевые покупки
GROUP BY i.item_code, i.game_items --все подсчеты ведутся в разрезе категории "эпические предметы"
ORDER BY rate_of_buying_users DESC
LIMIT 10;	

-- Часть 2. Решение ad hoc-задач

-- Задача 1. Зависимость активности игроков от расы персонажа:
WITH count_users AS(
	SELECT  r.race_id,
			r.race,
			COUNT(DISTINCT u.id) AS count_users, --подсчет количества игроков в разрезе расы
			COUNT(DISTINCT e.id) AS count_buying_users  --подсчет количества игроков, совершивших покупку, в разрезе расы
	FROM fantasy.users u
	LEFT JOIN fantasy.events e using(id)
	LEFT JOIN fantasy.race r using(race_id)
	GROUP BY  r.race_id, r.race
),

count_paying_users AS(

	SELECT  u.race_id,
			COUNT(DISTINCT e.id) AS paying_buying_users_count --подсчет количества платящих покупателей
			--именно покупателей, так как здесь подсчет идет по уникальным id в таблице events,
			-- а игрок будет встречаться в этой таблице, только если он является покупателем
			--(если бы мы считали уникальыне id из таблицы users, то, действительно, нашли бы всех платящих игроков)
	FROM fantasy.users u
	LEFT JOIN fantasy.events e using(id)
	WHERE u.payer = 1 -- фильтрация платящий/неплатящий
	GROUP BY u.race_id
	ORDER BY u.race_id
),
count_users2 AS(
	SELECT  cu.race_id,
			cu.race,
			cu.count_users,
			cu.count_buying_users,
			ROUND(cu.count_buying_users * 1.0 / cu.count_users, 3) AS rate_of_buying_users, --расчет доли игроков, совершивших покупку, от всех игроков в разрезе расы
			ROUND(cpu.paying_buying_users_count * 1.0 / cu.count_buying_users, 3) AS rate_of_payers_from_buying_users  --расчет доли платящих игроков от игроков, совершивших покупку, в разрезе расы
	FROM count_users cu
	LEFT JOIN count_paying_users cpu using(race_id)
	ORDER BY rate_of_payers_from_buying_users DESC 
),
transactions_by_users AS(
	SELECT  u.id,
			u.race_id,
			COUNT(e.transaction_id) AS count_transaction_id, -- подсчет количества покупок по каждому игроку
			--AVG(e.amount)AS avg_amount, -- посчет средней стоимости покупки игрока
			SUM(e.amount) AS sum_amount --подсчет суммы всех покупок игрока
	FROM fantasy.users u
	LEFT JOIN fantasy.events e using(id)
	WHERE e.amount > 0 --исключаем нулевые покупки
	GROUP BY  u.id, u.race_id
	ORDER BY  u.id, u.race_id
), 
transactions_by_users2 AS(
	SELECT  race_id,
			ROUND(AVG(count_transaction_id)::numeric, 2) AS avg_transactions_by_user, -- подсчет среднего количества покупок 
			ROUND((AVG(sum_amount)/AVG(count_transaction_id))::numeric, 2) AS avg_amount_by_user, -- посчет средней стоимости покупки на одного игрока 
			ROUND(AVG(sum_amount)::numeric, 2) AS avg_sum_amount_by_user -- подсчет средней суммарной стоимости всех покупок на одного игрока
	FROM transactions_by_users
	GROUP BY race_id -- все агрегации в разрезе расы
)
SELECT  cu2.race_id,
		cu2.race,
		cu2.count_users,
		cu2.count_buying_users,
		cu2.rate_of_buying_users,
		cu2.rate_of_payers_from_buying_users,
		tbu.avg_transactions_by_user,
		tbu.avg_amount_by_user,
		tbu.avg_sum_amount_by_user
FROM count_users2 cu2
FULL JOIN transactions_by_users2 tbu USING(race_id)
ORDER BY cu2.rate_of_payers_from_buying_users DESC;
-- Задача 2: Частота покупок
WITH days_between_transactions AS(
	SELECT  t1.id,
			u.payer,
			COUNT(t1.transaction_id) AS count_transactions, --подсчет количества покупок для каждого пользователя
			AVG(t1.days_from_previous_transaction) AS avg_days_between_transactions --расчет среднего количества дней между покупками
	FROM (SELECT  id,
				transaction_id,
				date::date, --приведение к типу date
				date::date - LAG(date::date) OVER (PARTITION BY id ORDER BY date::date) AS days_from_previous_transaction --расчет интервала времени в днях до каждой предыдущей покупки с помощью оконной функции смещения
		FROM fantasy.events
		WHERE amount > 0 --исключаем нулевые покупки
		GROUP BY id, transaction_id
		ORDER BY id) AS t1 
		JOIN fantasy.users AS u USING (id)
		GROUP BY t1.id, u.payer
		HAVING COUNT(t1.transaction_id) >= 25 --оставляем только игроков с 25 и более покупками
		ORDER BY avg_days_between_transactions
),
prepared_data AS(
	SELECT  *,
			NTILE(3) OVER (ORDER BY avg_days_between_transactions ASC) AS frequency_group --разбиваем игроков на три примерно равные группы по среднему кол-ву дней между покупками
	FROM days_between_transactions
), 
payers_count AS(
	SELECT  frequency_group,
			COUNT(DISTINCT id) AS count_payers --подсет кол-ва платящих игроков в каждой группе
	FROM prepared_data
	WHERE payer = 1 --отбираем платящих игроков
	GROUP BY frequency_group
			
),
frequency_groups_noname AS(
	SELECT frequency_group,
		COUNT(DISTINCT id) AS count_users, --кол-во игроков в каждой  группе
		count_payers, --кол-во платящих игроков в каждой  группе
		ROUND(count_payers * 1.0 / COUNT(DISTINCT id), 3) AS rate_of_payers_from_users, --доля платящих игроков от общего кол-ва игроков в разрезе группы
		ROUND(AVG(count_transactions), 2) AS avg_count_transactions, --среднее кол-во покупок на игрока в разрезе группы
		ROUND(AVG(avg_days_between_transactions), 2) AS avg_days_between_transactions --среднее кол-во дней между покупками в разрезе группы
	FROM prepared_data AS pd
	LEFT JOIN payers_count pc USING (frequency_group)
	GROUP BY frequency_group, count_payers
)
SELECT  CASE WHEN frequency_group = 1 THEN 'high frequency' 
			WHEN frequency_group = 2 THEN 'moderate frequency' 
			ELSE 'low frequency'
		END AS frequency_group, --даем названия группам по частоте покупок
		count_users,
		count_payers,
		rate_of_payers_from_users,
		avg_count_transactions,
		avg_days_between_transactions
FROM frequency_groups_noname;

