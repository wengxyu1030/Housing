****************************************************************************
* Description: Rent Summary from 2004-2005 (NSS 61)
* Date: Nov 29 2020
* Version 1.0
* Last Editor: Nadem
****************************************************************************

****************************************************************************
clear 
clear matrix
set more off
****************************************************************************

****************************************************************************
* Determine Whose Machine is running the code and set the global directory
****************************************************************************
if "`c(username)'" == "wb308830" local pc = 0
if "`c(username)'" != "wb308830" local pc = 1
if `pc' == 0 global root "C:\Users\wb308830\OneDrive - WBG\Documents\TN\Data\NSS 61\"
if `pc' != 0 global root "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\nss_data\NSS65"
if `pc' != 0 global script "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\Housing_git\nss\Survey_NSS"

di "$root"
global r_input "${root}\Raw Data & Dictionaries"
di "${r_input}"
global r_output "${root}\Data Output Files"

****************************************************************************

****************************************************************************
* NSS 61 on expenditure: block 3, block 13, poverty
* Import from DLW and save
****************************************************************************
/*
datalibweb, country(IND) year(2004) type(SARRAW) surveyid(IND_2004_NSS61-SCH1.0_v01_M) filename(bk_3b.dta)
gen ID = string(fsu) + string(hamlet) + string(secstage) + string(hhsno,"%02.0f")
save "${r_input}\NSS_61_Sch_1_Block_3a.dta", replace
 

datalibweb, country(IND) year(2004) type(SARRAW) surveyid(IND_2004_NSS61-SCH1.0_v01_M) filename(bk_10.dta)
keep if item_cod == 520
gen ID = string(fsu) + string(hamlet) + string(secstage) + string(hhsno,"%02.0f")

save "${r_input}\NSS_61_Rent_Exp.dta", replace

datalibweb, country(IND) year(2004) type(SARRAW) surveyid(IND_2004_NSS61-SCH1.0_v01_M) filename(poverty61_ind.dta)
save "${r_input}\NSS_61_Poverty.dta", replace
*/ 

**********************************************************************************
* Merge Rent to Consumption Data and to Block 3
**********************************************************************************
use "${r_input}\NSS_61_Poverty.dta", clear
ren hhid ID

merge 1:1 ID using "${r_input}/NSS_61_Rent_Exp.dta", force
drop _merge 

merge 1:1 ID using "${r_input}/NSS_61_Sch_1_Block_3a.dta", force
drop _merge 


**********************************************************************************
* Merge Rent to Consumption Data and to Block 3
**********************************************************************************

gen renter_1 = 100*(dwelling == 2) // only those with tenure status == rent
label var renter_1 "Renter - de jure (%)"


replace value = 0 if value == .
gen renter_2 = 100 * (value > 0 ) // de facto renter - reports a positive rent 
label var renter_2 "Renter - de facto (%)"

gen double month_exp_m = hhsize * mpce_mrp
label var month_exp_m "Monthly HH M Expenditure (Rs.)"

gen rent_1_exp = (100 * (value / (100*month_exp_m))) * (renter_1 == 100)
label var rent_1_exp "Rent to Expenditure - de jure (%)"

gen rent_2_exp = (100 * (value / (100*month_exp_m))) * (renter_2 == 100)
label var rent_2_exp "Rent to Expenditure - de facto (%)"

replace rent_1_exp = . if rent_1_exp == 0 
replace rent_2_exp = . if rent_2_exp == 0 

gen rent_1 = value * (renter_1 ==100 ) * (1/100)
label var rent_1 "Rent - de jure (Rs.)"

gen rent_2 = value * (renter_2 ==100 ) * (1/100)
label var rent_2 "Rent - de facto (Rs.)"

replace rent_1 = . if rent_1 == 0
replace rent_2 = . if rent_2 == 0

label var hhsize "HH Size"

xtile decile =  month_exp_m [aw=hhwt], nq(10) 
xtile quintile =  month_exp_m [aw=hhwt], nq(5) 

*Save uniform renters file
keep sector renter_1 rent_1 rent_1_exp month_exp_m  hhsize poor hhwt renter_2 rent_2 rent_2_exp decile quintile state

save "${r_output}/NSS_61_Renters.dta", replace



*Urbanization 
count
gen count = 100/ `r(N)'
table sector [aw=hhwt], c(sum count mean renter_1) row format("%9.1fc")


* TABLE SUMMARY across deciles 
xtile d_61 =  month_exp_m [aw=hhwt], nq(10)
table d_61 [aw=hhwt], 		c(mean renter_1 p50 month_exp_m	p50 rent_1 p50 rent_1_exp) format("%9.0fc") row

* URBAN ONLY 
table d_61 [aw=hhwt] if sector == 2, c(mean renter_1 p50 month_exp_m	p50 rent_1 p50 rent_1_exp) format("%9.0fc") row

* Poor 
sum poor [aw=hhwt]
table poor [aw=hhwt] , c(mean renter_1 p50 month_exp_m	p50 rent_1 p50 rent_1_exp) format("%9.0fc") row