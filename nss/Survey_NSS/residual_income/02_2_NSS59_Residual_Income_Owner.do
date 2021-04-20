
***************************
*** AFH 
*** NSS59-Residual Income Approach (2003)
*** Prepared by Aline Weng
*** Date:4/20/2021
***************************

/*
This version is using the Tendulka approach construct the non-housing budget standard (non-housing poverty line). 
Following up to the 02_, this file is fow owners only. 
*/

clear 
set more off 

if "`c(username)'" == "wb308830" local pc = 0
if "`c(username)'" != "wb308830" local pc = 1
if `pc' == 0 global root "C:\Users\wb308830\OneDrive - WBG\Documents\TN\Data\NSS 70"
if `pc' == 0 global root_68 "C:\Users\wb308830\OneDrive - WBG\Documents\TN\Data\NSS 68"
if `pc' != 0 global root "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\nss_data\NSS70"
if `pc' != 0 global root_68 "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\nss_data\NSS68"
if `pc' != 0 global script "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\Housing_git\nss\Survey_NSS"

di "$root"
global r_input "${root}\Raw Data & Dictionaries"
di "${r_input}"
global r_output "${root}\Data Output Files"
di "${r_output}"
global r_output_68 "${root_68}\Data Output Files"
di "${r_output_68}"

log using "${script}\residual_income\02_2_NSS59_Residual_Income_Owner.log",replace
set linesize 255

***************************************************************
*Step 3: Budget Standard for Owners **************************
***************************************************************

***Data preparation***

*Household type
use"${r_output}\NSS70_All.dta",clear  
keep if urban == 1

egen hh_cut_manual = cut(hhsize), at(0,3,4,5,6,100)
table hh_cut_manual, c(min hhsize max hhsize)
tab hh_cut_manual [aw=hhwgt]

gen hh_type = ""
replace hh_type = "1-2" if hh_cut_manual == 0
replace hh_type = "3" if hh_cut_manual == 3
replace hh_type = "4" if hh_cut_manual == 4
replace hh_type = "5" if hh_cut_manual == 5
replace hh_type = ">=6" if hh_cut_manual == 6
tab hh_type [aw=hhwgt]

rename hh_cut_manual hh_type_grp

keep HHID hh_type hh_type_grp
save "${r_output}\nss70_ria_hh_type.dta",replace 

***********Combine wealth to income, non-housing poverty line**********
use "${r_output_68}\nss68_ria_master.dta",clear 
bysort state: keep if _n == 1
keep state pline_nhs_* pline

gen state_temp = state
tostring state_temp, format(%02.0f) replace

rename state state_txt
rename state_temp state

merge 1:m state using "${r_output}\NSS70_All.dta"
tab state if _merge == 2 //TELENGANA founded in 2014, after nss68(2012)
keep if _merge == 3
drop _merge

keep if urban == 1 //only focusing on urban 

drop if wealth < 0 //exclude negative wealth data. 

xtile wealth_100 = wealth [aw = hhwgt],nq(100)
tab wealth_100 [aw = hhwgt]

/*
//not taking log can not get the result? negative value?
xtile wealth_100 = wealth [aw = hhwgt],nq(100) //household weight, wealth is measured at household level. [aw = hhwgt]
tab wealth_100 [aw = hhwgt]
*/

merge m:1 wealth_100 using "${r_input}\NSS70_IHDS_Wealth_to_Inc.dta",nogen
drop if HHID == "" 

merge 1:1 HHID using "${r_output}\nss70_ria_hh_type.dta"
keep if _merge == 3 //negative wealth households not merged from using.
drop _merge 

gen double income = (wealth/alpha_a1_u_ip)/12 //a1 assumption with income (monthly income)
sum income [aw = hhwgt],de

gen income_pc = income/hhsize

save "${r_output}\nss70_ria_master.dta",replace

***********RIA approach for housing owner**********
use "${r_output}\nss70_ria_master.dta",clear

gen owner = (building_dwelling > 0 & !mi(building_dwelling))*100
replace owner = 0 if mi(building_dwelling)
tab owner [aw = hhwgt]

*Maximum amount available for mortgage per capita/household
forvalues i = 1/2 {
gen own_ria_`i'_pc = income/hhsize - pline_nhs_`i' //hypothetical expenditure, we are using mpce (actual exp.), different from Australia
gen own_ria_`i'_hh = income - pline_nhs_`i'*hhsize
gen pline_nhs_`i'_hh = pline_nhs_`i'*hhsize
}

label var own_ria_1_pc "Max Residual HH Monthly Mortgage at NHBS (mean)" //per capita
label var own_ria_1_hh "Max Residual HH Monthly Mortgage at NHBS (mean)" //hh. 

label var own_ria_2_pc "Max Residual HH Monthly Mortgage at 1.5NHBS (mean)" //per capita
label var own_ria_2_hh "Max Residual HH Monthly Mortgage at 1.5NHBS (mean)" //hh.

*The max housing exp with ratio approach 
gen own_ratio_pc = (income/hhsize)*0.3
label var own_ratio_pc "Max Residual HH Monthly Mortgage at 30% Rule" //per capita

gen own_ratio_hh = income*0.3
label var own_ratio_hh "Max Residual HH Monthly Mortgage at 30% Rule" //hh.

*convert the maximun mortgage to house value
/*
PV = mortgage amount
PMT = monthly payment (own_ria_1_hh, own_ria_2_hh, own_ratio_1_hh)
i = monthly interest rate
(nss70: Average interest rate for all India housing mortgage holder,
housing loan with immovable property as secure type: 11%)
n = the term in number of month
(NSS70: Average term of loan for all India housing mortgage holder,
housing loan with immovable property as secure type: 102 month, change to 9 year 108 month)
*/

global rate = (1+0.11)^(1/12) - 1 
di ${rate}
global term = 108 
global ltv = 0.7

forvalues i = 1/2 {
gen max_loan_`i' = own_ria_`i'_hh * (1 - ((1+$rate)^-$term)) / $rate
gen max_hse_val_`i' = max_loan_`i' / $ltv
}

gen max_loan_ratio = own_ratio_hh * (1 - ((1+$rate)^-$term)) / $rate
gen max_hse_val_ratio = max_loan_ratio / $ltv

label var max_hse_val_1 "LBS"
label var max_hse_val_2 "MBS"
label var max_hse_val_ratio "30% Rule"

label var building_dwelling "Housing Value (million)"

*merge with mortgage payment information
merge 1:m HHID using "${r_output}\b14_hse_mortgage"
bysort HHID: egen repay_mt_2_max = max(repay_mt_2) //Less conservative (let's label 2) housing loan with mortgage
bysort HHID: keep if _n == 1 //maximum monthly mortgage repay

gen ratio_pay = (repay_mt_2_max > own_ratio_hh)*100
label var ratio "Unaffordable at 30% Rule (%)"

gen ria_1_pay = (repay_mt_2_max > own_ria_1_hh)*100
label var ria_1 "Unaffordable at NHBS (%)"

gen ria_2_pay = (repay_mt_2_max > own_ria_2_hh)*100
label var ria_2 "Unaffordable at 1.5NHBS (%)"

tostring (ria_1_pay ria_2_pay ratio_pay),gen(ria_1_pay_tx ria_2_pay_tx ratio_pay_tx) //Identify the different affordability group
gen afd_grp_pay = ria_1_pay_tx + ria_2_pay_tx //focus only on ria1 and ria2
tab afd_grp_pay [aw = hhwgt] //different section
seperate repay_mt_2_max,by(afd_grp_pay) //group households by housing value
label var repay_mt_2_max1 "Affordable Housing" 
label var repay_mt_2_max2 "Intermediate Unaffordable Housing"
label var repay_mt_2_max3 "Unaffordable Housing"

*affordability table for owner
egen owner_type = wtmean(owner),weight(hhwgt) by(hh_type) //overall share of owner hh in urban , 
egen owner_al = wtmean(owner),weight(hhwgt) //share of owner hh by household type 
label var owner_type "Owners (%)"
label var owner_al "Owners (%)"

label var hhsize "Household Size (mean) "
label var wealth "Total HH Wealth"
label var income "Imputed HH Income*" //*mapping wealth to income from Nadeem using distance based approach

gen pline_hh = pline*hhsize
label var pline_hh "HH Poverty Line**"

gen pline_hh_15 = 1.5*pline_hh
label var pline_hh_15 "HH 1.5 Poverty Line"

gen poor = (income < pline_hh)*100
label var poor "%HH Poor at PL"

gen poor_15 = (income < pline_hh_15)*100
label var poor_15 "%HH Poor at 1.5PL"

label var pline_nhs_1_hh "HH Non-Housing Budget Standard (NHBS)^"
label var pline_nhs_2_hh "HH 1.5NHBS^" //^mean of non-housing poverty line by state for urban sector

label var max_hse_val_1 "Max Housing Value at NHBS (mean, million)"
label var max_hse_val_2 "Max Housing Value at 1.5NHBS (mean, million)"

gen ratio = (building_dwelling > max_hse_val_ratio)*100
label var ratio "Unaffordable at 30% Rule (%)"

gen ria_1 = (building_dwelling > max_hse_val_1)*100
label var ria_1 "Unaffordable at NHBS (%)"

gen ria_2 = (building_dwelling > max_hse_val_2)*100
label var ria_2 "Unaffordable at 1.5NHBS (%)"

tostring (ria_1 ria_2 ratio),gen(ria_1_tx ria_2_tx ratio_tx) //Identify the different affordability group
gen afd_grp = ria_1_tx + ria_2_tx //focus only on ria1 and ria2
tab afd_grp [aw = hhwgt] //different section
seperate building_dwelling,by(afd_grp) //group households by housing value
label var building_dwelling1 "Affordable Housing" 
label var building_dwelling2 "Intermediate Unaffordable Housing"
label var building_dwelling3 "Unaffordable Housing"

*change unit to million 
foreach var of varlist building_dwelling max_hse_val* {
replace `var' = `var'/1e6
}

save "${r_output}\nss70_ria_master_final.dta",replace

********************produce esttab table
use "${r_output}\nss70_ria_master_final.dta",clear

*calculate housing value median. 
foreach var of varlist building_dwelling max_hse_val* {

//median of all hh
gen `var'_md_al = .
summarize `var' [aw = hhwgt] if owner ==100,de
replace `var'_md_al = r(p50) if owner ==100

//median by housing type
gen `var'_md = . 
quietly foreach i in 0 3 4 5 6 { 
    summarize `var' [aw = hhwgt] if hh_type_grp == `i' & owner == 100, detail 
    replace `var'_md = r(p50) if hh_type_grp == `i' & owner == 100
	} 
}

label var max_hse_val_1_md_al "Max Housing Value at NHBS (median, million)"
label var max_hse_val_2_md_al "Max Housing Value at 1.5NHBS (median, million)"
label var building_dwelling_md_al "Housing Value (median, million)"


global var_tab "owner_al building_dwelling_md_al hhsize wealth income pline_hh pline_hh_15 poor poor_15 pline_nhs_1_hh pline_nhs_2_hh max_hse_val_1_md_al max_hse_val_2_md_al own_ria_1_hh own_ria_2_hh ratio ria_1 ria_2"

qui eststo total : estpost summarize $var_tab [aw = hhwgt] if owner ==100,de  

replace owner_al = owner_type
foreach var of varlist building_dwelling max_hse_val_1 max_hse_val_2 {
replace `var'_md_al = `var'_md
}

foreach i in 0 3 4 5 6 {
qui eststo grp`i' : estpost summarize $var_tab [aw = hhwgt] if hh_type_grp == `i' & owner == 100,de
}

esttab total grp0 grp3 grp4 grp5 grp6, cells(mean(fmt(%15.1fc))) label collabels(none) varwidth(40) ///
 mtitles( "All HH" "Size 1-2" "Size 3" "Size 4" "Size 5" "Size >=6" ) stats(N, label("Observations") fmt(%15.1gc)) ///
 title("Owner affordability using different affordability measures in urban India, 2013") ///
 addnotes("Notes: Homeowners are households own residential building used as dwelling by household members." ///
          "       * mapping wealth to income using distance based approach." ///
          "       ** Tendulkar (2012) poverty estimation weighted mean by state as the poverty line is different in every state." ///
		  "       Low Budget Standard corresponds to poverty line (Tendulkar), Moderate budget standard is 1.5 times" ///
		  "       ^ methodology – renters only, removing actual rent at the 2nd (poverty line) decile of expenditure and 4th (1.5 * poverty line) to arrive at non-housing poverty lines." )

**************plot the affordability curve: maximum monthly mortgage payment value and income
use "${r_output}\nss70_ria_master_final.dta",clear
keep if owner == 100 //only on housing owners. 

foreach var of varlist own_ria_* repay_mt_2* {
replace `var' = . if `var' <= 0
//replace `var' = . if `var' > 2e3
}

format own_ria_* repay_mt_2*  %15.0fc

sum income [aw = hhwgt],de
twoway line own_ria_1_hh own_ria_2_hh own_ratio_hh income if state == "33" & ///
hh_type == "4" & inrange(income,0,`r(p90)') ,lpattern(p1 p1 dash) lcolor(cranberry dkorange gs11) || ///
scatter repay_mt_2_max1 repay_mt_2_max2 repay_mt_2_max3 income if state == "33" & ///
hh_type == "4" & inrange(income,0,`r(p90)') , msize(tiny) mcolor(dkgreen dkorange cranberry) graphregion(color(white)) msymbol(circle triangle square) ///
msize(tiny tiny tiny) xtitle("Household Monthly Income") ytitle("Maximum Monthly Mortgage Payment") ///
title("Maximum affordable mortgage payment (Tamil Nadu: 4-member household, 2013)", size(small)) xline(`r(p50)', lpattern(dash) lcolor(gs4)) ///
legend(cols(3) label(1 "PLBS") label(2 "1.5PLBS") size(vsmall)) ///
note("Note: PLBS is Poverty Line Budget Standard, 1.5PLBS is 1.5 times PLBS." ///
     "      The income percentile is for housing owners only weighted by household weight.") ///
xlabel(4119 `" "4,119" "(p10)" "' 6612 `" "6,612" "(p25)" "' 12445 `" "12,445" "(p50)" "' 23597 `" "23,597" "(p75)" "' 39886 `" "39,886" "(p90)" "',labsize(vsmall))  //text(2e3 `r(p50)' "50th Percentile", color(black))
graph export "${r_output}/ria_owner_size4_mortgage_nss70.png",width(800) height(600) replace

sum income [aw = hhwgt],de
twoway line own_ria_1_hh own_ria_2_hh own_ratio_hh income if state == "33" & ///
hh_type == "5" & inrange(income,0,`r(p90)') ,lpattern(p1 p1 dash) lcolor(cranberry dkorange gs11) || ///
scatter repay_mt_2_max1 repay_mt_2_max2 repay_mt_2_max3 income if state == "33" & ///
hh_type == "5" & inrange(income,0,`r(p90)') , msize(tiny) mcolor(dkgreen dkorange cranberry) graphregion(color(white)) msymbol(circle triangle square) ///
msize(tiny tiny tiny) xtitle("Household Monthly Income") ytitle("Maximum Monthly Mortgage Payment") ///
title("Maximum affordable mortgage payment (Tamil Nadu: 5-member household, 2013)", size(small)) xline(`r(p50)', lpattern(dash) lcolor(gs4)) ///
legend(cols(3) label(1 "PLBS") label(2 "1.5PLBS") size(vsmall)) ///
note("Note: PLBS is Poverty Line Budget Standard, 1.5PLBS is 1.5 times PLBS" ///
     "      The income percentile is for housing owners only weighted by household weight.") ///
xlabel(4119 `" "4,119" "(p10)" "' 6612 `" "6,612" "(p25)" "' 12445 `" "12,445" "(p50)" "' 23597 `" "23,597" "(p75)" "' 39886 `" "39,886" "(p90)" "',labsize(vsmall))  //text(2e3 `r(p50)' "50th Percentile", color(black))
graph export "${r_output}/ria_owner_size5_mortgage_nss70.png",width(800) height(600) replace

***********plot the affordability curve: maximum affordable housing value and income
use "${r_output}\nss70_ria_master_final.dta",clear
keep if owner == 100 //only on housing owners. 

format max_hse_val* max_loan* %15.1fc

sum building_dwelling [aw = hhwgt],de

foreach var of varlist building_dwelling* {
replace `var' = `var'/1e6 //change the housing value unit to million 
}

foreach var of varlist max_hse_val_* building_dwelling* {
replace `var' = . if `var' > 2 //around 80 percentile housing value
replace `var' = . if `var' <= 0
}

sum income [aw = hhwgt],de //percentile among urban housing owner. 
twoway line max_hse_val_1 max_hse_val_2 max_hse_val_ratio income if state == "33" & ///
hh_type == "4" & inrange(income,0,`r(p90)') ,lpattern(p1 p1 dash) lcolor(cranberry dkorange gs11) ///
|| scatter building_dwelling1 building_dwelling2 building_dwelling3 income if state == "33" & ///
hh_type == "4" & inrange(income,0,`r(p90)') , msize(tiny) mcolor(dkgreen dkorange cranberry) graphregion(color(white)) msymbol(circle triangle square) ///
msize(tiny tiny tiny) xtitle("Household Monthly Income") ytitle("Maximum affordable housing value (million)") ///
title("Maximum affordable housing value (Tamil Nadu: 4-member household, 2013)", size(small)) xline(`r(p50)', lpattern(dash) lcolor(gs4)) ///
legend(cols(3) label(1 "PLBS") label(2 "1.5PLBS") size(vsmall)) ///
note("Note: PLBS is Poverty Line Budget Standard, 1.5PLBS is 1.5 times PLBS." ///
     "      The income percentile is for housing owners only weighted by household weight.") ///
xlabel(4119 `" "4,119" "(p10)" "' 6612 `" "6,612" "(p25)" "' 12445 `" "12,445" "(p50)" "' 23597 `" "23,597" "(p75)" "' 39886 `" "39,886" "(p90)" "',labsize(vsmall))  //text(2e3 `r(p50)' "50th Percentile", color(black))
graph export "${r_output}/ria_owner_size4_house_nss70.png",width(800) height(600) replace

sum income [aw = hhwgt],de //percentile among urban housing owner. 
twoway line max_hse_val_1 max_hse_val_2 max_hse_val_ratio income if state == "33" & ///
hh_type == "5" & inrange(income,0,`r(p90)') ,lpattern(p1 p1 dash) lcolor(cranberry dkorange gs11) || scatter building_dwelling1 building_dwelling2 building_dwelling3 income if state == "33" & ///
hh_type == "5" & inrange(income,0,`r(p90)') , msize(tiny) mcolor(dkgreen dkorange cranberry) graphregion(color(white)) msymbol(circle triangle square) ///
msize(tiny tiny tiny) xtitle("Household Monthly Income") ytitle("Maximum affordable housing value (million)") ///
title("Maximum affordable housing value (Tamil Nadu: 5-member household, 2013)", size(small)) xline(`r(p50)', lpattern(dash) lcolor(gs4)) ///
legend(cols(3) label(1 "PLBS") label(2 "1.5PLBS") size(vsmall)) ///
note("Note: PLBS is Poverty Line Budget Standard, 1.5PLBS is 1.5 times PLBS." ///
     "      The income percentile is for housing owners only weighted by household weight.") ///
xlabel(4119 `" "4,119" "(p10)" "' 6612 `" "6,612" "(p25)" "' 12445 `" "12,445" "(p50)" "' 23597 `" "23,597" "(p75)" "' 39886 `" "39,886" "(p90)" "',labsize(vsmall))  //text(2e3 `r(p50)' "50th Percentile", color(black))
graph export "${r_output}/ria_owner_size5_house_nss70.png",width(800) height(600) replace

log close

