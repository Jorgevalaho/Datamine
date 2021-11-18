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

