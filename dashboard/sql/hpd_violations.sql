SELECT subset.*,   
    first(replace(trim(both'"{}",' from cast(corpnames as text)), '"','')) as owner
    from
        (select pluto.cd,
        viols.bbl,
        pluto.address,
        pluto.unitsres as residentialunits,
        uc2007, uc2017,
        pluto.borocode,
        pluto.block,
        pluto.lot,
        pluto.zipcode,
        pluto.council,
        count(case when class = 'A' then 1 else null end) as class_a,
        count(case when class = 'B' then 1 else null end) as class_b,
        count(case when class = 'C' then 1 else null end) as class_c,
            sum(case
            when class = 'A' then 1
            when class = 'B' then 1
            when class = 'C' then 1
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
	from hpd_violations viols
    LEFT JOIN pluto_18v2 pluto on viols.bbl = pluto.bbl
    INNER JOIN rentstab rentstab on rentstab.ucbbl = viols.bbl
    WHERE
       pluto.cd = '${ cd }' 
	   and novissueddate >= date_trunc('month', current_date - interval '1 month') 
       and novissueddate < date_trunc('month', current_date - interval '0 month')
       and coalesce(uc2007,uc2008, uc2009, uc2010, uc2011, uc2012, uc2013, uc2014,uc2015,uc2016,uc2017) is not null
    group by viols.bbl, pluto.cd, pluto.address, residentialunits, uc2007, uc2017, borocode, pluto.block, pluto.lot, pluto.council, pluto.zipcode, pluto.bbl
    having count(class) > 9
    ) as subset
LEFT JOIN hpd_registrations_grouped_by_bbl_with_contacts hpd_reg on hpd_reg.bbl = subset.bbl
left join pluto_18v1 pluto on pluto.bbl = subset.bbl
group by subset.bbl, subset.cd, subset.address, residentialunits, uc2007, uc2017, class_a, class_b, class_c, total, subset.borocode, subset.block, subset.lot, hpdlink, subset.council, subset.zipcode
order by cd asc, total desc






