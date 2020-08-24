// Author:          Oscar Suen
// Date Modified:   04/23/18
// Description:     Generating demographic/labor characteristics
//                  by year/cz 

// Reset stata
cap log close
clear all
set more off

// Date last run CHANGE
local daterun 20180324

// File locations REPLACE root
global root "/bbkinghome/osuen/project/cps"

// Export graph filetype
global expt ".pdf"

// Starts log
log using $root/cps_`daterun'.log, text replace

// Input filenames
local cps_raw cps_00002.dta
local cty2cz cty2cz_crosswalk.dta

// Output filenames
local panel_yearcz cps_yearcz.dta
local descriptivetable summary_table.tex
local instrument_histogram instrument_histogram.gph
local instrument_histogram_expt instrument_histogram$expt

// Section switches
local switch_yearczpanel=   0
local switch_summarytable=  0
local switch_instrhist=     1

********************************
* Generate Panel               *
********************************

* Generate year/zip panel
********************************
if `switch_yearczpanel' {
    use $root/`cps_raw', clear

    drop if county==0

    tostring county, replace format("%05.0f")

    replace county = "12086" if county == "12025" // Renamed Miami-Dale
    replace county = "08001" if county == "08014" // New county in CO

    merge m:1 county using $root/`cty2cz'

    keep if year >= 2000 & year <= 2016

    // Create age group shares
    generate age_00_15 = age <= 15
    generate age_16_17 = age >= 16 & age <= 17
    generate age_18_19 = age >= 18 & age <= 19
    generate age_20_20 = age == 20
    generate age_21_22 = age >= 21 & age <= 22
    generate age_23_24 = age >= 23 & age <= 24
    generate age_25_29 = age >= 25 & age <= 29
    generate age_30_34 = age >= 30 & age <= 34
    generate age_35_39 = age >= 35 & age <= 39
    generate age_40_44 = age >= 40 & age <= 44
    generate age_45_49 = age >= 45 & age <= 49
    generate age_50_54 = age >= 50 & age <= 54
    generate age_55_59 = age >= 55 & age <= 59
    generate age_60_64 = age >= 60 & age <= 64
    generate age_65_69 = age >= 65 & age <= 69
    generate age_70_74 = age >= 70 & age <= 74
    generate age_75_79 = age >= 75 & age <= 79
    generate age_80_00 = age >= 80
    assert age_00_15 + age_16_17 + age_18_19 + age_20_20 + age_21_22 + age_23_24 + age_25_29 + age_30_34 + age_35_39 + age_40_44 + age_45_49 + age_50_54 + age_55_59 + age_60_64 + age_65_69 + age_70_74 + age_75_79 + age_80_00 == 1

    generate age_elderly = age_65_69 + age_70_74 + age_75_79 + age_80_00
    generate age_labforce = !age_elderly & !age_00_15

    generate sex_m = sex == 1
    generate sex_f = sex == 2

    generate tmphispa = hispan >= 100 & hispan <= 900
    generate tmpwhite = race == 100 | (race >= 801 & race <= 804) | (race >= 810 & race <= 814) | race == 816 | race == 817 | race == 819
    generate tmpblack = race == 200 | (race >= 805 & race <= 807) | race == 818
    generate tmpother = race == 300 | (race >= 650 & race <= 652) | race == 808 | race == 809 | race==815 | race == 820 | race == 830
    assert tmpwhite + tmpblack + tmpother == 1

    generate race_white = tmpwhite & !tmphispa
    generate race_hispa = tmpwhite & tmphispa
    generate race_black = tmpblack
    generate race_other = tmpother
    assert race_white + race_hispa + race_black + race_other == 1

    generate marst_marsp = marst == 1
    generate marst_marsa = marst == 2
    generate marst_separ = marst == 3
    generate marst_divor = marst == 4
    generate marst_widow = marst == 5
    generate marst_singl = marst == 6
    replace marst_singl = 1 if marst_marsp+marst_marsa+marst_separ+marst_divor+marst_widow+marst_singl == 0 & age>=15
    assert marst_marsp + marst_marsa + marst_separ + marst_divor + marst_widow + marst_singl == 1 if age >= 15

    generate empstat_armed = empstat == 1
    generate empstat_empld = empstat == 10 | empstat == 12
    generate empstat_unemp = empstat == 21 | empstat == 22
    generate empstat_unabl = empstat == 32
    generate empstat_retir = empstat == 36
    generate empstat_nilfo = empstat == 34
    replace empstat_nilfo = 1 if empstat_armed + empstat_empld + empstat_unemp + empstat_unabl + empstat_retir + empstat_nilfo == 0 & age >= 15
    assert empstat_armed + empstat_empld + empstat_unemp + empstat_unabl + empstat_retir + empstat_nilfo == 1 if age >= 15

    generate labforce_part = (empstat_empld | empstat_unemp) if age_labforce

    // TODO: occupation and industry

    // TODO: hours

    generate educ_hidrop = educ < 70
    generate educ_higrad = educ >= 70 & educ < 80
    generate educ_somcol = educ >= 80 & educ < 110
    generate educ_cograd = educ == 111
    generate educ_prfdeg = educ > 111
    assert educ_hidrop + educ_higrad + educ_somcol + educ_cograd + educ_prfdeg == 1

    // TODO: earnings

    keep year cz *_* pernum

    generate cnt = 1

    collapse (mean) *_* (sum) cnt [fw=pernum], by(year cz)

    bysort year : egen yrcnt = sum(cnt)
    generate popwt = cnt/yrcnt
    drop cnt yrcnt
    
    save $root/`panel_yearcz', replace
}


********************************
* Descriptives                 *
********************************

* Summary tables
********************************
if `switch_summarytable' {
    use $root/`panel_yearcz', clear
    generate educ_anycol = educ_somcol+educ_cograd+educ_prfdeg
    summ age_elderly labforce_part race_white educ_anycol [aw=popwt]
    summ age_elderly labforce_part race_white educ_anycol [aw=popwt] if year<2006
    summ age_elderly labforce_part race_white educ_anycol [aw=popwt] if year>=2006
    /*outreg2 using $root/`descriptivetable'              ,replace tex(fragment) sum(log) eqkeep(mean sd) keep(age_elderly labforce_part race_white educ_anycol) cttop("All Years")*/
    /*outreg2 using $root/`descriptivetable' if year<2006 , append tex(fragment) sum(log) eqkeep(mean sd) keep(age_elderly labforce_part race_white educ_anycol) cttop("2000--2005")*/
    /*outreg2 using $root/`descriptivetable' if year>=2006, append tex(fragment) sum(log) eqkeep(mean sd) keep(age_elderly labforce_part race_white educ_anycol) cttop("2006--2016")*/
}

* Instrument histogram
if `switch_instrhist' {
    use $root/`panel_yearcz', clear
    histogram age_elderly if year==2003
    graph save $root/`instrument_histogram', replace
    graph export $root/`instrument_histogram_expt', replace
}

log close

