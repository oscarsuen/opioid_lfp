STATA = stata-se -b do
STATA_RUN = $(STATA) $< && rm $(subst .do,.log,$(notdir $<))

%.dta:
	$(STATA_RUN)

DTA = data/dta
RAW = data/raw
CODE = code
OUT = out
FIGS = out/figs
TABS = out/tabs

.PHONY: cleanlogs
cleanlogs:
	rm -f log/*

.PHONY: cleandtas
cleandtas:
	rm -f $(DTA)/*

CPI_DTAS = $(DTA)/cpi_quarter.dta $(DTA)/cpi_year.dta
$(CPI_DTAS): $(CODE)/aux_cpi.do $(RAW)/CPILFESL.csv

$(RAW)/CPILFESL.csv:
	curl -X GET -G https://fred.stlouisfed.org/graph/fredgraph.csv -d id=CPILFESL -d cosd=1990-01-01 -d coed=2019-12-31 -d fq=Quarterly -d fam=avg -o $@

$(DTA)/acs_yearcz.dta: $(CODE)/acs_clean.do $(RAW)/usa_00011.dta $(DTA)/cpi_year.dta $(DTA)/puma2cz_crosswalk.dta

$(RAW)/usa_00011.dta: $(RAW)/usa_00011.dta.gz
	gunzip -c $< > $@

$(DTA)/pop_yearcty.dta: $(CODE)/aux_ctypop.do $(RAW)/co-est00int-agesex-5yr.csv $(RAW)/cc-est2019-alldata.csv

$(RAW)/co-est00int-agesex-5yr.csv:
	curl https://www2.census.gov/programs-surveys/popest/datasets/2000-2010/intercensal/county/co-est00int-agesex-5yr.csv -o $@

$(RAW)/cc-est2019-alldata.csv:
	curl https://www2.census.gov/programs-surveys/popest/datasets/2010-2019/counties/asrh/cc-est2019-alldata.csv -o $@

CROSSWALK_OUT = zip2cty puma2cty cty2cz puma2cz zip2cz state2reg cz2state
CROSSWALKS = $(CROSSWALK_OUT:%=$(DTA)/%_crosswalk.dta)
CROSSWALK_IN = zipcty.csv ctycz.xls pumacty.csv statereg.xls 
$(CROSSWALKS): $(CODE)/aux_crosswalks.do $(addprefix $(RAW)/,$(CROSSWALK_IN)) $(DTA)/pop_yearcty.dta

CZPOPS = $(DTA)/pop_yearcz.dta $(DTA)/wt_yearcz.dta $(DTA)/cz_elderly.dta
$(CZPOPS): $(CODE)/aux_czpop.do $(DTA)/pop_yearcty.dta $(DTA)/cty2cz_crosswalk.dta

WF_IN = qwi_qtrcz opioid_qtrcz cz_elderly cz2state_crosswalk state2reg_crosswalk
WORKFILE_IN = $(WF_IN:%=$(DTA)/%.dta)
WORKFILE_OUT = $(DTA)/workfile_quarter.dta $(DTA)/workfile_year.dta
$(WORKFILE_OUT): $(CODE)/analysis_workfile.do $(WORKFILE_IN)

$(OUT)/estimates.sters: $(CODE)/analysis_regressions.do $(WORKFILE_OUT)
	$(STATA_RUN)

$(FIGS)/event_%.pdf: $(CODE)/analysis_event.do $(WORKFILE_OUT)
	$(STATA_RUN)

$(TABS)/main_%.tex: $(CODE)/analysis_tables.do $(OUT)/estimates.sters
	$(STATA_RUN)

$(FIGS)/binscatter.pdf: $(CODE)/analysis_binscatter.do $(DTA)/workfile.dta
	$(STATA_RUN)

$(DTA)/opioid_yearcz.dta $(DTA)/opioid_qtrcz.dta: $(CODE)/arcos_clean.do $(RAW)/prescriptions.csv $(DTA)/zip2cz_crosswalk.dta $(DTA)/pop_yearcz.dta

PRESCRIPTION_YRS = $(shell seq 2000 2016)
$(RAW)/prescriptions.csv: $(CODE)/arcos_combine.R $(PRESCRIPTION_YRS:%=$(RAW)/_arcos_csv/prescriptions_%.csv)
	Rscript $<

$(PRESCRIPTION_YRS:%=$(RAW)/_arcos_csv/prescriptions_%.csv): $(CODE)/arcos_txt2csv.py $(PRESCRIPTION_YRS:%=$(RAW)/_arcos_txt/zipcode_%.txt)
	python3 $<

ARCOS_REPORT_YRS1 = $(shell seq 2000 2005)
ARCOS_REPORT_PDFS1 = $(ARCOS_REPORT_YRS1:%=$(RAW)/arcos_pdf/report_yr_%.pdf)
ARCOS_REPORT_YRS2 = $(shell seq 2006 2010) $(shell seq 2012 2015)
ARCOS_REPORT_PDFS2 = $(ARCOS_REPORT_YRS2:%=$(RAW)/arcos_pdf/%_rpt1.pdf)
ARCOS_REPORT_YRS3 = $(shell seq 2016 2019)
ARCOS_REPORT_PDFS3 = $(ARCOS_REPORT_YRS3:%=$(RAW)/arcos_pdf/report_yr_%.pdf)
ARCOS_REPORT_PDFS = $(ARCOS_REPORT_PDFS1) $(ARCOS_REPORT_PDFS2) $(RAW)/arcos_pdf/2011_rpt1.pdf $(ARCOS_REPORT_PDFS3)

$(PRESCRIPTION_YRS:%=$(RAW)/_arcos_txt/zipcode_%.txt): $(CODE)/arcos_pdf2txt.sh $(ARCOS_REPORT_PDFS)
	sh $<

$(ARCOS_REPORT_PDFS1):
	curl https://www.deadiversion.usdoj.gov/arcos/retail_drug_summary/archive/$(notdir $@) -o $@

$(RAW)/arcos_pdf/2011_rpt1.pdf:
	curl https://www.deadiversion.usdoj.gov/arcos/retail_drug_summary/2011/2011-rpt1.pdf -o $@

$(ARCOS_REPORT_PDFS2):
	curl https://www.deadiversion.usdoj.gov/arcos/retail_drug_summary/$(subst _rpt1.pdf,,$(notdir $@))/$(notdir $@) -o $@

$(ARCOS_REPORT_PDFS3):
	curl https://www.deadiversion.usdoj.gov/arcos/retail_drug_summary/$(notdir $@) -o $@

STATES = $(shell cat $(RAW)/statefips.txt)
QWI_JSONS = $(STATES:%=$(RAW)/qwi_json/%.json)
$(QWI_JSONS): $(CODE)/qwi_scrape.py $(RAW)/statefips.txt
	python3 $<

$(RAW)/qwi.csv: $(CODE)/qwi_convert.py $(QWI_JSONS) $(RAW)/statefips.txt
	python3 $<

$(DTA)/qwi_yearcz.dta $(DTA)/qwi_qtrcz.dta: $(CODE)/qwi_clean.do $(RAW)/qwi.csv $(DTA)/cpi_quarter.dta $(DTA)/cty2cz_crosswalk.dta $(DTA)/pop_yearcz.dta
