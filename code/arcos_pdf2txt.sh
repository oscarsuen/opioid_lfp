#!/bin/bash

IN=data/raw/arcos_pdf
OUT=data/raw/_arcos_txt

years=($(seq 2000 2005))
pages=(158 656 399 382 654 406)
for i in ${!years[@]}
do
    echo ${years[i]}
    pdftotext -f 2 -l ${pages[i]} -layout ${IN}/report_yr_${years[i]}.pdf ${OUT}/zipcode_${years[i]}.txt
done

for year in `seq 2006 2015`
do
    echo $year  
    pdftotext -f 2 -layout ${IN}/${year}_rpt1.pdf ${OUT}/zipcode_$year.txt
done

years=($(seq 2016 2019))
pages=(460 791 387 386)
starts=(1 1 2 2)
for i in ${!years[@]}
do
    echo ${years[i]}
    pdftotext -f ${starts[i]} -l ${pages[i]} -layout ${IN}/report_yr_${years[i]}.pdf ${OUT}/zipcode_${years[i]}.txt
done
