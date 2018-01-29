#!/bin/bash
#Made by: Wouter Wijsman aka sharkwouter
#This script downloads packages with their dependencies for vaporos

#Change directory to the directory of this script
olddir="${PWD}"
cd "$(dirname "$0")"

#Set variables
workdir="${PWD}"
dockerfile="${workdir}/Dockerfile"
tempdir="${workdir}/output"
target="../packages"
packages="${@}"

#Show how to use gen.sh
usage ( ) {
	cat <<EOF
Usage: $0 pkg1 [pkg2 ...]

This script allows you to download specific packages and their dependencies into VaporOS.
EOF
}

#Stop the program if we don't know which packages the user wants
if [ -z "${packages}" ];then
    usage
    exit 1
fi


#Make the target directory
mkdir -p ${target} 2>/dev/null

#Build the docker container
docker build -f ${dockerfile} -t package-builder ${workdir}

#Make the directory which will be added to the container
mkdir -p ${tempdir}

#Run container
docker run --rm -ti -v ${tempdir}:/home/builder/share -h package-builder package-builder apt-get install -d -o dir::cache=/home/builder/share -o Debug::NoLocking=1 -y ${packages}

#Move 
mv ${tempdir}/archives/*deb ${target}
rm -rf ${tempdir}

#Return to previous directory
cd ${PWD}
