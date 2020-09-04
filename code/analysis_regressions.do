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
local workfile workfile_quarter.dta

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
eststo firststage_qtr: reghdfe opioid_rate instrument [w=popwt03], absorb(quarter) cluster(cz)
eststo firststage_cz: reghdfe opioid_rate instrument [w=popwt03], absorb(cz) cluster(cz)
eststo firststage_czyr: reghdfe opioid_rate instrument [w=popwt03], absorb(cz quarter) cluster(cz)
eststo firststage_czdivqtrunw: reghdfe opioid_rate instrument, absorb(cz divqtr) cluster(cz)
eststo firststage_czdivqtr: reghdfe opioid_rate instrument [w=popwt03], absorb(cz divqtr) cluster(cz)
eststo firststage_czstateqtr: reghdfe opioid_rate instrument [w=popwt03], absorb(cz stateqtr) cluster(cz)
eststo firststage_timetrend: reghdfe opioid_rate instrument c.sh_elderly03#c.quarter [w=popwt03], absorb(cz divqtr) cluster(cz)

// TODO: CONTROLS NEEDED? ABSORBED BY INDICATORS?

local vars epop realinc lgrlinc
local ages_prime 2554 1554 2564 1564
local ages_group 1524 2534 3544 4554 5564
local sexes m f
foreach var in `vars' {
    foreach age in `ages_prime' {
        eststo ols_`var'_`age'_: reghdfe `var'_a_`age' opioid_rate [w=popwt03], absorb(cz divqtr) cluster(cz)
        eststo red_`var'_`age'_: reghdfe `var'_a_`age' instrument [w=popwt03], absorb(cz divqtr) cluster(cz)
        eststo ivr_`var'_`age'_: ivreghdfe `var'_a_`age' (opioid_rate=instrument) [w=popwt03], absorb(cz divqtr) cluster(cz)
    }
    foreach age in `ages_group' {
        eststo ivr_`var'_age_`age': ivreghdfe `var'_a_`age' (opioid_rate=instrument) [w=popwt03], absorb(cz divqtr) cluster(cz)
    }
    foreach sex in `sexes' {
        foreach age in `ages_prime' {
            eststo ivr_`var'_`age'_sex_`sex': ivreghdfe `var'_`sex'_`age' (opioid_rate=instrument) [w=popwt03], absorb(cz divqtr) cluster(cz)
        }
        foreach age in `ages_group' {
            eststo ivr_`var'_sex_`sex'_age_`age': ivreghdfe `var'_`sex'_`age' (opioid_rate=instrument) [w=popwt03], absorb(cz divqtr) cluster(cz)
        }
    }
}

estwrite * using $out/`estimates', replace


log close
