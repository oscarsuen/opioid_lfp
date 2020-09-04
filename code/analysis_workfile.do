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
local qwi_quarter qwi_qtrcz.dta
local opioid_quarter opioid_qtrcz.dta
local cz_elderly cz_elderly.dta
local cz2state cz2state_crosswalk.dta
local state2reg state2reg_crosswalk.dta

// Output filenames
local workfile_quarter workfile_quarter.dta
local workfile_year workfile_year.dta
local workfile_copy _workfile_`daterun'.dta

********************************
* Workfile                     *
********************************

* Generate Workfile
********************************
use $dta/`opioid_quarter', clear

merge 1:1 cz quarter using $dta/`qwi_quarter'
tab quarter _merge if _merge != 3
drop _merge // keeping all obs

merge m:1 cz using $dta/`cz_elderly'
tab quarter _merge if _merge != 3
assert _merge == 3
drop _merge

merge m:1 cz using $dta/`cz2state'
assert _merge == 3
drop _merge

merge m:1 state using $dta/`state2reg'
tab state if _merge != 3
keep if _merge == 3
drop _merge

rename percap opioid_rate
rename elderly_share sh_elderly03

generate instrument = sh_elderly03 * (quarter >= tq(2006q1))
egen stateqtr = group(state quarter)
egen divqtr = group(division quarter)
generate int year = yofd(dofq(quarter))
xtset cz quarter, quarterly

// TODO: maybe add epop_a_all > 1
generate _epop_exists = epop_a_all != . & epop_a_all != 0
generate _opioid_exists = opioid_rate != . & opioid_rate != 0
by cz: egen _epop_counts = sum(_epop_exists)
by cz: egen _opioid_counts = sum(_opioid_exists)
generate consistent_sample = _epop_counts == _opioid_counts
drop _*

save $dta/`workfile_quarter', replace
save $dta/`workfile_copy', replace

collapse (sum) grams opioid_rate consistent_sample (mean) epop_* realinc_* lgrlinc_* (first) sh_elderly03 popwt03 state region division instrument, by(cz year)
egen stateyr = group(state year)
egen divyr = group(division year)
replace consistent_sample = consistent_sample == 4
xtset cz year, yearly
save $dta/`workfile_year', replace

log close
