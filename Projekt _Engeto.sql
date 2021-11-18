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

