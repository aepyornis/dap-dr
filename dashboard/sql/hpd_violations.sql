SELECT subset.*,   
	first(concat('<a href="http://whoownswhat.justfix.nyc/address/',
       case 
              when borocode = '1' then 'MANHATTAN'
              when borocode = '2' then 'BRONX'
              when borocode = '3' then 'BROOKLYN'
              when borocode = '4' then 'QUEENS'
              when borocode = '5' then 'STATEN ISLAND'
       end,
       '/',
       split_part(address,' ',1),
       '/',
       split_part(address,' ',2),
       '%20',
       split_part(address,' ',3),
       '%20',
       split_part(address,' ',4),
       '" target="_blank">',
       replace(trim(both'"{}"' from cast(corpnames as text)), '"',''),
        ' </a>'
           )) as owner
    from
	(select pluto.cd,
	viols.bbl,
	pluto.address,
	pluto.unitsres as residentialunits,
	uc2007, uc2016,
    pluto.borocode,
	count(case when violationclass = 'A' then 1 else null end) as class_a,
	count(case when violationclass = 'B' then 1 else null end) as class_b,
	count(case when violationclass = 'C' then 1 else null end) as class_c,
		sum(case
		when violationclass = 'A' then 1
		when violationclass = 'B' then 1
		when violationclass = 'C' then 1
		else 0 end) as total,
      concat('<a href="https://hpdonline.hpdnyc.org/HPDonline/Provide_address.aspx?p1=',
            pluto.borocode,
            '&p2=',
            split_part(pluto.address,' ', 1),
            '&p3=',
            split_part(pluto.address,' ',2),
            '+',
            split_part(pluto.address,' ',3),
            '+',
            split_part(pluto.address,' ',4),
            '" target="_blank">(HPD)</a>'
               ) as hpdlink,
      concat('<a href="http://a810-bisweb.nyc.gov/bisweb/PropertyProfileOverviewServlet?boro=',
            pluto.borocode,
            '&block=',
            pluto.block,
            '&lot=',
            pluto.lot,
            '" target="_blank">(BIS)</a>'
                ) as bislink,
      concat('<a href="http://a836-acris.nyc.gov/bblsearch/bblsearch.asp?borough=',
            pluto.borocode,
            '&block=',
            pluto.block,
            '&lot=',
            pluto.lot,
            '" target="_blank">(ACRIS)</a>'
               ) as acrislink
	from hpd_violations viols
    LEFT JOIN pluto_16v2 pluto on viols.bbl = pluto.bbl
    INNER JOIN rentstab rentstab on rentstab.ucbbl = viols.bbl
    WHERE
       pluto.cd = '${ cd }' 
	   and novissueddate >= date_trunc('month', current_date - interval '3 month')
       and novissueddate < date_trunc('month', current_date - interval '2 month')
       AND coalesce(uc2007,uc2008, uc2009, uc2010, uc2011, uc2012, uc2013, uc2014,uc2015,uc2016) is not null
    group by viols.bbl, pluto.cd, pluto.address, residentialunits, novissueddate, uc2007, uc2016, borocode, pluto.block, pluto.lot
    having count(violationclass) > 9
    ) as subset
LEFT JOIN hpd_registrations_grouped_by_bbl_with_contacts hpd_reg on hpd_reg.bbl = subset.bbl
group by subset.bbl, cd, address, residentialunits, uc2007, uc2016, class_a, class_b, class_c, total, borocode, hpdlink, bislink, acrislink
order by total desc, subset.bbl asc 






