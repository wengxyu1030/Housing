*this file to harmonize the state code

***set the environment****
global ROOT "C:/Users/wb500886/OneDrive - WBG/7_Housing/survey_all"
global raw "${ROOT}/raw"
global inter "${ROOT}/inter"
global final "${ROOT}/final"
global github "C:/Users/wb500886/OneDrive - WBG/7_Housing/survey_all/Housing_git/nss"

import excel "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\Housing_git\nss\state_code.xlsx", sheet("all") firstrow clear

rename state_nss_code hh_state
keep hh_state isocode 
destring hh_state, replace
save "${raw}/state_code.dta",replace