// Author:          Oscar Suen
// Date Modified:   03/23/18
// Description:     Generating opioid prescription panel
//                  by year/cz (currently zip)

// Reset stata
cap log close
clear all
set more off

// Date last run CHANGE
local daterun 20180523

// File locations REPLACE root
global root "/bbkinghome/osuen/project/lau"
global code $root/code
global csv  $root/csv
global logs $root/logs
global out  $root/out
global dta  $root/dta

// Export graph filetype
global expt ".pdf"

// Starts log
log using $logs/prescriptions_`daterun'.log, text replace

// Input filenames
local raw_csv lau_cty.csv
local cty2cz cty2cz_crosswalk.dta
local czpop pop_yearcz.dta

// Output filenames
local cty_raw lau_cty.dta
local cz_raw lau_cz.dta
local rate_panel labforce_rate.dta

// Section switches
local switch_convertdta=    1
local switch_yearczpanel=   1
local switch_ratepanel=     0
local switch_grossgraph=    0
local switch_presmaps=      0
local switch_pctilegraph=   1

********************************
* Generate Panel               *
********************************

* Convert to dta
********************************
if `switch_convertdta' {
    import delimited using $csv/`raw_csv', clear varnames(1) stringcols(1) numericcols(2 3 4)
    compress
    save $dta/`cty_raw', replace
}

* Generate year/cz panel
********************************
if `switch_yearczpanel' {
    use $dta/`cty_raw', clear

    drop if substr(county, 1, 2)=="72" // Drop PR
    replace county="08001" if county=="08014" // new county in CO
    replace county="46113" if county=="46102" // county in SD
    // Alaska county changes
    replace county="02232" if county=="02230" | county=="02105"
    replace county="02280" if county=="02195"
    replace county="02201" if county=="02198"
    replace county="02280" if county=="02275" // moved new county into old
    replace county="02270" if county=="02158"

    // Replace 7 LA counties in 05,06 with missing values (Katrina?)
    replace labforce = 0 if labforce == .
    replace employed = 0 if employed == .

    merge m:1 county using $dta/`cty2cz'
    drop if _merge==2
    assert _merge==3

    collapse (sum) labforce employed, by(year cz)

    save $dta/`cz_raw', replace
}

if `switch_ratepanel' {
    use $dta/`cz_raw', clear
    merge 1:1 year cz using $dta/`czpop'
    drop if year==2017
    keep year cz labforce employed popestimate
    generate percap = grams/popestimate
    save $dta/`opioid_rate', replace

}


********************************
* Summary Statistics           *
********************************

* Graph of gross totals 
********************************
if `switch_grossgraph' {
    use $dta/`raw_panel_count', clear
    collapse (sum) grams, by(year)
    tsset year, yearly
    line grams year
    graph save $out/`us_total_graph', replace
    graph export $out/`us_total_graph_expt', replace
}

* Maps of Crisis
********************************
if `switch_presmaps' {
    use $dta/`opioid_rate', clear
    pctile breakpoints=percap, nq(8)
    forvalues yr = 2000/2016 {
        maptile percap if year==`yr', geo(cz2000) cutp(breakpoints) twopt(legend(off))
        graph export $out/`opioidmap'`yr'$expt, replace
    }
}

* Distribution of CZs over time
********************************
if `switch_pctilegraph' {
    use $dta/`opioid_rate', clear
    collapse (p10) p10=percap (p25) p25=percap (p50) p50=percap (p75) p75=percap (p90) p90=percap [w=popestimate], by(year)
    line p10 year || line p25 year || line p50 year || line p75 year || line p90 year
    graph save $out/`pctile_graph', replace
    graph export $out/`pctile_graph_expt', replace
}

log close
