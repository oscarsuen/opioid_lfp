// Author:          Oscar Suen
// Date Modified:   08/24/2020
// Description:     Main regressions

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
log using $log/analysis_regressions_`daterun'.log, text replace

// Input filenames
local workfile workfile.dta

// Output filenames
local estimates estimates.sters


********************************
* Regressions                  *
********************************

* Generate estimates
********************************
use $dta/`workfile', clear

// First Stage
eststo firststage_simpleunw: regress opioid_rate instrument, cluster(cz)
eststo firststage_simplewtd: regress opioid_rate instrument [w=popwt03], cluster(cz)
eststo firststage_year: reghdfe opioid_rate instrument [w=popwt03], absorb(year) cluster(cz)
eststo firststage_cz: reghdfe opioid_rate instrument [w=popwt03], absorb(cz) cluster(cz)
eststo firststage_czyr: reghdfe opioid_rate instrument [w=popwt03], absorb(cz year) cluster(cz)
eststo firststage_czdivyrunw: reghdfe opioid_rate instrument, absorb(cz divisionyear) cluster(cz)
eststo firststage_czdivyr: reghdfe opioid_rate instrument [w=popwt03], absorb(cz divisionyear) cluster(cz)
eststo firststage_czstateyr: reghdfe opioid_rate instrument [w=popwt03], absorb(cz stateyear) cluster(cz)
eststo firststage_timetrend: reghdfe opioid_rate instrument c.sh_elderly03#c.year [w=popwt03], absorb(cz divisionyear) cluster(cz)

* CONTROLS NEEDED? ABSORBED BY INDICATORS? *
// local controls

foreach var in lfp unemp lgrlinc ihsrlinc noincome poverty {
    foreach age in 1664 1654 2564 2554 {
        eststo ols_`var'_`age'_: reghdfe `var'_`age' opioid_rate [w=popwt03], absorb(cz divisionyear) cluster(cz)
        eststo red_`var'_`age'_: reghdfe `var'_`age' instrument [w=popwt03], absorb(cz divisionyear) cluster(cz)
        eststo ivr_`var'_`age'_: reghdfe `var'_`age' (opioid_rate=instrument) [w=popwt03], absorb(cz divisionyear) cluster(cz)
    }
    foreach age in 1624 2534 3544 4554 5564 {
        eststo ivr_`var'_`age'_age: reghdfe `var'_`age' (opioid_rate=instrument) [w=popwt03], absorb(cz divisionyear) cluster(cz)
    }
    foreach age in 2554 {
        foreach sex in m f {
            eststo ivr_`var'_2554_sex_`sex': reghdfe `var'_`age'`sex' (opioid_rate=instrument) [w=popwt03], absorb(cz divisionyear) cluster(cz)
        }
    }
}

estwrite * using $out/`estimates', replace


log close
