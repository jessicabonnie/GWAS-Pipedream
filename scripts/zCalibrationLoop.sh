
reportloc=$1
betaloc=$2


echo -e
echo "Here are the arguments passed to the script: "
echo "____________________________________________"
echo -e
echo "GS Report Location: " $reportloc
echo "BETAs to Use in Calibration: " $betaloc


if [ $# == 3 ]; then
  zPATH=$3
  echo "Path to zCall: " $zPATH
else
  zPATH=/t121/jdrfdn/projects/JDRFDN/apps/zCall/Version3_GenomeStudio
  echo "Using hardcoded path to zCall scripts folder: " $zPATH
fi

caldir=$(pwd)/threshold_calibration_checking
mkdir ${caldir}




#echo "EXITING FROM CALIBRATION, WILL RETURN TO THIS STEP LATER"
#exit



	echo -e
	echo -e "\n------------------"
	echo "STEP III.1. Calibrate Z"
	echo -e "------------------\n"
	echo -e

        # STEP X1. Calibrating Z
                # Step X1A: Find thresholds for various values of Z (run in separate bash script)


        for z in $(seq 3 15); do
        echo "Now Running findThresholds.py on threshold $z, "$(date)
        python ${zPATH}/findThresholds.py -R ${reportloc} -Z $z -B ${betaloc} > ${caldir}/thresholds.$z
        
        done




	echo -e
	echo -e "\n------------------"
	echo "STEP III.2. Calculate the accuracy of a given values of Z "
	echo -e "------------------\n"
	echo -e

        # STEP X2. Calculating the accuracy of a given value of Z (run in separate bash script)
        	summarytable=${caldir}/calibrate.summary
	titlelist=('Global Concordance' 'Specificity' 'SensitivityAB' 'SensitivityBB' 'Negative Predictive Value' 'Positive Predictive Value AB' 'Positive Predictive Value BB' 'nAA' 'nAB' 'nBB' "nNC")
	lesspaintitlelist=('GlobalConcordance' 'Specificity' 'SensitivityAB' 'SensitivityBB' 'NegativePredictiveValue' 'PositivePredictiveValueAB' 'PositivePredictiveValueBB' 'nAA' 'nAB' 'nBB' "nNC")
	titlecount=${#titlelist[@]}
	
	
		titleheader=("Threshold" "${lesspaintitlelist[@]}")
	echo ${titleheader[@]} > ${summarytable}
        for z in $(seq 3 15); do
        echo "Now Running calibrateZ.py on threshold $z, "$(date)
        #python ${zPATH}/../additionalScripts/calibrateZ_bugFix.py -R ${reportloc} -T ${caldir}/thresholds.$z > ${caldir}/calibrate.$z
        python ${zPATH}/calibrateZ.py -R ${reportloc} -T ${caldir}/thresholds.$z > ${caldir}/calibrate.$z
        #Initialize array of values from output and add threshold index as first elemenvalues=()
		values=()
		values+=("${z}")
		    for t in $(seq ${titlecount}); do
		    tindex=$((${t}-1))
		    title=${titlelist[${tindex}]}
            value=$(grep "${title}" ${caldir}/calibrate.$z | awk  '{print $NF}')
            values+=("${value}")
            done

		echo ${values[@]} | awk '{print}' >> ${summarytable}
        done

