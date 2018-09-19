-- This still doesn't select the most recent sale, but it will select only one from the last month.
select subset.*,
      first(replace(trim(both'"{}",' from cast(corpnames as text)), '"','')) as owner
      from (
            select 
            pluto.bbl,
            pluto.cd,
            pluto.address,
            pluto.unitsres as residentialunits,
            uc2007, uc2016,
            pluto.borocode,
            pluto.block,
            pluto.lot,
            pluto.zipcode,
            pluto.council,
            left(first(saleprice)::money::text, -3) as saleprice,
            left((first(saleprice) / nullif(first(sales.grosssquarefeet), 0))::money::text, -3) as ppgsf,
            left((first(saleprice) / pluto.unitsres)::money::text, -3) as ppu,
            to_char(first(saledate), 'MM/DD/YYYY') as saledate,
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
	FROM 
        (select distinct on (bbl) * from dof_sales order by bbl, saleprice desc) as sales
	LEFT JOIN pluto_18v1 pluto on sales.bbl = pluto.bbl
	INNER JOIN rentstab ON rentstab.ucbbl = pluto.bbl
	WHERE pluto.cd is not null
      AND pluto.cd = '${ cd }'
      AND saledate >= date_trunc('month', current_date - interval '2 month') 
      and saledate < date_trunc('month', current_date - interval '1 month')
      AND sales.residentialunits > 0
      AND COALESCE(uc2007,uc2008, uc2009, uc2010, uc2011, uc2012, uc2013, uc2014,uc2015,uc2016) is not null
        group by sales.bbl, pluto.cd, pluto.address, pluto.unitsres, uc2007, uc2016, borocode, pluto.block, pluto.lot, pluto.council, pluto.zipcode, pluto.bbl
      ) as subset
LEFT JOIN hpd_registrations_grouped_by_bbl_with_contacts hpd_reg on hpd_reg.bbl = subset.bbl
left join pluto_18v1 pluto on pluto.bbl = subset.bbl
group by subset.bbl, subset.cd, subset.address, residentialunits, uc2007, uc2016, subset.borocode, subset.block, subset.lot, subset.zipcode, subset.council, subset.saleprice, ppgsf, ppu, subset.saledate, hpdlink