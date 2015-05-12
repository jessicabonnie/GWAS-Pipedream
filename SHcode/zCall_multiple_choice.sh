#!/bin/bash
#!/usr/bin/bash
##############################################################################
#
# Title: Script commands to run zCall on HumanCoreExomeChip Samples
#
# Desc:  Script to Combine Genotyping Results (Exported from GenomeStudio (GenTrain2)) after initial
#       preliminary QC with rare SNPs called using ZCall
# Note:  In its current form this script creates results for each permutation of three different decisions.
#        A text file describing the contents of the results folders and a flowchart illustrating the decision tree are included in this folder.
#        zCall for HumanCoreExomeChip samples genotyped at University of Virginia
#
# Note: See "Using zCall on raw Genotype Files " SOP in zCall folder
#
# Date: Feb, 2015
# By:   jbonnie

##############################################################################

zcall_fulldata=$1
chip_version=$2
sampletoberemoved=$3
rawplink=$4

echo -e
echo "Here are the arguments passed to the script: "
echo "____________________________________________"
echo -e
echo "Raw GS Report Location: " $zcall_fulldata
echo "HumanCoreExome Chip Version: " $chip_version
echo "List of Samples to be removed because of prior analysis: " $sampletoberemoved
echo "Raw Plink Files used in prior analysis: " $rawplink



#zCall scripts are here:
zcall=/h4/t1/users/jkb4y/bin/zCall/Version3_GenomeStudio
echo "Here is where program will look for zCall suite: " $zCall


#I assume that we are in the top level directory already
workdir=$(pwd)
commondaughter=${workdir}/commonThresholds
basicdaughter=${workdir}/basicThresholds

echo -e
echo "Top Level Directory is : ${workdir}"
echo -e



# Find the Name of the Report File

reportname=$(basename "$zcall_fulldata")
extension="${reportname##*.}"
reportname="${reportname%.*}"

report_qced=${workdir}/${reportname}_QCed.txt


echo -e
echo -e "\n------------------"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo -e
echo "I. Create Files Needed In Every Branch of the Tree"
echo -e
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo -e "------------------\n"
echo -e


echo -e
echo -e "\n------------------"
echo "Step I.1. QC Raw Report for Feeding Into Zcall"
echo -e "------------------\n"
echo -e

	echo -e
	echo -e "\n------------------"
	echo "Step I.1.A. Removing List of Known Bad Samples from Report"
	echo -e "------------------\n"
	echo -e
        # Step 1a. Removing List of Samples from Report

	#Edit the sample list to be used in during zcall
	sampletoberemovedZ=${workdir}/sampletoberemovedZ.txt
	awk '{print $2}' ${sampletoberemoved} > ${sampletoberemovedZ}
	
	#Here is where we will write the output when we remove the samples
	echo ${workdir}/${reportname}_QCed1a.txt
	
	#Use zcall's additional scripts version of dropSamplesFromReport (THE OTHER ONE DOESN'T WORK) to remove the given samples
        python  ${zcall}/../additionalScripts/dropSamplesFromReport_FasterVersion.py ${zcall_fulldata} ${sampletoberemovedZ} > ${workdir}/${reportname}_QCed1a.txt

	#DID NOT REALIZE HOW GINORMOUS A FILE THAT IS TO KEEP AROUND ... perhaps zip it up or remove it after usage?

	echo -e
	echo -e "\n------------------"
	echo "Step I.1.B. Applying Subject Call Rate Threshold Filter (98%)"
	echo -e "------------------\n"
	echo -e
        # Step 1b. Applying Subject Call Rate Threshold Filter (98%)

        python  ${zcall}/qcReport.py \
                -R  ${workdir}/${reportname}_QCed1a.txt -C 0.98 > ${report_qced}


	echo -e
	echo -e "\n------------------"
	echo "Step I.1.C. Counting number of subjects - Original and after filtering"
	echo -e "------------------\n"
	echo -e
        # 1c. Counting number of subjects - Original and after filtering
        # Original File (divide number by 3 for subject count)
        		echo "Subject Counts:"
                echo "     Original Report: "$(head -1 ${zcall_fulldata} | tr '\t ' '\n' | awk 'NR > 3' | wc)

		# File with subjects removed from list (divide number by 3 for subject count)
                echo "     Minus Predetermined Bad Samples: " $(head -1 ${workdir}/${reportname}_QCed1a.txt | tr '\t ' '\n' | awk 'NR > 3' | wc)

        # Subject Call rate filtered File (divide number by 3 for subject count)
                echo "     After Subject Callrate Filter (98%):" $(head -1 ${report_qced} | tr '\t ' '\n' | awk 'NR > 3' | wc)
                
	echo -e
	echo -e "\n------------------"
	echo "Step I.1.D. Zip Up Intermediate QC report"
	echo -e "------------------\n"
	echo -e
		gzip -1qf ${workdir}/${reportname}_QCed1a.txt
	
	

echo -e
echo -e "\n------------------"
echo "Step I.2. Calculate Mean & Standard Deviations for each Homozygote Cluster"
echo -e "------------------\n"
echo -e
		meanfile=${workdir}/${reportname}_MEAN.SD.txt
		python  ${zcall}/findMeanSD.py -R ${report_qced} > ${meanfile}
		echo "Line Count of ${meanfile}: " $(wc -l ${meanfile})

echo -e
echo -e "\n------------------"
echo "I.3.: Create Common (1) and Rare (3) SNP Lists using raw plink files (those used by Wei-Min in Initial QC)"
echo -e "------------------\n"
echo -e

	echo -e
    echo -e "\n------------------"
    echo "Step I.3.A: Calculate Minor Allele Frequency in raw samples"
    echo -e "------------------\n"
    echo -e
    	plink --bfile ${rawplink} --noweb --freq --out raw_genotype_v${chip_version}_maf

	echo -e
	echo -e "\n------------------"
    echo "Step I.3.B: Calculate Missingness in raw samples"
    echo -e "------------------\n"
    echo -e      
    	plink --bfile ${rawplink} --noweb --missing --out raw_genotype_v${chip_version}_missing

	echo -e
    echo -e "\n------------------"
	echo "Step I.3.C: Merge MAF and SNP Missingness files"
	echo -e "------------------\n"
	echo -e

		# Prep Missingness file for merging
		awk '{print $2, $5}' raw_genotype_v${chip_version}_maf.frq > raw_genotype_v${chip_version}_mafX.frq 

		# Prep Missingness file for merging
		awk '{print $2, $5}' raw_genotype_v${chip_version}_missing.lmiss > raw_genotype_v${chip_version}_missingX.lmiss 

		# Merging files - custom PERL script to merge samples by variable name
		perl /h4/t1/users/jkb4y/programs/zCall/merge_tables.pl \
		raw_genotype_v${chip_version}_mafX.frq \
		raw_genotype_v${chip_version}_missingX.lmiss \
		SNP > raw_genotype_v${chip_version}_snpdetails.txt
                
	echo -e
	echo -e "\n------------------"
	echo "Step I.3.D.: Create List of Common SNPs (MAF>1%) with call rate greater than 98%"
	echo -e "\n------------------"
	echo -e
        awk '$3 > 0.01 && $2 <=0.02' raw_genotype_v${chip_version}_snpdetails.txt > common98.txt
        wc -l common98.txt

	echo -e
	echo -e "\n------------------"
	echo "I.3.E: Create Three Lists of Rare (MAF>1%) SNPs with Callrates of 97%, 98%, 99%"
	echo -e "------------------\n"
	echo -e
        awk '$3 <= 0.01 && $2 <= 0.03' raw_genotype_v${chip_version}_snpdetails.txt > rare97.txt
        awk '$3 <= 0.01 && $2 <= 0.02' raw_genotype_v${chip_version}_snpdetails.txt > rare98.txt
        awk '$3 <= 0.01 && $2 <= 0.01' raw_genotype_v${chip_version}_snpdetails.txt > rare99.txt
        
        wc -l rare97.txt
        wc -l rare98.txt
        wc -l rare99.txt


echo -e
echo -e "\n------------------"
echo "I.4.: Create Allele and Flipping Update Files from Manifest"
echo -e "------------------\n"
echo -e


	echo -e
	echo -e "\n------------------"
	echo "Step I.4.A. Identify correct manifest files based on chip version"
	echo -e "------------------\n"
	echo -e

		manifest_loc=XXXXXXXXXXXX
		snp_table=XXXXXXXXXXXX
		if [ "${chip_version}" = "1" ]; then 
			manifest_loc=/t121/xxxxxx/projects/XXXXX/ExomeChip_v1_XXXX_Upload/HumanCoreExome-12-v1-0-D.csv
			snp_table=XXXXXXXXXXXXXXX

		elif [ "${chip_version}" = "1.1" ]; then 
		manifest_loc=/t121/xxxxxx/projects/XXXXXX/ExomeChip_v1.1_XXXX_Upload/HumanCoreExome-12-v1-1-C.csv
		snp_table=/t121/xxxxxx/projects/XXXXXX/ExomeChip_v1.1_XXXX_Upload/12082014-XXXXCoreExome1.1_SNP_Table.txt
		fi
		echo "Manifest Loc set to ${manifest_loc}"

	echo -e
	echo -e "\n------------------"
	echo "Step I.4.B. Update Illumina Alleles (A/B) to ATCG"
	echo -e "------------------\n"
	echo -e
		illumina_allele_update=${workdir}/v${chip_version}_illumina_allele_update.txt
		cat ${manifest_loc} | awk -F"," 'NR > 8 {print $2, $4}' | sed -e 's/\[//g' -e 's/\]//g' -e 's/\//\t/g' | awk '{print $1, "\t", "A", "\t", "B", "\t", $2, "\t", $3}' > ${illumina_allele_update}

	echo -e
	echo -e "\n------------------"
	echo "Step I.4.C. Update Illumina Alleles (A/B) to ATCG"
	echo -e "------------------\n"
	echo -e
		illumina_topflip_update=${workdir}/v${chip_version}_illumina_topflip_update.txt
		
		# Set 1: Positive on BOT (hence Negative on Top)
        cat ${manifest_loc} | awk -F"," 'NR>8; /+/ && $3 =="BOT" {print $2, $3, $21}' > fliplist1.tmp
        # Set 2: Negative on Top 
        cat ${manifest_loc} | awk -F"," 'NR>8{print $2, $3, $21}' | grep -v "+" | awk '/TOP/' > fliplist2.tmp
        # Final List of SNPs to Flip (combine separate files)
        cat fliplist1.tmp fliplist2.tmp >  ${illumina_topflip_update}


echo -e
echo -e "\n------------------"
echo "Step I.5.  EXTRACT COMMON SNPs from Raw PLINK Files"
echo -e "------------------\n"
echo -e
		plink --noweb --extract common98.txt --bfile ${rawplink} --make-bed --out raw_extractcommon --allow-no-sex
		

echo -e
echo -e "\n------------------"
echo "Step I.6.  EXCLUDE RARE SNPs from Raw PLINK Files - All 3 Lists"
echo -e "------------------\n"
echo -e
		plink --noweb --exclude rare97.txt --bfile ${rawplink} --make-bed --out raw_excluderare97 --allow-no-sex
		plink --noweb --exclude rare98.txt --bfile ${rawplink} --make-bed --out raw_excluderare98 --allow-no-sex	
		plink --noweb --exclude rare99.txt --bfile ${rawplink} --make-bed --out raw_excluderare99 --allow-no-sex


echo -e
echo -e "\n------------------"
echo "I.7.: Create Update Files from Raw PLINK File"
echo -e "------------------\n"
echo -e
		awk '{print $2,$2,$1,$2}' ${rawplink}.fam > updateids.txt
		awk '{print $1,$2,$5}' ${rawplink}.fam > updatesex.txt
		awk '{print $1,$2,$3,$4}' ${rawplink}.fam > updateparents.txt
		


echo -e
echo -e "\n------------------"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo -e
echo "II. Use Thresholds That are Calculated Using Only COMMON SNPs"
echo -e
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo -e "------------------\n"
echo -e


commondaughter=${workdir}/commonThresholds
mkdir ${commondaughter}
cd ${commondaughter}


	echo -e
	echo -e "\n------------------"
	echo "Step II.1. Subset ${meanfile} (CREATED IN I.2) with COMMON SNP list (Created in I.3.D)"
	echo -e "------------------\n"
	echo -e
		
		submeanfile=${commondaughter}/${reportname}_MEAN.SD_common98.txt
		perl /h4/t1/users/jkb4y/programs/zCall/fgrep.pl \
        ${workdir}/common98.txt ${meanfile} 1 \
        >  ${submeanfile}.tmp
        
        head -n1 ${meanfile} >  ${submeanfile}
        cat  ${submeanfile}.tmp >>  ${submeanfile}
        
        echo "New mean file: ${submeanfile}"
        wc -l ${submeanfile}


	echo -e
	echo -e "\n------------------"
	echo "Step II.2. Recalculate BETAs using ${submeanfile} file"
	echo -e "------------------\n"
	echo -e
		Rscript ${zcall}/findBetas.r ${submeanfile}  ${commondaughter}/BETAS.txt 1


	echo -e
	echo -e "\n------------------"
	echo "Step II.3. Find the thresholds used for calling No Calls"
	echo -e "------------------\n"
	echo -e

	python ${zcall}/findThresholds.py -R ${report_qced} -B ${commondaughter}/BETAS.txt -Z 7 -I 0.2 > ${commondaughter}/thresholds.7X


	echo -e
	echo -e "\n------------------"
	echo "Step II.4. Recall all NoCalls using these Thresholds"
	echo -e "------------------\n"
	echo -e

        python ${zcall}/zCall.py \
        -R ${zcall_fulldata} \
        -T ${commondaughter}/thresholds.7X \
        -O ${commondaughter}/zcall_preupdate

	echo -e
	echo -e "\n------------------"
	echo "Step II.5. Convert zCalled file to PLINK Bim/Bed Format and Update Sex"
	echo -e "------------------\n"
	echo -e

        plink --noweb --tfile ${commondaughter}/zcall_preupdate  --make-bed --out  ${commondaughter}/zcall_preupdate_nopheno
        plink --noweb --bfile ${commondaughter}/zcall_preupdate_nopheno --update-ids ${workdir}/updateids.txt --make-bed --out ${commondaughter}/zcall_preupdateA --allow-no-sex
        plink --noweb --bfile ${commondaughter}/zcall_preupdateA --update-sex ${workdir}/updatesex.txt --make-bed --out  ${commondaughter}/zcall_preupdateB --allow-no-sex
        plink --noweb --bfile ${commondaughter}/zcall_preupdateB --update-parents ${workdir}/updateparents.txt --make-bed --out  ${commondaughter}/zcall_preupdate --allow-no-sex
        
	echo -e
	echo -e "\n------------------"
	echo "Step II.6. Update Alleles and Flipping"
	echo -e "------------------\n"
	echo -e

        plink --noweb --bfile ${commondaughter}/zcall_preupdate  --make-bed --out  ${commondaughter}/zcall_ALLELES --update-alleles ${illumina_allele_update} --allow-no-sex

		plink --bfile ${commondaughter}/zcall_ALLELES --noweb --flip ${illumina_topflip_update} --make-bed --out ${commondaughter}/zcall_TOP --allow-no-sex

	echo -e
	echo -e "\n------------------"
	echo "Step II.7. EXTRACT RARE lists from zCalled PLINK FILES for ALL THREE RARE LISTS"
	echo -e "------------------\n"
	echo -e

		plink --bfile ${commondaughter}/zcall_TOP --noweb --extract ${workdir}/rare97.txt --make-bed --out ${commondaughter}/zcall_rare97 --allow-no-sex
		plink --bfile ${commondaughter}/zcall_TOP --noweb --extract ${workdir}/rare98.txt --make-bed --out ${commondaughter}/zcall_rare98 --allow-no-sex
		plink --bfile ${commondaughter}/zcall_TOP --noweb --extract ${workdir}/rare99.txt --make-bed --out ${commondaughter}/zcall_rare99 --allow-no-sex


	echo -e
	echo -e "\n------------------"
	echo "Step II.8. Create Results from EXTRACTING RARES from zCall and EXTRACTING COMMONS from raw"
	echo -e "------------------\n"
	echo -e
		mkdir ${commondaughter}/raw_extractcommon
		plink --noweb --bfile ${commondaughter}/zcall_rare97 --bmerge ${workdir}/raw_extractcommon.bed ${workdir}/raw_extractcommon.bim ${workdir}/raw_extractcommon.fam --out ${commondaughter}/raw_extractcommon/extractcommon_extractrare_merge97 --make-bed --allow-no-sex
		plink --noweb --bfile ${commondaughter}/zcall_rare98 --bmerge ${workdir}/raw_extractcommon.bed ${workdir}/raw_extractcommon.bim ${workdir}/raw_extractcommon.fam --out ${commondaughter}/raw_extractcommon/extractcommon_extractrare_merge98 --make-bed --allow-no-sex
		plink --noweb --bfile ${commondaughter}/zcall_rare99 --bmerge ${workdir}/raw_extractcommon.bed ${workdir}/raw_extractcommon.bim ${workdir}/raw_extractcommon.fam --out ${commondaughter}/raw_extractcommon/extractcommon_extractrare_merge99 --make-bed --allow-no-sex
						

	echo -e
	echo -e "\n------------------"
	echo "Step II.9. Create Results from EXTRACTING RARES from zCall and EXCLUDING RARES from raw"
	echo -e "------------------\n"
	echo -e
		mkdir ${commondaughter}/raw_excluderare
		plink --noweb --bfile ${commondaughter}/zcall_rare97 --bmerge ${workdir}/raw_excluderare97.bed ${workdir}/raw_excluderare97.bim ${workdir}/raw_excluderare97.fam --out ${commondaughter}/raw_excluderare/excluderare_extractrare_merge97 --make-bed --allow-no-sex
		plink --noweb --bfile ${commondaughter}/zcall_rare98 --bmerge ${workdir}/raw_excluderare98.bed ${workdir}/raw_excluderare98.bim ${workdir}/raw_excluderare98.fam --out ${commondaughter}/raw_excluderare/excluderare_extractrare_merge98 --make-bed --allow-no-sex
		plink --noweb --bfile ${commondaughter}/zcall_rare99 --bmerge ${workdir}/raw_excluderare99.bed ${workdir}/raw_excluderare99.bim ${workdir}/raw_excluderare99.fam --out ${commondaughter}/raw_excluderare/excluderare_extractrare_merge99 --make-bed --allow-no-sex
						
	
	echo -e
	echo -e "\n------------------"
	echo "Step II.10. Run Threshold and Calibration Checking Loop"
	echo -e "------------------\n"
	echo -e
		cd ${commondaughter}
		bash //h4/t1/users/jkb4y/programs/zCall/zCalibrationLoop.sh ${report_qced} ${chip_version} ${commondaughter}/BETAS.txt

	
echo -e
echo -e "\n------------------"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo -e
echo "III. Use Thresholds That are Calculated Using zCall's built in Thresholds for SNPs"
echo -e
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo -e "------------------\n"
echo -e


basicdaughter=${workdir}/basicThresholds
mkdir ${basicdaughter}
cd ${basicdaughter}



	echo -e
	echo -e "\n------------------"
	echo "Step III.1. Recalculate BETAs using ${meanfile} file"
	echo -e "------------------\n"
	echo -e
		Rscript ${zcall}/findBetas.r ${meanfile}  ${basicdaughter}/BETAS.txt 1


	echo -e
	echo -e "\n------------------"
	echo "Step III.2. Find the thresholds used for calling No Calls"
	echo -e "------------------\n"
	echo -e

	python ${zcall}/findThresholds.py -R ${report_qced} -B ${basicdaughter}/BETAS.txt -Z 7 -I 0.2 > ${basicdaughter}/thresholds.7X


	echo -e
	echo -e "\n------------------"
	echo "Step III.3. Recall all NoCalls using these Thresholds"
	echo -e "------------------\n"
	echo -e

        python ${zcall}/zCall.py \
        -R ${zcall_fulldata} \
        -T ${basicdaughter}/thresholds.7X \
        -O ${basicdaughter}/zcall_preupdate

	echo -e
	echo -e "\n------------------"
	echo "Step III.4. Convert zCalled file to PLINK Bim/Bed Format and Update Sex"
	echo -e "------------------\n"
	echo -e

        plink --noweb --tfile ${basicdaughter}/zcall_preupdate  --make-bed --out  ${basicdaughter}/zcall_preupdate_nopheno
        plink --noweb --bfile ${basicdaughter}/zcall_preupdate_nopheno --update-ids ${workdir}/updateids.txt --make-bed --out ${basicdaughter}/zcall_preupdateA --allow-no-sex
        plink --noweb --bfile ${basicdaughter}/zcall_preupdateA --update-sex ${workdir}/updatesex.txt --make-bed --out  ${basicdaughter}/zcall_preupdateB --allow-no-sex
        plink --noweb --bfile ${basicdaughter}/zcall_preupdateB --update-parents ${workdir}/updateparents.txt --make-bed --out  ${basicdaughter}/zcall_preupdate --allow-no-sex
         
	echo -e
	echo -e "\n------------------"
	echo "Step III.5. Update Alleles and Flipping"
	echo -e "------------------\n"
	echo -e

        plink --noweb --bfile ${basicdaughter}/zcall_preupdate  --make-bed --out  ${basicdaughter}/zcall_ALLELES --update-alleles ${illumina_allele_update} --allow-no-sex

		plink --bfile ${basicdaughter}/zcall_ALLELES --noweb --flip ${illumina_topflip_update} --make-bed --out ${basicdaughter}/zcall_TOP --allow-no-sex

	echo -e
	echo -e "\n------------------"
	echo "Step III.6. EXTRACT RARE lists from zCalled PLINK FILES for ALL THREE RARE LISTS"
	echo -e "------------------\n"
	echo -e

		plink --bfile ${basicdaughter}/zcall_TOP --noweb --extract ${workdir}/rare97.txt --make-bed --out ${basicdaughter}/zcall_rare97  --allow-no-sex
		plink --bfile ${basicdaughter}/zcall_TOP --noweb --extract ${workdir}/rare98.txt --make-bed --out ${basicdaughter}/zcall_rare98 --allow-no-sex
		plink --bfile ${basicdaughter}/zcall_TOP --noweb --extract ${workdir}/rare99.txt --make-bed --out ${basicdaughter}/zcall_rare99 --allow-no-sex


echo -e
	echo -e "\n------------------"
	echo "Step II.8. Create Results from EXTRACTING RARES from zCall and EXTRACTING COMMONS from raw"
	echo -e "------------------\n"
	echo -e
		mkdir ${basicdaughter}/raw_extractcommon
		plink --noweb --bfile ${basicdaughter}/zcall_rare97 --bmerge ${workdir}/raw_extractcommon.bed ${workdir}/raw_extractcommon.bim ${workdir}/raw_extractcommon.fam --out ${basicdaughter}/raw_extractcommon/extractcommon_extractrare_merge97 --make-bed --allow-no-sex
		plink --noweb --bfile ${basicdaughter}/zcall_rare98 --bmerge ${workdir}/raw_extractcommon.bed ${workdir}/raw_extractcommon.bim ${workdir}/raw_extractcommon.fam --out ${basicdaughter}/raw_extractcommon/extractcommon_extractrare_merge98 --make-bed --allow-no-sex
		plink --noweb --bfile ${basicdaughter}/zcall_rare99 --bmerge ${workdir}/raw_extractcommon.bed ${workdir}/raw_extractcommon.bim ${workdir}/raw_extractcommon.fam --out ${basicdaughter}/raw_extractcommon/extractcommon_extractrare_merge99 --make-bed --allow-no-sex
						

	echo -e
	echo -e "\n------------------"
	echo "Step II.9. Create Results from EXTRACTING RARES from zCall and EXCLUDING RARES from raw"
	echo -e "------------------\n"
	echo -e
		mkdir ${basicdaughter}/raw_excluderare
		plink --noweb --bfile ${basicdaughter}/zcall_rare97 --bmerge ${workdir}/raw_excluderare97.bed ${workdir}/raw_excluderare97.bim ${workdir}/raw_excluderare97.fam --out ${basicdaughter}/raw_excluderare/excluderare_extractrare_merge97 --make-bed --allow-no-sex
		plink --noweb --bfile ${basicdaughter}/zcall_rare98 --bmerge ${workdir}/raw_excluderare98.bed ${workdir}/raw_excluderare98.bim ${workdir}/raw_excluderare98.fam --out ${basicdaughter}/raw_excluderare/excluderare_extractrare_merge98 --make-bed --allow-no-sex
		plink --noweb --bfile ${basicdaughter}/zcall_rare99 --bmerge ${workdir}/raw_excluderare99.bed ${workdir}/raw_excluderare99.bim ${workdir}/raw_excluderare99.fam --out ${basicdaughter}/raw_excluderare/excluderare_extractrare_merge99 --make-bed --allow-no-sex
						
	
	echo -e
	echo -e "\n------------------"
	echo "Step II.10. Run Threshold and Calibration Checking Loop"
	echo -e "------------------\n"
	echo -e
		cd ${basicdaughter}
		#bash /h4/t1/users/jkb4y/programs/zCall//zCalibrationLoop.sh ${report_qced} ${chip_version} ${basicdaughter}/BETAS.txt


