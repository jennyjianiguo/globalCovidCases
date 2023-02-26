/*
Covid 19 Data Exploration
Skills used: Joins, Subqueries, CTEs, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

-- Change Relevant Datatypes
update covid_deaths set total_deaths = NULL where total_deaths = '';
alter table covid_deaths modify total_deaths int;

update covid_vaccinations set new_vaccinations = NULL where new_vaccinations = '';
alter table covid_vaccinations modify new_vaccinations int;

select * from covid_deaths;

-- 1. Total Cases vs Total Deaths
-- Shows likelihood of death from contracting Covid in the United States over time
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
from covid_deaths
where location = 'United States'
order by 1, 2;

-- 2. Average Death Percentage by Country
select location, avg(death_percentage) as avg_death_percent
from
	(select location, date, (total_deaths/total_cases)*100 as death_percentage from covid_deaths where continent != '')
    as cases_death_percent
group by location
order by 2 desc;

-- 3. Total Cases vs Population
-- Shows percentage of the population infected with Covid in the United States over time
select location, date, total_cases, population, (total_cases/population)*100 as population_infected_percentage
from covid_deaths
where location like '%states%'
order by 1, 2;

-- 4. Countries with Highest Infection Rate compared to Population
select location, population, max(total_cases) as highest_infection, max((total_cases/population))*100 as population_infected_percentage
from covid_deaths
where continent != ''
group by 1, 2
order by 4 desc;

-- 5. Countries with Highest Death Count
select location, max(total_deaths) as total_death_count
from covid_deaths
where continent != ''
group by 1
order by 2 desc;

-- 6. Infection Percentage by Continent
select continent, max(total_cases/population) as total_infected_percent
from covid_deaths
where continent != ''
group by 1
order by 2 desc;

-- 7. Global Infection and Death by Covid Percentage
select max(total_cases/population) as total_infected_percent, max(total_deaths/population) as death_by_covid_percent
from covid_deaths
where continent != '';

-- 8. Total Population vs Vaccinations
-- Shows percentage of the population that has recieved at least one Covid Vaccine over time
-- CTE method
with pop_vs_vac (location, date, population, new_vaccinations, sum_people_vaccinated)
as(
	select d.location, d.date, d.population, v.new_vaccinations,
		sum(v.new_vaccinations) over (partition by d.location order by d.location, d.date) as sum_people_vaccinated
		-- sum_people_vaccinated*100
	from covid_deaths d
	join covid_vaccinations v
		on d.location = v.location
		and d.date = v.date
	where d.continent != ''
)
select *, (sum_people_vaccinated/Population)*100 as percent_vaccinated
from pop_vs_vac;

-- Temp table method
drop table if exists percent_vaccinated;
create temporary table percent_vaccinated(
	location varchar(255),
	date varchar(20),
	population int,
	new_vaccinations int,
	sum_people_vaccinated int
);
insert into percent_vaccinated(
	select d.location, d.date, d.population, v.new_vaccinations,
		sum(v.new_vaccinations) over (partition by d.location order by d.location, d.date) as sum_people_vaccinated
		-- sum_people_vaccinated*100
	from covid_deaths d
	join covid_vaccinations v
		on d.location = v.location
		and d.date = v.date
	where d.continent != ''
);
select *, (sum_people_vaccinated/Population)*100 as percent_vaccinated
from percent_vaccinated;

-- 9. Creating View for future data visualization
create view percent_vaccinated as(
	select d.location, d.date, d.population, v.new_vaccinations,
		sum(v.new_vaccinations) over (partition by d.location order by d.location, d.date) as sum_people_vaccinated
		-- sum_people_vaccinated*100
	from covid_deaths d
	join covid_vaccinations v
		on d.location = v.location
		and d.date = v.date
	where d.continent != '');