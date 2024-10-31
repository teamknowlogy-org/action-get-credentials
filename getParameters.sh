#!/bin/bash

# Parámetros de entrada
project="$1"
applicationName="$2"
region="us-east-1"

# Variables iniciales
export SSM_BASE_PATH="/$project"
MATRIX="${applicationName^^}"
tempFile="tempvars.out"

# Limpiar o crear archivos
> .env
> $tempFile

# Mostrar parámetros de entrada para debugging
echo "Debug: Parámetros de entrada"
echo "project: $project"
echo "applicationName: $applicationName"
echo "region: $region"
echo "SSM_BASE_PATH: $SSM_BASE_PATH"
echo "MATRIX: $MATRIX"
echo "-----------------------------------"

for x in $(echo $MATRIX)
do
    # Obtener valores globales
    export SSM_GLOBAL_PATH="$SSM_BASE_PATH/global"
    export SSM_PATH="$SSM_GLOBAL_PATH"
    echo "GETTING GLOBAL PARAMETERS FOR $SSM_PATH"
    echo "#GLOBAL PARAMETERS"

    for i in $(aws ssm get-parameters-by-path --region $region --recursive --path "$SSM_PATH" | jq -c '.Parameters[] | .Name + "=" + .Value'  |  sed  's/"//g' | cut -d "/"  -f4- | awk '{print $0}')
    do
        echo "$i" >> $tempFile
    done
    
    # Obtener valores específicos de la aplicación
    echo "#SPECIFIC PARAMETERS" 
    export SSM_SERVICE_PATH="$SSM_BASE_PATH/services/$x"
    export SSM_PATH="$SSM_SERVICE_PATH"
    echo "GETTING APPLICATION PARAMETERS FOR $SSM_PATH"
    for i in $(aws ssm get-parameters-by-path --region $region --recursive --path "$SSM_PATH" | jq -c '.Parameters[] | .Name + "=" + .Value'  |  sed  's/"//g' | cut -d "/"  -f5- | awk '{print $0}')
    do
        echo "$i" >> $tempFile
    done 
    
    # Depuración: Mostrar contenido del archivo temporal antes de eliminar duplicados
    echo "Debug: Contenido del archivo temporal antes de eliminar duplicados"
    cat $tempFile

    # Escribir en el archivo .env y eliminar duplicados
    awk -F'=' '!seen[$1]++ {print $1"="$2}' "$tempFile" > .env

    # Depuración: Mostrar contenido del archivo .env después de procesar
    echo "Debug: Contenido del archivo .env después de procesar"
    cat .env

    # Limpiar archivo temporal
    rm $tempFile
done

# Mostrar el archivo .env final
echo "Debug: Contenido final del archivo .env"
cat .env
