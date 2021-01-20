select subset.*,
      first(replace(trim(both'"{}",' from cast(corpnames as text)), '"','')) as owner
      from
            (select pluto.cd, 
            hpd.bbl, 
            pluto.address,
            pluto.unitsres as residentialunits, 
            uc2007, uc2019,
            pluto.borocode, 
            pluto.block,
            pluto.lot,
            pluto.zipcode,
            pluto.council,
            count(distinct complaintid) as hpdcomplaints,
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
      from hpd_complaints hpd
      left join pluto_19v2 pluto on pluto.bbl=hpd.bbl
      inner join rentstab on rentstab.ucbbl=hpd.bbl
      left join rentstab_v2 rr on rr.ucbbl = pluto.bbl 
      where 
            pluto.cd = '${ cd }' and
            receiveddate >= date_trunc('month', current_date - interval '2 month') 
            and receiveddate < date_trunc('month', current_date - interval '1 month')
            and pluto.unitsres > 0
            and coalesce(uc2007,uc2008, uc2009, uc2010, uc2011, uc2012, uc2013, uc2014,uc2015,uc2016,uc2017,uc2018,uc2019) is not null
      group by hpd.bbl, pluto.cd, pluto.address, residentialunits, uc2007, uc2019, borocode, pluto.block, pluto.lot, pluto.council, pluto.zipcode, pluto.bbl
      having count(distinct complaintid) > 4
      ) as subset
left join hpd_registrations_grouped_by_bbl_with_contacts hpd_reg on hpd_reg.bbl = subset.bbl
left join pluto_19v2 pluto on pluto.bbl = subset.bbl
group by subset.bbl, subset.cd, subset.address, residentialunits, uc2007, uc2019, hpdcomplaints, subset.borocode, subset.block, subset.lot, hpdlink, subset.council, subset.zipcode
order by cd asc, hpdcomplaints desc


