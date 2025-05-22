drop table if exists europel2;
drop table if exists pre;
create table pre as select * from europel2_road union all select * from  europel2_iww union all select * from europel2_rail;
create table  europel2 as select grp, org, dst, sum(qty) as qty from pre group by grp, org, dst;
drop table pre;

