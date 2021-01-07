# Script for updating datasets other than DOF sales
#1 - same window
cd ~/Documents/repos/new/nycdb/src
nycdb --download hpd_complaints
nycdb --download hpd_violations
nycdb --download dob_complaints
nycdb --download dobjobs
nycdb --download hpd_registrations
nycdb --download dof_sales

#2 - separate windows
cd ~/Documents/repos/new/nycdb/src  
nycdb --download hpd_complaints

cd ~/Documents/repos/new/nycdb/src  
nycdb --download hpd_violations

cd ~/Documents/repos/new/nycdb/src   
nycdb --download dob_complaints

cd ~/Documents/repos/new/nycdb/src  
nycdb --download dobjobs

cd ~/Documents/repos/new/nycdb/src  
nycdb --download hpd_registrations

# Use find and replace to advance the months
psql -U postgres -d nycdbweb -c '
alter table hpd_complaints
rename to hpd_complaints_oct20;
drop table hpd_complaints_sep20 cascade;
alter table hpd_complaint_problems
rename to hpd_complaint_problems_oct20;
drop table hpd_complaint_problems_sep20;
alter table hpd_violations
rename to hpd_violations_oct20;
drop table hpd_violations_sep20 cascade;
alter table dob_complaints
rename to dob_complaints_oct20;
drop table dob_complaints_sep20 cascade;
alter table dobjobs
rename to dobjobs_oct20;
drop table dobjobs_sep20 cascade;
alter table hpd_registrations
rename to hpd_registrations_oct20;
drop table hpd_registrations_sep20;
alter table hpd_registrations_grouped_by_bbl
rename to hpd_registrations_grouped_by_bbl_oct20;
drop table hpd_registrations_grouped_by_bbl_sep20;
alter table hpd_registrations_grouped_by_bbl_with_contacts
rename to hpd_registrations_grouped_by_bbl_with_contacts_oct20;
drop table hpd_registrations_grouped_by_bbl_with_contacts_sep20;
alter table hpd_contacts
rename to hpd_contacts_oct20;
drop table hpd_contacts_sep20;
alter table hpd_corporate_owners
rename to hpd_corporate_owners_oct20;
drop table hpd_corporate_owners_sep20;
alter table hpd_business_addresses
rename to hpd_business_addresses_oct20;
drop table hpd_business_addresses_sep20;'

psql -U postgres -d nycdbweb -c 'alter table dof_sales rename to dof_sales_sep20;'


# Load tables into local nycdbweb instance 
nycdb --load hpd_complaints -D nycdbweb 
nycdb --load hpd_violations -D nycdbweb
nycdb --load dob_complaints  -D nycdbweb
nycdb --load dobjobs -D nycdbweb
nycdb --load hpd_registrations -D nycdbweb
nycdb --load dof_sales -D nycdbweb 
# Add indices 
psql nycdbweb -c 'create index on hpd_complaints (receiveddate);
create index on hpd_complaints (complaintid);
create index on hpd_complaints (bbl);
create index on hpd_violations (novissueddate);
create index on hpd_violations (class);
create index on dob_complaints (dateentered);
create index on dob_complaints (complaintnumber);
create index on dob_complaints (housenumber);
create index on dob_complaints (housestreet);
create index on dob_complaints (communityboard);
create index on dobjobs (prefilingdate);
create index on dobjobs (fullypaid);
create index on dobjobs (job);
create index on hpd_registrations_grouped_by_bbl_with_contacts (bbl);
create index on hpd_registrations_grouped_by_bbl_with_contacts (corpnames);
create index on dof_sales (saledate);
create index on dof_sales (saleprice);
create index on dof_sales (residentialunits);
create index on dof_sales (grosssquarefeet);
create index on dof_sales (bbl);'

# Test whether the dates are correct in the loaded tables
psql nycdbweb 
select receiveddate from hpd_complaints 
order by receiveddate desc nulls last limit 1;
select novissueddate from hpd_violations 
order by novissueddate desc nulls last limit 1;
select dateentered from dob_complaints
order by dateentered desc nulls last limit 1;
select prefilingdate from dobjobs
order by prefilingdate desc nulls last limit 1;
select saledate from dof_sales
order by saledate desc nulls last limit 1;
\q

cd ~/Documents/repos/dap-dr
# Change lines 36-37 in /Users/Lucy/Documents/dap-dr/dashboard/sql/recent_sales.sql from '1 month' and '0 month' to '2 month' and '1 month'
./communityBoardJson.js "postgres://127.0.0.1:5432/nycdbweb" > boardsoct20-2.json 
# Change line 34 in /Users/Lucy/Documents/dap-dr/dashboard/templates/communityBoard.pug to current month
./communityBoardPages.js boardsoct20-2.json public/oct20
# Run a python server to check pages look good, then archive whole dapreports directory in dap-dr_local/website subdirectory, update releasenotes
cd ~/Documents/dapreports


# Find and replace for dropdown in dapreports pages
# ([0-9][0-9][0-9]) searches for a 3-digit string and $1 is used to replace it as a variable.
# Search for:
<li class="item"><a class="dropdown" href="../([0-9][0-9][0-9]).html">October 2020</a></li>
# Replace with:
<li class="item"><a class="dropdown" href="/oct20/$1.html">October 2020</a></li><li class="item"><a class="dropdown" href="../$1.html">November 2020</a></li>


# Script for updating DOF sales towards end of month
cd ~/Documents/repos/new/nycdb/src  
source venv/bin/activate
nycdb --download dof_sales
psql -U postgres -d nycdbweb -c 'alter table dof_sales rename to dof_sales_sep20;'
nycdb --load dof_sales -D nycdbweb -P chartreuse
psql -d nycdbweb -c 'create index on dof_sales (saledate);
                    create index on dof_sales (saleprice);
                    create index on dof_sales (residentialunits);
                    create index on dof_sales (grosssquarefeet);
                    create index on dof_sales (bbl);'
psql nycdbweb select saledate from dof_sales order by saledate desc nulls last limit 1;
cd ~/Documents/repos/dap-dr
# Change lines 36-37 in /Users/Lucy/Documents/dap-dr/dashboard/sql/recent_sales.sql from '2 month' to '1 month' and '1 month' to '0 month'
./communityBoardJson.js "postgres://Lucy:chartreuse@127.0.0.1:5432/nycdbweb" > boardsoct20-2.json 
# Change line 34 in /Users/Lucy/Documents/dap-dr/dashboard/templates/communityBoard.pug to current month
./communityBoardPages.js boardsoct20-1.json public
# Run a python server to check pages look good, then archive whole dapreports directory in dap-dr_local/website subdirectory, update releasenotes
cd ~/Documents/dapreports



# Replace the entire dropdown:
# Search for:
<li class="item"><a class="dropdown" href="/jan17/([0-9][0-9][0-9]).html">January 2017</a></li>.*</li></ul>
# Replace with:
<li class="item"><a class="dropdown" href="/jan17/$1.html">January 2017</a></li><li class="item"><a class="dropdown" href="/feb17/$1.html">February 2017</a></li><li class="item"><a class="dropdown" href="/mar17/$1.html">March 2017</a></li><li class="item"><a class="dropdown" href="/apr17/$1.html">April 2017</a></li><li class="item"><a class="dropdown" href="/may17/$1.html">May 2017</a></li><li class="item"><a class="dropdown" href="/jun17/$1.html">June 2017</a></li><li class="item"><a class="dropdown" href="/jul17/$1.html">July 2017</a></li><li class="item"><a class="dropdown" href="/aug17/$1.html">August 2017</a></li><li class="item"><a class="dropdown" href="/sep17/$1.html">September 2017</a></li><li class="item"><a class="dropdown" href="/oct17/$1.html">October 2017</a></li><li class="item"><a class="dropdown" href="/nov17/$1.html">November 2017</a></li><li class="item"><a class="dropdown" href="/dec17/$1.html">December 2017</a></li><li class="item"><a class="dropdown" href="/jan18/$1.html">January 2018</a></li><li class="item"><a class="dropdown" href="/feb18/$1.html">February 2018</a></li><li class="item"><a class="dropdown" href="/mar18/$1.html">March 2018</a></li><li class="item"><a class="dropdown" href="/apr18/$1.html">April 2018</a></li><li class="item"><a class="dropdown" href="/may18/$1.html">May 2018</a></li><li class="item"><a class="dropdown" href="/jun18/$1.html">June 2018</a></li><li class="item"><a class="dropdown" href="/jul18/$1.html">July 2018</a></li><li class="item"><a class="dropdown" href="/aug18/$1.html">August 2018</a></li><li class="item"><a class="dropdown" href="/sep18/$1.html">September 2018</a></li><li class="item"><a class="dropdown" href="/oct18/$1.html">October 2018</a></li><li class="item"><a class="dropdown" href="/nov18/$1.html">November 2018</a></li><li class="item"><a class="dropdown" href="dec18/$1.html">December 2018</a></li><li class="item"><a class="dropdown" href="/jan19/$1.html">January 2019</a></li><li class="item"><a class="dropdown" href="/feb19/$1.html">February 2019</a></li><li class="item"><a class="dropdown" href="/mar19/$1.html">March 2019</a></li><li class="item"><a class="dropdown" href="/apr19/$1.html">April 2019</a></li><li class="item"><a class="dropdown" href="/may19/$1.html">May 2019</a></li><li class="item"><a class="dropdown" href="/jun19/$1.html">June 2019</a></li><li class="item"><a class="dropdown" href="/jul19/$1.html">July 2019</a></li><li class="item"><a class="dropdown" href="/aug19/$1.html">August 2019</a></li><li class="item"><a class="dropdown" href="/sep19/$1.html">September 2019</a></li><li class="item"><a class="dropdown" href="/oct19/$1.html">October 2019</a></li><li class="item"><a class="dropdown" href="/nov19/$1.html">November 2019</a></li><li class="item"><a class="dropdown" href="/dec19/$1.html">December 2019</a></li><li class="item"><a class="dropdown" href="/jan20/$1.html">January 2020</a></li><li class="item"><a class="dropdown" href="/feb20/$1.html">February 2020</a></li><li class="item"><a class="dropdown" href="/mar20/$1.html">March 2020</a></li><li class="item"><a class="dropdown" href="/apr20/$1.html">April 2020</a></li><li class="item"><a class="dropdown" href="/may20/$1.html">May 2020</a></li>

</ul>
