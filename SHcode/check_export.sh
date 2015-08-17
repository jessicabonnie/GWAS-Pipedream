#!/bin/bash
#!/usr/bin/bash

### This script runs basic sample and SNP QC on PLINK files.
### It produces tables containing samples for follow up with the genotyping lab.


##############################################################################
# Usage: sh  check_export.sh {data_export} {tracking_sheet}
##############################################################################

####################################################################3
#Arguments
#
# data_export : the path to the full data table exported from Genome Studio.
# tracking_sheet : path to the sample tracking sheet that matches the export -- 
#	8 informational rows, with a table starting on row 11 with the following columns: Sample_ID,SentrixBarcode_A,SentrixPosition_A
# format : a column type contained within the export e.g. "Top Allele", "Gtype", etc
#
#
#####################################################################


# Definining/Reading user specified script parameters/variables/values

DATAFILE=$1
tracking=$2
format=$3


echo -e "#########################################################################"
echo -e
echo -e "# GWAS-Pipedream - Standard GWAS QC Pipeline Package"
echo -e "# (c) 2014-2015 JBonnie, WMChen"
echo -e
echo -e "#########################################################################"


echo -e "########################################################################################################################################"
echo -e
echo -e "# Title: CHECK EXPORT - Standard GWAS QC Pipeline"
echo -e "#"
 echo -e "#"
echo -e "# Disc: Check integrity of the full data export and the sample tracking sheet."
echo -e "#"
echo -e "#"
echo -e "# Usage: sh  ~/SHcode/check_export.sh {data_export} {tracking_sheet} {format}"
echo -e "#"
echo -e "# See Script for option/parameter details"
echo -e "#"
echo -e "# by:  jbonnie"
echo -e "# date: 07.28.15"
echo -e
echo -e "Genome Studio Export: ${DATAFILE}"
echo -e "Sample Tracking Sheet: ${tracking}"
echo -e "Column Type within the export: ${format}"
echo -e "Performed on:"
date
echo -e
echo -e "########################################################################################################################################"



wkdir=$(pwd)


tracking_header=$(head -n12 ${tracking}| sed 's/\r//g' | awk 'BEGIN {FS = "\t"}; $0 ~/^Sample_ID/ {print NR}')


echo -e
echo -e "\n------------------"
echo "Comparing Field Counts within the Export"
echo -e "------------------\n"
echo -e


row2=$(head -n2 $DATAFILE |tail -n1 | awk 'BEGIN { FS = "\t" } ; {print NF}')
lastrow=$(tail -n1 $DATAFILE | awk 'BEGIN { FS = "\t" } ; {print NF}')

if [ $row2 -ne $lastrow ]; then
  echo -e
  echo -e "ERROR: DATA EXPORT IS INCOMPLETE! CONTACT THE CORE!"
  echo -e
  
fi



echo -e
echo -e "\n------------------"
echo "Checking export for duplicate IDs"
echo -e "------------------\n"
echo -e


head -n1 $DATAFILE | sed "s/\t/\n/g; s/\r//g" | grep "${format}" | sed "s/\.$format//g" > $wkdir/export_iids.tmp
excount=$(cat $wkdir/export_iids.tmp | wc -l)
uniqex=$(sort $wkdir/export_iids.tmp | uniq | wc -l )

if [ $excount -ne $uniqex ]; then

  sort $wkdir/export_iids.tmp | uniq -d >  $wkdir/duplicate_export_iids.txt
  echo -e
  echo -e "ERROR: DATA EXPORT CONTAINS DUPLICATE IDS!"
  echo -e "List of duplicate IDs written here: "$wkdir/duplicate_export_iids.txt
  echo -e
  
fi

echo -e
echo -e "\n------------------"
echo "Checking tracking sheet for duplicate barcode/position pairs"
echo -e "------------------\n"
echo -e

awk -v header=$tracking_header 'BEGIN { FS = "," }; NR>header{print $2"_"$3}' ${tracking}  | sed 's/\r//g' | sed 's/^[[:space:]]*//' > $wkdir/tracking_pairs.tmp

trackpairs=$(cat $wkdir/tracking_pairs.tmp | wc -l)
uniqpairs=$(sort $wkdir/tracking_pairs.tmp | uniq | wc -l )


if [ $trackpairs -ne $uniqpairs ]; then

  sort $wkdir/tracking_pairs.tmp | uniq -u | sed 's/_/\t/g' >  $wkdir/duplicate_barcode_positions.txt
  echo -e
  echo -e "ERROR: TRACKING SHEET CONTAINS DUPLICATE BARCODE/POSITION PAIRS!"
  echo -e "List of $( cat $wkdir/duplicate_barcode_positions.txt | wc -l ) duplicate Barcode/Position Pairs here: "$wkdir/duplicate_barcode_positions.txt
  echo -e
  
fi


echo -e
echo -e "\n------------------"
echo "Checking Tracking Sheet for Duplicate IDs"
echo -e "------------------\n"
echo -e

awk -v header=$tracking_header 'BEGIN { FS = "," }; NR>header{print $1}' ${tracking} | sed 's/\r//g'  | sed 's/^[[:space:]]*//' > $wkdir/tracking_iids.tmp

trackcount=$(cat $wkdir/tracking_iids.tmp | wc -l)
trackuniq=$(sort $wkdir/tracking_iids.tmp | uniq | wc -l )

if [ $trackcount -ne $trackuniq ]; then

  sort $wkdir/tracking_iids.tmp| uniq -u >  $wkdir/duplicate_tracking_iids.txt
  echo -e
  echo -e "ERROR: TRACKING SHEET CONTAINS DUPLICATE IDS!"
  echo -e "List of $( cat $wkdir/duplicate_tracking_iids.txt | wc -l ) duplicate IDs written here: "$wkdir/duplicate_tracking_iids.txt
  echo -e
  
fi



echo -e
echo -e "\n------------------"
echo "Checking IDs between Tracking Sheet and Export"
echo -e "------------------\n"
echo -e



if [ $uniqex -ne $trackuniq ]; then

  echo -e
  echo -e "ERROR: DIFFERENT NUMBER OF UNIQUE IDS IN TRACKING SHEET AND EXPORT!"
  echo -e
  
fi

join <(cat $wkdir/tracking_iids.tmp | sort | uniq) <(cat $wkdir/export_iids.tmp | sort | uniq) > $wkdir/join.tmp
idjoin=$(join <(cat $wkdir/tracking_iids.tmp | sort | uniq) <(cat $wkdir/export_iids.tmp | sort | uniq) | wc -l)

if [ $idjoin -ne $trackuniq ]; then
  
  sort <( sort $wkdir/join.tmp | uniq) <( sort $wkdir/tracking_iids.tmp | uniq) | uniq -u  > $wkdir/trackingIDs_notinExport.txt
  echo -e "List of $(cat $wkdir/trackingIDs_notinExport.txt | wc -l) IIDs found in tracking sheet but not found in export: "$wkdir/trackingIDs_notinExport.txt
  echo -e
  
fi


if [ $idjoin -ne $uniqex ]; then
  
  sort <( sort $wkdir/join.tmp | uniq) <( sort $wkdir/export_iids.tmp | uniq) | uniq -u > $wkdir/exportIDs_notinTracking.txt
  echo -e "List of $(cat $wkdir/exportIDs_notinTracking.txt | wc -l) IIDs found in export but not found in tracking sheet: "$wkdir/exportIDs_notinTracking.txt
  echo -e
  
fi


