######################################################################
# Create Nodus OD tables (NUTS2) from an ETIS modelled (CSV) data
######################################################################

# Replace "xxx" by "iww", "rail" or "road"
@@srcTable := f_transport_xxx;
@@dstTable := od2010l2_xxx;

drop table if exists @@srcTable;
CREATE TABLE @@srcTable (
    id  DECIMAL(9),
    org3 DECIMAL(9),
    dst3 DECIMAL(9),
    nst2 DECIMAL(2),
    qty DECIMAL(15,4)
);

# Use importcsvh Nodus SQL command (import CSV file with Header)
importcsvh @@srcTable;

# Add level 2 origin an destination and level1 NST
alter table @@srcTable 
	add column org2 decimal(7),
	add column dst2 decimal(7),
	add column nst1 decimal(1);
update @@srcTable set 
	org2 = floor(org3/100),
	dst2 = floor(dst3/100),
	nst1 = floor(nst2/10);

# Create indexes to improve performance
create index idx2 on @@srcTable (org2,dst2,nst1);

# Zone level 2 OD
drop table if exists @@dstTable;
create table @@dstTable as select nst1 as grp, org2 as org , dst2 as dst, round(sum(qty),0) as qty from @@srcTable group by org, dst, grp;
delete from @@dstTable where org = dst;
delete from @@dstTable where qty = 0;
