project="$1"
environment="$2"
applicationName="$3"
region="us-east-1"

export SSM_BASE_PATH="/$project/$environment"

MATRIX="$applicationName"
> archivoVariables.out
for x in $(echo $MATRIX)
do
	## FETCH GLOBAL VALUES
	export SSM_GLOBAL_PATH="$SSM_BASE_PATH/global"
	export SSM_PATH="$SSM_GLOBAL_PATH"
        echo "GETTING GLOBAL PARAMETERS FOR $SSM_PATH"
	for i in $(aws ssm get-parameters-by-path --region $region --recursive --path "$SSM_PATH" | jq -c '.Parameters[] | .Name + "=" + .Value' |rev | cut -d"/" -f1 | rev |  sed  's/"//g')
	do
		echo "$i" >> archivoVariables.out
	done
	
	## FETCH SPECIFIC VALUES
        export SSM_SERVICE_PATH="$SSM_BASE_PATH/service/$x"
        export SSM_PATH="$SSM_SERVICE_PATH"
	echo "GETTING APPLICATION PARAMETERS FOR $SSM_PATH"
	for i in $(aws ssm get-parameters-by-path --region $region --recursive --path "$SSM_PATH" | jq -c '.Parameters[] | .Name + "=" + .Value' |rev | cut -d"/" -f1 | rev |  sed  's/"//g')
	do
		echo "$i" >> archivoVariables.out
	done 

done

cat archivoVariables.out