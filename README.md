# Project PostgreSQL_project: Secrets_Of_Darkwood

Here I demonstrate using Postgres. Aggregation, filtering, CTE, subqueries, window functions, merging etc.

The aim of the project is to study the influence of the characteristics of players and their game characters on the purchase of in-game currency "paradise petals", as well as to evaluate the activity of players when making in-game purchases.

Selling "paradise petals" is the main source of income for the development team. The game team plans to attract paying players and promote the purchase of epic items through advertising.

Several tasks needed to be solved:
- find out what proportion of players buy the in-game currency "paradise petals" for real money and whether the proportion of paying players depends on the character's race;
- study in detail how the purchase of epic items occurs in the game.

Conclusions and analytical comments:

1. Results of the exploratory data analysis:

1.1 What is the proportion of paying players for the entire game and how does the character's race affect this indicator?

The share of paying users according to all data is 18%. In terms of character race, there are more paying players among characters of the Demon race - their share is 19.4%, but this is the smallest race. It is worthwhile to direct efforts to ensure that players choose this race more often.

1.2. How many in-game purchases were made and what can be said about their cost (minimum and maximum, is there a difference between the average and median, what is the spread of the data)?

A total of 1,307,678 in-game purchases were made for a total of 6,86,615,040. The minimum purchase value was 0, and the maximum was 486,615.1. The large difference between the average value (525.69) and the median (74.86) indicates that although the data range is very large (average deviation 2,517), half of the purchases do not exceed 74.86 in value.

1.3. Are there any abnormal purchases by value? If so, how many are there?

907 purchases with abnormal value were found. Their share among the total number of purchases is 0.069%.

1.4. How many players make in-game purchases and how actively? The behavior of paying and non-paying players.

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
