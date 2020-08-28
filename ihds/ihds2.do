**********************************
***IHDS for housing condition****
**********************************

global ROOT "C:/Users/wb500886/OneDrive - WBG/7_Housing/HDS11-12/stata"
global raw "${ROOT}/raw"
global inter "${ROOT}/inter"
global final "${ROOT}/final"

global raw_batch "C:/Users/wb500886/OneDrive - WBG/7_Housing/survey_all/raw"


*****calculate indicators by file*****

use "${raw}/ihds2/DS0002/36151-0002-Data.dta",clear

    *id_survey:
	gen id_survey = "ihds2"
	
	*id: common id
	gen id = IDHH
	
	*hh_sector: urban or rural sector
    gen hh_sector = URBAN2011
	gen hh_urban = (hh_sector == 1)
	
	label define hh_urbanl 0 "rural" 1 "urban"
	label values hh_urban hh_urbanl
   
    *hh_state, hh_tn: whether the state is Tamil Nadu
    gen hh_state = STATEID
	gen hh_tn = (hh_state == 33)  //check the state code, harmonize with the 76th. 
	
	label define hh_tnl 0 "non-TN" 1 "TN"
	label values hh_tn hh_tnl
	
    *multiplier
    gen hh_weight = FWT
	destring(hh_weight),replace

    *hh_size: household size
    //gen hh_size = B3_q1  to be updated. 
	
	*hh_umce: household monthly consumer expenditure
	gen hh_umce = COTOTAL
	gen hh_umce_ln = ln(hh_umce)
	
	*hh_income: household total income
	gen hh_income = INCOME
	gen hh_income_ln = ln(hh_income)
	
	*hq_tenure: the tenurial status
	gen hq_tenure = CG1
	destring(hq_tenure),replace
	
	*legal_own: the dwelling is owned
	gen legal_own = (hq_tenure == 1) if !mi(hq_tenure)
	
	*legal_rent: the dwelling is rented
	gen legal_rent = (hq_tenure == 2) if !mi(hq_tenure)
	
	*hq_rent_se: Do you have a rental agreement? only for renter.
	gen hq_rent_se = (CG1A == 1) if !mi(CG1A)
	
	*household owns TV. 
	gen ast_tv = CGTV
	
*******save file*****  
keep id* hh_* hq_* legal_* ast_*
save "${final}/ihds2",replace
save "${raw_batch}/ihds2",replace