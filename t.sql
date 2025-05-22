DISABLEECHO;
DISABLEHEADERS;
# Mode 1 = road, 2 = IWW, 3 = Rail
@@mode := 1;
# Scenario 1 = reference, 2 = road + 5%, 3 = IWW + 5%, 4 = Rail + 5%
@@vnet := retrec_vnet1;
SELECT ROUND(SUM(`qty0`),0) FROM @@vnet WHERE `mode1` = 0 AND `mode2` = @@mode GROUP BY `mode2`;
SELECT ROUND(SUM(`qty1`),0) FROM @@vnet WHERE `mode1` = 0 AND `mode2` = @@mode GROUP BY `mode2`;
SELECT ROUND(SUM(`qty2`),0) FROM @@vnet WHERE `mode1` = 0 AND `mode2` = @@mode GROUP BY `mode2`;
SELECT ROUND(SUM(`qty3`),0) FROM @@vnet WHERE `mode1` = 0 AND `mode2` = @@mode GROUP BY `mode2`;
SELECT ROUND(SUM(`qty4`),0) FROM @@vnet WHERE `mode1` = 0 AND `mode2` = @@mode GROUP BY `mode2`;
SELECT ROUND(SUM(`qty5`),0) FROM @@vnet WHERE `mode1` = 0 AND `mode2` = @@mode GROUP BY `mode2`;
SELECT ROUND(SUM(`qty6`),0) FROM @@vnet WHERE `mode1` = 0 AND `mode2` = @@mode GROUP BY `mode2`;
SELECT ROUND(SUM(`qty7`),0) FROM @@vnet WHERE `mode1` = 0 AND `mode2` = @@mode GROUP BY `mode2`;
SELECT ROUND(SUM(`qty8`),0) FROM @@vnet WHERE `mode1` = 0 AND `mode2` = @@mode GROUP BY `mode2`;
SELECT ROUND(SUM(`qty9`),0) FROM @@vnet WHERE `mode1` = 0 AND `mode2` = @@mode GROUP BY `mode2`;
ENABLEECHO;
