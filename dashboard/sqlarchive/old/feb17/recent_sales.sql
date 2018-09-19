-- This still doesn't select the most recent sale, but it will select only one from the last month.
select subset.*,
      first(replace(trim(both'"{}",' from cast(corpnames as text)), '"','')) as ownertext,
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
            replace(trim(both'"{}",' from cast(corpnames as text)), '"',''),
            ' </a>'
            )) as owner
      from (
      select 
      pluto.bbl,
      pluto.cd,
	pluto.address,
      pluto.unitsres as residentialunits,
      uc2007, uc2016,
      pluto.borocode,
      pluto.zipcode,
      pluto.council,
      pluto.numbldgs,
      left(first(saleprice)::money::text, -3) as saleprice,
      left((first(saleprice) / nullif(first(sales.grosssquarefeet), 0))::money::text, -3) as ppgsf,
      left((first(saleprice) / pluto.unitsres)::money::text, -3) as ppu,
	to_char(first(saledate), 'MM/DD/YYYY') as saledate,
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
            '" target="_blank">(HPD)</a>') as hpdlink,
      concat('<a href="http://a810-bisweb.nyc.gov/bisweb/PropertyProfileOverviewServlet?boro=',
            pluto.borocode,
            '&block=',
            pluto.block,
            '&lot=',
            pluto.lot,
            '" target="_blank">(DOB)</a>') as bislink,
      concat('<a href="http://a836-acris.nyc.gov/bblsearch/bblsearch.asp?borough=',
            pluto.borocode,
            '&block=',
            pluto.block,
            '&lot=',
            pluto.lot,
            '" target="_blank">(ACRIS)</a>') as acrislink,
      concat('<a href="http://webapps.nyc.gov:8084/CICS/fin1/find001i?FFUNC=C&FBORO=',
            pluto.borocode,
            '&FBLOCK=',
            pluto.block,
            '&FLOT=',
            pluto.lot,
            '" target="_blank">(Taxes)</a>') as taxlink,
      concat('<a href="http://www.oasisnyc.net/map.aspx?zoomto=lot:',
            pluto.bbl,
            '" target="_blank">(OASIS)</a>') as oasislink,
      concat('<a href="http://www.google.com/maps/place/',
            pluto.address,
            ' ',
            pluto.zipcode,
            '" target="_blank">',
            pluto.address,
            '</a>') as googlelink
	FROM 
        (select * from dof_sales order by saledate desc) as sales
	LEFT JOIN pluto_17v1 pluto on sales.bbl = pluto.bbl
	INNER JOIN rentstab ON rentstab.ucbbl = pluto.bbl
	WHERE pluto.cd is not null
      AND pluto.cd = '${ cd }'
      AND sales.saledate between '02-01-2017' and '02-28-2017'
      AND sales.residentialunits > 0
      AND COALESCE(uc2007,uc2008, uc2009, uc2010, uc2011, uc2012, uc2013, uc2014,uc2015,uc2016) is not null
        group by sales.bbl, pluto.cd, pluto.address, pluto.unitsres, uc2007, uc2016, borocode, pluto.block, pluto.lot, pluto.council, pluto.zipcode, pluto.bbl, pluto.numbldgs
      ) as subset
LEFT JOIN hpd_registrations_grouped_by_bbl_with_contacts hpd_reg on hpd_reg.bbl = subset.bbl
group by subset.bbl, cd, address, residentialunits, uc2007, uc2016, borocode, zipcode, council, numbldgs, subset.saleprice, ppgsf, ppu, subset.saledate, hpdlink, bislink, acrislink, taxlink, googlelink, oasislink