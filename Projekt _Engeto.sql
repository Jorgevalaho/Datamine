# Tabulka covid basic differences obsahuje seznam zemí, který není shodný s covid tests.
# Potøebuji mít seznam zemí z obou tabulek, abych navázal data z covid differences a covid tests. 
# Nìkteré názvy zemí se v tabulkách liší.

# Zemì co jsou v covid tests, ale nejsou v covid differences
create view v_zeme_v_tests_ale_ne_v_diff as
select ct.country 
from covid19_tests ct 
except
select cbd.country 
from covid19_basic_differences cbd ;

# Zemì co jsou v differences ale ne v tests
create view v_zeme_v_diff_ale_ne_v_tests as
select cbd.country 
from covid19_basic_differences cbd
except
select ct.country 
from covid19_tests ct ;

# tyto zemì pøejmenovat v tabulce tests
---- Czech republic = Czechia
---- Myanamar = Burma
---- South Korea = Korea, South
---- Taiwan= Taiwan*
---- United States = US

create table t_covid_tests_uprava_zemi as
select * from covid19_tests ct ;

update t_covid_tests_uprava_zemi set country = 'Czechia' where ISO = 'CZE';
update t_covid_tests_uprava_zemi set country = 'Burma' where ISO = 'MMR';
update t_covid_tests_uprava_zemi set country = 'Korea, South' where ISO = 'KOR';
update t_covid_tests_uprava_zemi set country = 'Taiwan*' where ISO = 'TWN';
update t_covid_tests_uprava_zemi set country = 'US' where ISO = 'USA';

#Vytvor tabulku, kde bude zaznam o potvrzenych pripadech a testech. Ke vsem zaznamenavanym dnum potvrzenych pripadu nejsou zaznamy o testech.

create table t_covid_confirmed_tests as
select cbd.country , cbd.`date` , cbd.confirmed , tctuz.tests_performed 
from covid19_basic_differences cbd 
left join t_covid_tests_uprava_zemi tctuz
on cbd.country = tctuz.country and cbd.`date` = tctuz.`date`
order by country asc;

# Tabulka s poslednim dostupnym udajem o detske umrtnosti.
create table t_mort5 as
select country , mortaliy_under5 
from economies e
where mortaliy_under5 is not null
group by country 
order by country asc;

# Udaje o HDP na obyvatele chci za 2020, nebo 2019. Starsi nechci.
# HDP na obyvatele za 2020.
create table t_gdp_per_capita
select country , GDP , round (gdp / population, 2) as gdp_per_capita
from economies e 
where `year` = '2020'
order by country asc;

# HPD na obyvatele za rok 2019 u zemi, kde chybi udaj za rok 2020.
create table t_gdp_per_capita_2019
select z.country , e.GDP , round (e.gdp / e.population, 2) as gdp_per_capita
from economies e 
join (select country from economies e2 where `year`= '2020' and gdp is null) as z
on z.country = e.country 
where e.`year` = '2019' and e.GDP is not null;

# Ted updatuju tabulku t_gdp_per_capita tam, kde chybi udaje za 2020 a doplnim zde udaj za 2019.
update t_gdp_per_capita as base 
inner join t_gdp_per_capita_2019 as a 
on base.country = a.country 
set base.gdp_per_capita = a.gdp_per_capita 
where base.gdp_per_capita is null 
and a.gdp_per_capita is not null;

# GINI: Nejmladsi dostupna hodnota GINI, ale zaroven ne starsi, nez z roku 2010.
create table t_gini as
select country , `year` , gini as GINI
from economies e 
where year >= 2010 and gini is not null
group by country 
order by country asc;

# Population density vypocitam. V tabulce countries se hodnota population_density u nekterych zemi lisi od vypoctene hodnoty z population/surface_area. 
# Vypocitavam jen z udaju dostupnych.
create table t_pop_density
select country , round (population / surface_area,4) as population_density
from countries c 
where population != 0 and surface_area != 0
order by country asc;

