// Author:          Oscar Suen
// Date Modified:   03/24/18
// Description:     Generating opioid prescription panel
//                  by year/cz (currently zip)

// Reset stata
cap log close
clear all
set more off

// Date last run CHANGE
local daterun 20180407

// File locations REPLACE root
global root "/bbkinghome/osuen/project/pop"
global code $root/code
global csv  $root/csv
global logs $root/logs
global dta  $root/dta

// Starts log
log using $logs/yearcz_population_`daterun'.log, text replace

// Input filenames
local pop2000 co-est2010-alldata.csv
local pop2010 co-est2017-alldata.csv
local cty2cz cty2cz_crosswalk.dta

// Output filenames
local raw2000 yearcty2000.dta
local raw2010 yearcty2010.dta
local yearcty pop_yearcty.dta
local yearcz pop_yearcz.dta
local yearczwt wt_yearcz.dta

// Section switches
local switch_convertdta=    1
local switch_yearcz=        1
local switch_weights=       1

* Convert csv to dta
********************************
if `switch_convertdta' {
    foreach year in 2000 2010 {
        display `year'
        import delimited $csv/`pop`year'', clear
        tostring state, replace format("%02.0f")
        rename county countyfip
        tostring countyfip, replace format("%03.0f")
        drop if countyfip == "000" // remove state totals
        generate county = state + countyfip
        drop sumlev region division state countyfip stname ctyname
        drop census`year'pop estimatesbase`year' gqestimatesbase`year'
        drop rbirth* rdeath* rnaturalinc* rinternationalmig* rdomesticmig* rnetmig*
        reshape long popestimate npopchg_ births deaths naturalinc internationalmig domesticmig netmig residual gqestimates, i(county) j(year)
        rename npopchg_ npopchg
        save $dta/`raw`year'', replace
    }

    use $dta/`raw2000', clear
    drop if year==2010
    // put estimates of 51515 into 51019
    replace county="51019" if county=="51515"
    collapse (sum) popestimate npopchg births deaths naturalinc internationalmig domesticmig netmig residual gqestimates, by(county year)

    append using $dta/`raw2010'
    replace county="02270" if county=="02158"
    replace county="46113" if county=="46102"

    save $dta/`yearcty', replace
}

* Collapse to CZ
********************************
if `switch_yearcz' {
    use $dta/`yearcty', clear
    replace county="08001" if county=="08014" // new county in CO
    // Alaska county changes
    replace county="02232" if county=="02230" | county=="02105"
    replace county="02280" if county=="02195"
    replace county="02201" if county=="02198"
    replace county="02280" if county=="02275" // moved new county into old

    merge m:1 county using $dta/`cty2cz'
    drop if _merge==2

    collapse (sum) popestimate npopchg births deaths naturalinc internationalmig domesticmig netmig residual gqestimates, by(year cz)
    compress

    save $dta/`yearcz', replace
}

* Generate Weights
*******************************
if `switch_weights' {
    use $dta/`yearcz', clear
    keep year cz popestimate
    rename popestimate pop
    bysort year : egen totalpop = total(pop)
    generate popwt = pop/totalpop
    keep year cz popwt
    save $dta/`yearczwt', replace
}

log close
