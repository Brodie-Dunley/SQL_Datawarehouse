# SQL_Datawarehouse
Creating a star schema dimensional model data warehouse/data mart to meet specific business requirements

I have broken the queries up into multiple pieces for better reading ability of each stage of the process. I have also included a full script that will compile the entire process at once. 

The business requirments are as follows:

We would like to track sales information for WideWorldImporters. We would like to analyze which products are being ordered to determine how things like brand, colour, and price may impact gross sales. In particular, we would like to identify preferences for specific customers so that we may more effectively predict which products they may be interested in. Similarly, we would like to be able to determine if certain cities have brand, colour, and price preferences. We would also like to determine whether certain salespeople have more success selling certain products, selling to certain customers, or selling in certain cities. We would also to determine whether certain suppliers products show more successful sales, and which customers and cities they are most successful in.  We need to track the date of each order to be able to track the impact of our change over time

**Requirement 1:**
- Build and execute the SQL script required to build the tables needed for this data warehouse star schema model. Ensure the appropriate indexes are optimized for users to analyze their business by seeking records in dimension tables(s) and then seek their corresponding/matching records in the related fact table

**Requirement 2:**
- Create a stored procedure to insert into the date dimension table

**Requirement 3:**
- Write a query that will return Customer, City, Salespeople, Products, Suppliers and dates for Order Facts using this dimension model database. Come up with your own scenario/business problem for this query. I wanted to determine the best sales person to sell a particular product during the holiday season. This would help the business determine what product to try to sell and allow them to increase stock during that time period. Also, they can determine which cities in the past have sold more so they can be more efficient in their product distribution.

**Requirement 4:**
- Create stage tables to insert the extracted data into, and Write stored procedures that will obtain all the required data from the following source data sets from WideWorldImporters :
    •	Customers – Query that joins Customers, CustomerCategories, Cities, StateProvinces, and Countries.
    •	Products – Query that joins StockItems and Colours
    •	Salespeople – Query of People where IsSalesperson is 1
    •	Orders – Query that joins Orders, OrderLines, Customers, and People, and accepts an @OrderDate as a parameter, and only selects records that match that date.
    •	Suppliers – Query that joins Suppliers and SupplierCategories (Business Analyst and SME review of the Supplier source tables suggests that SupplierCategory might also influence sales orders, so please add the SupplierCategoryName field to the appropriate table in the dimensional model).

**Requirement 5:**
- Create the PreLoad staging tables that match the structure of the destination (dim) tables, and Stored Procedures to perform the transformations of the source to destination data.  Include in the transformations:
	  - Updating any SCD’s that require it.
    - For SCD 1 dimensions, create and use a Sequence to set the dimension business key to the NEXT VALUE for any newly added records (ie. did NOT EXIST before), and use the existing surrogate key if a record already exists when updating it from the stage table.
    - For SCD 2 dimensions, add updated records, add existing records and expire as necessary, create newly added records (ie. Did NOT EXIST before), and expire missing records.
    	  - When there is a match, but no non-key attributes have changed, we add the record as-is so it is available for our fact transform.
    	  - When there is a match and a non-key attribute has changed, we create a new record and expire the previous record.
        - When there is no match in the data mart, we create a new record.
    	  - When there is no match in our extract for a record in the data mart, we expire the existing record.

    - A simple validation error if there are no records found, where appropriate.
  
**Requirement 6:**
- Create stored procedures that will load the dimension tables with any changed records, and load the fact table in the WideWorldImporters Data mart/Data warehouse.

**Requirement 7:**
- Execute the above procedures for 4 days worth of Orders to load the Data Mart (2013-01-01 to 2013-01-04).
- Run the query that you created in Requirement 3 to return Customer, City, Salespeople, Products, suppliers and dates for Order facts using this dimensional table
