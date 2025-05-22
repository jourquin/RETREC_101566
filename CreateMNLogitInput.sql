##################################################################
# Prepare wide input data for logit estimation
##################################################################

# Uncalibrated assignment
@@srcTable := retrec_path0_header;

# Output table
@@dstTable := uncalibrated_europel2;


# Road OD table
@@od1Table := europel2_road;

# IWW OD table
@@od2Table := europel2_iww;

# Rail OD table
@@od3Table := europel2_rail;

# Centroids table
@@centroids := centroidsl2;

# Total quantities from and to each centroid table
@@totalqty := totalqtyl2;

drop table if exists tmp2;
create table tmp2 as select grp, org, dst, qty, length, 
    ldcost+ulcost+trcost+tpcost+mvcost as cost, 
	ldduration+ulduration+trduration+tpduration+mvduration as duration, 
	ldmode from @@srcTable;
create index tmp2idx on tmp2 (grp,org,dst,ldmode,cost);

# Create a table with the total quantity per mode, based on the minimum total cost
drop table if exists tmp;
create table tmp as select t.grp, t.org, t.dst, x.qty, t.length, t.cost, t.duration, t.ldmode 
from ( 
   select grp, org, dst, sum(qty) as qty, length, min(cost) as mincost, duration, ldmode
   from tmp2 group by grp, org, dst, ldmode
) as x inner join tmp2 as t on t.grp = x.grp and t.org=x.org and t.dst=x.dst and t.ldmode=x.ldmode and t.cost = x.mincost;


# Create wide table
create index tmpidx on tmp (grp,org,dst);

drop table if exists tmp2;
create table tmp2 as select org, dst, grp from tmp group by org,dst,grp order by org,dst,grp;
alter table tmp2 add cost1 DECIMAL(13,3);
alter table tmp2 add cost2 DECIMAL(13,3);
alter table tmp2 add cost3 DECIMAL(13,3);
alter table tmp2 add length1 DECIMAL(13,3);
alter table tmp2 add length2 DECIMAL(13,3);
alter table tmp2 add length3 DECIMAL(13,3);
alter table tmp2 add duration1 DECIMAL(13,3);
alter table tmp2 add duration2 DECIMAL(13,3);
alter table tmp2 add duration3 DECIMAL(13,3);
alter table tmp2 add qty1 DECIMAL(13,3) default 0;
alter table tmp2 add qty2 DECIMAL(13,3) default 0;
alter table tmp2 add qty3 DECIMAL(13,3) default 0;
alter table tmp2 add qty1from DECIMAL(13,3) default 0;
alter table tmp2 add qty2from DECIMAL(13,3) default 0;
alter table tmp2 add qty3from DECIMAL(13,3) default 0;
alter table tmp2 add qty1to DECIMAL(13,3) default 0;
alter table tmp2 add qty2to DECIMAL(13,3) default 0;
alter table tmp2 add qty3to DECIMAL(13,3) default 0;
create index tmp2idx on tmp2 (grp,org,dst);

# Create totalqty table
drop table if exists @@totalqty;
create table @@totalqty as select num from @@centroids;
alter table @@totalqty add grp DECIMAL(2,0) default 0;
alter table @@totalqty add qty1from DECIMAL(13,3) default 0;
alter table @@totalqty add qty2from DECIMAL(13,3) default 0;
alter table @@totalqty add qty3from DECIMAL(13,3) default 0;
alter table @@totalqty add qty1to DECIMAL(13,3) default 0;
alter table @@totalqty add qty2to DECIMAL(13,3) default 0;
alter table @@totalqty add qty3to DECIMAL(13,3) default 0;

drop table if exists tmp3;
create table tmp3 as select * from @@totalqty;
update tmp3 set grp = 1;
insert into @@totalqty select * from tmp3;
update tmp3 set grp = 2;
insert into @@totalqty select * from tmp3;
update tmp3 set grp = 3;
insert into @@totalqty select * from tmp3;
update tmp3 set grp = 4;
insert into @@totalqty select * from tmp3;
update tmp3 set grp = 5;
insert into @@totalqty select * from tmp3;
update tmp3 set grp = 6;
insert into @@totalqty select * from tmp3;
update tmp3 set grp = 7;
insert into @@totalqty select * from tmp3;
update tmp3 set grp = 8;
insert into @@totalqty select * from tmp3;
update tmp3 set grp = 9;
insert into @@totalqty select * from tmp3;
drop table if exists tmp3;


# Make sure OD tables have one single entry for each grp,org,dst combination;
drop table if exists od1;
create table od1 select grp,org,dst, sum(qty) as qty from @@od1Table group by grp, org, dst;
drop table if exists od2;
create table od2 select grp,org,dst, sum(qty) as qty from @@od2Table group by grp, org, dst;
drop table if exists od3;
create table od3 select grp,org,dst, sum(qty) as qty from @@od3Table group by grp, org, dst;
create index od1idx on od1 (grp,org,dst);
create index od2idx on od2 (grp,org,dst);
create index od3idx on od3 (grp,org,dst);

# Update qty
update tmp2,od1 set tmp2.qty1 = od1.qty 
	where tmp2.grp=od1.grp 
	and   tmp2.org=od1.org 
	and   tmp2.dst = od1.dst; 
update tmp2,od2 set tmp2.qty2 = od2.qty
	where tmp2.grp=od2.grp 
	and   tmp2.org=od2.org 
	and   tmp2.dst = od2.dst;
update tmp2,od3 set tmp2.qty3 = od3.qty
	where tmp2.grp=od3.grp 
	and   tmp2.org=od3.org 
	and   tmp2.dst = od3.dst;

# Update costs
update tmp2,tmp set tmp2.cost1 = tmp.cost  
	where tmp2.grp=tmp.grp 
	and   tmp2.org=tmp.org 
	and   tmp2.dst = tmp.dst 
	and   tmp.ldmode=1;
update tmp2,tmp set tmp2.cost2 = tmp.cost  
	where tmp2.grp=tmp.grp 
	and   tmp2.org=tmp.org 
	and   tmp2.dst = tmp.dst 
	and   tmp.ldmode=2;
update tmp2,tmp set tmp2.cost3 = tmp.cost  
	where tmp2.grp=tmp.grp 
	and   tmp2.org=tmp.org 
	and   tmp2.dst = tmp.dst 
	and   tmp.ldmode=3;

# Update lengths
update tmp2,tmp set tmp2.length1 = tmp.length 
	where tmp2.grp=tmp.grp 
	and   tmp2.org=tmp.org 
	and   tmp2.dst = tmp.dst 
	and   tmp.ldmode=1;
update tmp2,tmp set tmp2.length2 = tmp.length 
	where tmp2.grp=tmp.grp 
	and   tmp2.org=tmp.org 
	and   tmp2.dst = tmp.dst 
	and   tmp.ldmode=2;
update tmp2,tmp set tmp2.length3 = tmp.length 
	where tmp2.grp=tmp.grp 
	and   tmp2.org=tmp.org 
	and   tmp2.dst = tmp.dst 
	and   tmp.ldmode=3;

# Update durations
update tmp2,tmp set tmp2.duration1 = tmp.duration
	where tmp2.grp=tmp.grp 
	and   tmp2.org=tmp.org 
	and   tmp2.dst = tmp.dst 
	and   tmp.ldmode=1;
update tmp2,tmp set tmp2.duration2 = tmp.duration
	where tmp2.grp=tmp.grp 
	and   tmp2.org=tmp.org 
	and   tmp2.dst = tmp.dst 
	and   tmp.ldmode=2;
update tmp2,tmp set tmp2.duration3 = tmp.duration
	where tmp2.grp=tmp.grp 
	and   tmp2.org=tmp.org 
	and   tmp2.dst = tmp.dst 
	and   tmp.ldmode=3;

# Add total quantities per org and dst
drop table if exists tmp;
create table tmp as select org, grp, sum(qty1) as qty from tmp2 group by grp, org;
create index tmpidx on tmp (grp,org);
update tmp2, tmp set tmp2.qty1from = tmp.qty where tmp2.grp = tmp.grp and tmp2.org = tmp.org;
update @@totalqty, tmp set @@totalqty.qty1from = tmp.qty where @@totalqty.num = tmp.org and @@totalqty.grp = tmp.grp;

drop table if exists tmp;
create table tmp as select org, grp, sum(qty2) as qty from tmp2 group by grp, org;
create index tmpidx on tmp (grp,org);
update tmp2, tmp set tmp2.qty2from = tmp.qty where tmp2.grp = tmp.grp and tmp2.org = tmp.org;
update @@totalqty, tmp set @@totalqty.qty2from = tmp.qty where @@totalqty.num = tmp.org and @@totalqty.grp = tmp.grp;

drop table if exists tmp;
create table tmp as select org, grp, sum(qty3) as qty from tmp2 group by grp, org;
create index tmpidx on tmp (grp,org);
update tmp2, tmp set tmp2.qty3from = tmp.qty where tmp2.grp = tmp.grp and tmp2.org = tmp.org;
update @@totalqty, tmp set @@totalqty.qty3from = tmp.qty where @@totalqty.num = tmp.org and @@totalqty.grp = tmp.grp;

drop table if exists tmp;
create table tmp as select dst, grp, sum(qty1) as qty from tmp2 group by grp, dst;
create index tmpidx on tmp (grp,dst);
update tmp2, tmp set tmp2.qty1to = tmp.qty where tmp2.grp = tmp.grp and tmp2.dst = tmp.dst;
update @@totalqty, tmp set @@totalqty.qty1to = tmp.qty where @@totalqty.num = tmp.dst and @@totalqty.grp = tmp.grp;

drop table if exists tmp;
create table tmp as select dst, grp, sum(qty2) as qty from tmp2 group by grp, dst;
create index tmpidx on tmp (grp,dst);
update tmp2, tmp set tmp2.qty2to = tmp.qty where tmp2.grp = tmp.grp and tmp2.dst = tmp.dst;
update @@totalqty, tmp set @@totalqty.qty2to = tmp.qty where @@totalqty.num = tmp.dst and @@totalqty.grp = tmp.grp;

drop table if exists tmp;
create table tmp as select dst, grp, sum(qty3) as qty from tmp2 group by grp, dst;
create index tmpidx on tmp (grp,dst);
update tmp2, tmp set tmp2.qty3to = tmp.qty where tmp2.grp = tmp.grp and tmp2.dst = tmp.dst;
update @@totalqty, tmp set @@totalqty.qty3to = tmp.qty where @@totalqty.num = tmp.dst and @@totalqty.grp = tmp.grp;

# Clean temporary tables;
drop table if exists od1;
drop table if exists od2;
drop table if exists od3;
drop table if exists tmp;

# Remove records for which there is a qty but not path (must be fixed in input data)
delete from tmp2 where cost1 is null and qty1 > 0;
delete from tmp2 where cost2 is null and qty2 > 0;
delete from tmp2 where cost3 is null and qty3 > 0;

# Rename final table
drop table if exists @@dstTable;
rename table tmp2 to @@dstTable;

# Transform totalqty table in "long" format
create table tmp1 as select num, grp, qty1from as qtyfrom, qty1to as qtyto from @@totalqty;
alter table tmp1 add ldmode DECIMAL(2,0) default 1;
create table tmp2 as select num, grp, qty2from as qtyfrom, qty2to as qtyto from @@totalqty;
alter table tmp2 add ldmode DECIMAL(2,0) default 2;
create table tmp3 as select num, grp, qty3from as qtyfrom, qty3to as qtyto from @@totalqty;
alter table tmp3 add ldmode DECIMAL(2,0) default 3;
drop table if exists @@totalqty;
rename table tmp1 to @@totalqty;
insert into @@totalqty select * from tmp2;
insert into @@totalqty select * from tmp3;
drop table if exists tmp2;
drop table if exists tmp3;

SELECT 'Done.' as '';
