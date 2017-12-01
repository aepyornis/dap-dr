select subset.*,
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
      (select community_board, 
      pluto.bbl, 
      concat(house_number,' ',house_street) as address,
      pluto.unitsres as residentialunits, 
      uc2007, uc2016,
      pluto.borocode,
      count(distinct complaint_number) as dobcomplaints,
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
                  '" target="_blank">(DOB)</a>') as bislink,
            concat('<a href="http://a836-acris.nyc.gov/bblsearch/bblsearch.asp?borough=',
                  pluto.borocode,
                  '&block=',
                  pluto.block,
                  '&lot=',
                  pluto.lot,
                  '" target="_blank">(ACRIS)</a>'
                  ) as acrislink,
            concat('<a href="http://webapps.nyc.gov:8084/CICS/fin1/find001i?FFUNC=C&FBORO=',
                  pluto.borocode,
                  '&FBLOCK=',
                  pluto.block,
                  '&FLOT=',
                  pluto.lot,
                  '" target="_blank">(Taxes)</a>') as taxlink,
            concat('<a href="http://www.google.com/maps/place/',
                  pluto.address,
                  ' ',
                  pluto.zipcode,
                  '" target="_blank">',
                  pluto.address,
                  '</a>') as googlelink
      from dob_complaints dob
      left join pluto_16v2 pluto on pluto.address = concat(house_number,' ',house_street)
      inner join rentstab on rentstab.ucbbl=pluto.bbl
      where cast(date_entered as date) >= date_trunc('month', current_date - interval '1 month') 
      AND community_board = '${ cd }'
      and pluto.unitsres > 0 
      AND COALESCE(uc2007,uc2008, uc2009, uc2010, uc2011, uc2012, uc2013, uc2014,uc2015,uc2016) is not null
      group by pluto.bbl, concat(house_number,' ',house_street), community_board, pluto.unitsres, uc2007, uc2016, pluto.address, pluto.borocode, pluto.block, pluto.lot, pluto.zipcode
      having count(distinct complaint_number) > 1
      ) as subset
LEFT JOIN hpd_registrations_grouped_by_bbl_with_contacts hpd_reg on hpd_reg.bbl = subset.bbl
group by subset.bbl, address, community_board, residentialunits, uc2007, uc2016, dobcomplaints, borocode, hpdlink, bislink, acrislink, googlelink, taxlink
      order by community_board asc, dobcomplaints desc


