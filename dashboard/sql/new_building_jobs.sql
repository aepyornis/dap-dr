select id, job, doc, borough, house, streetname, bbl, bin, address,
        jobtype, jobstatus, jobstatusdescription, latestactiondate,
        buildingtype, applicantname, ownername, 
        existingheight, proposedheight, existingnoofstories, proposednoofstories,
        existingdwelling, proposeddwellingunits, jobdescription
from dobjobs
/*changed this because I don't need it, it was ziggy's*/
where jobtype = 'not real building' 
AND communityboard = '${ cd }'
order by latestactiondate desc
limit 10;
