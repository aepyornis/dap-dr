create or replace view bbljobs as 
    select bbl, 
           job,
           jobtype
    from dobjobs
    where prefilingdate >= date_trunc('month', current_date - interval '1 month') 
	and prefilingdate < date_trunc('month', current_date - interval '0 month')
    and doc = 1
    group by bbl, job, jobtype;

SELECT subset.*,   
      first(replace(trim(both'"{}",' from cast(corpnames as text)), '"','')) as owner
    from
	(select pluto.cd,
	bbljobs.bbl,
	pluto.address,
	pluto.unitsres as residentialunits,
	uc2007, uc2019,
    pluto.borocode,
    pluto.block,
    pluto.lot,
    pluto.zipcode,
    pluto.council,
    count(case when bbljobs.jobtype ='A1' then 1 else null end) as a1,
    count(case when bbljobs.jobtype='A2' then 1 else null end) as a2,
    count(case when bbljobs.jobtype='DM' then 1 else null end) as dm,
    sum(case
        when bbljobs.jobtype = 'A1' then 1
        when bbljobs.jobtype = 'A2' then 1
        when bbljobs.jobtype = 'DM' then 1
        else 0 end) as total,
            concat('https://hpdonline.hpdnyc.org/HPDonline/Provide_address.aspx?p1=',
            pluto.borocode,
            '&p2=',
            split_part(pluto.address,' ', 1),
            '&p3=',
            split_part(pluto.address,' ',2),
            '+',
            split_part(pluto.address,' ',3),
            '+',
            split_part(pluto.address,' ',4)) as hpdlink
	from bbljobs
    LEFT JOIN pluto_19v2 pluto on bbljobs.bbl = pluto.bbl
    INNER JOIN rentstab r on r.ucbbl = bbljobs.bbl
    left join rentstab_v2 rr on rr.ucbbl = bbljobs.bbl 
    where pluto.cd = '${ cd }' 
        and coalesce(uc2007,uc2008, uc2009, uc2010, uc2011, uc2012, uc2013, uc2014,uc2015,uc2016,uc2017,uc2018,uc2019) is not null
    group by bbljobs.bbl, pluto.cd, pluto.address, residentialunits, uc2007, uc2019, borocode, pluto.block, pluto.lot, pluto.council, pluto.zipcode, pluto.bbl
    ) as subset
LEFT JOIN hpd_registrations_grouped_by_bbl_with_contacts hpd_reg on hpd_reg.bbl = subset.bbl
left join pluto_19v2 pluto on pluto.bbl = subset.bbl
where (
    a1 > 0 or
    a2 > 0 or
    dm > 0)
group by subset.bbl, subset.cd, subset.address, residentialunits, uc2007, uc2019, a1, a2, dm, total, subset.borocode, subset.block, subset.lot, hpdlink,  subset.council, subset.zipcode
order by cd asc, a2 desc
