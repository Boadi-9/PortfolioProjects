/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/



Select *
From[PortfolioProject].. CovidDeaths
order by 3,4

Select *
From[PortfolioProject].. CovidVaccinations
order by 3,4


 --Total Cases vs Total Deaths

SELECT 
    Location, 
    date, 
    total_cases, 
    new_cases, 
    total_deaths, 
    (ISNULL(CAST(NULLIF(total_deaths, '') AS float), 0) / 
     ISNULL(CAST(NULLIF(total_cases, '') AS float), 1)) AS death_case_ratio
FROM 
    PortfolioProject..CovidDeaths
ORDER BY 
    1,2


	-- Shows likelihood of dying if you contract covid in your country say "United States" 


	SELECT 
    Location, 
    date, 
    total_cases, 
    new_cases, 
    total_deaths, 
    (ISNULL(CAST(NULLIF(total_deaths, '') AS float), 0) / 
     ISNULL(CAST(NULLIF(total_cases, '') AS float), 1)) AS death_case_ratio
FROM 
    PortfolioProject..CovidDeaths
Where location like '%states%'
ORDER BY 
    1,2



-- Total Cases vs Population
-- Shows what percentage of population infected with Covid


	SELECT 
    Location, 
    date, 
	Population,
    total_cases, 
    (ISNULL(CAST(NULLIF(total_cases, '') AS float), 0) / 
     ISNULL(CAST(NULLIF(Population, '') AS float), 1)) AS death_case_ratio
FROM 
    PortfolioProject..CovidDeaths
--Where location like '%states%'
ORDER BY 
    1,2


-- Countries with Highest Infection Rate compared to Population

SELECT 
    Location, 
    Population,
    MAX(total_cases) as HighestInfectionCount,
    MAX((ISNULL(CAST(NULLIF(total_cases, '') AS float), 0) / 
     ISNULL(CAST(NULLIF(Population, '') AS float), 1))) AS PercentPopulationInfected
FROM 
    PortfolioProject..CovidDeaths
--Where location like '%states%'
GROUP BY Location, date, Population
ORDER BY PercentPopulationInfected DESC



-- Countries with Highest Death Count per Population


Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM 
    PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc



-- ALL Locations with the Highest Death Count per Population

SELECT 
    Location,
    MAX(TRY_CAST(Total_deaths AS int)) AS TotalDeathCount
FROM 
    PortfolioProject..CovidDeaths
WHERE 
    continent IS NOT NULL AND
    continent <> ''
GROUP BY 
    Location
ORDER BY 
    TotalDeathCount DESC



--BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM 
    PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc


-- With this query, you should get the maximum total death count for each continent, excluding rows where continent is NULL or an empty string.

SELECT 
    continent, 
    MAX(TRY_CAST(Total_deaths AS int)) AS TotalDeathCount
FROM 
    PortfolioProject..CovidDeaths
WHERE 
    continent IS NOT NULL AND
    continent <> ''
GROUP BY 
    continent
ORDER BY 
    TotalDeathCount DESC



	-- GLOBAL NUMBERS

SELECT 
    SUM(TRY_CAST(new_cases AS int)) as total_cases, 
    SUM(TRY_CAST(new_deaths AS int)) as total_deaths, 
    (SUM(TRY_CAST(new_deaths AS int)) / NULLIF(SUM(TRY_CAST(new_cases AS int)), 0)) * 100 as DeathPercentage
FROM 
    [PortfolioProject]..CovidDeaths
WHERE 
    continent IS NOT NULL AND
    continent <> ''
--GROUP BY 
--    date
ORDER BY 
    1,2




-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (
        PARTITION BY dea.location 
        ORDER BY dea.location, dea.date
    ) as RollingPeopleVaccinated
FROM 
    PortfolioProject..CovidDeaths dea
JOIN 
    PortfolioProject..CovidVaccinations vac
ON 
    dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL
ORDER BY 
    dea.location, dea.date





-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        CONVERT(bigint, dea.population), 
        CONVERT(bigint, vac.new_vaccinations),
        SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
    FROM 
        PortfolioProject..CovidDeaths dea
    JOIN 
        PortfolioProject..CovidVaccinations vac
    ON 
        dea.location = vac.location
        AND dea.date = vac.date
    WHERE 
        dea.continent IS NOT NULL
)
SELECT 
    *,
    (RollingPeopleVaccinated * 1.0 / Population) * 100 AS VaccinationPercentage
FROM 
    PopvsVac




-- Using Temp Table to perform Calculation on Partition By in previous query
-- Drop the temporary table if it exists
DROP TABLE IF EXISTS #PercentPopulationVaccinated

-- Create a temporary table
CREATE TABLE #PercentPopulationVaccinated
(
    Continent nvarchar(255),
    Location nvarchar(255),
    Date datetime,
    Population bigint,
    New_vaccinations bigint,
    RollingPeopleVaccinated bigint
)

-- Insert data into the temporary table
INSERT INTO #PercentPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    TRY_CAST(dea.population AS bigint), 
    TRY_CAST(vac.new_vaccinations AS bigint),
    SUM(TRY_CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM 
    PortfolioProject..CovidDeaths dea
JOIN 
    PortfolioProject..CovidVaccinations vac
ON 
    dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL 

-- Select data from the temporary table and calculate the vaccination percentage
SELECT 
    *, 
    (RollingPeopleVaccinated * 1.0 / NULLIF(Population, 0)) * 100 AS VaccinationPercentage
FROM 
    #PercentPopulationVaccinated







-- Creating or altering a view to store data for later visualizations

CREATE OR ALTER VIEW PercentPopulationVaccinated AS
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    TRY_CAST(dea.population AS bigint) AS population, 
    TRY_CAST(vac.new_vaccinations AS bigint) AS new_vaccinations,
    SUM(TRY_CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
FROM 
    PortfolioProject..CovidDeaths dea
JOIN 
    PortfolioProject..CovidVaccinations vac
ON 
    dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL
