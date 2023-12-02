project="$1"
environment="$2"
applicationName="$3"
region="us-east-1"

export SSM_BASE_PATH="/$project/$environment"

MATRIX="$applicationName"
> .env
for x in $(echo $MATRIX)
do
	## FETCH GLOBAL VALUES
	export SSM_GLOBAL_PATH="$SSM_BASE_PATH/global"
	export SSM_PATH="$SSM_GLOBAL_PATH"
        echo "GETTING GLOBAL PARAMETERS FOR $SSM_PATH"
	echo "#GLOBAL PARAMETERS" >> .env

	for i in $(aws ssm get-parameters-by-path --region $region --recursive --path "$SSM_PATH" | jq -c '.Parameters[] | .Name + "=" + .Value' |rev | cut -d"/" -f1 | rev |  sed  's/"//g')
	do
		echo "$i" >> .env
	done
	
	## FETCH SPECIFIC VALUES
        echo "#SPECIFIC PARAMETERS" >> .env
        export SSM_SERVICE_PATH="$SSM_BASE_PATH/services/$x"
        export SSM_PATH="$SSM_SERVICE_PATH"
	echo "GETTING APPLICATION PARAMETERS FOR $SSM_PATH"
	for i in $(aws ssm get-parameters-by-path --region $region --recursive --path "$SSM_PATH" | jq -c '.Parameters[] | .Name + "=" + .Value'  |  sed  's/"//g' | cut -d "/"  -f6- | awk '{print $0}')
	do
		echo "$i" >> .env
	done 

done
