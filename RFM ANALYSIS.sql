-- Let's check total no. row in dataset
select count(*) from data_csv dc ;

-- Checking data columns and patterns
select * from data_csv dc;

-- Here's InvoiceDate doesn't seems good for processing
-- So InvoiceDate should be cleaned by removing time from it
-- Let's check whether our data set contains any null data
select count(*) from (select * from data_csv dc) where InvoiceNo = '' or InvoiceNo ISNULL; -- 0
select count(*) from (select * from data_csv dc) where CustomerID = '' or CustomerID ISNULL; -- 135080
select count(*) from (select * from data_csv dc) where Quantity = '' or Quantity ISNULL; -- 0
select count(*) from (select * from data_csv dc) where InvoiceDate = '' or InvoiceDate ISNULL; -- 0
select count(*) from (select * from data_csv dc) where UnitPrice = '' or UnitPrice ISNULL; -- 0

-- Cleaning Date fromat
select InvoiceNo, CustomerID, Quantity, UnitPrice,
printf('%04d-%02d-%02d',
                 substr(InvoiceDate, instr(InvoiceDate, ' ')-4, 4),
                 substr(InvoiceDate, 0, instr(InvoiceDate, '/')), 
                 substr(InvoiceDate, instr(InvoiceDate, '/')+1, instr(substr(InvoiceDate, instr(InvoiceDate, '/')+1), '/')-1)
               ) as ConvertedDate
from data_csv dc where CustomerID is not '';

-- Generating Recency by grouping rows on CustomerID
select CustomerID, julianday(date("now")) - julianday(max(ConvertedDate)) as Recency
from (select InvoiceNo, CustomerID, Quantity, UnitPrice,
printf('%04d-%02d-%02d',
                 substr(InvoiceDate, instr(InvoiceDate, ' ')-4, 4),
                 substr(InvoiceDate, 0, instr(InvoiceDate, '/')), 
                 substr(InvoiceDate, instr(InvoiceDate, '/')+1, instr(substr(InvoiceDate, instr(InvoiceDate, '/')+1), '/')-1)
               ) as ConvertedDate
from data_csv dc where CustomerID is not '')
group by CustomerID;

-- Generating frequency by grouping rows on CustomerID
select CustomerID, count(distinct InvoiceNo) as Frequency
from (select InvoiceNo, CustomerID, Quantity, UnitPrice,
printf('%04d-%02d-%02d',
                 substr(InvoiceDate, instr(InvoiceDate, ' ')-4, 4),
                 substr(InvoiceDate, 0, instr(InvoiceDate, '/')), 
                 substr(InvoiceDate, instr(InvoiceDate, '/')+1, instr(substr(InvoiceDate, instr(InvoiceDate, '/')+1), '/')-1)
               ) as ConvertedDate
from data_csv dc where CustomerID is not '')
group by CustomerID
order by Frequency DESC;

-- Generating Monetary by grouping rows on CustomerID
select CustomerID, sum(Quantity * UnitPrice) as Monetary
from (select InvoiceNo, CustomerID, Quantity, UnitPrice,
printf('%04d-%02d-%02d',
                 substr(InvoiceDate, instr(InvoiceDate, ' ')-4, 4),
                 substr(InvoiceDate, 0, instr(InvoiceDate, '/')), 
                 substr(InvoiceDate, instr(InvoiceDate, '/')+1, instr(substr(InvoiceDate, instr(InvoiceDate, '/')+1), '/')-1)
               ) as ConvertedDate
from data_csv dc where CustomerID is not '')
group by CustomerID;

-- Calculating recency percent rank
select *,
PERCENT_RANK() over (order by Recency) as rfm_rec 
from (select CustomerID, julianday(date("now")) - julianday(max(ConvertedDate)) as Recency
from (select InvoiceNo, CustomerID, Quantity, UnitPrice,
printf('%04d-%02d-%02d',
                 substr(InvoiceDate, instr(InvoiceDate, ' ')-4, 4),
                 substr(InvoiceDate, 0, instr(InvoiceDate, '/')), 
                 substr(InvoiceDate, instr(InvoiceDate, '/')+1, instr(substr(InvoiceDate, instr(InvoiceDate, '/')+1), '/')-1)
               ) as ConvertedDate
from data_csv dc where CustomerID is not '')
group by CustomerID)
order by Recency desc

-- Calculating frequency percent rank
select *,
PERCENT_RANK() over (order by Frequency) as rfm_freq 
from (select CustomerID, count(distinct InvoiceNo) as Frequency
from (select InvoiceNo, CustomerID, Quantity, UnitPrice,
printf('%04d-%02d-%02d',
                 substr(InvoiceDate, instr(InvoiceDate, ' ')-4, 4),
                 substr(InvoiceDate, 0, instr(InvoiceDate, '/')), 
                 substr(InvoiceDate, instr(InvoiceDate, '/')+1, instr(substr(InvoiceDate, instr(InvoiceDate, '/')+1), '/')-1)
               ) as ConvertedDate
from data_csv dc where CustomerID is not '')
group by CustomerID)
order by Frequency desc

-- Calculating monetary percent rank
select *,
PERCENT_RANK() over (order by Monetary) as rfm_mon 
from (select CustomerID, sum(Quantity * UnitPrice) as Monetary
from (select InvoiceNo, CustomerID, Quantity, UnitPrice,
printf('%04d-%02d-%02d',
                 substr(InvoiceDate, instr(InvoiceDate, ' ')-4, 4),
                 substr(InvoiceDate, 0, instr(InvoiceDate, '/')), 
                 substr(InvoiceDate, instr(InvoiceDate, '/')+1, instr(substr(InvoiceDate, instr(InvoiceDate, '/')+1), '/')-1)
               ) as ConvertedDate
from data_csv dc where CustomerID is not '')
group by CustomerID)
order by Monetary desc

-- Let's merge the above query and create a single query to get table with rfm rank data
select *, cast (r_rank||f_rank||m_rank as int) as rfm_score from (select CustomerID,
	case
		when rfm_Recency <= 0.25 then 1
		when rfm_Recency > 0.25 and rfm_Recency <= 0.50 then 2
		when rfm_Recency > 0.50 and rfm_Recency <= 0.75 then 3
		else 4 end as r_rank,
	case
		when rfm_Frequency <= 0.25 then 1
		when rfm_Frequency > 0.25 and rfm_Frequency <= 0.50 then 2
		when rfm_Frequency > 0.50 and rfm_Frequency <= 0.75 then 3
		else 4 end as f_rank,
	case
		when rfm_Monetary <= 0.25 then 1
		when rfm_Monetary > 0.25 and rfm_Monetary <= 0.50 then 2
		when rfm_Monetary > 0.50 and rfm_Monetary <= 0.75 then 3
		else 4 end as m_rank
from (select CustomerID,
	PERCENT_RANK() over (order by Recency desc) as rfm_Recency, 
    PERCENT_RANK() over (order by Frequency) as rfm_Frequency, 
    PERCENT_RANK() over (order by Monetary) as rfm_Monetary 
from (
	select CustomerID, 
		julianday(date("now")) - julianday(max(ConvertedDate)) as Recency,
		count(distinct InvoiceNo) as Frequency,
		sum(Quantity * UnitPrice) as Monetary
	from (
		select InvoiceNo, CustomerID, Quantity, UnitPrice,
			printf('%04d-%02d-%02d',
				substr(InvoiceDate, instr(InvoiceDate, ' ')-4, 4),
				substr(InvoiceDate, 0, instr(InvoiceDate, '/')), 
				substr(InvoiceDate, instr(InvoiceDate, '/')+1, instr(substr(InvoiceDate, instr(InvoiceDate, '/')+1), '/')-1)) as ConvertedDate
		from data_csv dc where CustomerID is not '')
		group by CustomerID
))
order by r_rank desc, f_rank desc, m_rank desc)

