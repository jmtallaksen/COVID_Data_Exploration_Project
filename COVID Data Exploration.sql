SELECT *
FROM COVID_Portfolio_Project..Covid_Deaths
WHERE continent is not null
order by 3,4

--^^Nulls were discovered in the source during "highest death rate by country" calculation listed below

--Selecting data we will be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM COVID_Portfolio_Project..Covid_Deaths
WHERE continent is not null
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths
-- First glance shows the likelihood of death if the virus is contracted based on a person's location

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_rate
FROM COVID_Portfolio_Project..Covid_Deaths
WHERE location = 'United States' AND continent is not null
ORDER BY 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of the population has contracted COVID based on location
SELECT location, date, population, total_cases, (total_cases/population)*100 AS infection_rate
FROM COVID_Portfolio_Project..Covid_Deaths
WHERE location = 'United States' AND continent is not null
ORDER BY 1,2

-- Looking at countries with the highest infection rate compared to population

SELECT location, population, MAX(total_cases) AS highest_case_count, MAX((total_cases/population))*100 AS infection_rate
FROM COVID_Portfolio_Project..Covid_Deaths
WHERE continent is not null
GROUP BY location, population
ORDER BY infection_rate DESC

-- Showing countries with highest death count per population

SELECT location, MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM COVID_Portfolio_Project..Covid_Deaths
WHERE continent is not null
GROUP BY location
ORDER BY total_death_count DESC

-- Information broken down by continent - It is believed that the nulled continent entries in the data source are the actual totals
-- for the continents. When 'location' is replaced with 'continent' in the script below the total for North America is the same value
-- as the total for 'United States' when looking at totals by country.

-- Showing continents with the highest death count.

SELECT continent, 
	MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM COVID_Portfolio_Project..Covid_Deaths
WHERE continent is not null
GROUP BY continent
ORDER BY total_death_count DESC


-- Global numbers

SELECT date, 
	SUM(new_cases) AS daily_new_cases
FROM COVID_Portfolio_Project..Covid_Deaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

SELECT date, 
	SUM(new_cases) AS daily_new_cases, 
	SUM(CAST(new_deaths AS int)) AS daily_new_deaths
FROM COVID_Portfolio_Project..Covid_Deaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

SELECT date, SUM(new_cases) AS daily_new_cases, 
	SUM(CAST(new_deaths AS int)) AS daily_new_deaths, 
	SUM(CAST(new_deaths as int))/SUM(new_cases)*100 AS daily_death_rate
FROM COVID_Portfolio_Project..Covid_Deaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

-- Total global cases vs total global deaths

SELECT SUM(new_cases) AS daily_new_cases, 
	SUM(CAST(new_deaths AS int)) AS daily_new_deaths, 
	SUM(CAST(new_deaths as int))/SUM(new_cases)*100 AS daily_death_rate
FROM COVID_Portfolio_Project..Covid_Deaths
WHERE continent is not null
ORDER BY 1,2

-- Incorporating vaccinations data for comparison

SELECT*
FROM COVID_Portfolio_Project..Covid_Deaths dea
JOIN COVID_portfolio_Project..Covid_vaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date

-- Looking at total vaccinations vs population

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations as int)) OVER (partition by dea.location ORDER BY dea.location, dea.date) as running_total_vaccinations
FROM COVID_Portfolio_Project..Covid_Deaths dea
JOIN COVID_portfolio_Project..Covid_vaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

--Using CTE to compare vaccination and population

WITH population_vs_vaccination (continent, location, date, population, new_vaccinations, running_total_vaccinations)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations as int)) OVER (partition by dea.location ORDER BY dea.location, dea.date) as running_total_vaccinations
FROM COVID_Portfolio_Project..Covid_Deaths dea
JOIN COVID_portfolio_Project..Covid_vaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
)
SELECT*, (running_total_vaccinations/population)*100 AS vaccination_rate
FROM population_vs_vaccination

-- Temp Table

CREATE TABLE #Percent_Population_Vaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
running_total_vaccinations numeric
)
INSERT INTO #Percent_Population_Vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations as int)) OVER (partition by dea.location ORDER BY dea.location, dea.date) as running_total_vaccinations
FROM COVID_Portfolio_Project..Covid_Deaths dea
JOIN COVID_portfolio_Project..Covid_vaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null

SELECT*, (running_total_vaccinations/population)*100 AS vaccination_rate
FROM #Percent_Population_Vaccinated


-- Creating Views for later visualizations

-- DROP VIEW if exists Percent_Population_Vaccinated (Noted out from troubleshooting. View was successfully created, but would not show up 
-- even after refresh and restart. View was mistakenly created in the wrong database.)

CREATE VIEW
Percent_Population_Vaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations as int)) OVER (partition by dea.location ORDER BY dea.location, dea.date) as running_total_vaccinations
FROM COVID_Portfolio_Project..Covid_Deaths dea
JOIN COVID_portfolio_Project..Covid_vaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null

SELECT*
FROM Percent_Population_Vaccinated
