**This file is to clearn census 2011 data. 
global github "C:/Users/wb500886/OneDrive - WBG/7_Housing/survey_all/Housing_git/census"

import excel "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\Housing_git\census\Census 2011 Ownership (HH4).xls", sheet("Sheet1") cellrange(A7:S3463) firstrow clear

keep B F G H I J
rename (B F G H I J) (hh_state state hh_sector legal_tenure hh_size hh_n)
keep if hh_size == "All Households"
destring hh_state,replace
drop hh_size

merge m:1 hh_state using "C:/Users/wb500886/OneDrive - WBG/7_Housing/survey_all/raw/state_code.dta"

rename isocode state_iso
replace state_iso = "IN" if _merge == 1 //India has no iso_code
drop if _merge == 2
drop _merge

gen year = 2011
replace legal_tenure = "Other" if legal_tenure == "Any Other"

*reshape to sector level 
reshape wide hh_n, i(hh_state state hh_sector state_iso year) j(legal_tenure) string

rename (hh_nOther hh_nOwned hh_nRented hh_nTotal) (other own rent total)

save "${github}/census_2011.dta",replace
