select bbl
from dobjobs
/*changed this because I don't need it, it was ziggy's*/
where jobtype = 'not real building' 
AND communityboard = '${ cd }'
order by latestactiondate desc
limit 0;
