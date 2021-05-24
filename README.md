# Recency-Frequency-Monetary (RFM) analysis

A dataset in csv format contains all purchase transaction data, we calculated a score based on how recently the customer purchased, how often they make purchases and how much they spend in dollars on average on each purchase.

Using these scores, we segmented our customer list to:
 + How recent was the customer's last purchase?
 + How often did this customer make a purchase in a given period?
 + How much money did the customer spend in a given period?
 
 + A score from 1 to 4 is given, with 4 being the highest.
	- Recency : 4 is the recent purchase (lowest day difference between today and last purchase).
	- Frequency : 4 is the highest frequency with highest visit.
	- Monetary : 4 is the highest Monetary with highest purchased amount in dollars.
	
What can be found in this repository ?
| 1. | data.csv | (Our main dataset which we used for analysis) |
| 2. | RFM ANALYSIS.sql | (Sqlite script that we used to analyze our dataset and to generate result) |
| 3. | RFM ANALYSIS(data).xlsx | (Output data in formatted in rows and columns) |