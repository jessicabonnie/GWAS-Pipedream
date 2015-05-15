							GWAS-PIPEDREAM

Description
-----------

GWAS-Pipedream (working title) is a pipeline to perform basic SNP, gender, and population QC on genomic data.
Copyright (C) 2015  JBonnie, WMChen


Contents
----------
Folder: SHcode
	makedata.sh
	pheno_inc.sh
	qc1.sh
	relatedness_qc.sh

Folder: Rcode


Folder: PYTHONcode



INPUTS
-----------
nickname - alias for the data, used in all filenames
DATAFILE - path to full data table output from GenomeStudio, Top Allele format
phenofile - phenotype file, specific columns expected, see SHcode/pheno_inc.sh for details
covariablecount : integer, the number of covariables to incorporate from the hard-coded list
chip : I/E, character value indicating whether data was generated from the Immunochip (I) or the HumanCoreExomeChip (E)
covariablevalue : integer, the number of WHICH covariable on the list should be included in the table for checking or used to color the graphs


Order of Scripts
------------------

SHcode/makedata.sh
	Transforms output from Genome Studio into plink files.
	See Script for option/parameter details

SHcode/pheno_inc.sh
	This script incorporates phenotypic information (disease status, sex, family relationships) into the raw plink files from makedata.sh
	It creates numeric covariate files based on a hard coded list of column names.

SHcode/qc1.sh
	This script runs the initial SNP and Sample QC steps.
	It produces a folder full of files in 2_QC1 folder, and, most importantly, a list of SNPs and Samples to be removed.

SHcode/relatedness_qc.sh
	This script runs initial relatedness checking on data after the initial QC step.
	It uses files in the 2_QC1 folder as well as the covariable lists created during pheno_inc.sh.
	The output from this script is used in qc_pdf.sh for graphing.

Requirements
--------------
PLINK
KING
Python
R


Authors
----------
JBonnie
WMChen
