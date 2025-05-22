# Prepare a Biogeme input table using a "wide data" mlogit_input table

@@inputTable := uncalibrated_europel2;
@@outputTable := biogeme_europel2;

# Create table skeleton
drop table if exists tmp1;
create table tmp1 as select * from @@inputTable;
alter table tmp1 add avail1 DECIMAL(1,0) default 1;
alter table tmp1 add avail2 DECIMAL(1,0) default 1;
alter table tmp1 add avail3 DECIMAL(1,0) default 1;
alter table tmp1 add choice DECIMAL(1,0) default 0;
alter table tmp1 add qty DECIMAL(13,3) default 0;

# Mark available modes
update tmp1 set avail1 = 0 where cost1 is null;
update tmp1 set avail2 = 0 where cost2 is null;
update tmp1 set avail3 = 0 where cost3 is null;

# Fill for mode 2
drop table if exists tmp2;
create table tmp2 as select * from tmp1;
update tmp2 set choice = 2;
update tmp2 set qty = qty2;

# Fill for mode 3
drop table if exists tmp3;
create table tmp3 as select * from tmp1;
update tmp3 set choice = 3;
update tmp3 set qty = qty3;

# Fill for mode 1
update tmp1 set choice = 1;
update tmp1 set qty = qty1;

# Merge tables
drop table if exists @@outputTable;
create table @@outputTable as select * from tmp1 union all select * from tmp2 union all select * from  tmp3;


# Remove some inconsitent records
update @@outputTable set qty = 0 where qty is null;
update @@outputTable set qty1 = 0 where qty1 is null;
update @@outputTable set qty2 = 0 where qty2 is null;
update @@outputTable set qty3 = 0 where qty3 is null;
delete from @@outputTable where avail1 = 0 and choice = 1;
delete from @@outputTable where avail2 = 0 and choice = 2;
delete from @@outputTable where avail3 = 0 and choice = 3;

# Delete tmp tables
drop table if exists tmp1;
drop table if exists tmp2;
drop table if exists tmp3;

# Reorder records for more readability
drop table if exists tmp;
create table tmp as select * from @@outputTable order by grp, org, dst, choice;
drop table @@outputTable;
rename table tmp to @@outputTable;

SELECT 'Done.' as '';

