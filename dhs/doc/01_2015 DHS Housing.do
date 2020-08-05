*------------"------------------------------------------------*
*
* Date:7/28/2020
* Desription: India DHS
*------------------------------------------------------------*

*------------------------------------------------------------*
* BASE
*------------------------------------------------------------*

cd "C:\Users\wb308830\OneDrive - WBG\Documents\TN\India Housing Paper\Data Work\DHS"
clear
set maxvar 120000

** 2015 ** 
use "2015 IAHR74FL.dta", clear

// sample 5
//
// save "2015 IAHR74FL_s05.dta"

// use "2015 IAHR74FL_s05.dta", clear

keep hhid hv005 hv024  hv025  shv005 sh46 hv213 hv214 hv215 shstruc

gen dont_own = 100*(sh46 == 0)

gen finished = 100 *( (hv213 >= 30 & hv213 < 40) & (hv214 >= 30 & hv214 < 40) & (hv215 >= 30 & hv215 < 40))

drop sh46 hv2*

gen year = 2015

table hv025 [aw=hv005], c(mean dont_own mean finished) format("%9.2f") row

decode hv024, gen(state)

compress 
save 2015_DHS_Housing.dta, replace 
