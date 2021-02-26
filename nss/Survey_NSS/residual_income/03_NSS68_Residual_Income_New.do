***************************
*** AFH 
*** NSS68-Residual Income Approach (2012)
*** Prepared by Aline Weng
*** Date:2/26/2021
***************************

/*
This version is using the Tendulka approach construct the non-housing budget standard (non-housing poverty line). 
*/

clear 
set more off 

if "`c(username)'" == "wb308830" local pc = 0
if "`c(username)'" != "wb308830" local pc = 1
if `pc' == 0 global root "C:\Users\wb308830\OneDrive - WBG\Documents\TN\Data\NSS 68"
if `pc' != 0 global root "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\nss_data\NSS68"
if `pc' != 0 global script "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\Housing_git\nss\Survey_NSS"

cd "${root}"

global r_input "${root}\Raw Data & Dictionaries"
global r_output "${root}\Data Output Files"

//log using "${script}\NSS68\03_NSS68_Residual_Income_New.log",replace
set linesize 255

***************************************************************
*Step 1: Data Cleaning ****************************************
***************************************************************

use "${r_input}\bk_12.dta",clear
merge m:1 ID using "${r_input}\bk_3.dta"
drop _merge
   
/* poverty line is by state and by sector */
	  
	  *Fuel and light (12: 18, 30 days recall period)
	  gen double fuel = B12_v06*(B12_v01 == 18)
	
	  egen double total_fuel = sum(fuel), by(ID)
	  bys ID: keep if _n == 1 // keep only one observation for each HH
	
      merge 1:m ID using "${r_input}\bk_10.dta"
      drop _merge
     
	  *water charge(10: 540, 30 days recall period)
	  gen water = B10_v03*(B10_v02 == 540)
	  
	  *Rent charge (10: 529 all rent included, 30 days recall period)
	  gen rent = B10_v03*(B10_v02 == 529)
	  
	  *Imputed rent
	  gen rent_impt = B10_v03*(B10_v02 == 539)
	  
	  foreach var in water rent rent_impt { 
	  egen double total_`var' = sum(`var'), by(ID)
	  drop `var'
	  } 
	  
	  bys ID: keep if _n == 1 // keep only one observation for each HH
	  
	  *Identify renter, owner (de jure)
	  gen renter = ( B3_v18 == 2 )
	  label var renter "Renter"
	  
	  gen owner = ( B3_v18 == 1 )
	  label var owner "Owner"
	
rename ID hhid
merge 1:1 hhid using "${r_input}\poverty68.dta"
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
	  
	  sum poor poor_double [aw = pwt]
	  sum poor poor_double [aw = pwt] if sector == 2
	 
	  
      *Only focus on urban (the Tendulka approach decile is based on urban exp.)
      gen urban = sector - 1
	  keep if urban == 1
      label var urban "Urban"
      
	  *Decile of the expenditure
      xtile decile = mpce_mrp [aw = pwt] , n(10)
      label var decile "Exp. decile"

      label var hhsize "Household size"

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
//ssc inst _gwtmean
forvalues i = 2/6 {
gen rent_pc_d`i' = rent_pc * (decile == `i')
bys state: egen rent_pc_`i' = wtmean(rent_pc_d`i') , weight(pwt) //the poverty line is in the 2nd decile MPCE class
drop rent_pc_d`i' 
}

*check the double poverty line and the 6th decile. 
table decile [aw = pwt], c(mean mpce_mrp med mpce_mrp) row 

*generate the non-housing poverty line for each state at different budget standard
gen pline_nhs_1 = pline_1- rent_pc_2 // poverty line and double poverty line (only double pline not rent)
gen pline_nhs_2 = pline_2- rent_pc_6 //6th decile is where the double poverty line mpce class doubled 

*estimate income based on expenditure //Picketty approach. 
xtile exp_100 = mpce_mrp [aw=pwt], nq(100)

merge m:1 exp_100 using "${r_input}\IDHS_Exp_To_Income_All_Urban_Rural.dta",nogen

forvalues i = 0(1)2 {
gen income_a`i' = (mpce_mrp * alpha_a`i'_u) //the income unit is consistent to budget standard
}

xtile decile_ic = income_a1 [aw = pwt] , n(10) //decile for income
xtile qt_ic = income_a1 [aw = pwt] , n(5) //quintile for income

gen rent_ic = rent_pc/income_a1*100 //share of rent on income

drop rent_pc_*
save "${r_output}\nss68_ria_master.dta",replace

***************************************************************
*Step 3: Budget Standard for Renters **************************
***************************************************************

*Maximum amount available for rent
use "${r_output}\nss68_ria_master.dta",clear
forvalues i = 1/2 {
gen rent_ria_`i' = mpce_mrp - pline_nhs_`i'

  forvalues  q = 0(1)2 {
  gen rent_ria_income_a`q'_`i' = income_a`q' - pline_nhs_`i'
  }
}

*The max housing exp with ratio approach
gen rent_ratio = mpce_mrp*0.3

forvalues  q = 0(1)2 {
gen rent_income_ratio_a`q' = income_a`q'*0.3
}

label var rent_ria_income_a1_1 "Low Cost Budget Standard"
label var rent_ria_income_a1_2 "Modest Budget Standard"
label var rent_income_ratio_a1 "30% Rule"

*Identify the different affordability group
egen rent_pc_max = rowmax(rent_ria_income_a1_1 rent_ria_income_a1_2 rent_income_ratio_a1)
egen rent_pc_min = rowmin(rent_ria_income_a1_1 rent_ria_income_a1_2 rent_income_ratio_a1)

gen ria_1 = (rent_pc > rent_ria_income_a1_1)
gen ria_2 = (rent_pc > rent_ria_income_a1_2)
gen ratio = (rent_pc > rent_income_ratio_a1)
tostring (ria_1 ria_2 ratio),gen(ria_1_tx ria_2_tx ratio_tx)

gen afd_grp = ria_1_tx + ria_2_tx + ratio_tx
tab afd_grp [aw = pwt] //different section

seperate rent_pc,by(afd_grp)
forvalues i = 1(1)6 {
label var rent_pc`i' "Group`i'" 
}

*Plot the curve

//x is mpce  & inrange(mpce_mrp,0, 200)
twoway line rent_ria_1 rent_ria_2 rent_ratio mpce_mrp if renter == 1 & state == 33 & inrange(mpce_mrp,0,4e3) || scatter rent_pc mpce_mrp if renter == 1 &  inrange(mpce_mrp,0, 4e3) & state == 33, ///
msize(tiny) ytitle("Maximum Housing Exp. (Per Capita)") xtitle("Monthly Expenditure(Per Capita)") title("Maximum affordable rent payments (Tamil Nadu)") xline(`r(p50)') 

//x is income per capita
twoway line rent_ria_income_a1_1 rent_ria_income_a1_2 rent_income_ratio_a1 income_a1 if renter == 1 & inrange(mpce_mrp,0, 4e3) & state == 33 || scatter rent_pc income_a1 if renter == 1 & inrange(mpce_mrp,0, 4e3) & state == 33, ///
msize(tiny) ytitle("Maximum Housing Exp. (Per Capita)") xtitle("Monthly Income(Per Capita)") title("Maximum affordable rent payments (Tamil Nadu)") xline(`r(p50)') 

//x is income per capita (beta version)
foreach var in rent_ria_income_a1_1 rent_ria_income_a1_2 {
replace `var' = . if `var' <= 0
}

format rent_ria_income_a1_1 rent_ria_income_a1_2 income_a1 %9.0fc

sum income_a1 [aw = pwt] ,de f
twoway line rent_ria_income_a1_1 rent_ria_income_a1_2 rent_income_ratio_a1 income_a1 if renter == 1 & inrange(income_a1,0, 3.2e3) & state == 33 || ///
scatter rent_pc1 rent_pc2 rent_pc3 rent_pc4 rent_pc5 rent_pc6 income_a1 if renter == 1 & inrange(income_a1,0, 3.2e3) & state == 33, graphregion(color(white)) ///
msize(tiny tiny tiny tiny tiny tiny) ytitle("Maximum Housing Exp. (PC. in Rsd.)") xtitle("Monthly Income (PC. in Rsd.)") title("Maximum affordable rent payments (Tamil Nadu)") ///
xline(`r(p50)', lpattern(dash))  legend(cols(3) label(1 "Low Budget") label(2 "Modest Budget")) ///
xlabel(640 `" "640" "(p10)" "' 1032 `" "1,032" "(p25)" "' 1846 `" "1,846" "(p50)" "' 3146 `" "3,146" "(p75)" "') //text(2e3 `r(p50)' "50th Percentile", color(black))


*find the households living in unaffordable houses
foreach var in ria_1 ria_2 ratio {
replace `var' = `var'*100
gen exp_`var' = (rent_pc > rent_`var')*100
}

//table of unaffordability using expenditure
table decile [aw = pwt],c(mean exp_ria_1 mean exp_ria_2 mean exp_ratio) row format(%15.2f)

//table of unaffordability using income
table decile_ic [aw = pwt], c(mean ria_1 mean ria_2 mean ratio) row format(%15.2f)

replace renter = renter*100

foreach var in ria_1 ria_2 ratio {
replace `var' = `var'*100
}

global var_tab "ria_1 ria_2 ratio rent_ic income_a1"
qui eststo total : estpost summarize $var_tab [aw = pwt] if renter ==100,de
forvalues i = 1/5 {
qui eststo q`i' : estpost summarize $var_tab [aw = pwt] if qt_ic == `i' & renter ==100,de
}

label var ria_1 "RIA, Low Budget Standard"
label var ria_2 "RIA, Modest Budget Standard"
label var ratio "30% Rule"
label var rent_ic "Rent to Income(%)"
label var income_a1 "Monthly Income (mean,PC. in Rsd.)"

esttab total q1 q2 q3 q4 q5, cells(mean(fmt(%15.1fc))) label collabels(none) varwidth(40) ///
 mtitles( "Urban" "Urban-Q1" "Urban-Q2" "Urban-Q3" "Urban-Q4" "Urban-Q5") stats(N, label("Observations") fmt(%15.1gc)) ///
 title("Rental affordability using different affordability measures in urban India (percent of population)") ///
 addnotes("Notes: Renter is defined as tenure status as hired" )

/*
stats (esttab): 
    
3-4 candidate for the higher 
    
compare mcpe for each decile 
    
see which decile equals 2 x value from decile3
    
affordability - % of HH for measures that we classify as afforadable / not-affordable 
    
what kind of HHs are these? features? sanitazation, hh size, expensive mega cities, gender, water, roof 
*/

***************************************************************
*Step 3: Budget Standard for Owners **************************
***************************************************************


***Data preparation***

*Household type
use "${r_input}\bk_4.dta",clear

bysort ID: gen hhsize_m = _N //manually calculate household size
sum hhsize_m [aw = hhwt],de

mdesc B4_v05
drop if mi(B4_v05)
gen adult = (B4_v05 >= 18)

gen n = 1
collapse (sum) n (mean) hhsize_m (mean) hhwt (mean) B1_v05,by(ID adult)
reshape wide n,i(ID) j(adult)

foreach var in n0 n1 {
replace `var' = 0 if mi(`var')
}

rename (n0 n1 B1_v05) (n_child n_adult sector)

save "${r_output}\household_type.dta",replace


*use kmeans kmedians to get the clusters of household type： adult and children
use "${r_output}\household_type.dta",clear
keep if sector == 2
//only child:0,1,2,>=3
cluster kmedians n_child, k(4) start(firstk)
tab _clus_1 [aw = hhwt]
table _clus_1 [aw = hhwt],c(p50 n_adult p50 n_child)
table _clus_1 [aw = hhwt],c(min n_adult max n_adult min n_child  max n_child) 

//only adult: <=1,2,3,4,>=5
cluster kmedians n_adult, k(5) start(firstk)
tab _clus_2 [aw = hhwt]
table _clus_2 [aw = hhwt],c(p50 n_adult p50 n_child)
table _clus_2 [aw = hhwt],c(min n_adult max n_adult min n_child  max n_child) 

//adult and child:
foreach var in adult child {
tostring(n_`var'),gen(n_`var'_txt)
}

gen adult_child = n_adult_txt + "_" + n_child_txt
tab adult_child [aw = hhwt],sort

cluster kmedians n_child n_adult, k(6) start(firstk)
tab _clus_3 [aw = hhwt]
table _clus_3 [aw = hhwt],c(p50 n_adult p50 n_child )
table _clus_3 [aw = hhwt],c(min n_adult max n_adult min n_child  max n_child) 

/*
adult_child == "2_2" //tow adults with two children (12.99% urban hh.)
adult_child == "1_0"  //single adult without child (11.40% urban hh.)
adult_child == "2_0" //two adults only (9.84%)
adult_child == "2_1"  //two adults with one children (8.72% urban hh.)
*/

gen hh_type = adult_child //only for urban, please note stats are not representative at hh_type level. 
replace hh_type = "other" if !inlist(adult_child, "2_2","1_0","2_0","2_1")
tab hh_type [aw = hhwt] //top 4 types of households cover 42% India urban households. 


*use kmeans kmedians to get the clusters of household type: total household number
use "${r_output}\household_type.dta",clear
keep if sector == 2

cluster kmedians hhsize_m, k(4) start(firstk)
tab _clus_1 [aw = hhwt]
table _clus_1 [aw = hhwt],c(p50 hhsize_m min hhsize_m max hhsize_m)

gen hh_type = ""
replace hh_type = "5-31" if _clus_1 == 1 // > 4 household member (36.12% urban hh.)
replace hh_type = "4" if _clus_1 == 4 //4 household member (24.14% urban hh.)
replace hh_type = "1-2" if _clus_1 == 2 //1-2 household member (23.76%)
replace hh_type = "3" if _clus_1 == 3 //3 household member (15.98% urban hh.)

tab hh_type [aw = hhwt] //top 4 types of households cover 63% India urban households. 

*use the relationship to household head for household types. 
/*
B4_v03: Relation to household head
           1 Self
           2 Spouse of head
           3 Married child
           4 Spouse of married child
           5 Unmarried child
           6 Grandchild
           7 Father/mother/father-in-law/mother-in-law
           8 Brother/sister/brother-in-law/sister-in-law/other relatives
           9 Servant/employees/other non-relatives

*/
/*
gen hh_type = . //please note stats are not representative at hh_type level. 
replace hh_type = 1 if hhsize_m == 1 //single person 
replace hh_type = 2 if hhsize_m == 2 & n2 == 1 //couple only 
replace hh_type = 3 if hhsize_m == 2 & n5 == 1 //sole parent with one child (unmarried)
replace hh_type = 4 if hhsize_m == 4 & n2 == 1 & n5 == 2 //couple with two children 
*/

rename ID hhid
keep hhid hh_type

merge 1:1 hhid using "${r_output}\nss68_ria_master.dta"
keep if _merge == 3 


***********imputed rent to total expenditure**********
*generate the adjusted mpce
gen rent_impt_pc = total_rent_impt /hhsize

mdesc mpce_mrp rent_pc rent_impt_pc
gen mpce_mrp_impt = mpce_mrp - rent_pc + rent_impt_pc //adjust the mpce
gen rent_impt_mpce = rent_impt_pc/mpce_mrp_impt*100 //share of rent on total expenditure per capita (renters)

*stats for owners
table decile [aw = pwt], c(mean owner) row 
table decile if owner == 1 [aw = pwt], c(mean rent_impt_pc mean mpce_mrp_impt mean rent_impt_mpce) row // only for owners 

***********RIA approach for housing owner**********
*Using income instead of exp. 

*Maximum amount available for mortgage per capita/household
forvalues i = 1/2 {
gen own_ria_`i'_pc = mpce_mrp - pline_nhs_`i' //hypothetical expenditure, we are using mpce (actual exp.), different from Australia
gen own_ria_`i'_hh = own_ria_`i' *hhsize

  forvalues  q = 0(1)2 {
  gen own_ria_income_a`q'_`i'_pc = income_a`q' - pline_nhs_`i'
  gen own_ria_income_a`q'_`i'_hh = own_ria_income_a`q'_`i'_pc*hhsize
  }
}

label var own_ria_1_pc "Low Cost Budget Standard"
label var own_ria_1_hh "Low Cost Budget Standard"

label var own_ria_income_a1_1_hh "Low Cost Budget Standard"
label var own_ria_income_a1_1_pc "Low Cost Budget Standard"

label var own_ria_2_pc "Modest Budget Standard"
label var own_ria_2_hh "Modest Budget Standard"

label var own_ria_income_a1_2_hh "Modest Budget Standard"
label var own_ria_income_a1_2_pc "Modest Budget Standard"

*The max housing exp with ratio approach 
gen own_ratio_pc = mpce_mrp*0.3
label var own_ratio "30% Rule"

gen own_ratio_hh = mpce_mrp*hhsize*0.3
label var own_ratio_hh "30% Rule"

forvalues  q = 0(1)2 {
gen own_income_ratio_a`q'_pc = income_a`q'*0.3
label var own_income_ratio_a`q'_pc "30% Rule"

gen own_income_ratio_a`q'_hh = income_a`q'*hhsize*0.3
label var own_income_ratio_a`q'_hh "30% Rule"
}

*Plot the curve (per capita)
sum mpce_mrp [aw = pwt],de
twoway line own_ria_1_pc own_ria_2_pc own_ratio_pc mpce_mrp if owner == 1 & inrange(mpce_mrp,0, 200) & state == 33 || scatter rent_impt_pc mpce_mrp if owner == 1 & inrange(mpce_mrp,0, 200) & state == 33, ///
msize(tiny) ytitle("Maximum Mortgage Payment(Per Capita)") xtitle("Monthly Exp.(Per Capita)") title("Maximum affordable mortgage and imputed rent for housing owner (Tamil Nadu Urban)", size(small)) xline(`r(p50)') //looking at Tamil Nadu state level 

sum income_a1 [aw = pwt],de
twoway line own_ria_income_a1_1_pc own_ria_income_a1_2_pc own_income_ratio_a1_pc income_a1 if owner == 1 & inrange(income_a1,0, 200) & state == 33 || scatter rent_impt_pc income_a1 if owner == 1 & inrange(income_a1,0, 200) & state == 33, ///
msize(tiny) ytitle("Maximum Mortgage Payment(Per Capita)") xtitle("Monthly Income(Per Capita)") title("Maximum affordable mortgage and imputed rent for housing owner (Tamil Nadu Urban)", size(small)) xline(`r(p50)') //looking at Tamil Nadu state level 

*Plot the curve (by household type)
gen mhce = mpce_mrp*hhsize

forvalues  i = 0(1)2 {
gen income_a`i'_hh = income_a`i'*hhsize
}

//expenditure
sum mhce [aw = hhwt],de
line own_ria_1_hh own_ria_2_hh own_ratio_hh mhce if owner == 1 & state == 33 & hh_type == "4" & own_ria_2_hh >= 0 , ///
xtitle("Household Monthly Exp.") ytitle("Maximum Monthly Mortgage Payment") title("Maximum affordable mortgage payments in USD(Tamil Nadu: 4-member household)", size(small)) xline(`r(p50)') 

sum mhce [aw = hhwt],de
line own_ria_1_hh own_ria_2_hh own_ratio_hh mhce if owner == 1 & state == 33 & hh_type == "3" & own_ria_2_hh >= 0 , ///
xtitle("Household Monthly Exp.") ytitle("Maximum Monthly Mortgage Payment") title("Maximum affordable mortgage payments in USD(Tamil Nadu: 3-member Household)", size(small)) xline(`r(p50)') 

//income
sum income_a1_hh [aw = hhwt],de
line own_ria_1_hh own_ria_2_hh own_ratio_hh mhce if owner == 1 & state == 33 & hh_type == "4" & own_ria_2_hh >= 0 , ///
xtitle("Household Monthly Exp. ") ytitle("Maximum Monthly Mortgage Payment") title("Maximum affordable mortgage payments in USD(Tamil Nadu: 4-member household)", size(small)) xline(`r(p50)') 

sum income_a1_hh [aw = hhwt],de
line own_ria_1_hh own_ria_2_hh own_ratio_hh mhce if owner == 1 & state == 33 & hh_type == "3" & own_ria_2_hh >= 0, ///
xtitle("Household Monthly Exp.") ytitle("Maximum Monthly Mortgage Paymen") title("Maximum affordable mortgage payments in USD(Tamil Nadu: 3-member Household)", size(small)) xline(`r(p50)') 


*convert the maximun mortgage to house value
/*
PV = mortgage amount
PMT = monthly payment (is not fixed, can not just plug in the own_ria_1_hh)
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

format max_hse_val* max_loan* %15.0fc

sum mhce [aw = hhwt],de
line max_hse_val_1 max_hse_val_2 max_hse_val_ratio mhce if owner == 1 & state == 33 & hh_type == "4", ///
xtitle("Household Monthly Exp.") ytitle("Maximum Monthly Mortgage Paymen") title("Maximum affordable housing value (Tamil Nadu: 4-member household)", size(small)) xline(`r(p50)') //looking at  



//change everthing in dollar. 
