// Author:          Oscar Suen
// Date Modified:   08/24/2020
// Description:     Generate workfile for analysis

// Reset stata
cap log close
clear all
set more off

set maxvar 20000

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
log using $log/analysis_workfile_`daterun'.log, text replace

// Input filenames
local panel_yearcz acs_yearcz.dta
local czpop pop_yearcz.dta
local czwt wt_yearcz.dta
local opioid_rate opioid_yearcz.dta
local cz_elderly cz_elderly.dta
local cz2state cz2state_crosswalk.dta
local state2reg state2reg_crosswalk.dta

// Output filenames
local workfile workfile.dta
local workfile_copy _workfile_`daterun'.dta

********************************
* Workfile                     *
********************************

* Generate Workfile
********************************
use $acs/`panel_yearcz', clear
rename popwt popwtacs

foreach file in $pop/`czpop' $pop/`czwt' $arcos/`opioid_rate' {
    merge 1:1 year cz using `file'
    tab year if _merge==1
    tab year if _merge==2
    keep if _merge==3
    drop _merge
}
save $dta/`workfile', replace

use $pop/`cz_elderly', clear
rename elderly_share sh_elderly03
rename popwt popwt03
save $dta/temp.dta, replace

use $dta/`workfile', clear
merge m:1 cz using $dta/temp.dta
assert _merge==3
drop _merge

rename percap opioid_rate

merge m:1 cz using $crosswalks/`cz2state'
drop if _merge==2
assert _merge==3
drop _merge

merge m:1 state using $crosswalks/`state2reg'
drop if _merge==2
assert _merge==3
drop _merge

generate instrument = sh_elderly03 * (year >= 2006)

egen stateyear = group(state year)
egen divisionyear = group(division year)

xtset cz year, yearly

save $dta/`workfile', replace
erase $dta/temp.dta

use $dta/`workfile', clear
save $dta/`workfile_copy', replace


log close
