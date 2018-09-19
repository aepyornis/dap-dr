
select 'lots' as name, count(*) as d
from pluto_16v2
where cd = '${ cd }'

union

select 'unitsres' as name, sum(unitsres) as d
from pluto_16v2
where cd = '${ cd }'

union

select 'buildingsres' as name, sum(numbldgs) as d
from pluto_16v2
where cd = '${ cd }'
and unitsres > 0

union

select	'buildingsWithOpenViolations' as name,
	count(distinct ov_bbls.*) as d
from (
	select distinct bbl as bbl
     	from hpd_violations
	where currentstatusid not in (3,6,9,19,36)
) as ov_bbls
inner join pluto_16v2 on pluto_16v2.bbl = ov_bbls.bbl
where pluto_16v2.cd = '${ cd }'

union

select 'totalNumberOfOpenViolations' as name,
       sum(ov.c) as d
from (
	select bbl, count(*) as c
     	from hpd_violations
	where currentstatusid not in (3,6,9,19,36)
    	group by bbl
      ) as ov
left join pluto_16v2 on pluto_16v2.bbl = ov.bbl
where pluto_16v2.cd = '${ cd }';
