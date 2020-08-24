#!/bin/bash

years=($(seq 2000 2005))
pages=(158 656 399 382 654 406)
for i in `seq 0 5`
do
    echo ${years[i]}
    pdftotext -f 2 -l ${pages[i]} -layout rawpdf/report_yr_${years[i]}.pdf txt/zipcode_${years[i]}.txt
done

for year in `seq 2006 2015`
do
    echo $year  
    pdftotext -f 2 -layout rawpdf/${year}_rpt1.pdf txt/zipcode_$year.txt
done

echo 2016
pdftotext -l 460 -layout rawpdf/rpt_2016.pdf txt/zipcode_2016.txt
