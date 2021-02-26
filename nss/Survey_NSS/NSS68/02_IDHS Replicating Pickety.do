
****************************************************************************
* Description: Use NSS68 and UMD HDS data estimate income, this file to 
* describe the income-exp ratio. 
* Date: Feb. 15, 2021
* Version 2
* Last Editor: Aline 
****************************************************************************

****************************************************************************
clear 
clear matrix
****************************************************************************

****************************************************************************
* Determine Whose Machine is running the code and set the global directory
****************************************************************************
if "`c(username)'" == "wb308830" local pc = 0
if "`c(username)'" != "wb308830" local pc = 1
if `pc' == 0 global root "C:\Users\wb308830\OneDrive - WBG\Documents\TN\Data\IDHS" //please correct accordingly
if `pc' != 0 global root "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\nss_data\NSS68"
if `pc' != 0 global script "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\Housing_git\nss\Survey_NSS\NSS68"

di "$root"
global r_input "${root}\Raw Data & Dictionaries"
di "${r_input}"
global r_output "${root}\Data Output Files"
di "${r_output}"

set more off 
clear 

putpdf clear
putpdf begin

*log using "${script}\03_HDS_income_stats.log",replace
set linesize 255

*******************************************
*******Estimate income expenditure ratio
*******************************************

use "${r_input}\DS0002\36151-0002-Data.dta",clear //UMD DHS data

foreach var of var * {
rename `var' `= lower("`var'")'
}

replace income = 0 if income < 0 //assumption there's no negative income. 

egen con_1 = rowtotal(co1x co2x co3x co4x co5x co6x co7x co8x co9x co10x co11x co12x ///
co13x co14x) //constructed
egen con_2 = rowtotal(co15-co30) 
egen con_3 = rowtotal(co31-co33)
egen con_4 = rowtotal(co34-co52) //annual

replace cototal= (con_1+con_2+con_3)*12+con_4
drop con_1-con_4
sum cototal [aw = indwt]
rename cototal exp

//per capita expenditure and its log
gen exp_ind = exp/npersons 
gen exp_ind_ln = ln(exp_ind)
gen exp_ln = ln(exp)

//per capita income and its log
gen income_ind = income/npersons
gen income_ind_ln = ln(income_ind)
gen income_ln = ln(income)

//label the variables
label var income "Income(Household)"
label var income_ind "Income(Per Capita)"
label var income_ind_ln "Log Income(Per Capita)"
label var income_ln "Log Income"

label var exp "Expenditure(Household)"
label var exp_ind "Expenditure(Per Capita)"
label var exp_ind_ln "Log Expenditure(Per Capita)"
label var exp_ln "Log Expenditure"

label var npersons "Household Size"

* X tiles 
xtile inc_10 =  income_ind [aw=indwt], nq(10)
xtile exp_10 =  exp_ind [aw=indwt], nq(10)

gen ratio = income / exp 


*Replicating Pickety 
*For each percentile of expenditure, calculate alpha as (mean income) / (mean expenditure)
xtile exp_100 = exp [aw=indwt], nq(100)
xtile inc_100 = income [aw=indwt], nq(100)

*assuming percentiles match 
egen mean_income_q = wtmean(income), by(inc_100) weight(indwt)
egen mean_exp_q = wtmean(exp), by(exp_100) weight(indwt)

keep if inc_100 == exp_100
keep inc_100 exp_100 mean_income_q mean_exp_q
duplicates drop

*ratio of two means 
gen alpha_a1 = mean_income_q / mean_exp_q

*mean of ratios 
sort exp_100
twoway line alpha_a1 exp_100 

*Gen A2 and A0 
gen alpha_a2 = max(1,alpha_a1)
gen alpha_a0 = 0.5 * (alpha_a1 + alpha_a2)

*Graph all three 
twoway line alpha_a1 alpha_a0 alpha_a2 exp_100, legend(row(1)) graphr(c(white))

drop inc_100 mean*

compress 
save "${root}/IDHS_Exp_To_Income.dta", replace

