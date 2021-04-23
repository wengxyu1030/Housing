***************************
*** AFH 
*** NSS61-Residual Income Approach (2004)
*** Prepared by Aline Weng
*** Date:1/25/2021
***************************

clear 
set more off 

if "`c(username)'" == "wb308830" local pc = 0
if "`c(username)'" != "wb308830" local pc = 1

if `pc' == 0 global root "C:\Users\wb308830\OneDrive - WBG\Documents\TN\Data\NSS 61"
if `pc' == 0 global root_nss68 "C:\Users\wb308830\OneDrive - WBG\Documents\TN\Data\NSS 68"

if `pc' != 0 global root "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\nss_data\NSS61"
if `pc' != 0 global root_nss68 "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\nss_data\NSS68"

if `pc' != 0 global script "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\Housing_git\nss\Survey_NSS\residual_income"

cd "${root}"

global r_input "${root}\Raw Data & Dictionaries"
global r_input_nss68 "${root_nss68}\Raw Data & Dictionaries"
global r_output "${root}\Data Output Files"

log using "${script}\02_1_NSS61_Residual_Income_Renter.log",replace
set linesize 255

***************************************************************
*Step 1: Data Cleaning **************************************** 
***************************************************************
use "${r_input}\Block 10_Monthly expenditure on miscellaneous goods and services including medical (non-institutional), rents and taxes.dta",clear
merge m:1 HHID using "${r_input}\Block 3.dta"
drop _merge
merge m:1 HHID using "${r_input}\Block 3 Part 2_Household Characteristics.dta"
drop _merge

gen hhsize = B3_q1
label var hhsize "Household size"
   
/* poverty line is by state and by sector */

    *estimate housing related expenditure:
	  
	    *Rent (10: code = 529, 30 days recall period)
	    gen double rent = B10_q4*(B10_q1 == "520")
	  
	    *Water charge(10: 540, 30 days recall period)
	    gen double water = B10_q4*(B10_q1 == "540")
	  
	    *Collapse at household level for water ant rent
	    foreach var in rent water { 
	    egen double total_`var' = sum(`var'), by(HHID)
	    } 
	    bys HHID: keep if _n == 1 // keep only one observation for each HH

merge 1:m HHID using "${r_input}\Block 6_Monthly consumption of fuel & light.dta"
drop _merge
	  
	    *Fuel and light (12: 18, 30 days recall period)
	    gen double fuel = B6_q6*(B6_q1 == "359")
        egen double total_fuel = sum(fuel), by(HHID)
	    bys HHID: keep if _n == 1

	*Total housing expenditure
	egen double exp_housing = rowtotal(total_rent total_fuel total_water)

    *Housing consumption per capita
	gen double total_exp_housing_pp = exp_housing/hhsize 
	
    *Identify renters, owner (de jure)
	gen renter = (B3_q16 == "2") //rent is positive and tenure status is hire. 
	label var renter "Renter"
	
	gen owner = ( B3_q16 == "1" )
	label var owner "Owner"
	
rename HHID hhid
merge 1:1 hhid using "${r_input}\NSS_61_Poverty_For_Aline.dta"
keep if _merge == 3
drop _merge

   *adjust the unit from India Rupee to USD: 1 Indian Rupee = 0.014 USD in 2/24/2021 （later）
   global r_u = 0.014
	  
   foreach var of var pline mpce* total_* {
   gen `var'_usd = `var'*${r_u}
   }

   *different budget scenario: pline, double pline, triple pline.    
   forvalues i = 1/3 {
   gen pline_`i' = pline*`i'
   }	  
   gen pline_15 = pline*1.5

   *Only focus on urban (the Tendulka approach decile is based on urban exp.)
   gen urban = sector - 1
   keep if urban == 1
   label var urban "Urban"
   
   *Decile of the expenditure
   xtile decile = mpce_mrp [aw = pwt] , n(10)
   label var decile "Exp. decile"

   
       
**************************************************************
*Step 2: Construct budget standards **************************
**************************************************************
 
*remove rent budget from the original poverty line by state
gen rent_pc = total_rent/hhsize
gen rent_mpce = rent_pc/mpce_mrp*100 //share of rent on total expenditure per capita (renters)

*stats for renters
table decile [aw = pwt], c(mean renter ) row 
table decile [aw = pwt], c(mean rent_mpce mean mpce_mrp) row // for both renters and owners, the poverty line budget share of rent is 2.8%, lower than the 5.3% for exp. survey in 05. 
table decile if renter == 1 [aw = pwt], c(med rent_pc med mpce_mrp med rent_mpce) row // only for renters 

*collapse at state and declie level
tab poor [aw = pwt] if urban == 1 //25.7% poverty rate in urban India (2004): 3th decile MPCE class

//ssc inst _gwtmean
forvalues i = 2/6 {
gen rent_pc_d`i' = rent_pc * (decile == `i')
bys state: egen rent_pc_`i' = wtmean(rent_pc_d`i') , weight(pwt) //the poverty line is in the 2nd decile MPCE class
drop rent_pc_d`i' 
}   

*check the double poverty line and the mpce in each decile.. 
table decile [aw = pwt], c(mean mpce_mrp min mpce_mrp max mpce_mrp) row 

local mpce_pline = 570.6 //mean mpce_mrp at poverty line mpce class (decile 3, urban)
local mpce_pline_15 = `mpce_pline'*1.5 //1.5 times mean poverty line mpce class (urban)

di  `mpce_pline_15' //6th decile mpce class (urban), different than that in the 4th decile in 2012

*generate the non-housing poverty line for each state at different budget standard (differ than 2012)
gen pline_nhs_1 = pline_1- rent_pc_3 // poverty line and 1.5 poverty line (only double pline not rent)
gen pline_nhs_2 = pline_15- rent_pc_6 //6th decile is where the poverty line mpce class doubled 

*estimate income based on expenditure //Picketty approach. 
xtile exp_100 = mpce_mrp [aw=pwt], nq(100)

merge m:1 exp_100 using "${r_input_nss68}\IDHS_Exp_To_Income_All_Urban_Rural.dta",nogen

forvalues i = 0(1)2 {
gen income_a`i' = (mpce_mrp * alpha_a`i'_u) //the income unit is consistent to budget standard
}

xtile decile_ic = income_a2 [aw = pwt] , n(10) //decile for income: with the assumption that there's no income smaller than expenditure 
xtile qt_ic = income_a2 [aw = pwt] , n(5) //quintile for income

gen rent_ic = rent_pc/income_a2*100 //share of rent on income

drop rent_pc_*
save "${r_output}\nss61_ria_master.dta",replace


***************************************************************
*Step 3: Budget Standard for Renters **************************
***************************************************************

*Maximum amount available for rent
use "${r_output}\nss61_ria_master.dta",clear
forvalues i = 1/2 {
gen rent_ria_`i' = mpce_mrp - pline_nhs_`i'

  forvalues  q = 0(1)2 {
  gen rent_ria_income_a`q'_`i' = max(income_a`q' - pline_nhs_`i',0)
  }
}

*The max housing exp with ratio approach
gen rent_ratio = mpce_mrp*0.3

forvalues  q = 0(1)2 {
gen rent_income_ratio_a`q' = income_a`q'*0.3
}

label var rent_ria_income_a2_1 "Low Cost Budget Standard"
label var rent_ria_income_a2_2 "Modest Budget Standard"
label var rent_income_ratio_a2 "30% Rule"

*Identify the different affordability group
gen ria_1 = (rent_pc > rent_ria_income_a2_1)
gen ria_2 = (rent_pc > rent_ria_income_a2_2)
gen ratio = (rent_pc > rent_income_ratio_a2)
tostring (ria_1 ria_2 ratio),gen(ria_1_tx ria_2_tx ratio_tx)

gen afd_grp = ria_1_tx + ria_2_tx //focus only on ria1 and ria2
tab afd_grp [aw = pwt] //different section

seperate rent_pc,by(afd_grp)
label var rent_pc1 "Affordable Rent" 
label var rent_pc2 "Intermediate Unaffordable Rent"
label var rent_pc3 "Unaffordable Rent"


*produce the table
foreach var in ria_1 ria_2 ratio {
replace `var' = `var'*100 //unaffordability with income measure.
gen exp_`var' = (rent_pc > rent_`var')*100 //unaffordability with expenditure measure.
}

replace renter = renter*100
egen renter_q = wtmean(renter),weight(pwt) by(qt_ic) //overall share of renter hh in urban
egen renter_al = wtmean(renter),weight(pwt) //share of renter hh by urban quintile 

forvalue i = 1/2 {
egen pline_nhs_`i'_nat = wtmean(pline_nhs_`i'), weight(pwt)  //weighted mean by state non-housing poverty line. 
}

foreach var in poor poor_double {
replace `var' = `var'*100 //poverty rate in %
}

gen poor_income_1 = (income_a2 < pline)*100
gen poor_income_2 = (income_a2 < pline_15)*100

//labels
label var renter_q "Renters (%)"
label var renter_al "Renters (%)"
label var pline "PC Poverty Line (mean)*"
label var pline_15 "PC 1.5 Poverty Line (mean)" //??check national poverty line estimate. 
label var pline_nhs_1_nat "PC NHBS)^"
label var pline_nhs_2_nat "PC 1.5 NHBS"
label var mpce_mrp "Monthly PC Expenditure (mean)"
label var income_a2 "Monthly PC Income (mean)"
label var poor "Below PL (exp. < PL) (%)"
label var poor_double "Below 1.5PL (exp. < 1.5PL) (%)"

label var poor_income_1 "Below PL (income < PL) (%)"
label var poor_income_2 "Below 1.5PL (income < 1.5PL) (%)**"

label var rent_pc "PC Rent(mean) (conditional)"
label var rent_ic "PC Rent to Income(%, mean) (conditional)"

label var rent_ria_income_a2_1 "Max PC Rent at NHBS (mean)"
label var rent_ria_income_a2_2 "Max PC Rent at 1.5NHBS (mean)"

label var ratio "Unaffordable at 30% Rule (%)"
label var ria_1 "Unaffordable at NHBS (%)"
label var ria_2 "Unaffordable at 1.5NHBS (%)"

//produce esttab table
global var_tab "renter_al pline pline_15 pline_nhs_1_nat pline_nhs_2_nat mpce_mrp income_a2 poor poor_double poor_income_1 poor_income_2 rent_pc rent_ic rent_ria_income_a2_1 ratio rent_ria_income_a2_2 ria_1 ria_2"
qui eststo total : estpost summarize $var_tab [aw = pwt] if renter ==100,de 
replace renter_al = renter_q
forvalues i = 1/5 {
qui eststo q`i' : estpost summarize $var_tab [aw = pwt] if qt_ic == `i' & renter ==100,de
}

esttab total q1 q2 q3 q4 q5, cells(mean(fmt(%15.1fc))) label collabels(none) varwidth(40) ///
 mtitles( "Urban" "Urban-Q1" "Urban-Q2" "Urban-Q3" "Urban-Q4" "Urban-Q5") stats(N, label("Observations") fmt(%15.1gc)) ///
 title("Rental affordability using different affordability measures in urban India, 2004") ///
 addnotes("Notes: Renter is defined as tenure status as hired" ///
          "       * Temdulkar (2004) poverty estimation weighted mean by state as the poverty line is different in every state." ///
		  "       Low Budget Standard corresponds to poverty line (Tendulkar), Moderate budget standard is 1.5 times" ///
		  "       ^ methodology – renters only, removing actual rent at the 2nd (poverty line) decile of expenditure and 4th (1.5 x poverty line) to arrive at non-housing poverty lines" ///
		  "       ** use picketty to get income (horizontal transformation A2 (preferred – floor)." ///
		  "       PL is Poverty Line, 1.5PL is 1.5 x Poverty Line. NHBS is non-housing budget standard, 1.5NHBS is 1.5 x NHBS.")

		  
table renter [aw = pwt], c(mean poor) row //double check the poverty rate: poverty rate among renters (mpce_mrp) is low in Urban. 

*Plot the curve
//x is income per capita 
foreach var in rent_ria_income_a2_1 rent_ria_income_a2_2 rent_income_ratio_a2 rent_pc1 rent_pc2 rent_pc3 {
replace `var' = . if `var' <= 0
replace `var' = . if `var' > 1e3 //the cutoff is 2e3 in 2012
}

format rent_ria_income_a2_1 rent_ria_income_a2_2 income_a2 %9.0fc

sum income_a2 [aw = pwt] ,de f //?how to set the y scale to 0-1e3? 
twoway line rent_ria_income_a2_1 rent_ria_income_a2_2 rent_income_ratio_a2 income_a2 if renter == 100 & inrange(income_a2,0, `r(p90)') & state == 33,lpattern(p1 p1 dash) lcolor(cranberry dkorange gs11) || ///
scatter rent_pc1 rent_pc2 rent_pc3 income_a2 if renter == 100 & inrange(income_a2,0, `r(p90)') & state == 33, mcolor(dkgreen dkorange cranberry) graphregion(color(white)) msymbol(circle triangle square) ///
msize(tiny tiny tiny) ytitle("Maximum Rent (PC in Rs.)") xtitle("Monthly Income (PC in Rs.)") title("Maximum affordable rent payments (Tamil Nadu,2004)") ///
xline(`r(p50)', lpattern(dash) lcolor(gs4))  legend(cols(3) label(1 "PLBS") label(2 "1.5PLBS") size(vsmall)) ///
note("Note: PLBS is Poverty Line Budget Standard, 1.5PLBS is 1.5 times PLBS" ///
     "      The income percentile is for urban India, weighted by household weight.") ///
xlabel(424 `" "424" "(p10)" "' 571 `" "571" "(p25)" "' 839 `" "839" "(p50)" "' 1551 `" "1,551" "(p75)" "' 2772 `" "2,772" "(p90)" "',labsize(vsmall))  

graph export "${r_output}/ria_renter_nss61.png",width(800) height(600) replace

log close
