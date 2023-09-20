-- Cleaning Data in SQL Queries

SELECT *
FROM [Project Portfolio].dbo.NashvilleHousing$

--------------------------------------------------------------------------------------------------


-- 1.a Standardize Date format using the CONVERT function

SELECT 
  SaleDate,
  CONVERT(Date, SaleDate)
FROM [Project Portfolio].dbo.NashvilleHousing$

UPDATE [Project Portfolio].dbo.NashvilleHousing$
SET SaleDate = CONVERT(Date, SaleDate) -- not working

-- 1.b Standardize Date format using the ALTER TABLE
ALTER TABLE [Project Portfolio].dbo.NashvilleHousing$
ALTER COLUMN SaleDate Date


-- 2. Populate the Property Address Data 
-- Fill up the PropertyAddress that has no entry
-- Check the data: 
SELECT *
FROM [Project Portfolio].dbo.NashvilleHousing$
WHERE PropertyAddress IS NULL
-- Upon checking, it was found out that: ParcelID is tied to the PropertyAddress but there is only one UniqueID for each row

-- To do: Join the same table to itself
-- Wherein the ParcelID is the same but it's not the same row
-- Meaning, there is only one uniqueID. 
-- IF THERE IS NULL: YOU CAN USE THE ISNULL FUNCTION
-- Using ISNULL(column_name_to_check, column_name_to_populate_if_1st_column_ISNULL)
SELECT 
  a.ParcelID,
  a.PropertyAddress,
  b.ParcelID,
  b.PropertyAddress,
  ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM [Project Portfolio].dbo.NashvilleHousing$ AS a
JOIN [Project Portfolio].dbo.NashvilleHousing$ AS b
  ON a.ParcelID = b.ParcelID AND
     a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

-- To update the NULL VALUES (Table a): 
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM [Project Portfolio].dbo.NashvilleHousing$ AS a
JOIN [Project Portfolio].dbo.NashvilleHousing$ AS b
  ON a.ParcelID = b.ParcelID AND
     a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL



-- 3. Breaking out Address into individual columns (Address, City, State)
-- a. Inspect the PropertyAddress
SELECT *
FROM [Project Portfolio].dbo.NashvilleHousing$


   -- a. Upon inspection, the address has a comma as a delimiter
   -- CHARINDEX is for seaching a specific character, word, group of charaters. etc. 
   -- To break the PropertyAdress to Address and City:
   SELECT
   SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS PropertySplitAdress,
   SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) AS PropertySplitCity
   FROM [Project Portfolio].dbo.NashvilleHousing$


   -- To update the table: 
   
   ALTER TABLE [Project Portfolio].dbo.NashvilleHousing$
   ADD PropertySplitAdress nvarchar(255) 
   UPDATE [Project Portfolio].dbo.NashvilleHousing$
   SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

   
   ALTER TABLE [Project Portfolio].dbo.NashvilleHousing$
   ADD PropertySplitCity nvarchar(255)  
   UPDATE [Project Portfolio].dbo.NashvilleHousing$
   SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))

-- b. Inspect the OwnerAddress

SELECT OwnerAddress
FROM [Project Portfolio].dbo.NashvilleHousing$
 
	-- Using PARSENAME (only useful with periods (.))
	-- if there is no period, just use REPLACE

 SELECT
 PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1),
 PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2), 
 PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) 
 FROM [Project Portfolio].dbo.NashvilleHousing$

	-- TO FIX: 
  SELECT
 PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS OwnerSplitAddress,
 PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS OwnerSplitCity, 
 PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS OwnerSplitState
 FROM [Project Portfolio].dbo.NashvilleHousing$


	-- Update table

 ALTER TABLE [Project Portfolio].dbo.NashvilleHousing$
 ADD OwnerSplitAddress nvarchar(255)

 UPDATE [Project Portfolio].dbo.NashvilleHousing$
 SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)


 ALTER TABLE [Project Portfolio].dbo.NashvilleHousing$
 ADD OwnerSplitCity nvarchar(255)

 UPDATE [Project Portfolio].dbo.NashvilleHousing$
 SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

 ALTER TABLE [Project Portfolio].dbo.NashvilleHousing$
 ADD OwnerSplitState nvarchar(255)

 UPDATE [Project Portfolio].dbo.NashvilleHousing$
 SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) 



-- 4. Change Y and N to Yes and No in "Sold as Vacant" field
	-- inspect the SoldAsVacant column
SELECT 
  DISTINCT(SoldAsVacant),
  COUNT(SoldAsVacant) AS count_distinct
FROM [Project Portfolio].dbo.NashvilleHousing$
GROUP BY SoldAsVacant
ORDER BY count_distinct

	-- USING CASE STATEMENT TO CHANGE Y TO YES AND N TO NO
SELECT 
  SoldAsVacant,
  CASE
  WHEN SoldAsVacant = 'Y' THEN 'Yes'
  WHEN SoldAsVacant = 'N' THEN 'No'
  ELSE SoldAsVacant
  END 
FROM [Project Portfolio].dbo.NashvilleHousing$

UPDATE [Project Portfolio].dbo.NashvilleHousing$
SET SoldAsVacant =  CASE
  WHEN SoldAsVacant = 'Y' THEN 'Yes'
  WHEN SoldAsVacant = 'N' THEN 'No'
  ELSE SoldAsVacant
  END
  


-- 5. Remove duplicates
/* It is not advisable to remove duplicates in you data, instead, just use
THE REMOVE DUPLICATES STATEMENT IN A TEMPORARY TABLE
*/
-- To remove duplicates, find a way first to identify the duplicates
SELECT *
FROM [Project Portfolio].dbo.NashvilleHousing$
-- identify unique fields for each entry EXCEPT THE PRIMARY FIELD
-- You can use partition by to display the row number of unique row entries as 1
-- Row number greater than 1 have duplicates

--WHERE row_num >1, cannot directly use where clause, make the above query as a CTE
WITH CTERowNum 
  AS (
	SELECT *,
	 ROW_NUMBER() OVER (
     PARTITION BY ParcelID,
				   PropertyAddress,
				   SaleDate,
				   SalePrice,
				   LegalReference
				   ORDER BY UniqueID
				  ) AS row_num
FROM [Project Portfolio].dbo.NashvilleHousing$
)
SELECT *
FROM CTERowNum 
WHERE row_num >1
ORDER BY PropertyAddress

-- TO DELETE THE DUPLICATE ROWS, ROW_NUMBER > 1:
WITH CTERowNum 
  AS (
	SELECT *,
	 ROW_NUMBER() OVER (
     PARTITION BY ParcelID,
				   PropertyAddress,
				   SaleDate,
				   SalePrice,
				   LegalReference
				   ORDER BY UniqueID
				  ) AS row_num
FROM [Project Portfolio].dbo.NashvilleHousing$
)
DELETE 
FROM CTERowNum 
WHERE row_num >1
--ORDER BY PropertyAddress


-- 6. Delete unused columns
-- it is not advisable to just delete columns from your raw data
-- The Advise is do not delete columns
-- identfy columns that you want to delete

ALTER TABLE [Project Portfolio].dbo.NashvilleHousing$
DROP COLUMN TaxDistrict


