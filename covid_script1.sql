Select *
From CovidProject..covid_deaths
Where continent is not null
order by 3,4

--Select * 
--From CovidProject..covid_vaccinations
--Where continent is not null
--order by 3,4

--Select Data that we are going to be using

Select Location, date, total_cases, new_cases, total_deaths, population
From CovidProject..covid_deaths 
order by 1,2


--Looking at Total Cases vs Total Deaths. Likelyhood of dying if you contract Covid in your country.

Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
From CovidProject..covid_deaths
Where Location like '%states%' and continent is not null
Order by 1,2

--Looking at Total Cases vs Population

Select Location, date, total_cases, population, (total_cases/population)*100 as infected_percentage
From CovidProject..covid_deaths
Where Location like '%states%'
Order by 1,2

--Looking at countries with highest infection rate compared to population

Select Location, population, max(total_cases) as HighestInfectionCount, max((total_cases/population)*100) as percent_population_infected
From CovidProject..covid_deaths
--Where Location like '%states%'
group by location, population
Order by percent_population_infected desc

--Looking at countries with highest death count per population

Select Location, max(cast(total_deaths as int)) as TotalDeathCount
From CovidProject..covid_deaths
--Where Location like '%states%'
Where continent is not null
group by location
Order by TotalDeathCount desc

--Looking at continent with highest death count per population
--Continent is put into 'location' column instead of 'continent'
Select location, max(cast(total_deaths as int)) as TotalDeathCount
From CovidProject..covid_deaths
--Where Location like '%states%'
Where continent is null
group by location
Order by TotalDeathCount desc

--Select continent, max(cast(total_deaths as int)) as TotalDeathCount
--From CovidProject..covid_deaths
----Where Location like '%states%'
--Where continent is not null
--group by continent
--Order by TotalDeathCount desc


--Global Numbers

--Global Death Daily %
Select date, sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as Death_Percentage
From CovidProject..covid_deaths
Where continent is not null
Group by date
Order by 1,2

--Global Death %
SELECT sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as Death_Percentage
FROM CovidProject.dbo.covid_deaths
WHERE continent is not null 
--and Location like '%states%'

SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations, 
	SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS RollingVaccinations
FROM CovidProject.dbo.covid_deaths death
JOIN CovidProject.dbo.covid_vaccinations vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent is not null
ORDER BY 2,3

-- % of population vaccinated
-- CTE Version
WITH POPvsVAC (Continent, Location, Date, Population, New_vaccinations, RollingVaccinations) AS
(SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations, 
	SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS RollingVaccinations
FROM CovidProject.dbo.covid_deaths death
JOIN CovidProject.dbo.covid_vaccinations vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent is not null
--ORDER BY 2,3
)
SELECT *, (RollingVaccinations/Population)*100 as PercentVaccinated FROM POPvsVAC


-- Temp Table

DROP TABLE IF EXISTS #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vacciantions numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations, 
	SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS RollingVaccinations
FROM CovidProject.dbo.covid_deaths death
JOIN CovidProject.dbo.covid_vaccinations vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent is not null
ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100 as PercentVaccinated FROM #PercentPopulationVaccinated


-- Creating View to store data for later visualizations
Create View PercentPopulationVaccianted as 
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations, 
	SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS RollingVaccinations
FROM CovidProject.dbo.covid_deaths death
JOIN CovidProject.dbo.covid_vaccinations vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent is not null
