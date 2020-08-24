// Author:          Oscar Suen
// Date Modified:   04/07/2018
// Description:     Descriptive statistics

// Reset stata
cap log close
clear all
set more off


// Date last run CHANGE
local daterun 20180429

// File locations REPLACE root
global root         "/bbkinghome/osuen/project"
global analysis     $root/analysis
global code         $analysis/code
global dta          $analysis/dta
global out          $analysis/out
global logs         $analysis/log
global acs          $root/acs/dta
global arcos        $root/arcos/dta
global pop          $root/pop/dta
global crosswalks   $root/crosswalks/dta

// Export graph filetype
global expt ".pdf"

// Starts log
log using $logs/descriptives_`daterun'.log, text replace

// Input filenames
local panel_yearcz acs_yearcz.dta
local czpop pop_yearcz.dta
local czwt wt_yearcz.dta
local raw_panel_count yearcz_count_raw.dta
local opioid_rate opioid_rate.dta
local cz_elderly cz_elderly.dta
local cz2state cz2state_crosswalk.dta
local state2reg state2reg_crosswalk.dta
local yearlycps cps_yearly_lfp.dta

// Section switches
local switch_shold=         0
local switch_opioid=        0
local switch_lfp=           0

local switch_shold_table=   0 | `switch_shold'
local switch_shold_hist=    0 | `switch_shold'
local switch_shold_map=     0 | `switch_shold'

local switch_opioid_table=  0 | `switch_opioid'
local switch_opioid_graph=  0 | `switch_opioid'
local switch_opioid_lfp=    1 | `switch_opioid'
local switch_opioid_hist=   0 | `switch_opioid'
local switch_opioid_map=    0 | `switch_opioid'

local switch_lfp_table=     0 | `switch_lfp'
local switch_lfp_graph=     0 | `switch_lfp'
local switch_lfp_hist=      0 | `switch_lfp'
local switch_lfp_map=       0 | `switch_lfp'

********************************
* Instrument                   *
********************************

* Output files
********************************
local summtable shold_share_means.tex
local rawhist shold_rawhist
local czmap shold_map

* Summary table
********************************
if `switch_shold_table' {
    use $pop/`cz_elderly', clear
    summarize elderly_share, detail
    summarize elderly_share [w=popwt], detail
    rename elderly_share elderly_share_unw
    generate weights = popwt*709
    generate elderly_share_wtd = elderly_share * weights
    estpost summarize elderly_share_*
    esttab using $out/`summtable', replace cell((mean(fmt(%9.3g)) sd(fmt(%9.3g)) min(fmt(%9.3g)) max(fmt(%9.3g)))) nomtitles nonumber
}

if `switch_shold_hist' {
    use $pop/`cz_elderly', clear
    histogram elderly_share, width(0.01) xtitle("Elderly Share")
    graph save $out/`rawhist', replace
    graph export $out/`rawhist'$expt, replace
}

if `switch_shold_map' {
    use $pop/`cz_elderly', clear
    maptile elderly_share, geo(cz2000) nquantiles(10) propcolor
    graph save $out/`czmap', replace
    graph export $out/`czmap'$expt, replace
}


********************************
* Opioids                      *
********************************

* Output files
********************************
local year_summtable opioid_summary.tex
local us_total_graph opioid_total_graph
local opioidmap opioid_map
local opioidmapdiff opioid_map_diff
local pctile_graph opioid_pctile_graph
local rawhist opioid_histogram
local rawhist06 opioid_histogram2006
local opioidlfp_graph opioidlfp_graph

* Summary Table
********************************
if `switch_opioid_table' {
    use $arcos/`opioid_rate', clear
    keep if year==2000 | (year>=2005 & year<=2011)
    drop popwt
    merge m:1 cz using $pop/`cz_elderly', nogenerate assert(match)
    rename popwt popwt03
    collapse (mean) percap [w=popwt03], by(cz)
    generate year=9999

    append using $arcos/`opioid_rate'
    keep if year==9999 | year <= 2011
    drop pop popwt
    reshape wide percap, i(cz) j(year)
    merge 1:1 cz using $pop/`cz_elderly', nogenerate assert(match)
    rename popwt popwt03
    rename percap* opioid_rate*
    rename opioid_rate9999 opioid_mean
    order opioid_mean, first

    generate opioid_diff0011 = opioid_rate2011-opioid_rate2000
    generate opioid_diff0005 = opioid_rate2005-opioid_rate2000
    generate opioid_diff0611 = opioid_rate2011-opioid_rate2006
    estpost summ opioid_mean opioid_rate* opioid_diff* [w=popwt03]

    esttab using $out/`year_summtable', replace cell((mean(fmt(%9.3f)) sd(fmt(%9.3f)) min(fmt(%9.3f)) max(fmt(%9.3f)))) nomtitles nonumber
    eststo clear
}

* Graphs over time
********************************
if `switch_opioid_graph' {
    use $arcos/`raw_panel_count', clear
    collapse (sum) grams, by(year)
    tsset year, yearly
    replace grams=grams/1000000
    line grams year, yscale(range(-10)) ylabel(0(50)200) ttitle("Year") ytitle("Million Grams")
    graph save $out/`us_total_graph', replace
    graph export $out/`us_total_graph'$expt, replace

    use $arcos/`opioid_rate', clear
    drop popwt
    merge m:1 cz using $pop/`cz_elderly', nogenerate assert(match)
    rename popwt popwt03
    collapse (p10) p10=percap (p25) p25=percap (p50) p50=percap (p75) p75=percap (p90) p90=percap [pw=popwt03], by(year)
    line p10 year || line p25 year || line p50 year || line p75 year || line p90 year
    graph save $out/`pctile_graph', replace
    graph export $out/`pctile_graph'$expt, replace
}

if `switch_opioid_lfp' {
    use $pop/`czpop', clear
    collapse (sum) popestimate, by(year)
    save tempopioidgraph.dta, replace
    use $arcos/`raw_panel_count', clear
    collapse (sum) grams, by(year)
    merge 1:1 year using tempopioidgraph.dta, nogenerate keep(match)
    merge 1:1 year using $dta/`yearlycps', nogenerate keep(match)
    tsset year, yearly
    generate percap = grams/popestimate
    egen maxpercap = max(percap)
    local top = maxpercap[1]*10+80
    line percap year, yaxis(1) ytitle("Opioids Prescribed per Capita (g)", axis(1)) yscale(range(-0.01) axis(1)) ylabel(0(0.1)0.5, axis(1)) || line lfp year, yaxis(2) ytitle("Labor Force Participation (%)", axis(2)) yscale(range(79.9 `top') axis(2)) ylabel(80(1)85, axis(2)) ||, ttitle("Year") legend(off)
    graph save $out/`opioidlfp_graph', replace
    graph export $out/`opioidlfp_graph'$expt, replace
    erase tempopioidgraph.dta
}

* Maps of Crisis
********************************
if `switch_opioid_map' {
    use $arcos/`opioid_rate', clear
    /*pctile breakpoints=percap, nq(8)*/
    /*forvalues yr = 2000/2011 {
        maptile percap if year==`yr', geo(cz2000) cutp(breakpoints) twopt(legend(off))
        graph export $out/`opioidmap'`yr'$expt, replace
    }*/
    drop pop popwt
    reshape wide percap, i(cz) j(year)
    generate opioid_diff0011 = opioid_rate2011-opioid_rate2000
    maptile opioid_diff0011, geo(cz2000) nquantiles(10) propcolor
    graph save $out/`opioidmapdiff', replace
    graph save $out/`opioidmapdiff'$expt, replace
}


* Histogram in 2006
********************************
if `switch_opioid_hist' {
    use $arcos/`opioid_rate', clear
    keep if year==2000 | (year >= 2005 & year <= 2011)
    histogram percap, width(0.025) xtitle("Grams per Capita")
    graph save $out/`rawhist', replace
    graph export $out/`rawhist'$expt, replace
    
    keep if year==2006
    histogram percap, width(0.025) xtitle("Grams per Capita")
    graph save $out/`rawhist06', replace
    graph export $out/`rawhist06'$expt, replace
}

********************************
* Labor Force Outcomes         *
********************************

* Output filenames
********************************
local summtable lfp_summary_table.tex
local us_lfp_graph lfp_us_graph
local pctile_graph lfp_cz_graph
local czmap lfp_cz_map
local rawhist lfp_histogram
local rawhist06 lfp_histogram_2006

* Summary tables
********************************
if `switch_lfp_table' {
    use $acs/`panel_yearcz', clear
    drop popwt
    merge m:1 cz using $pop/`cz_elderly', nogenerate assert(match)
    drop elderly_share
    rename popwt popwt03
    drop lfp_ unemp_ lgrlinc_ ihsrlinc_ noincome_ poverty_
    summ lfp_* [w=popwt03]
    summ unemp_* [w=popwt03]
    summ lgrlinc_* [w=popwt03]
    summ ihsrlinc_* [w=popwt03]
    summ noincome_* [w=popwt03]
    summ poverty_* [w=popwt03]
    local lfpvars lfp_1664 lfp_1654 lfp_2564 lfp_2554 lfp_2554m lfp_2554f lfp_1624 lfp_2534 lfp_3544 lfp_4554 lfp_5564
    local unempvars unemp_1664 unemp_1654 unemp_2564 unemp_2554 unemp_2554m unemp_2554f unemp_1624 unemp_2534 unemp_3544 unemp_4554 unemp_5564
    local lgrlincvars lgrlinc_1664 lgrlinc_1654 lgrlinc_2564 lgrlinc_2554 lgrlinc_2554m lgrlinc_2554f lgrlinc_1624 lgrlinc_2534 lgrlinc_3544 lgrlinc_4554 lgrlinc_5564
    local noincomevars noincome_1664 noincome_1654 noincome_2564 noincome_2554 noincome_2554m noincome_2554f noincome_1624 noincome_2534 noincome_3544 noincome_4554 noincome_5564
    estpost summ `lfpvars' `unempvars' `lgrlincvars' `noincomevars' [w=popwt03]
    esttab using $out/`summtable', replace cell((mean(fmt(%9.3g)) sd(fmt(%9.3g)) min(fmt(%9.3g)) max(fmt(%9.3g)))) nomtitles nonumber
    eststo clear
}

* Graphs of LabForcePart
********************************
if `switch_lfp_graph' {
    use $acs/`panel_yearcz', clear
    drop popwt
    merge m:1 cz using $pop/`cz_elderly', nogenerate assert(match)
    drop elderly_share
    rename popwt popwt03
    collapse (mean) lfp_2554 [w=popwt03], by(year)
    tsset year, yearly
    line lfp_2554 year
    graph save $out/`us_lfp_graph', replace
    graph export $out/`us_lfp_graph'$expt, replace

    use $acs/`panel_yearcz', clear
    drop popwt
    merge m:1 cz using $pop/`cz_elderly', nogenerate assert(match)
    drop elderly_share
    rename popwt popwt03
    collapse (p10) p10=lfp_2554 (p25) p25=lfp_2554 (p50) p50=lfp_2554 (p75) p75=lfp_2554 (p90) p90=lfp_2554 [w=popwt03], by(year)
    line p10 year || line p25 year || line p50 year || line p75 year || line p90 year
    graph save $out/`pctile_graph', replace
    graph export $out/`pctile_graph'$expt, replace
}

* Geogrpahic distribution of LFP
********************************
if `switch_lfp_map' {
    use $acs/`panel_yearcz', clear
    keep year cz lfp_2554
    rename lfp_2554 lfp
    reshape wide lfp, i(cz) j(year)
    generate lfpdiff = lfp2011-lfp2000
    maptile lfpdiff, geo(cz2000) nquantiles(10) propcolor revcolor
    graph save $out/`czmap', replace
    graph export $out/`czmap'$expt, replace
}

* Histogram of LFP
********************************
if `switch_lfp_hist' {
    use $acs/`panel_yearcz', clear
    histogram lfp_2554, width(0.01) xtitle("Labor Force Participation")
    graph save $out/`rawhist', replace
    graph export $out/`rawhist'$expt, replace
    keep if year==2006
    histogram lfp_2554, width(0.01) xtitle("Labor Force Participation")
    graph save $out/`rawhist06', replace
    graph export $out/`rawhist06'$expt, replace
}

log close

