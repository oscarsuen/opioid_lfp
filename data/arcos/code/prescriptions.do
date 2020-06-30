// Author:          Oscar Suen
// Date Modified:   03/23/18
// Description:     Generating opioid prescription panel
//                  by year/cz (currently zip)

// Reset stata
cap log close
clear all
set more off

// Date last run CHANGE
local daterun 20180427

// File locations REPLACE root
global root "/bbkinghome/osuen/project/arcos"
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
local raw_csv prescriptions.csv
local zip2cz zip2cz_crosswalk.dta
local czpop pop_yearcz.dta
local czwt wt_yearcz.dta
local cz_elderly cz_elderly.dta

// Output filenames
local raw_prescriptions prescriptions_raw.dta
local raw_panel_count yearcz_count_raw.dta

// Section switches
local switch_convertdta=    1
local switch_yearzippanel=  1
local switch_ratepanel=     1

********************************
* Generate Panel               *
********************************

* Convert to dta
********************************
if `switch_convertdta' {
    import delimited using $csv/`raw_csv', clear 
    rename zipcode zip
    tostring zip, replace format("%03.0f")

    save $dta/`raw_prescriptions', replace
}

* Generate year/zip panel
********************************
if `switch_yearzippanel' {
    use $dta/`raw_prescriptions', clear

    generate annual = q1 + q2 + q3 + q4
    
    // Puerto Rico
    drop if zip=="006"
    drop if zip=="007"
    drop if zip=="008"
    drop if zip=="009"

    // Replacing in same city
    replace zip="191" if zip=="192" // Philly
    replace zip="200" if zip=="202" | zip=="204" | zip=="205" // DC
    replace zip="303" if zip=="311" // Atlanta
    replace zip="331" if zip=="332" // Miami
    
    // Not in use? investigate.
    drop if zip=="345"
    drop if zip=="353"

    // Replacing in same city
    replace zip="381" if zip=="375" // Memphis
    replace zip="317" if zip=="398" // Albany, GA (weird)

    // Not in use? investigate.
    drop if zip=="702"
    
    // Replacing in same city
    replace zip="752" if zip=="753" // Dallas
    replace zip="770" if zip=="772" // Houston
    replace zip="850" if zip=="851" // Phoenix
    replace zip="900" if zip=="901" // LA (weird)
    replace zip="937" if zip=="938" // Fresno
    replace zip="958" if zip=="942" // Sacramento

    // Military? investigate.
    drop if zip=="962"
    drop if zip=="965"

    // Guam
    drop if zip=="969"

    // Opioids
    // Hydrocodone, Hydromorphone, Meperidine, Morphine, Oxycodone
    keep if drugcode=="9120" | drugcode=="9193" | drugcode=="9150" | drugcode=="9220L" | drugcode=="9230" | drugcode=="9300" | drugcode=="9143"

    generate mme = .
    replace mme = 0.25 if drugcode=="9120" // Dihydrocodeine
    replace mme = 1 if drugcode=="9193" // Hydrocodone
    replace mme = 4 if drugcode=="9150" // Hydromorphone
    replace mme = 11 if drugcode=="9220L" // Levorphanol
    replace mme = 0.1 if drugcode=="9230" // Meperidine
    replace mme = 1 if drugcode=="9300" // Morphine
    replace mme = 1.5 if drugcode=="9143" // Oxycodone
    assert mme != .

    generate grams = annual * mme

    collapse (sum) grams, by(year zip)

    rename zip zip3

    joinby zip3 using $dta/`zip2cz', unmatched(both)

    drop if _merge==2
    
    collapse (sum) grams [pw=gamma], by(cz year)

    save $dta/`raw_panel_count', replace
}

if `switch_ratepanel' {
    use $dta/`raw_panel_count', clear
    merge 1:1 year cz using $dta/`czpop'
    drop if year==2017
    keep year cz grams popestimate
    generate percap = grams/popestimate
    merge 1:1 year cz using $dta/`czwt'
    tab year if _merge == 1
    tab year if _merge == 2
    keep if _merge == 3
    rename popestimate pop
    keep year cz percap popwt pop
    save $dta/`opioid_rate', replace

}


log close
