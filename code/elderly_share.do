// Author:          Oscar Suen
// Date Modified:   04/23/18
// Description:     Elderly share by CZ in 2003

// Reset stata
cap log close
clear all
set more off

// Date last run CHANGE
local daterun 20180406

// File locations REPLACE root
global root "/bbkinghome/osuen/project/pop"
global code $root/code
global csv  $root/csv
global log  $root/log
global dta  $root/dta
global out  $root/out

// Export graph filetype
global expt ".pdf"

// Starts log
log using $log/elderly_`daterun'.log, text replace

// Input filenames
local popraw coest00intalldata.dta
local cty2cz cty2cz_crosswalk.dta
local czwt wt_yearcz.dta

// Output filenames
local cz_elderly cz_elderly.dta

// Section switches
local switch_elderlyshare=  0
local switch_summtable=     1
local switch_histogram=     0
local switch_map=           0

********************************
* Generate elderly share       *
********************************

* Generate elderly share
********************************
if `switch_elderlyshare' {
    use $dta/`popraw', clear
    keep if year==2003

    replace county="08001" if county=="08014" // new county in CO
    // AK county promblems
    replace county="02232" if county=="02230" | county=="02105"
    replace county="02280" if county=="02195"
    replace county="02201" if county=="02198"
    replace county="02280" if county=="02275" // moved new county into old

    keep county agegrp tot_pop
    rename tot_pop pop
    collapse (sum) pop, by(county agegrp)
    reshape wide pop, i(county) j(agegrp)
    rename pop99 totalpop
    generate elderlypop = pop14 + pop15 + pop16 + pop17 + pop18
    drop pop*

    merge 1:1 county using $dta/`cty2cz'
    drop if _merge==2
    assert _merge==3
    drop _merge

    collapse (sum) totalpop elderlypop, by(cz)

    generate elderly_share = elderlypop/totalpop

    keep cz elderly_share
    save $dta/`cz_elderly', replace
    
    use $dta/`czwt', clear
    keep if year==2003
    keep cz popwt
    merge 1:1 cz using $dta/`cz_elderly'
    assert _merge==3
    drop _merge
    save $dta/`cz_elderly', replace
}

log close

