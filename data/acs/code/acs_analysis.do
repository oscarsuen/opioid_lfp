// Author:          Oscar Suen
// Date Modified:   04/23/18
// Description:     Generating demographic/labor characteristics
//                  by year/cz 

// Reset stata
cap log close
clear all
set more off

set maxvar 20000

// Date last run CHANGE
local daterun 20180427

// File locations REPLACE root
global root "/bbkinghome/osuen/project/acs"
global code $root/code
global raw  $root/raw
global log  $root/log
global out  $root/out
global dta  $root/dta

// Export graph filetype
global expt ".pdf"

// Starts log
log using $log/acs_`daterun'.log, text replace

// Input filenames
local acs_raw usa_00011.dta
local puma2cz puma2cz_crosswalk.dta
local inflation_raw CPILFESL.csv

// Output filenames
local inflation cpi.dta
local rawdata acs_raw.dta
local panel_yearcz acs_yearcz.dta

// Section switches
local switch_cpidta=        0
local switch_yearczpanel=   1

********************************
* Generate Panel               *
********************************

* Generate CPI dta file
********************************
if `switch_cpidta' {
    import delimited $raw/`inflation_raw', clear
    rename date year
    rename cpilfesl cpi
    replace year = substr(year, 1, 4)
    destring year, replace
    save $dta/`inflation', replace
}

* Generate year/zip panel
********************************
if `switch_yearczpanel' {
    use $raw/`acs_raw', clear

    drop if year > 2011 // PUMA change DELETE

    generate age_elderly = age >= 65
    generate age_adult = age >= 16
    generate age_1664 = age >= 16 & age < 65
    generate age_1654 = age >= 16 & age < 55
    generate age_2564 = age >= 25 & age < 65
    generate age_2554 = age >= 25 & age < 55

    generate age_1624 = age >= 16 & age < 25
    generate age_2534 = age >= 25 & age < 35
    generate age_3544 = age >= 35 & age < 45
    generate age_4554 = age >= 45 & age < 55
    generate age_5564 = age >= 55 & age < 65

    generate age_1634 = age >= 16 & age < 35
    generate age_4564 = age >= 45 & age < 65

    generate sex_m = sex == 1
    generate sex_f = sex == 2

    generate race_wt = racesing == 1 & hispan == 0
    generate race_hi = hispan != 0 & racesing != 2
    generate race_bk = racesing == 2
    generate race_ot = racesing > 2 & hispan == 0
    assert race_wt + race_hi + race_bk + race_ot == 1

    generate poverty_ = poverty < 100 if poverty != 0

    generate empstat_empld = empstat == 1 if age_adult
    generate empstat_unemp = empstat == 2 if age_adult
    generate empstat_nilfo = empstat == 3 if age_adult
    replace empstat_nilfo = 1 if empstat_empld + empstat_unemp + empstat_nilfo == 0 & age_adult
    assert empstat_empld + empstat_unemp + empstat_nilfo == 1 if age_adult
    generate empstat_labforce = empstat_empld | empstat_unemp
    generate lfp_ = empstat_labforce
    generate unemp_ = empstat_unemp if empstat_labforce

    generate industry_manuf = (ind1990 >= 100 & ind1990 <= 392) if empstat_labforce

    generate educ_hd = educd < 60 if age_adult
    generate educ_hs = educd >= 60 & educd <= 64 if age_adult
    generate educ_sc = educd >= 65 & educd <= 100 if age_adult
    generate educ_cg = educd >= 101 if age_adult
    assert educ_hd + educ_hs + educ_sc + educ_cg == 1 if age_adult

    generate income = incwage if incwage!=999999
    generate incomenoz = incwage if incwage > 0 & incwage!=999999

    merge m:1 year using $dta/`inflation'
    drop if _merge==2
    assert _merge==3
    drop _merge

    generate realinc = income * cpi/181.2917 // 2000 USD
    generate lgrlinc_ = log(realinc) if realinc > 0
    generate ihsrlinc_ = log(realinc + sqrt(realinc^2 + 1))
    generate noincome_ = income == 0

    local outcomes lfp unemp lgrlinc ihsrlinc poverty noincome
    local ages 1664 1654 2564 2554 1624 2534 3544 4554 5564
    local sexes m f
    local races wt bk hi ot
    local educs hd hs sc cg

    foreach var in `outcomes' {
        foreach age in `ages' {
            generate `var'_`age' = `var'_ if age_`age'
        }
        foreach sex in `sexes' {
            generate `var'_2554`sex' = `var'_ if age_2554 & sex_`sex'
        }
    }



    replace puma=1801 if puma==77777 // Katrina change

    generate puma2k = (statefip*10000)+puma // unique id

    joinby puma2k using $dta/`puma2cz', unmatched(both)
    assert _merge==3
    drop _merge

    generate aperwt = alpha * pernum

    save $dta/`rawdata', replace

    keep year cz *_* aperwt

    generate cnt = 1

    collapse (mean) age_* sex_* race_* poverty_* empstat_* industry_* educ_* lfp_* unemp_* noincome_* (median) lgrlinc_* ihsrlinc_* (sum) cnt [pw=aperwt], by(year cz) fast

    bysort year : egen yrcnt = sum(cnt)
    generate popwt = cnt/yrcnt
    drop cnt yrcnt
    
    save $dta/`panel_yearcz', replace
}

log close

