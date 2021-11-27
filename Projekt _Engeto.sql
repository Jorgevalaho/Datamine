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

# Podily nabozenstvi. Pocitam podil populace na nabozenstvi / suma populace dle zeme. Vse pocitam z tabulky religions. 
create table t_religion_share as
select base.country, base.religion, base.population, a.total_population,
		round ((base.population/a.total_population)*100,2) as perc_share_on_total_population
from 
	(select country , religion , population 
	from religions r
	where `year` = 2020) as base
join
	(select country, sum (population) as total_population
	from religions r 
	where `year` = 2020
	group by country) as a
on base.country = a.country;

# Tabulka rozdil v ocekavane delce doziti v roce 1965 a 2015.
create table t_life_expectancy_diff as
select le15.country, le15.life_expectancy_2015, le65.life_expectancy_1965, round (le15.life_expectancy_2015-le65.life_expectancy_1965, 2) as life_expectancy_diff
from
	(select country, life_expectancy as life_expectancy_2015
	from life_expectancy le 
	where `year` = 2015) as le15
join
	(select country, life_expectancy as life_expectancy_1965
	from life_expectancy le 
	where `year` = 1965) as le65
on le15.country = le65.country
order by country ;

# Do tabulky weather pridam sloupec country.
create table t_weather as
select zeme.country, base.*
from
	(select * 
	from weather w ) as base
left join
	(select country, capital_city
	from countries) as zeme
on base.city = zeme.capital_city ;

# Tabulku t_weather jsem updatoval o nazvy zemi tam kde chybely.
update t_weather set country = 'Greece' where city = 'Athens';
update t_weather set country = 'Belgium' where city = 'Brussels';
update t_weather set country = 'Romania' where city = 'Bucharest';
update t_weather set country = 'Finland' where city = 'Helsinki';
update t_weather set country = 'Ukraine' where city = 'Kiev';
update t_weather set country = 'Portugal' where city = 'Lisbon';
update t_weather set country = 'Luxembourg' where city = 'Luxembourg';
update t_weather set country = 'Czechia' where city = 'Prague';
update t_weather set country = 'Italy' where city = 'Rome';
update t_weather set country = 'Austria' where city = 'Vienna';
update t_weather set country = 'Poland' where city = 'Warsaw';

# Upravil jsem v tabulce t_weather nazev Ruska aby se shodoval s tabulkou t_covid_confirmed_tests na kterou budu napojovat.
update t_weather set country = 'Russian Federation' where city = 'Moscow';

# Tabulka s prumernou denni teplotou.
create table t_avg_temp as
select *, avg (cast (trim (trim (trailing '°c' from temp))as float)) as avg_temp
from t_weather tw 
where `time` between '06:00' and '18:00'
and country is not null
group by country, `date`;
