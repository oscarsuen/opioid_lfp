# Addicted to Dropping Out: Opiods and Labor Force Participation
Using the differential impact of the introduction of Medicare Part D as an instrument for opioid supply, we measure the causal impact of the opioid epidemic on labor force participation and other labor market outcomes.  We find that an increase of 1 standard deviation in the long-difference of opioids per capita in a commuting zone leads to a 1.4 percentage point decrease in the labor force participation rate.  There is no significant effect on incomes for the employed, but there is an increase in the percentage of people earning zero income.  Moreover, effects are stronger for men than for women, and are concentrated among those aged 25--44.  Finally, an event study suggests that effects take time to materialize.

## Data Sources
- `usa_00011.dta.gz`
    - Source: [IPUMS](https://usa.ipums.org/usa/)
    - Used for ACS labor market variables
- `census_api_key.txt`
    - Place this in the `code` folder for `qwi_scrape.py`
    - Request a key from [this link](https://api.census.gov/data/key_signup.html).

Other sources can be found in the Makefile.

## Dependencies
- Python 3
    - `requests`
- `pdf2text`
- Stata
    - `estout`
    - `ftools`
    - `reghdfe`
    - `ivreghdfe`
    - `estwrite`
    - `ivreg2`
    - `ranktest`

## TODO
- [x] Github fixes
    - [x] LFS track `data/acs/raw/usa_00011.gz`
- [ ] Code fixes
    - [x] Rework entire filestructure
    - [x] Maybe use a `Makefile`
    - [x] Find sources for files
    - [ ] Automate everything, epsecially `LaTeX` problems in tables
    - [x] Quarterly opioids
    - [ ] Check if opioid panel constructed correctly from pdfs
    - [ ] `epop_*_*` not constructed correctly
    - [ ] Look at how QWI earnings are weighted (numbers don't line up)
    - [ ] Population back to 1990
    - [x] Check ZIP to County crosswalk
    - [ ] Replicate ACS
    - [ ] Check omitted `divyr` categories
    - [ ] Coefficient on `2007q4`
- [ ] Paper fixes
    - [ ] High exposure vs low exposure
    - [ ] DWH endogeneity test?
    - [ ] Cleveland Fed paper
    - [ ] Add policy implications (male/female resilience)
    - [ ] Maybe cite Notowidigdo
    - [ ] Two-way clustering
    - [ ] Tense (causes vs caused)
    - [ ] Reframe numbers (1SD -> 90--10 diff?)
    - [ ] Time frame of long difference consistency (2000/2005--2011)
    - [ ] Exclude AK, HI?
    - [ ] What to do about small CZs (multiple CZs in PUMA) (look at Finkelstein)
    - [ ] idea that this is a labor supply problem?
    - [ ] Disability insurance
    - [ ] Rework Summary table
    - [ ] Treat alternative "prime-aged" definitions as robustness tests
    - [ ] Deaths?
    - [ ] County analysis
    - [ ] Levenworth and military bases
