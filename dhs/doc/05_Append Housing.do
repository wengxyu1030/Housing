*------------"------------------------------------------------*
*
* Date:7/28/2020
* Desription: Append Housing 
*------------------------------------------------------------*

*------------------------------------------------------------*
* BASE
*------------------------------------------------------------*

cd "C:\Users\wb308830\OneDrive - WBG\Documents\TN\India Housing Paper\Data Work\DHS"


use 2015_dhs_Housing.dta, clear 

append using 2005_dhs_Housing.dta

append using 1998_dhs_Housing.dta

append using 1992_dhs_Housing.dta

*Clean States
replace state = "arunachal pradesh" if state == "arunachalpradesh"
replace state = "jammu and kashmir" if state == "jammu"
replace state = "orissa" if state == "odisha"
replace state = "uttarakhand" if state == "uttaranchal"
replace state = "new delhi" if state == "delhi"

gen state_iso = "" 

replace state_iso="AN" if state =="andaman and nicobar islands"
replace state_iso="AP" if state =="andhra pradesh"
replace state_iso="AR" if state =="arunachal pradesh"
replace state_iso="AS" if state =="assam"
replace state_iso="BR" if state =="bihar"
replace state_iso="CH" if state =="chandigarh"
replace state_iso="CT" if state =="chhattisgarh"
replace state_iso="DN" if state =="dadra and nagar haveli"
replace state_iso="DD" if state =="daman and diu"
replace state_iso="DL" if state =="new delhi"
replace state_iso="GA" if state =="goa"
replace state_iso="GJ" if state =="gujarat"
replace state_iso="HR" if state =="haryana"
replace state_iso="HP" if state =="himachal pradesh"
replace state_iso="JK" if state =="jammu and kashmir"
replace state_iso="JH" if state =="jharkhand"
replace state_iso="KA" if state =="karnataka"
replace state_iso="KL" if state =="kerala"
replace state_iso="LD" if state =="lakshadweep"
replace state_iso="MP" if state =="madhya pradesh"
replace state_iso="MH" if state =="maharashtra"
replace state_iso="MN" if state =="manipur"
replace state_iso="ML" if state =="meghalaya"
replace state_iso="MZ" if state =="mizoram"
replace state_iso="NL" if state =="nagaland"
replace state_iso="OR" if state =="orissa"
replace state_iso="PY" if state =="puducherry"
replace state_iso="PB" if state =="punjab"
replace state_iso="RJ" if state =="rajasthan"
replace state_iso="SK" if state =="sikkim"
replace state_iso="TN" if state =="tamil nadu"
replace state_iso="AP" if state =="telangana" // this is the new state, set equal to AP
replace state_iso="TR" if state =="tripura"
replace state_iso="UT" if state =="uttarakhand"
replace state_iso="UP" if state =="uttar pradesh"
replace state_iso="WB" if state =="west bengal"


table state year [aw=hv005], c(mean dont_own) format("%9.1f") row
table state year [aw=hv005] if hv025 == 1, c(mean dont_own) format("%9.1f") row

*Expand in 2 and make second set India Total 
count 
local n = `r(N)'
expand 2
replace state_iso = "_IN" if _n > `n' 


* Generate own_dwelling 

gen double own_wt = (100-dont_own) * hv005
replace hv025 = 2- hv025
gen double urban_wt = hv025 * 100 * hv005


foreach year in 1992 1998 2005 2015 {

local yr = substr("`year'",3,2)

*Rural - Own
egen double d_`yr'_own_r_top = total(own_wt*(hv025==0)*(year==`year')), by(state_iso)
egen double d_`yr'_own_r_bottom = total(hv005*(hv025==0)*(year==`year')), by(state_iso)
gen double d_`yr'_own_r = d_`yr'_own_r_top / d_`yr'_own_r_bottom

*Urban - Own
egen double d_`yr'_own_u_top = total(own_wt*(hv025==1)*(year==`year')), by(state_iso)
egen double d_`yr'_own_u_bottom = total(hv005*(hv025==1)*(year==`year')), by(state_iso)
gen double d_`yr'_own_u = d_`yr'_own_u_top / d_`yr'_own_u_bottom

*Total - Own
egen double d_`yr'_own_top = total(own_wt*(year==`year')), by(state_iso)
egen double d_`yr'_own_bottom = total(hv005*(year==`year')), by(state_iso)
gen double d_`yr'_own = d_`yr'_own_top / d_`yr'_own_bottom

*Urban Population 
egen double d_`yr'_urban_top = total(urban_wt*(year==`year')), by(state_iso)
egen double d_`yr'_urban_bottom = total(hv005*(year==`year')), by(state_iso)
gen double d_`yr'_urban = d_`yr'_urban_top / d_`yr'_urban_bottom

}

duplicates drop state_iso, force
drop *top *bottom
keep state_iso d_*

*Save 
save dhs_hse_own_99_15.dta, replace