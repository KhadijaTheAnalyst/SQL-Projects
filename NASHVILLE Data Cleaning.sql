/*

Data Cleaning

*/
------------ITS ALWAYS A GOOD IDEA TO MAKE A COPY OF ORIGINAL TABLE AND THEN WORK ON IT SO IF YOU MESS UP YOU HVAE A BACKUP-----------------
-- Lets Take a look to the data first 

SELECT *
FROM [Nashville Housing Data].dbo.[Nashville Housing Data for Data Cleaning]

/*
In the data I have found lots of rows are nulls in property address column 
lets try to populate it as it contains lots of data and we can't just ignore it.

While examining the data closely I have found the parcel ids have matching property addresses
so we can use it somehow to populate our property address columns for example 
check row 44 and 45. You can check this with self join.

*/

--Lets populate the proprty address column

SELECT *
FROM [Nashville Housing Data].dbo.[Nashville Housing Data for Data Cleaning]
WHERE PropertyAddress IS NULL
ORDER BY ParcelID
-- 29 rows founded that needds to be fixed. We can use self join here

SELECT na.ParcelID,na.PropertyAddress,nb.ParcelID,nb.PropertyAddress, ISNULL(na.PropertyAddress,nb.PropertyAddress) AS updated_address
FROM [Nashville Housing Data].dbo.[Nashville Housing Data for Data Cleaning] na
JOIN [Nashville Housing Data].dbo.[Nashville Housing Data for Data Cleaning] nb
ON na.ParcelID = nb.ParcelID
AND na.UniqueID <> nb.UniqueID
WHERE na.PropertyAddress IS NULL	

--Now lets update our table with the values

UPDATE na		-- when you give alias to the table use that in update
SET PropertyAddress = ISNULL(na.PropertyAddress,nb.PropertyAddress)
FROM [Nashville Housing Data].dbo.[Nashville Housing Data for Data Cleaning] na
JOIN [Nashville Housing Data].dbo.[Nashville Housing Data for Data Cleaning] nb
ON na.ParcelID = nb.ParcelID
AND na.UniqueID <> nb.UniqueID
WHERE na.PropertyAddress IS NULL

-- Run the previous query(24) to check if there are any null values in property address column

-- Now in the property column we have address and city together with comma delimiter. I will seperate them out.

-- Breaking out Address into individual columns

SELECT PropertyAddress
FROM [Nashville Housing Data].dbo.[Nashville Housing Data for Data Cleaning]


SELECT 
	SUBSTRING(PropertyAddress, 1,CHARINDEX(',',PropertyAddress)-1) AS Street,
	SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress)) AS City
FROM [Nashville Housing Data].dbo.[Nashville Housing Data for Data Cleaning]

ALTER TABLE [Nashville Housing Data].dbo.[Nashville Housing Data for Data Cleaning]
ADD PropertyAddressStreet varchar (250),
	PropertyAddressCity varchar (250);

UPDATE [Nashville Housing Data].dbo.[Nashville Housing Data for Data Cleaning]
SET PropertyAddressStreet = SUBSTRING(PropertyAddress, 1,CHARINDEX(',',PropertyAddress)-1),
	PropertyAddressCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress))


-- Now I am splitting Owner's Address

SELECT OwnerAddress
FROM [Nashville Housing Data].dbo.[Nashville Housing Data for Data Cleaning]

-- I will do it with the PARSENAME because it will be fast and easy but PARSENAME only works on periods and here we have commas.
--We will replace commas with periods.
-- PARSENAME works from right to left by default

SELECT 
		PARSENAME(REPLACE(OwnerAddress,',','.'),3) AS OwnerStreet,
		PARSENAME(REPLACE(OwnerAddress,',','.'),2) AS OwnerCity,
		PARSENAME(REPLACE(OwnerAddress,',','.'),1) AS OwnerState
FROM [Nashville Housing Data].dbo.[Nashville Housing Data for Data Cleaning]

ALTER TABLE [Nashville Housing Data].dbo.[Nashville Housing Data for Data Cleaning]
ADD OwnerStreet varchar (250),
	OwnerCity varchar (250),
	OwnerState varchar (250);

UPDATE [Nashville Housing Data].dbo.[Nashville Housing Data for Data Cleaning]
SET OwnerStreet = PARSENAME(REPLACE(OwnerAddress,',','.'),3),
	OwnerCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2),
	OwnerState = PARSENAME(REPLACE(OwnerAddress,',','.'),1);

--Lets Take a Look at SoldVsVacant
SELECT DISTINCT(SoldAsVacant),
		COUNT(SoldAsVacant) -- The data is imported as 1 N 0 instead of yes and no, lets correct this
FROM [Nashville Housing Data].dbo.[Nashville Housing Data for Data Cleaning]
GROUP BY SoldAsVacant
-- Here we can use two appraoches either I use the function cast and create a new column in the table that is easy and fast OR
--I alter the original column.
-- I will go with the 2nd one.

ALTER TABLE [Nashville Housing Data].dbo.[Nashville Housing Data for Data Cleaning]
ALTER COLUMN SoldAsVacant nvarchar(50)

UPDATE [Nashville Housing Data].dbo.[Nashville Housing Data for Data Cleaning]
SET SoldAsVacant = CASE
						WHEN SoldAsVacant = '0' THEN 'No'
						ELSE 'Yes'
						END

--Lets take a look if we have dulpicates here and remove them
--Best practice is to use windows functions like ROW NUMBER,RANK OR ORDER RANK, DENSE RANK

WITH DuplicateCTE AS
(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference,
				 TotalValue
	ORDER BY
				 UniqueID) AS Row_Num
				
FROM [Nashville Housing Data].dbo.[Nashville Housing Data for Data Cleaning]
--ORDER BY Row_Num DESC -- 104 duplicate IDs
)

DELETE
FROM DuplicateCTE
WHERE Row_Num > 1

-- So Lets get rid of unuseful columns

ALTER TABLE [Nashville Housing Data].dbo.[Nashville Housing Data for Data Cleaning]
DROP COLUMN SaleDate,OwnerAddress,PropertyAddress,TaxDistrict

--Now, The data is ready for further Analysis