*------------"------------------------------------------------*
*
* Date:7/8/2020
* Desription: Housing ownership by state for nss data. 
*------------------------------------------------------------*

*------------------------------------------------------------*
* BASE
*------------------------------------------------------------*

***set the environment****
global ROOT "C:/Users/wb500886/OneDrive - WBG/7_Housing/survey_all/Housing_git/nss/MASTER_NSS"
global raw "${ROOT}/raw"
global inter "${ROOT}/inter"
global final "${ROOT}/final"

use "${final}/nss.dta",clear

*don't own housing 
gen dont_own = 100- legal_own

*consolidate the code
rename hh_weight hv005
rename hh_urban hv025

*state level housing ownership 
table state_iso year [aw=hv005], c(mean dont_own) format("%9.1f") row
table state_iso year [aw=hv005] if hv025 == 1, c(mean dont_own) format("%9.1f") row


*Expand in 2 and make second set India Total 
count 
local n = `r(N)'
expand 2
replace state_iso = "IN" if _n > `n' 


* Generate own_dwelling 

gen double own_wt = (100-dont_own) * hv005

gen double urban_wt = hv025 * 100 * hv005


foreach year in 2018 2012 2008 2002 1993 {

local yr = substr("`year'",3,2)

*Rural - Own
egen double n_`yr'_own_r_top = total(own_wt*(hv025==0)*(year==`year')), by(state_iso)
egen double n_`yr'_own_r_bottom = total(hv005*(hv025==0)*(year==`year')), by(state_iso)
gen double n_`yr'_own_r = n_`yr'_own_r_top / n_`yr'_own_r_bottom

*Urban - Own
egen double n_`yr'_own_u_top = total(own_wt*(hv025==1)*(year==`year')), by(state_iso)
egen double n_`yr'_own_u_bottom = total(hv005*(hv025==1)*(year==`year')), by(state_iso)
gen double n_`yr'_own_u = n_`yr'_own_u_top / n_`yr'_own_u_bottom

*Total - Own
egen double n_`yr'_own_top = total(own_wt*(year==`year')), by(state_iso)
egen double n_`yr'_own_bottom = total(hv005*(year==`year')), by(state_iso)
gen double n_`yr'_own = n_`yr'_own_top / n_`yr'_own_bottom

*Urban Population 
egen double n_`yr'_urban_top = total(urban_wt*(year==`year')), by(state_iso)
egen double n_`yr'_urban_bottom = total(hv005*(year==`year')), by(state_iso)
gen double n_`yr'_urban = n_`yr'_urban_top / n_`yr'_urban_bottom

}

duplicates drop state_iso, force
drop *top *bottom
keep state_iso n_*

*Save 
save "${final}/nss_hse_own_93_18.dta", replace
//export excel using "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\Housing_git\tableswe\hse_own.xlsx",sheet("nss") first(var) sheetrep 

