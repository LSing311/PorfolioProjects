-- ATA Covid Portfolio Project
-- Data up to 2023-05-31 --

SELECT * 
FROM [PortfolioProject-COVID].dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4


--SELECT * 
--FROM dbo.CovidVaccinations
--ORDER BY 3,4

--Select Data that we are going to be using for the analysis
--SELECT Location, Date, total_cases, new_cases, total_deaths, population
--FROM CovidDeaths
--ORDER BY 1,2

----Alter data type of total_deaths from nvarchar to float
ALTER table [PortfolioProject-COVID].dbo.CovidDeaths
ALTER column total_deaths float

SELECT *
FROM [PortfolioProject-COVID].dbo.CovidDeaths
WHERE location like '%states%'

SELECT* FROM INFORMATION_SCHEMA.COLUMNS
ORDER BY TABLE_NAME

-- Looking at Total Cases vs. Total Deaths
-- Shows likelihood of dying if infected
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM [PortfolioProject-COVID].dbo.CovidDeaths
--WHERE location like '%states%'
ORDER BY 1,2

-- Looking at the Total Cases vs. Population
SELECT Location, date, total_cases, population, (total_cases/population)*100 as Percentage_Infected
FROM [PortfolioProject-COVID].dbo.CovidDeaths
--WHERE Location like '%states%'
ORDER BY Percentage_Infected DESC

-- Looking at countries with highest infection rate vs. population
SELECT Location, total_cases, population, (total_cases/population)*100 as infection_rate
FROM [PortfolioProject-COVID].dbo.CovidDeaths
ORDER BY infection_rate DESC

-- Looking at countries with highest infection rate with populations higher than 50 million people
SELECT Location, Population, MAX(total_cases) as HighestInfectionCount, MAX(total_cases/population)*100 as infection_rate
FROM [PortfolioProject-COVID].dbo.CovidDeaths
WHERE Location NOT LIKE '%union%' AND Population > 50000000
GROUP BY population, location
ORDER BY infection_rate DESC

-- Let's break thinks down by continent; this only takes the maximum value of total deaths by continent (USA), 
-- so it doesn't accurate inform on total contient deaths. See the next query for death rate by continent
SELECT continent, max(total_deaths) as TotalDeathCount -- DO NOT USE THIS QUERY!
FROM [PortfolioProject-COVID].dbo.CovidDeaths
WHERE Continent is not NULL
GROUP BY Continent
ORDER BY TotalDeathCount desc



-- Why isn't Canada, Mexico, or Central America included in North America group? 
-- Top 3 Total_Death_Count: US 1127152, Mex 334107, Can 52425; + Central + Caribbean
SELECT continent, location, max(total_deaths) as TotalDeathCount
FROM [PortfolioProject-COVID].dbo.CovidDeaths
WHERE Continent is not null and continent = 'North America'
GROUP BY continent, location
ORDER BY TotalDeathCount desc

-- Checking that Dominican Republic had 4384 total deaths: yes, it does
-- We use max(total_deaths) and not sum(total deaths) 
-- because each date provides a running death total rather than a total of deaths per day
SELECT location, max(total_deaths) as TotalDeathCount
FROM [PortfolioProject-COVID].dbo.CovidDeaths
WHERE location = 'dominican republic'
GROUP BY location


-- Showing countries with highest death count by population
SELECT Location, Population, MAX(total_deaths) as TotalDeathCount, MAX(total_deaths/population)*100 as death_rate
FROM [PortfolioProject-COVID].dbo.CovidDeaths
WHERE continent is not NULL
GROUP BY population, location
ORDER BY TotalDeathCount DESC

--------- PREPARE QUERIES FOR FINAL VIZ in TABLEAU ----------

-- Showing total deaths by continent and total for World while removing 'income' categories
SELECT location, max(total_deaths) as TotalDeathCount 
FROM [PortfolioProject-COVID].dbo.CovidDeaths
WHERE Continent is NULL and location not like '%income%' 
GROUP BY location
ORDER BY TotalDeathCount desc

--- Global Numbers by date
SELECT date, SUM(new_cases) as TotalCases, SUM(new_deaths) as TotalDeaths, SUM(new_deaths)/NULLIF(SUM(new_cases),0)*100 
	as DeathPercentage
FROM [PortfolioProject-COVID].dbo.CovidDeaths
WHERE Continent is NULL and location not like '%income%' and location != 'World'
GROUP BY date
ORDER BY 1,2
--- Sum of Global Numbers
SELECT SUM(new_cases) as TotalCases, SUM(new_deaths) as TotalDeaths, SUM(new_deaths)/NULLIF(SUM(new_cases),0)*100 
	as DeathPercentage
FROM [PortfolioProject-COVID].dbo.CovidDeaths
WHERE Continent is NULL and location not like '%income%' and location != 'World'
ORDER BY 1,2


--- JOIN two tables by location and date
SELECT * 
FROM [PortfolioProject-COVID].dbo.CovidDeaths dea
JOIN [PortfolioProject-COVID].dbo.CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date


-- Alter new_vaccinations columns to float
ALTER table [PortfolioProject-COVID].dbo.CovidVaccinations
ALTER column total_vaccinations float
ALTER table [PortfolioProject-COVID].dbo.CovidVaccinations
ALTER column total_tests float
ALTER table [PortfolioProject-COVID].dbo.CovidVaccinations
ALTER column new_tests float
ALTER table [PortfolioProject-COVID].dbo.CovidVaccinations
ALTER column new_vaccinations float

-- Looking at Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingVaccinations
FROM [PortfolioProject-COVID].dbo.CovidDeaths dea
JOIN [PortfolioProject-COVID].dbo.CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

-- USE CTE
-- If adding any queries, you must run the entire CTE with it. 
WITH POPvsVAC (Continent, Location, Date, Population, New_Vaccinations, RollingVaccinations)
as( 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingVaccinations
FROM [PortfolioProject-COVID].dbo.CovidDeaths dea
JOIN [PortfolioProject-COVID].dbo.CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
)
SELECT *, (RollingVaccinations/Population)*100
FROM POPvsVAC
ORDER BY Location, Date


-- TEMP TABLE
-- Once the table is created, you can run queries individually, 
--rather than having to select the entire create table code. 
-- OR use drop table if exists prior to create table if you want to alter the create table query. 

DROP TABLE if exists #PercentPopVac
CREATE TABLE #PercentPopVac
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingVaccinations numeric
)
INSERT INTO #PercentPopVac
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingVaccinations
FROM [PortfolioProject-COVID].dbo.CovidDeaths dea
JOIN [PortfolioProject-COVID].dbo.CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null

SELECT *, (RollingVaccinations/Population)*100 as Pct_Vaccinated
FROM #PercentPopVac
ORDER BY Location, Date


-- CREATE A VIEW to store data for later - becomes permenant part of database! :) 
USE [PortfolioProject-COVID]
GO
Create View PctPopVac as 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingVaccinations
FROM [PortfolioProject-COVID].dbo.CovidDeaths dea
JOIN [PortfolioProject-COVID].dbo.CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null



SELECT *, (RollingVaccinations/Population)*100 as Pct_Vaccinated
FROM #PercentPopVac
ORDER BY Location, Date
