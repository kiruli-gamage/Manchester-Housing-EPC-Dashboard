--STEP1_CONFIRM THE IMPORTED TABLES
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE='BASE TABLE';


--STEP2_BASIC EXPLORATORY DATA ANALYSIS

--A) Count rows in both tables
SELECT COUNT(*) AS total_certificates FROM dbo.certificates;
SELECT COUNT(*) AS total_recommendations FROM dbo.recommendations;

--B) View sample data
SELECT TOP 50 * FROM dbo.certificates;
SELECT TOP 50 * FROM dbo.recommendations;

--C) Find columns with missing values
-- 1.Missing values in certificates
SELECT 
    SUM(CASE WHEN LMK_KEY IS NULL OR LMK_KEY = '' THEN 1 END) AS missing_LMK_KEY,
    SUM(CASE WHEN ADDRESS IS NULL OR ADDRESS = '' THEN 1 END) AS missing_ADDRESS,
    SUM(CASE WHEN POSTCODE IS NULL OR POSTCODE = '' THEN 1 END) AS missing_POSTCODE
FROM dbo.certificates;

-- 2. Missing values in recommendations
SELECT 
    SUM(CASE WHEN LMK_KEY IS NULL OR LMK_KEY = '' THEN 1 END) AS missing_LMK_KEY,
    SUM(CASE WHEN IMPROVEMENT_ITEM IS NULL OR IMPROVEMENT_ITEM = '' THEN 1 END) AS missing_ITEM
FROM dbo.recommendations;


--D) Count duplicates (LMK_KEY is your joining key)
-- duplicates in certificates
SELECT LMK_KEY, COUNT(*) AS cnt
FROM dbo.certificates
GROUP BY LMK_KEY
HAVING COUNT(*) > 1;

-- duplicates in recommendations
SELECT LMK_KEY, COUNT(*) AS cnt
FROM dbo.recommendations
GROUP BY LMK_KEY
HAVING COUNT(*) > 1;

--E) Detect impossible numeric values
SELECT *
FROM dbo.certificates
WHERE ENERGY_CONSUMPTION_CURRENT < 0 OR ENERGY_CONSUMPTION_CURRENT > 100000;

--F) Find corrupted LMK_KEY values
SELECT DISTINCT LMK_KEY
FROM dbo.recommendations
WHERE LMK_KEY LIKE '%E+%' OR LMK_KEY LIKE '%E-%';


--STEP 3 DATA CLEANING

--1) Create clean_certificates table
IF OBJECT_ID('dbo.clean_certificates','U') IS NOT NULL
    DROP TABLE dbo.clean_certificates;
GO

SELECT
    -- Keep LMK_KEY as text
    LMK_KEY,

    -- Address fields
    ADDRESS1,
    ADDRESS2,
    ADDRESS3,
    POSTCODE,

    -- Convert numeric fields safely
    TRY_CAST(CURRENT_ENERGY_RATING AS INT) AS CURRENT_ENERGY_RATING,
    TRY_CAST(POTENTIAL_ENERGY_RATING AS INT) AS POTENTIAL_ENERGY_RATING,
    TRY_CAST(CURRENT_ENERGY_EFFICIENCY AS INT) AS CURRENT_ENERGY_EFFICIENCY,
    TRY_CAST(POTENTIAL_ENERGY_EFFICIENCY AS INT) AS POTENTIAL_ENERGY_EFFICIENCY,

	--Convert Datetime Fieald
	TRY_CAST(INSPECTION_DATE AS DATETIME) AS INSPECTION_DATE,
	TRY_CAST(LODGEMENT_DATE AS DATETIME) AS LODGEMENT_DATE,

    -- Convert decimal fields
    TRY_CAST(CO2_EMISSIONS_CURRENT AS DECIMAL(10,2)) AS CO2_EMISSIONS_CURRENT,
    TRY_CAST(CO2_EMISSIONS_POTENTIAL AS DECIMAL(10,2)) AS CO2_EMISSIONS_POTENTIAL,

    -- Cost fields
    TRY_CAST(LIGHTING_COST_CURRENT AS INT) AS LIGHTING_COST_CURRENT,
    TRY_CAST(LIGHTING_COST_POTENTIAL AS INT) AS LIGHTING_COST_POTENTIAL,
    TRY_CAST(HEATING_COST_CURRENT AS INT) AS HEATING_COST_CURRENT,
    TRY_CAST(HEATING_COST_POTENTIAL AS INT) AS HEATING_COST_POTENTIAL,

    -- Keep all long text fields as NVARCHAR(MAX)
    FLOOR_DESCRIPTION,
    WALLS_DESCRIPTION,
    ROOF_DESCRIPTION,
    MAINHEAT_DESCRIPTION,
    WINDOWS_DESCRIPTION,
    HOTWATER_DESCRIPTION,
    CONSTRUCTION_AGE_BAND,
    ADDRESS

INTO dbo.clean_certificates
FROM dbo.certificates;
GO

--2) Create clean_recommendations table
IF OBJECT_ID('dbo.clean_recommendations','U') IS NOT NULL
    DROP TABLE dbo.clean_recommendations;
GO

SELECT
    LMK_KEY,
    TRY_CAST(IMPROVEMENT_ITEM AS INT) AS IMPROVEMENT_ITEM,
    IMPROVEMENT_SUMMARY_TEXT,
    IMPROVEMENT_DESCR_TEXT,
    TRY_CAST(IMPROVEMENT_ID AS INT) AS IMPROVEMENT_ID,
    IMPROVEMENT_ID_TEXT,

    -- Clean cost (remove weird characters)
    REPLACE(REPLACE(INDICATIVE_COST, 'Â', ''), CHAR(160), '') AS INDICATIVE_COST_CLEAN

INTO dbo.clean_recommendations
FROM dbo.recommendations;
GO

--STEP 4_VALIDATE THE CLEANING

--1)Check cleaned tables
SELECT TOP 20 * FROM dbo.clean_certificates;
SELECT TOP 20 * FROM dbo.clean_recommendations;

--2)Count rows
SELECT COUNT(*) FROM dbo.clean_certificates;
SELECT COUNT(*) FROM dbo.clean_recommendations;

--3)Check numeric conversion success
SELECT
    SUM(CASE WHEN CURRENT_ENERGY_RATING IS NULL THEN 1 END) AS missing_energy_rating
FROM dbo.clean_certificates;


--STEP 5_JOIN BOTH CLEANED TABLES
SELECT 
    c.LMK_KEY,
    c.ADDRESS,
    c.POSTCODE,
    r.IMPROVEMENT_SUMMARY_TEXT,
    r.INDICATIVE_COST_CLEAN
FROM dbo.clean_certificates c
LEFT JOIN dbo.clean_recommendations r
    ON c.LMK_KEY = r.LMK_KEY;

SELECT*
FROM clean_certificates;