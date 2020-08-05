*------------"------------------------------------------------*
*
* Date:7/28/2020
* Desription: India DHS 1998
*------------------------------------------------------------*

*------------------------------------------------------------*
* BASE
*------------------------------------------------------------*

cd "C:\Users\wb308830\OneDrive - WBG\Documents\TN\India Housing Paper\Data Work\DHS"
clear
set maxvar 120000

** 2005 ** 
use "1998 IAHR42FL.dta", clear

// sample 5
//
// save "2015 IAHR74FL_s05.dta"

// use "2015 IAHR74FL_s05.dta", clear

keep hhid hv005 hv024 shv005   hv025  sh42 sh49 

gen dont_own = 100*(sh42 == 0)

gen finished = 100 *(sh49==1)

drop sh49 

gen year = 1998

table hv025 [aw=hv005], c(mean dont_own mean finished) format("%9.2f") row

decode hv024, gen(state)

compress 
save 1998_DHS_Housing.dta, replace 
