// Author:          Oscar Suen
// Date Modified:   08/24/2020
// Description:     Generating cz population data

// Reset stata
cap log close
clear all
set more off

// Date last run
local daterun : di %tdCYND daily(c(current_date), "DMY")

// File locations
global root `c(pwd)'
global code $root/code
global raw  $root/data/raw
global log  $root/log
global out  $root/out
global dta  $root/data/dta

// Starts log
log using $log/aux_czpop_`daterun'.log, text replace

// Input filenames
local yearcty pop_yearcty.dta
local cty2cz cty2cz_crosswalk.dta

// Output filenames
local yearcz pop_yearcz.dta
local yearczwt wt_yearcz.dta
local cz_elderly cz_elderly.dta

* Collapse to CZ
********************************
use $dta/`yearcty', clear
replace county="08001" if county=="08014" // new county in CO
// Alaska county changes
replace county="02232" if county=="02230" | county=="02105"
replace county="02280" if county=="02195"
replace county="02201" if county=="02198"
replace county="02280" if county=="02275" // moved new county into old

merge m:1 county using $dta/`cty2cz'
drop if _merge==2

collapse (sum) pop*, by(year cz)
compress

save $dta/`yearcz', replace

* Generate Weights
*******************************
use $dta/`yearcz', clear
keep year cz pop_a_all
rename pop_a_all pop
bysort year : egen totalpop = total(pop)
generate popwt = pop/totalpop
keep year cz pop popwt
save $dta/`yearczwt', replace

* Generate Elderly Share
*******************************
use $dta/`yearcz', clear
keep if year == 2003 // Medicare Part D Passed
generate elderly_share = pop_a_6599 / pop_a_all
egen totalpop = total(pop_a_all)
generate popwt03 = pop_a_all / totalpop
keep cz elderly_share popwt03
save $dta/`cz_elderly', replace



log close
