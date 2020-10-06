****************************************************************************
* Description: Generate a summary table of NSS 76 
* Date: October 2, 2020
* Version 1.0
* Last Editor: Nadeem 
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
if `pc' == 0 global root "C:\Users\wb308830\OneDrive - WBG\Documents\TN\Data\NSS 70\"
if `pc' != 0 global root "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\nss_data\NSS70"

di "$root"
global r_input "${root}\Raw Data & Dictionaries"
di "${r_input}"
global r_output "${root}\Data Output Files"
****************************************************************************
* Load the data
****************************************************************************
use "${root}\Data Output Files\NSS70_All.dta"

gen hh_urban = (sector == "2")

foreach var in asset debt wealth{
replace `var' = 0 if mi(`var')
} 
****************************************************************************
* Code to Produce the Table 
****************************************************************************
local var_summary asset debt wealth

eststo all: quietly estpost summarize `var_summary'  [aw=pwgt]
eststo urban: quietly estpost summarize `var_summary' if hh_urban == 1 [aw=pwgt]
eststo rural: quietly estpost summarize `var_summary' if hh_urban == 0 [aw=pwgt]
*eststo diff: quietly estpost ttest `var_summary' , by(hh_urban) 

unab vars : `var_summary'
*di `: word count `vars''
local num : word count `vars'
*di `num'
matrix b_prime = J(1,`num',0)
matrix se_prime = J(1,`num',0)
matrix t_prime = J(1,`num',0)

local rownames = "" 
local i = 1
foreach v of var `var_summary' {
	reg `v' hh_urban [aw=pwgt]
	matrix b_temp = e(b)
	matrix b_prime[1,`i'] = b_temp[1,1]
	matrix se_temp = e(V)
	local se = sqrt(se_temp[1,1])
	matrix se_prime[1,`i'] = `se'
	matrix t_prime[1,`i'] = b_prime[1,`i']/se_prime[1,`i']
	local i = `i' + 1
	di "`v'"
	local rownames =  "`rownames'" + " " +  "`v'"
	local N = `e(N)'
	}
di `N'
matrix b = b_prime 
matrix colnames b = `rownames'
matrix se = se_prime 
matrix colnames se = `rownames'
ereturn post b 
quietly estadd matrix se
quietly estadd scalar N = `N'
eststo diff2


esttab all urban rural diff2,  cells("mean(pattern(1 1 1 0) fmt(1)) b(star pattern(0 0 0 1) fmt(1))" ///
									  "sd(pattern(1 1 1 0) par fmt(1)) se(pattern(0 0 0 1) par fmt(1))") ///
			mtitles("All" "Urban" "Rural" "Delta U-R") nonumbers wide varwidth(41) label collabels(none) stats(N, label("Observations") fmt(%9.0gc)) ///
		addnote("Notes: Households weighted by survey weights." "       Standard deviations and standard errors shown in parentheses." "       * p<0.05, ** p<0.01, *** p<0.001") ///
		title("Summary Statistics of Household Wealth")