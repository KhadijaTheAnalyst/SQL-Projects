/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/


-- Select Data that we are going to be starting with

SELECT 
		location,
		date,
		total_cases,
		new_cases,
		total_deaths,
		population
FROM CovidDeaths
ORDER BY 1,2

--Some of the locations are group where we dont have continent so we exclude that 


-- Total Cases vs Total Deaths
SELECT 
	location,
	date,
	total_cases ,
	total_deaths ,
	population,
	(total_deaths/total_cases)*100 AS Death_Rate_Percentage
FROM CovidDeaths
WHERE continent is not null
Order BY 1,2

-- Shows likelihood of dying if you contract covid in your country
SELECT 
	location,
	date,
	total_cases ,
	total_deaths ,
	population,
	(total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE location = 'Luxembourg' AND continent is not null
Order BY 1,2

--Show what percentage of population got Covid
SELECT 
	location,
	date,
	total_cases ,
	total_deaths ,
	population,
	(total_cases/population)*100 AS InfectedPeoplePercentage
FROM CovidDeaths
WHERE continent is not null
Order BY 1,2

--Analysing for Luxembourg
SELECT 
	location,
	date,
	total_cases ,
	total_deaths ,
	population,
	(total_cases/population)*100 AS InfectedPeoplePercentage
FROM CovidDeaths
WHERE location = 'Luxembourg' AND continent is not null
Order BY (total_cases/population)*100 desc

--Looking at countries with highset cases 
SELECT 
	location,
	date,
	total_cases ,
	total_deaths ,
	population	
FROM CovidDeaths
WHERE continent is not null
Order BY total_cases DESC

--Looking at countries with highset Infection rates compared to population
SELECT 
	location,
	MAX(total_cases) AS HigestInfectionCount,
	population,
	MAX((total_cases/population)*100) AS MaxInfectedPeoplePercentage
FROM CovidDeaths
WHERE continent is not null
GROUP BY location,population
Order BY MaxInfectedPeoplePercentage DESC

--Looking at Luxembourg
SELECT 
	location,
	MAX(total_cases) AS HigestInfectionCount,
	population,
	MAX((total_cases/population)*100) AS MaxInfectedPeoplePercentage
FROM CovidDeaths
WHERE location = 'Luxembourg' AND continent is not null
GROUP BY location,population
Order BY MaxInfectedPeoplePercentage DESC

--10percent Population was infected oh lala including me ;)

--Showing the countries with highest death count compared to population
SELECT 
	location,
	MAX(total_deaths) AS TotalDeathCount,
	population	
FROM CovidDeaths
WHERE continent is not null
GROUP BY location,population
Order BY TotalDeathCount DESC

--LETS EXPLORE NOW BASED ON CONTINENT
SELECT 
	continent,
	MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
WHERE continent is not null
GROUP BY continent
Order BY TotalDeathCount DESC

--this query is not giving us the actual numbers as some of the continents are null and then in location it is grouped by continent
--Lets include location in above query

SELECT 
	location,
	MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
WHERE continent is null
GROUP BY location
Order BY TotalDeathCount DESC

--Grouping things by continents
with Continent AS
(
	SELECT 
		continent,
		location,
		MAX(total_cases) AS HigestInfectionCount,
		population,
		MAX((total_cases/population)*100) AS MaxInfectedPeoplePercentage
	FROM CovidDeaths
	WHERE continent is not null
	GROUP BY continent,location,population
	
	),
RankedContinent AS
(
	SELECT 
		continent,
		location,
		MaxInfectedPeoplePercentage,
		ROW_NUMBER() OVER (PARTITION BY continent ORDER BY MaxInfectedPeoplePercentage DESC) AS rn
	FROM Continent
	)
SELECT continent,
		location,
		MaxInfectedPeoplePercentage
FROM RankedContinent
WHERE rn = 1
ORDER BY MaxInfectedPeoplePercentage DESC

--We can see highest number of cases are recorded in Europe then Asia

--Lets Group data by date
SELECT 
	date,location,
	MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
WHERE continent is not null
GROUP BY date,location
Order BY TotalDeathCount DESC

--Lets see how many new cases were recorded and how it was suming up across the world
SELECT 
	date,
	SUM(new_cases) AS SumOfNewCases,
	SUM(new_deaths) AS SumOfNewDeaths,
	(SUM(new_deaths)/SUM(new_cases))*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent is not null
GROUP BY date
Order BY 1,2

--We can see it started towards the end of janurary 2020


--Lets see the total across the world
SELECT 
	SUM(new_cases) AS SumOfNewCases,
	SUM(new_deaths) AS SumOfNewDeaths,
	(SUM(new_deaths)/SUM(new_cases))*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent is not null
--GROUP BY date
Order BY 1,2


--Lets join our two table

SELECT *
FROM CovidDeaths cd
JOIN CovidVaccinations cv
ON cd.iso_code = cv.iso_code

--Lets see Total Population vs new vaccinations 
SELECT 
	cd.continent,
	cd.location,
	cd.date,
	population,
	cv.new_vaccinations
FROM CovidDeaths cd
JOIN CovidVaccinations cv
ON cd.location = cv.location
WHERE cv.continent is NOT NULL
ORDER BY 2,3

--Lets see now Total vaccinations Vs. Population
SELECT 
	cd.continent,
	cd.location,
	cd.date, -- we are looking here on daily basis
	population,
	cv.total_vaccinations
FROM CovidDeaths cd
JOIN CovidVaccinations cv
ON cd.location = cv.location
WHERE cv.continent is NOT NULL
ORDER BY 2,3


--Looking at Rolling total of new vaccinations now

SELECT 
	cd.continent,
	cd.location,
	cd.date,
	population,
	cv.new_vaccinations,
	SUM(cv.new_vaccinations) OVER (Partition by cd.location	ORDER BY cd.location,cd.date) AS RollingTotal
FROM CovidDeaths cd
JOIN CovidVaccinations cv
ON cd.location = cv.location
AND cd.date = cv.date
WHERE cv.continent is NOT NULL
ORDER BY 2,3

--USE CTE

WITH PopVsVac AS
(
	SELECT 
		cd.continent,
		cd.location,
		cd.date,
		population,
		cv.new_vaccinations,
		SUM(cv.new_vaccinations) OVER (Partition by cd.location	ORDER BY cd.location,cd.date) AS RollingTotal
	FROM CovidDeaths cd
	JOIN CovidVaccinations cv
	ON cd.location = cv.location
	AND cd.date = cv.date
	WHERE cv.continent is NOT NULL
	--ORDER BY 2,3
)
SELECT *,(RollingTotal/population)*100
FROM PopVsVac;

--TEMP TABLE

CREATE TABLE #PercentPopulationVaccinated
(
	continent nvarchar (255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	rollingtotal numeric
)

INSERT INTO #PercentPopulationVaccinated
	SELECT 
		cd.continent,
		cd.location,
		cd.date,
		population,
		cv.new_vaccinations,
		SUM(cv.new_vaccinations) OVER (Partition by cd.location	ORDER BY cd.location,cd.date) AS RollingTotal
	FROM CovidDeaths cd
	JOIN CovidVaccinations cv
	ON cd.location = cv.location
	AND cd.date = cv.date
	WHERE cv.continent is NOT NULL
	ORDER BY 2,3

SELECT continent,MAX(rollingtotal) AS MaxRollingTotal_NewVaccinations
FROM #PercentPopulationVaccinated
GROUP BY continent

	
--CREATING VIEWS

CREATE VIEW PopulationsVsVaccinations AS

SELECT 
	cd.continent,
	cd.location,
	cd.date, -- we are looking here on daily basis
	population,
	cv.total_vaccinations
FROM CovidDeaths cd
JOIN CovidVaccinations cv
ON cd.location = cv.location
WHERE cv.continent is NOT NULL
--ORDER BY 2,3


CREATE VIEW DeathsVsCasesVsVaccines AS

SELECT 
	cd.continent,
	cd.location,
	cd.date,
	cd.total_cases,
	cd.total_deaths,
	population,
	cv.new_vaccinations,
	cv.total_vaccinations
FROM CovidDeaths cd
JOIN CovidVaccinations cv
ON cd.location = cv.location
WHERE cv.continent is NOT NULL
--ORDER BY 2,3
