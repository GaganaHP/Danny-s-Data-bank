USE data_bank;

select * from customer_nodes;
select * from customer_transactions;
select * from regions;

# A. Customer Node Exploration

# 1. How many unique nodes are there on the Data Bank system?
select count(distinct node_id) as unique_nodes from customer_nodes;



# 2. What is the number of nodes per region?
select r.region_id, region_name, count(node_id) as no_of_nodes from customer_nodes c join regions r using(region_id)
group by r.region_id, region_name
order by r.region_id;



# 3. How many customers are allocated to each region?
select r.region_id, region_name, count(customer_id) as no_of_customers from customer_nodes c join regions r using(region_id)
group by r.region_id, region_name
order by r.region_id;



# 4. How many days on average are customers reallocated to a different node?
# my query
select node_id, round(avg(datediff(end_date, start_date)), 2) as avg_days from customer_nodes
group by node_id;

# chatgpt
SELECT ROUND(AVG(DATEDIFF(end_date, start_date)), 2) AS avg_days_reallocated
FROM data_bank.customer_nodes
WHERE end_date IS NOT NULL;



# 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
with customer_stay as (
select region_id, datediff(end_date, start_date) as no_of_days from customer_nodes
where end_date is not null
);



# B. Customer Transactions

# 1. What is the unique count and total amount for each transaction type?
select txn_type, count(distinct(customer_id)) as unique_customers, sum(txn_amount) as total_amount from customer_transactions
group by txn_type;



# 2. What is the average total historical deposit counts and amounts for all customers?
with deposit as (
select customer_id, count(txn_type) as count_deposit, sum(txn_amount) as total_deposit from customer_transactions
where txn_type in ('deposit')
group by customer_id)
select avg(count_deposit) as avg_count_deposit,
	   avg(total_deposit) as avg_total_deposit from deposit;


# 3. For each month - how many Data Bank customers make more than 1 deposit 
# and either 1 purchase or 1 withdrawal in a single month?

with info as (
select customer_id, date_format(txn_date, '%Y-%m') as txn_month,
	sum(case when txn_type = 'deposit' then 1 else 0 end) as deposit_count,
    sum(case when txn_type = 'withdrawal' then 1 else 0 end) as withdrawal_count,
    sum(case when txn_type = 'purchase' then 1 else 0 end) as purchase_count 
from customer_transactions
group by customer_id, txn_month)
select count(customer_id) as customers, txn_month from info
where deposit_count > 1 and (withdrawal_count >=1 or purchase_count>= 1)
group by txn_month
order by txn_month;



# 4. What is the closing balance for each customer at the end of the month?
with info as (
select customer_id, date_format(txn_date,'%Y-%m') as txn_month,
	sum(case when txn_type = 'deposit' then txn_amount else 0 end) as total_deposit,
    sum(case when txn_type = 'withdrawal' then txn_amount else 0 end) as total_withdrawal,
    sum(case when txn_type = 'purchase' then txn_amount else 0 end) as total_purchase
from customer_transactions
group by customer_id, txn_month)
select customer_id, txn_month, total_deposit, total_withdrawal, total_purchase, 
	   (total_deposit -(total_withdrawal + total_purchase)) as net_balance,
       sum(total_deposit -(total_withdrawal + total_purchase)) over(partition by customer_id order by txn_month) as closing_balance
from info
order by customer_id, txn_month;


# 5. What is the percentage of customers who increase their closing balance by more than 5%?
 