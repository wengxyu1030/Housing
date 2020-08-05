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
clear matrix
set maxvar 120000

** 2005 ** 
use "1992 IAHR23FL.dta", clear

// sample 5
//
// save "2015 IAHR74FL_s05.dta"

// use "2015 IAHR74FL_s05.dta", clear

ren shweight shv005

keep hhid hv005 hv024 shv005   hv025  sh031  

gen finished = 100 *(sh031==1)

drop sh031 

gen year = 1992

table hv025 [aw=hv005], c(mean finished) format("%9.2f") row

decode hv024, gen(state)

compress 
save 1992_DHS_Housing.dta, replace 
