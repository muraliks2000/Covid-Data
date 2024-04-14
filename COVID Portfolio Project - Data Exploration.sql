/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

select * from CovidDeaths
select * from CovidVaccinations

Select *
From CovidDeaths
Where continent is not null 
order by 3,4


-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From CovidDeaths
Where continent is not null 
order by 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT 
    Location, date, total_cases,total_deaths, (total_deaths / total_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE 
    (total_deaths / total_cases) * 100 IS NOT NULL  
    AND continent IS NOT NULL 
ORDER BY 
    1, 2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Where location like 'India'
order by 1,2


-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Group by Location, Population
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population

Select Location, MAX(convert(int,Total_deaths)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null and Total_deaths is not null
Group by Location
order by TotalDeathCount desc



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc



-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null 
order by 1,2



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, max(dea.population) population, sum(convert(int,vac.new_vaccinations)) Vaccinated
, SUM(CONVERT(int,vac.new_vaccinations)) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
group by dea.continent, dea.location
having sum(convert(int,vac.new_vaccinations)) is not null and SUM(CONVERT(int,vac.new_vaccinations)) is not null
order by 1,2


-- Using CTE to perform Calculation on Partition By 

With PopvsVac (Continent,location, population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, max(dea.population) population, sum(convert(int,vac.new_vaccinations)) Vaccinated
, SUM(CONVERT(int,vac.new_vaccinations)) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
group by dea.continent, dea.location
having sum(convert(int,vac.new_vaccinations)) is not null and SUM(CONVERT(int,vac.new_vaccinations)) is not null

)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac
order by 1,2



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentVaccinated
Create Table #PercentVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Population numeric,
Vaccinated bigint,
RollingPeopleVaccinated numeric
)

Insert into #PercentVaccinated
Select dea.continent, dea.location, max(dea.population) population, sum(convert(int,vac.new_vaccinations)) Vaccinated
, SUM(CONVERT(int,vac.new_vaccinations)) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
group by dea.continent, dea.location
having sum(convert(int,vac.new_vaccinations)) is not null and SUM(CONVERT(int,vac.new_vaccinations)) is not null
order by 1,2

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentVaccinated




-- Creating View to store data for later

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null




--Cleaning Data in SQL Queries



Select *
From PortfolioProject.dbo.CovidDeaths

--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format


Select date, CONVERT(Date,date)
From PortfolioProject.dbo.CovidDeaths


Update CovidDeaths
SET Date = CONVERT(Date,date)

-- If it doesn't Update properly

ALTER TABLE CovidDeaths
Add DateConverted Date;

Update CovidDeaths
SET DateConverted = CONVERT(Date,Date)


 --------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data

Select *
From PortfolioProject.dbo.CovidVaccinations
Where Continent is not null
order by continent, location

Select a.continent, a.location, b.new_vaccinations, b.total_vaccinations, ISNULL(a.location,b.location)
From PortfolioProject.dbo.CovidDeaths a
Full JOIN PortfolioProject.dbo.CovidVaccinations b
	on a.continent = b.continent
	AND a.location <> b.location
Where a.location is null

SELECT ISNULL(continent, location) AS address
FROM coviddeaths;

Update a
SET continent = ISNULL(a.continent,b.continent)
From PortfolioProject.dbo.coviddeaths a
JOIN PortfolioProject.dbo.CovidVaccinations b
	on a.continent = b.continent
	AND a.location <> b.location
Where a.location is null




--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)


Select location, population, total_deaths
From PortfolioProject.dbo.CovidDeaths
--Where location is null
--order by location

Select
PARSENAME(REPLACE(continent, ' ', '.') , 2)
From PortfolioProject.dbo.CovidDeaths
where continent like '% %'

--------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No in "Sold as Vacant" field


Select location, Count(location)
From PortfolioProject.dbo.CovidVaccinations
Group by location
order by 2 desc

alter table coviddeaths
add caseexample varchar(30);


Select location
, CASE When location = 'India' THEN 'Ind'
	   When location = 'Indonesia' THEN 'Indo'
	   ELSE location
	   END
From PortfolioProject.dbo.CovidDeaths
order by location

Update CovidDeaths
SET location = CASE When location = 'India' THEN 'Ind'
	   When location = 'Indonesia' THEN 'Indo'
	   ELSE location
	   END





-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Inserting Duplicates
select * from CovidDeaths
where location = 'india' and date = '2020-04-05 00:00:00.000'

insert into CovidDeaths
select * from CovidDeaths
where location = 'india' and date = '2020-04-05 00:00:00.000'

WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY location,
				 date
				 ORDER BY
					location
					) row_num
From PortfolioProject.dbo.CovidDeaths
where location like 'india'
--order by ParcelID
)
select *  
From RowNumCTE
Where row_num > 1

-- Remove Duplicates

WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY location,
				 date
				 ORDER BY
					location
					) row_num
From PortfolioProject.dbo.CovidDeaths
where location like 'india'
--order by ParcelID
)
delete From RowNumCTE
Where row_num > 1


---------------------------------------------------------------------------------------------------------
-- Add Columns

ALTER TABLE coviddeaths
add dummy int

-- Delete Unused Columns

Select *
From PortfolioProject.dbo.CovidDeaths


ALTER TABLE coviddeaths
DROP COLUMN dummy
