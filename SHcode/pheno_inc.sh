#!/bin/bash
#!/usr/bin/bash

### This script incorporates phenotypic information (disease status, sex, family relationships) into the raw plink files from makedata.sh
### It also creates numeric covariable files based on a hard coded list of column names.


##############################################################################
# Usage: sh  pheno_inc.sh {phenofile} {nickname} {covariablecount} {family_info}
##############################################################################

####################################################################3
#Arguments
#phenofile : the path to phenotype table, expected to contain "Gender_converted_to_number" column. If it doesn't, flip "sex_repair" argument to add that column to the file.
#		Also expected to contain the columns hard coded into the covariable list, as well as a status column titled "T1D", and a sample id column "Sample_ID"
#nickname : string, the alias for the project, used in all filenames
#covariablecount : integer, the number of covariables to incorporate from the hard-coded list
#family_info : T/F, Do we have relationship information to incorporate at the start of QC?
#		If so, it had better be contained in ${project_folder}/updatefamily.txt and ${project_folder}/updateparent.txt.
#
#####################################################################

echo -e "#########################################################################"
echo -e
echo -e "# GWAS-Pipedream - Standard GWAS QC Pipeline Package"
echo -e "# (c) 2014-2015 JBonnie, WMChen"
echo -e
echo -e "#########################################################################"


# Definining/Reading user specified script parameters/variables/values
phenofile=$1
nickname=$2
covariablecount=$3
#covariabletitlefile=$3
family_info=$4


#Some studies does not include status information, but, generally, this is something we will want.
status=T
if [ "${nickname}" = "dn" ]; then
  status=F
fi

#DOES THE PHENOTYPE FILE CONTAIN THE NECESSARY "Gender_converted_to_number" column?
sex_repair=F

#Establish project folder as current working directory
project_folder=$(pwd)


#It's easier to make variables to indicate these subfolders and files
qc1_folder=${project_folder}/2_QC1
raw_folder=${project_folder}/1_raw
cov0=${raw_folder}/${nickname}0.cov
cov=${qc1_folder}/${nickname}.cov


#Here is an array of likely covariable titles, note, we will assume that these are also the titles in the phenotype file
covariabletitles=(Cohort Race Race_Ethnicity)

#Alternatively, we could READ the covariable titles from a list file!
  #IFS=$'\n' read -d '' -r -a covariabletitles <${covariabletitlefile}
  #covariablecount=$(cat ${covariabletitlefile} | wc -l)

echo -e "########################################################################################################################################"
echo -e
echo -e "# Title: PHENOTYPE INCLUSION SCRIPT - Standard GWAS QC Pipeline"
echo -e "#"
 echo -e "#"
echo -e "# Disc: Incorporates phenotypic information into the raw plink files from makedata.sh; creates numeric covariable files based on a hard coded list of column names."
echo -e "#"
echo -e "# Note: Study specific variables are expected"
echo -e "# Note: Creates covariable lists and covariable file for use by later scripts in pipeline"
echo -e "#"
echo -e "# Usage: sh  ~/SHcode/pheno_inc.sh {phenofile} {nickname} {covariablecount} {family_info}"
echo -e "#"
echo -e "# See Script for option/parameter details"
echo -e "#"
echo -e "# by:  jbonnie"
echo -e "# date: 08.25.14"
echo -e
echo -e "Phenotype file: ${phenofile}"
echo -e "Study Alias: ${nickname}"
echo -e "Number of Covariables to be included: ${covariablecount}"
echo -e "Family Information Included: ${family_info}"
echo -e "Performed on:"
date
echo -e
echo -e "########################################################################################################################################"

mkdir ${qc1_folder}

echo -e
echo -e "\n------------------"
echo "Appending Numeric Sex Column to Phenotype File : ${sex_repair}"
echo -e "------------------\n"
echo -e

#make new pheno with numeric sexcol
if [ "${sex_repair}" = "T" ]; then
  badsexcol=$(head -n1 ${phenofile}| sed 's/\r//g' | sed 's/\t/\n/g'| awk 'BEGIN {FS = "\t"}; $0 ~/^Sex$/ {print NR}')
  echo Gender_converted_to_number > sexcol.tmp
  awk 'NR>1' $phenofile| sed 's/\r//g' | awk -v scol=${badsexcol} 'BEGIN {FS = "\t"}; {print $scol}' >> sexcol.tmp
  sed -i 's/Female/2/g;s/Male/1/g;s/female/2/g;s/male/1/g' sexcol.tmp
  sed -i 's/F$/2/g;s/M$/1/g;s/f$/2/g;s/m$/1/g' sexcol.tmp
  
  paste $phenofile sexcol.tmp > pheno_corrected.txt
  sed -i 's/\r//g' pheno_corrected.txt
  
  phenofile=pheno_corrected.txt
  rm sexcol.tmp
fi

echo -e
echo -e "\n------------------"
echo "Storing column numbers from the phenotype file"
echo -e "------------------\n"
echo -e

#Let's read some column numbers in the phenotype file
sexcol=$(head -n1 ${phenofile}| sed 's/\r//g' | sed 's/\t/\n/g'| awk 'BEGIN {FS="\t"}; $0 ~/Gender_converted_to_number/ {print NR}')
statuscol=$(head -n1 ${phenofile}| sed 's/\r//g' | sed 's/\t/\n/g'| awk 'BEGIN {FS="\t"}; $0 ~/^T1D$/ {print NR}')
familycol=$(head -n1 ${phenofile}| sed 's/\r//g' | sed 's/\t/\n/g'| awk 'BEGIN {FS="\t"}; $0 ~/^Family_ID$/ {print NR}')

if [ -z "$sexcol" ]; then
  sexcol=$(head -n1 ${phenofile}| sed 's/\r//g' | sed 's/\t/\n/g'| awk 'BEGIN {FS="\t"}; $0 ~/Sex/ {print NR}')
fi
#The title of the ID column will depend on the project with some regularity
if [ "${nickname}" = "dn" ]; then
	idcol=$(head -n1 ${phenofile}| sed 's/\r//g' | sed 's/\t/\n/g'| awk 'BEGIN {FS="\t"}; $0 ~/^UVA_ID$/ {print NR}')
else
  idcol=$(head -n1 ${phenofile}| sed 's/\r//g' | sed 's/\t/\n/g'| awk 'BEGIN {FS="\t"}; $0 ~/^Sample_ID$/ {print NR}')
  if [ -z "$idcol" ]; then
    idcol=$(head -n1 ${phenofile}| sed 's/\r//g' | sed 's/\t/\n/g'| awk 'BEGIN {FS="\t"}; $0 ~/^AnalyticID$/ {print NR}')
    fi
  if [ -z "$idcol" ]; then
    idcol=$(head -n1 ${phenofile}| sed 's/\r//g' | sed 's/\t/\n/g'| awk 'BEGIN {FS="\t"}; $0 ~/^Analytic_ID$/ {print NR}')
    fi
fi

echo -e
echo "Here are the column numbers for the numeric gender, sample id, and status columns"
echo ${sexcol}
echo ${idcol}
echo ${statuscol}
echo -e

echo -e
echo -e "\n------------------"
echo "Creating Sex Update File"
echo -e "------------------\n"
echo -e

awk 'NR>1' $phenofile | sed 's/\r//g' | sed '/^\s*$/d' | awk -v sexcol=${sexcol} -v idcol=${idcol} 'BEGIN {FS="\t"; OFS="\t"};{print $idcol, $idcol, $sexcol}' > ${qc1_folder}/updatesex.txt


echo -e
echo -e "\n------------------"
echo "Creating Covariable Lists"
echo -e "------------------\n"
echo -e

 for covindex in $(seq ${covariablecount}); do
    titleindex=$((${covindex}-1))
    covariabletitle=${covariabletitles[${titleindex}]}
    ## FIGURING OUT THE LINE BELOW ALMOST MADE ME DO SOMETHING DRASTIC, LIKE GIVE UP COMPUTERS ALTOGETHER AND BECOME AN ELVIS IMPERSONATOR
    covcol=$(head -n1 ${phenofile}| sed 's/\r//g' | sed 's/\t/\n/g'| awk -v pattern="^"$covariabletitle"$" 'BEGIN {FS="\t"}; $0 ~ pattern {print NR}')
    awk -v "covcol=${covcol}" 'BEGIN {FS="\t"; OFS="\t"}; NR>1{print $covcol}' ${phenofile}| sed 's/\r//g' | sed '/^\s*$/d' |sort | uniq > ${project_folder}/covariables${covindex}.list
    
    done

    
    
echo -e
echo -e "\n------------------"
echo "Creating Covariable File"
echo -e "------------------\n"
echo -e

#Now lets copy in the columns we want
#Lets start with the id columns
awk 'NR>1' ${phenofile} | sed 's/\r//g' | sed '/^\s*$/d' | awk -v "idcol=${idcol}" 'BEGIN {FS="\t"; OFS="\t"}; {print $idcol, $idcol}' > covnames0.tmp



##################################################################################################################################
## Function to retrieve the covariable columns from the phenotype file. Uses the list of covariables hard coded at the beginning
###############################################################################################################################

function fetch_covar {
## Function to retrieve the covariable columns from the phenotype file. Uses the list of covariables hard coded at the beginning
  covindex=$1
  titleindex=$((${covindex}-1))
  covariabletitle=${covariabletitles[${titleindex}]}
  ## FIGURING OUT THE LINE BELOW ALMOST MADE ME DO SOMETHING DRASTIC, LIKE GIVE UP COMPUTERS ALTOGETHER AND BECOME AN ELVIS IMPERSONATOR
  covcol=$(head -n1 ${phenofile}| sed 's/\r//g' | sed 's/\t/\n/g'| awk -v pattern="^"$covariabletitle"$" '$0 ~ pattern {print NR}')
  awk -v "covcol=${covcol}" 'BEGIN {FS="\t"; OFS="\t"};NR>1{print $covcol}' ${phenofile} | sed 's/\r//g' | sed '/^\s*$/d'  > cov_${covindex}_col.tmp
  paste covnames${titleindex}.tmp cov_${covindex}_col.tmp > covnames${covindex}.tmp
 }
 

 for i in $(seq ${covariablecount}); do
    fetch_covar $i
    
    done
 
#Lets add the titles to the covariable file
echo  -e 'FID\tIID\t'${covariabletitles[*]:0:${covariablecount}}| column -t > ${cov0}
#And now the actual info
cat covnames${covariablecount}.tmp >> ${cov0}
 
 
# Just in case, later, we want the covariable file without numbers substituded for the strings
cp ${cov0} ${raw_folder}/${nickname}0names.cov



##################################################################################################################################
## Function to replace the strings in the covariable file with a number, which will be it's order in the covariable.list file
###############################################################################################################################


function replace_covariable {
## Function to replace the strings in the covariable file with a number, which will be it's order in the covariable.list file

  covindex=$1
  covariablefile=${project_folder}/covariables${covindex}.list
  #covariables=($( <${covariablefile}))
  #count=$(echo ${#covariables[@]})
  IFS=$'\n' read -d '' -r -a covariables <${covariablefile}
  count=$(cat ${covariablefile} | wc -l)
  
  covcol=$((${covindex}+2))
  echo ${covariables[@]}
  for i in $(seq ${count}); do
    index=$(($i-1))
    awk -v i=${i} -v "covar=${covariables[${index}]}" -v "covcol=${covcol}" 'BEGIN {FS="\t"; OFS="\t"}; $covcol == covar{sub(covar, i, $covcol); } 1' ${cov0} > cov.tmp
    mv cov.tmp ${cov0}
  done

  title=$(head -n1 ${cov0} | awk -v "covcol=${covcol}" 'BEGIN {FS="\t"}; {print $covcol}')
  echo -e
  echo "The following numbers will be used for covariable #${covindex} in the covariable file (${title}):"
  echo -e
  for i in $(seq ${count}); do index=$(($i-1)); echo $i ${covariables[${index}]}; done
  echo -e
 }
#Now lets replace the covariable names in the file with their numerical values
for i in $(seq ${covariablecount}); do
    replace_covariable $i
done



cp ${cov0} ${cov}

echo -e
echo -e "\n------------------"
echo "Update Status Information: ${status}"
echo "Update Sex Information: ${status}"
echo -e "------------------\n"
echo -e
#If status is included in the phenotype file, it needs to be incorporated into the plink file too!
if [ "${status}" = "T" ]; then awk 'NR>1' $phenofile | sed 's/\r//g' | sed '/^\s*$/d'  | awk -v idcol=${idcol} -v statuscol=${statuscol} '{print $idcol, $idcol, $statuscol}' > ${qc1_folder}/updatestatus.txt

  #use PLINK to update the status in the 0 files produced in makedata steps
  plink --bfile ${raw_folder}/${nickname}0 --make-bed --out ${qc1_folder}/${nickname}1a --noweb --pheno ${qc1_folder}/updatestatus.txt
  #use PLINK to update the sex in the files
  plink --bfile ${qc1_folder}/${nickname}1a --update-sex ${qc1_folder}/updatesex.txt  --make-bed --out ${qc1_folder}/${nickname}1 --noweb

else plink --bfile ${raw_folder}/${nickname}0 --make-bed --out ${qc1_folder}/${nickname}1 --noweb --update-sex ${qc1_folder}/updatesex.txt
fi


echo -e
echo -e "\n------------------"
echo "Update Family Information: ${family_info}"
echo -e "------------------\n"
echo -e

if [ "${family_info}" = "T" ]; then 
mv ${qc1_folder}/${nickname}1.bim ${qc1_folder}/${nickname}1b.bim
mv ${qc1_folder}/${nickname}1.log ${qc1_folder}/${nickname}1b.log
mv ${qc1_folder}/${nickname}1.fam ${qc1_folder}/${nickname}1b.fam
mv ${qc1_folder}/${nickname}1.bed ${qc1_folder}/${nickname}1b.bed
plink --bfile ${qc1_folder}/${nickname}1b --make-bed --out ${qc1_folder}/${nickname}1c --noweb --update-ids ${project_folder}/updatefamily.txt
plink --bfile ${qc1_folder}/${nickname}1c --make-bed --out ${qc1_folder}/${nickname}1 --noweb --update-parents ${project_folder}/updateparent.txt
fi



