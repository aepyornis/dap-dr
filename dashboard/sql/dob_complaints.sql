select subset.*,
      first(replace(trim(both'"{}",' from cast(corpnames as text)), '"','')) as owner
      from
            (select communityboard, 
            pluto.bbl, 
            concat(housenumber,' ',housestreet) as address,
            pluto.unitsres as residentialunits, 
            uc2007, uc2017,
            pluto.borocode,
            pluto.block,
            pluto.lot,
            pluto.zipcode,
            pluto.council,
            count(distinct complaintnumber) as dobcomplaints,
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
      from dob_complaints dob
      left join pluto_18v2 pluto on pluto.address = concat(housenumber,' ',housestreet)
      inner join rentstab on rentstab.ucbbl=pluto.bbl
      where 
      communityboard = '${ cd }'
      and dateentered >= date_trunc('month', current_date - interval '1 month') 
      and dateentered < date_trunc('month', current_date - interval '0 month')
      and pluto.unitsres > 0 
      AND COALESCE(uc2007,uc2008, uc2009, uc2010, uc2011, uc2012, uc2013, uc2014,uc2015,uc2016,uc2017) is not null
      group by pluto.bbl, concat(housenumber,' ',housestreet), communityboard, pluto.unitsres, uc2007, uc2017, pluto.address, pluto.borocode, pluto.block, pluto.lot, pluto.council, pluto.zipcode, pluto.bbl
      having count(distinct complaintnumber) > 1
      ) as subset
LEFT JOIN hpd_registrations_grouped_by_bbl_with_contacts hpd_reg on hpd_reg.bbl = subset.bbl
left join pluto_18v1 pluto on pluto.bbl = subset.bbl
group by subset.bbl, subset.address, communityboard, residentialunits, uc2007, uc2017, dobcomplaints, subset.borocode, subset.block, subset.lot, hpdlink, subset.council, subset.zipcode
      order by communityboard asc, dobcomplaints desc

/*
more minimal SQL code/table for testing/other applications

same criteria for narrowing/filtering, but just cb, BBL, and dob complaint count (can be a view table for other testing)
      select communityboard,
            pluto.bbl, 
            count(distinct complaintnumber) as dobcomplaints
      from dob_complaints dob
      left join pluto_18v1 pluto on pluto.address = concat(housenumber,' ',housestreet)
      inner join rentstab on rentstab.ucbbl=pluto.bbl
      where 
      dateentered >= date_trunc('month', current_date - interval '1 month') 
      and dateentered < date_trunc('month', current_date - interval '0 month')
      and pluto.unitsres > 0 
      AND COALESCE(uc2007,uc2008, uc2009, uc2010, uc2011, uc2012, uc2013, uc2014,uc2015,uc2016,uc2017) is not null
      group by pluto.bbl, concat(housenumber,' ',housestreet), communityboard, pluto.unitsres, uc2007, uc2017, pluto.address, pluto.borocode, pluto.block, pluto.lot, pluto.council, pluto.zipcode, pluto.bbl
      having count(distinct complaintnumber) > 1

*/