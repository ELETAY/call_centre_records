#check csv data loaded 
SELECT * FROM call_center
ORDER BY customer_name
LIMIT 10;

/*cleaning data by converting the call_timestamp from varchar to date and changing csat_score from 0 to null */
SET SQL_SAFE_UPDATES = 0;
UPDATE call_center SET call_timestamp = str_to_date(call_timestamp, "%m/%d/%Y")
UPDATE call_center SET csat_score = NULL WHERE csat_score = 0;
SET SQL_SAFE_UPDATES = 1;

/*check statistics of call_center table*/
SELECT COUNT(*) AS cc_row FROM call_center; #32941
SELECT COUNT(*) AS cc_col FROM information_schema.columns WHERE table_name = 'call_center' ; #12

#billing qns comprises 71% of the total reasons for call, followed by payments and service outage.
SELECT DISTINCT reason, COUNT(*), round(COUNT(*)/(SELECT COUNT(*)FROM call_center)*100,2) AS pct_count
FROM call_center
GROUP BY 1
ORDER BY 3 DESC;

#highest percentage of contact are from call-center, and it has highest avg call duration.
SELECT CHANNEL, round(COUNT(*)*100/ (select COUNT(*) from call_center),2) as percent_calls, round(AVG(call_duration),2) AS avg_call_duration FROM call_center GROUP BY 1 ORDER BY 2 DESC;

#avg call duration is around 24-25 min, service outage taking up the longest call duration. 
SELECT call_center, reason, COUNT(*), MIN(call_duration) AS shortest_call, MAX(call_duration) AS longest_call, AVG(call_duration) FROM call_center GROUP BY 1,2 ORDER BY 1, 6 desc; 

#top 3 states with highest num of calls
SELECT state, COUNT(*) as num_calls FROM call_center
GROUP BY 1
ORDER BY 2 DESC
LIMIT 3

#find out how many calls received each day of the week.
SELECT DAYNAME(call_timestamp) AS day_of_call, count(*) AS call_count FROM call_center GROUP BY 1 ORDER BY 2 DESC;

#tues - thurs see longer overall calltimes. to cope with heavy calls, make sure to have back up staff in case main staff takes urgent leave, mc.
SELECT call_timestamp, DAYNAME(call_timestamp) AS day_of_call, 
SUM(call_duration) AS ttl_call_duration, 
MAX(call_duration) OVER(PARTITION BY call_timestamp) AS max_call_duration
FROM call_center
GROUP BY 1,2
ORDER BY 3 DESC;

# check SLA performance of each call center, ideal is within sla.
SELECT call_center, response_time, COUNT(*)  AS COUNT, ROUND(COUNT(*)*100/SUM(COUNT(*)) OVER (PARTITION BY call_center),2) AS percent_count
FROM call_center GROUP BY 1,2 ORDER BY 1,3 DESC;

#find out csat score statistics 
SELECT call_center, COUNT(*) AS call_count, MIN(csat_score) AS min_csat,  MAX(csat_score) AS max_csat, AVG(csat_score) AS avg_csat
FROM call_center
WHERE csat_score IS NOT NULL
GROUP BY 1 ORDER BY 5 desc;

#find out csat score statistics 
CREATE table senti_calltime1 as
SELECT state,  
CASE 
WHEN sentiment IN ("Negative", "Very Negative") THEN "1. Negative" 
WHEN sentiment = "Neutral" THEN "2. Neutral" 
WHEN sentiment IN ("Positive", "Very Positive") THEN "3. Positive" END AS sentiment1, 
COUNT(*) AS count, round(COUNT(*)*100/SUM(COUNT(*)) OVER (PARTITION BY state),2) as percent_calls, sum(call_duration), AVG(call_duration)
FROM call_center
GROUP BY 1,2
ORDER BY 1,2;

#the longest call duration with negative sentiment
SELECT * FROM senti_calltime1
WHERE sentiment1 like ("%Neg%")
ORDER BY 6 DESC
LIMIT 3;

#the longest call duration with positive sentiment
SELECT * FROM senti_calltime1
WHERE sentiment1 like ("%Pos%")
ORDER BY 6 DESC
LIMIT 3;