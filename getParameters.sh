project="$1"
applicationName="$2"
region="us-east-1"

export SSM_BASE_PATH="/$project"

MATRIX="${applicationName^^}"
tempFile="tempvars.out"
> .env
> $tempFile

for x in $(echo $MATRIX)
do
	## FETCH GLOBAL VALUES
	export SSM_GLOBAL_PATH="$SSM_BASE_PATH/global"
	export SSM_PATH="$SSM_GLOBAL_PATH"
        echo "GETTING GLOBAL PARAMETERS FOR $SSM_PATH"
	echo "#GLOBAL PARAMETERS"

	for i in $(aws ssm get-parameters-by-path --region $region --recursive --path "$SSM_PATH" | jq -c '.Parameters[] | .Name + "=" + .Value'  |  sed  's/"//g' | cut -d "/"  -f4- | awk '{print $0}')
	do
		echo "$i" >> $tempFile
	done
	
	## FETCH SPECIFIC VALUES
        echo "#SPECIFIC PARAMETERS" 
        export SSM_SERVICE_PATH="$SSM_BASE_PATH/services/$x"
        export SSM_PATH="$SSM_SERVICE_PATH"
	echo "GETTING APPLICATION PARAMETERS FOR $SSM_PATH"
	for i in $(aws ssm get-parameters-by-path --region $region --recursive --path "$SSM_PATH" | jq -c '.Parameters[] | .Name + "=" + .Value'  |  sed  's/"//g' | cut -d "/"  -f5- | awk '{print $0}')
	do
		echo "$i" >> $tempFile
	done 
	awk -F'=' '!seen[$1]++ {print $1"="$2}' "$tempFile" > .env
	rm $tempFile

done
