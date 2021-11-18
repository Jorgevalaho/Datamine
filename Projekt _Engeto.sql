# Tabulka covid basic differences obsahuje seznam zem�, kter� nen� shodn� s covid tests.
# Pot�ebuji m�t seznam zem� z obou tabulek, abych nav�zal data z covid differences a covid tests. 
# N�kter� n�zvy zem� se v tabulk�ch li��.

# Zem� co jsou v covid tests, ale nejsou v covid differences
create view v_zeme_v_tests_ale_ne_v_diff as
select ct.country 
from covid19_tests ct 
except
select cbd.country 
from covid19_basic_differences cbd ;

# Zem� co jsou v differences ale ne v tests
create view v_zeme_v_diff_ale_ne_v_tests as
select cbd.country 
from covid19_basic_differences cbd
except
select ct.country 
from covid19_tests ct ;

# tyto zem� p�ejmenovat v tabulce tests
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