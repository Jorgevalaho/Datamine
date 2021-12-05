# Zaklad dat budou tabulky covid19_basic_differences a covid19_tests.
# Seznam zemi v covid19_basic_differences se musi shodovat se seznamem z covid19_tests.
# Nektere nazvy zemi se v tabulkach lisi.

# Zeme co jsou v covid tests, ale ne v differences.
create view v_zeme_v_tests_ale_ne_v_diff as
select ct.country 
from covid19_tests ct 
except
select cbd.country 
from covid19_basic_differences cbd ;

# Zeme co jsou v differences, ale ne v tests.
create view v_zeme_v_diff_ale_ne_v_tests as
select cbd.country 
from covid19_basic_differences cbd
except
select ct.country 
from covid19_tests ct ;

# Tyto zeme prejmenovat v tabulce tests.
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
select 
	cbd.country , cbd.`date` , cbd.confirmed , tctuz.tests_performed 
from covid19_basic_differences cbd 
left join t_covid_tests_uprava_zemi tctuz
on cbd.country = tctuz.country and cbd.`date` = tctuz.`date`
order by country asc;

# Tabulka s poslednim dostupnym udajem o detske umrtnosti.
create table t_mort5 as
select 
	country , mortaliy_under5 
from economies e
where mortaliy_under5 is not null
group by country 
order by country asc;

# Udaje o HDP na obyvatele chci za 2020, nebo 2019. Starsi nechci.
# HDP na obyvatele za 2020.
create table t_gdp_per_capita
select 
	country , 
	GDP , 
	round (gdp / population, 2) as gdp_per_capita
from economies e 
where `year` = '2020'
order by country asc;

# HPD na obyvatele za rok 2019 u zemi, kde chybi udaj za rok 2020.
create table t_gdp_per_capita_2019
select 
	z.country , 
	e.GDP , 
	round (e.gdp / e.population, 2) as gdp_per_capita
from economies e 
join 
    (select country 
    from economies e2 
    where `year`= '2020' and gdp is null) as z
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
select 
	country ,
	`year` , 
	gini as GINI
from economies e 
where year >= 2010 and gini is not null
group by country 
order by country asc;

# Population density vypocitam. V tabulce countries se hodnota population_density u nekterych zemi lisi od vypoctene hodnoty z population/surface_area. 
# Vypocitavam jen z udaju dostupnych.
create table t_pop_density
select 
	country , 
	round (population / surface_area,4) as population_density
from countries c 
where population != 0 and surface_area != 0
order by country asc;

# Podily nabozenstvi. Pocitam podil populace na nabozenstvi / suma populace dle zeme. Vse pocitam z tabulky religions. 
create table t_religion_share as
select 
	base.country, 
	base.religion, 
	base.population, 
	a.total_population,
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
select 
	le15.country, 
	le15.life_expectancy_2015, 
	le65.life_expectancy_1965, 
	round (le15.life_expectancy_2015-le65.life_expectancy_1965, 2) as life_expectancy_diff
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
select 
	zeme.country, 
	base.*
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
select 
	*, 
	avg (cast (trim (trim (trailing '°c' from temp))as float)) as avg_temp
from t_weather tw 
where `time` between '06:00' and '18:00'
and country is not null
group by country, `date`;

# Pocet hodin srazek behem dne.
create table t_srazky as
	select 
	*, 
	count (rain2) as pocet_zaznamu_srazek, (count (rain2))*3 as Rain_hours
from
    (select *,cast (trim (trim (trailing 'mm' from rain))as float) as rain2
     from t_weather tw 
     where country is not null) as base
where rain2 > 0
group by country, `date`;

# Maximalni sila vetru v narazech behem dne.
create table t_max_gusty_wind as
	select 
	*, 
	max (cast (trim (trim (trailing 'km/h' from gust))as int)) as max_gusty_wind
from t_weather tw 
	where `time` between '06:00' and '18:00'
	and country is not null
group by country,`date` ;

# Tabulku t_covid_confirmed_tests rozsirim o casove promenne, ktere budou nasledovat hned za sloupcem date.
create table t_covid_confirmed_tests_cas as
select 
	country ,
	`date` , 
	case 
              when dayofweek (`date`) = 7 or dayofweek (`date`) = 1 then 'YES'
              else 'NO'
              end as Weekend,
              case when `date` BETWEEN '2020-03-20' AND '2020-06-20' or `date` between '2021-03-20' AND '2021-06-20' then 0
              when `date` BETWEEN '2020-06-21' AND '2020-09-21' or `date` between '2021-06-21' AND '2021-09-21' then 1
              when `date` BETWEEN '2020-09-22' AND '2020-12-20' or `date` between '2021-09-22' AND '2021-12-20' then 2
              else 3
         	  end as Season,
     confirmed , 
     tests_performed 
from t_covid_confirmed_tests tcct ;

# Uprava tabulek vychazejicich z economies, aby se nazvy zemi shodovaly se zakladni tabulkou t_covid_confirmed_tests_cas.
update t_mort5 set country = 'Brunei' where country = 'Brunei Darussalam';
update t_mort5 set country = 'Czechia' where country = 'Czech Republic';
update t_mort5 set country = 'Burma' where country = 'Myanmar';
update t_mort5 set country = 'Russia' where country = 'Russian Federation';
update t_mort5 set country = 'Korea, South' where country ='South Korea';
update t_mort5 set country = 'Saint Kitts and Nevis' where country = 'St. Kitts and Nevis';
update t_mort5 set country = 'Saint Lucia' where country = 'St. Lucia';
update t_mort5 set country = 'Saint Vincent and the Grenadines' where country = 'St. Vincent and the Grenadines';
update t_mort5 set country = 'Congo (Kinshasa)' where country = 'The Democratic Republic of Congo';
update t_mort5 set country = 'Congo (Brazzaville)' where country = 'Congo';
update t_mort5 set country = 'US' where country = 'United States';

update t_gdp_per_capita set country = 'Brunei' where country = 'Brunei Darussalam';
update t_gdp_per_capita set country = 'Czechia' where country = 'Czech Republic';
update t_gdp_per_capita set country = 'Burma' where country = 'Myanmar';
update t_gdp_per_capita set country = 'Russia' where country = 'Russian Federation';
update t_gdp_per_capita set country = 'Korea, South' where country ='South Korea';
update t_gdp_per_capita set country = 'Saint Kitts and Nevis' where country = 'St. Kitts and Nevis';
update t_gdp_per_capita set country = 'Saint Lucia' where country = 'St. Lucia';
update t_gdp_per_capita set country = 'Saint Vincent and the Grenadines' where country = 'St. Vincent and the Grenadines';
update t_gdp_per_capita set country = 'Congo (Kinshasa)' where country = 'The Democratic Republic of Congo';
update t_gdp_per_capita set country = 'Congo (Brazzaville)' where country = 'Congo';
update t_gdp_per_capita set country = 'US' where country = 'United States';

update t_gini set country = 'Czechia' where country = 'Czech Republic';
update t_gini set country = 'Burma' where country = 'Myanmar';
update t_gini set country = 'Russia' where country = 'Russian Federation';
update t_gini set country = 'Korea, South' where country ='South Korea';
update t_gini set country = 'Saint Lucia' where country = 'St. Lucia';
update t_gini set country = 'Congo (Kinshasa)' where country = 'The Democratic Republic of Congo';
update t_gini set country = 'Congo (Brazzaville)' where country = 'Congo';
update t_gini set country = 'US' where country = 'United States';

# Uprava tabulky t_pop_density, aby se nazvy zemi shodovaly se zakladni tabulkou.
update t_pop_density set country = 'US' where country = 'United States';
update t_pop_density set country = 'Korea, South' where country = 'South Korea';
update t_pop_density set country = 'Burma' where country = 'Myanmar';
update t_pop_density set country = 'Czechia' where country = 'Czech Republic';
update t_pop_density set country = 'Congo (Kinshasa)' where country = 'Congo';

# Uprava nazvu zemi v tabulce t_religion_share.
update t_religion_share set country = 'Czechia' where country = 'Czech Republic';
update t_religion_share set country = 'Burma' where country = 'Myanmar';
update t_religion_share set country = 'Russia' where country = 'Russian Federation';
update t_religion_share set country = 'Korea, South' where country ='South Korea';
update t_religion_share set country = 'Saint Kitts and Nevis' where country = 'St. Kitts and Nevis';
update t_religion_share set country = 'Saint Lucia' where country = 'St. Lucia';
update t_religion_share set country = 'Saint Vincent and the Grenadines' where country = 'St. Vincent and the Grenadines';
update t_religion_share set country = 'Congo (Kinshasa)' where country = 'The Democratic Republic of Congo';
update t_religion_share set country = 'Congo (Brazzaville)' where country = 'Congo';
update t_religion_share set country = 'US' where country = 'United States';

# Uprava nazvu Taiwan v tabulce t_religion_share.
update t_religion_share set country = 'Taiwan*' where country = 'Taiwan';

# Uprava zemi v t_life_expectancy_diff.
update t_life_expectancy_diff set country = 'Czechia' where country = 'Czech Republic';
update t_life_expectancy_diff set country = 'Burma' where country = 'Myanmar';
update t_life_expectancy_diff set country = 'Russia' where country = 'Russian Federation';
update t_life_expectancy_diff set country = 'Korea, South' where country ='South Korea';
update t_life_expectancy_diff set country = 'Congo (Kinshasa)' where country = 'The Democratic Republic of Congo';
update t_life_expectancy_diff set country = 'Congo (Brazzaville)' where country = 'Congo';
update t_life_expectancy_diff set country = 'US' where country = 'United States';
update t_life_expectancy_diff set country = 'Taiwan*' where country = 'Taiwan';

# Uprava zemi v tabulkach vychazejicich z t_weather.
update t_avg_temp set country = 'Russia' where country = 'Russian Federation';
update t_srazky set country = 'Russia' where country = 'Russian Federation';
update t_max_gusty_wind set country = 'Russia' where country = 'Russian Federation';

# Tabulky pro nabozenstvi.
create table t_christianity as
select country , religion, perc_share_on_total_population as Christianity 
from t_religion_share trs2 where religion = 'Christianity';

create table t_islam as
select country , religion, perc_share_on_total_population as Islam
from t_religion_share trs2 where religion = 'Islam';

create table t_Unaffiliated_Religions as
select country , religion, perc_share_on_total_population as Unaffiliated_Religions
from t_religion_share trs2 where religion = 'Unaffiliated Religions';

create table t_hinduism as
select country , religion, perc_share_on_total_population as Hinduism
from t_religion_share trs2 where religion = 'Hinduism';

create table t_buddhism as
select country , religion, perc_share_on_total_population as Buddhism
from t_religion_share trs2 where religion = 'Buddhism';

create table t_Folk_Religions as
select country , religion, perc_share_on_total_population as Folk_Religions
from t_religion_share trs2 where religion = 'Folk Religions';

create table t_Other_Religions as
select country , religion, perc_share_on_total_population as Other_Religions
from t_religion_share trs2 where religion = 'Other Religions';

create table t_Judaism as
select country , religion, perc_share_on_total_population as Judaism
from t_religion_share trs2 where religion = 'Judaism';

# Tabulka finale.

create table t_Jiri_Valasek_projekt_SQL_final as
select 
	tcctc.*, 
	tpd.population_density , 
	tgpc.gdp_per_capita , 
	tg.GINI , 
	tm.mortaliy_under5 , 
	tled.life_expectancy_diff , 
	tc.Christianity , 
	ti.Islam , 
	tb.Buddhism ,
	th.Hinduism ,
	tj.Judaism ,
    tfr.Folk_Religions ,
    tur.Unaffiliated_Religions ,
    tor.Other_Religions , 
    tat.avg_temp ,
    ts.Rain_hours ,
    tmgw.max_gusty_wind 
from t_covid_confirmed_tests_cas tcctc 
left join t_pop_density tpd 
on tcctc.country = tpd.country 
left join t_gdp_per_capita tgpc 
on tcctc.country = tgpc.country 
left join t_gini tg 
on tcctc.country = tg.country 
left join t_mort5 tm 
on tcctc.country = tm.country 
left join t_life_expectancy_diff tled 
on tcctc.country = tled.country
left join t_christianity tc 
on tcctc.country = tc.country 
left join t_islam ti 
on tcctc.country = ti.country 
left join t_buddhism tb 
on tcctc.country = tb.country 
left join t_hinduism th 
on tcctc.country = th.country 
left join t_judaism tj 
on tcctc.country = tj.country 
left join t_folk_religions tfr 
on tcctc.country = tfr.country
left join t_unaffiliated_religions tur 
on tcctc.country = tur.country 
left join t_other_religions tor 
on tcctc.country = tor.country 
left join t_avg_temp tat 
on tcctc.country = tat.country and tcctc.`date` = tat.`date` 
left join t_srazky ts 
on tcctc.country = ts.country and tcctc.`date` = ts.`date` 
left join t_max_gusty_wind tmgw 
on tcctc.country = tmgw.country and tcctc.`date` = tmgw.`date` ;

# Vytvoreni tabulky s udaji o celkove populaci a uprava nazvu zemi.
create table t_population as 
select country ,population 
from countries;

update t_population set country = 'US' where country = 'United States';
update t_population set country = 'Korea, South' where country = 'South Korea';
update t_population set country = 'Burma' where country = 'Myanmar';
update t_population set country = 'Czechia' where country = 'Czech Republic';
update t_population set country = 'Congo (Kinshasa)' where country = 'Congo';

# Smazani tabulky finale.
drop table t_jiri_valasek_projekt_sql_final ;

# Vytvoreni nove tabulky finale.
create table t_Jiri_Valasek_projekt_SQL_final as
select 
	tcctc.*,
	tp.population ,
	tpd.population_density , 
	tgpc.gdp_per_capita , 
	tg.GINI , 
	tm.mortaliy_under5 , 
	tled.life_expectancy_diff , 
	tc.Christianity , 
	ti.Islam , 
	tb.Buddhism ,
	th.Hinduism ,
	tj.Judaism ,
    tfr.Folk_Religions ,
    tur.Unaffiliated_Religions ,
    tor.Other_Religions , 
    tat.avg_temp ,
    ts.Rain_hours ,
    tmgw.max_gusty_wind 
from t_covid_confirmed_tests_cas tcctc 
left join t_population tp 
on tcctc.country = tp.country 
left join t_pop_density tpd 
on tcctc.country = tpd.country 
left join t_gdp_per_capita tgpc 
on tcctc.country = tgpc.country 
left join t_gini tg 
on tcctc.country = tg.country 
left join t_mort5 tm 
on tcctc.country = tm.country 
left join t_life_expectancy_diff tled 
on tcctc.country = tled.country
left join t_christianity tc 
on tcctc.country = tc.country 
left join t_islam ti 
on tcctc.country = ti.country 
left join t_buddhism tb 
on tcctc.country = tb.country 
left join t_hinduism th 
on tcctc.country = th.country 
left join t_judaism tj 
on tcctc.country = tj.country 
left join t_folk_religions tfr 
on tcctc.country = tfr.country
left join t_unaffiliated_religions tur 
on tcctc.country = tur.country 
left join t_other_religions tor 
on tcctc.country = tor.country 
left join t_avg_temp tat 
on tcctc.country = tat.country and tcctc.`date` = tat.`date` 
left join t_srazky ts 
on tcctc.country = ts.country and tcctc.`date` = ts.`date` 
left join t_max_gusty_wind tmgw 
on tcctc.country = tmgw.country and tcctc.`date` = tmgw.`date` ;

# Kontroloval jsem chybejici udaje ve finalni tabulce a nasel chyby.
# Zahozeni finalni tabulky a oprava chyb v primarnich datech.

drop table t_jiri_valasek_projekt_sql_final ;

update t_population set country = "Cote d'Ivoire" where country = 'Ivory Coast';
update t_population set country = 'Fiji' where country = 'Fiji Islands';
update t_population set country = 'Holy See' where country = 'Holy See (Vatican City State)';
update t_population set country = 'Libya' where country = 'Libyan Arab Jamahiriya';
update t_population set country = 'Micronesia' where country = 'Micronesia, Federated States of';
update t_population set country = 'Russia' where country = 'Russian Federation';
update t_population set country = 'Timor-Leste' where country = 'East Timor';

update t_pop_density set country = "Cote d'Ivoire" where country = 'Ivory Coast';
update t_pop_density set country = 'Fiji' where country = 'Fiji Islands';
update t_pop_density set country = 'Holy See' where country = 'Holy See (Vatican City State)';
update t_pop_density set country = 'Libya' where country = 'Libyan Arab Jamahiriya';
update t_pop_density set country = 'Micronesia' where country = 'Micronesia, Federated States of';
update t_pop_density set country = 'Russia' where country = 'Russian Federation';
update t_pop_density set country = 'Timor-Leste' where country = 'East Timor';

update t_mort5 set country = "Cote d'Ivoire" where country = 'Ivory Coast';
update t_gdp_per_capita set country = "Cote d'Ivoire" where country = 'Ivory Coast';
update t_gini set country = "Cote d'Ivoire" where country = 'Ivory Coast';

# Jeste upravy chyb v primarnich datech.
update t_life_expectancy_diff set country = "Cote d'Ivoire" where country = 'Ivory Coast';
update t_life_expectancy_diff set country = 'Micronesia' where country = 'Micronesia (country)';
update t_life_expectancy_diff set country = 'Timor-Leste' where country = 'Timor';

update t_religion_share set country = "Cote d'Ivoire" where country = 'Ivory Coast';
