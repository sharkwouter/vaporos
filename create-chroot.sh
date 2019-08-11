#!/bin/bash
###############
# Script Info #
###############
# Author: Wouter Wijsman aka sharkwouter
# Description:
# This script can be used to create a chroot based on the buildroot created when running gen.sh.
# It is an easy way to test if the base system will install with the generated ISO as well.

##########
# Script #
##########
# Make sure we're running in the correct directory
cd "$(dirname "$0")"

###################
# Basic variables #
###################
# Directories:
WORKDIR="${PWD}"
BUILD="${WORKDIR}/buildroot"
CHROOTPATH="${WORKDIR}/chroot"
DISTNAME="brewmaster"
SCRIPT="${WORKDIR}/brewmaster"

# Other info:
DEPS="debootstrap"

#############
# Functions #
#############
#Show how to use gen.sh
usage ( )
{
	cat <<EOF
	$0 [OPTION]
	-h		  Print this message
	-b		  Set the directory for the base of the chroot
EOF
}

checkroot ( ) {
# Make sure we are running as root
	if [ "$EUID" -ne 0 ]
	  then echo "Please run as root"
	  exit
	fi
}

#Check some basic dependencies this script needs to run
deps ( ) {
	#Check dependencies
	for dep in ${DEPS}; do
		if which ${dep} >/dev/null 2>&1; then
			:
		else
			echo "Missing dependency: ${dep}"
			exit 1
		fi
	done
	if test "`expr length \"$ISOVNAME\"`" -gt "32"; then
		echo "Volume ID is more than 32 characters: ${ISOVNAME}"
		exit 1
	fi
}

#Remove the ${BUILD} directory to start from scratch
scratch ( ) {
	if [ -d "${CHROOTPATH}" ]; then
		echo "Building ${CHROOTPATH} from scratch"
		rm -fr "${CHROOTPATH}"
	fi
	
	#Create new directory
	mkdir -p ${CHROOTPATH}
}

#Build the chroot
createbasechroot ( ) {
	if [ ! -d ${BUILD} ]; then
		echo "Error: ${BUILD} directory not found, run gen.sh first"
	fi
	base_include="${BUILD}/.disk/base_include"
	base_exclude="${BUILD}/.disk/base_exclude"

	components=""
	for component in `cat ${BUILD}/.disk/base_components`; do
		if [ "${component}" == "main" ]; then
			components="${component}"
		else
			components="${components},${component}"
		fi
	done

	includes=""
	if [ -f ${base_include} ]; then
		for include in `cat ${base_include}`; do
			includes="${includes},${include}"
			if [ "${include}" == "$(head -1 ${base_include})" ]; then
				includes="--include=${include}"
			else
				includes="${includes},${include}"
			fi
		done
	fi

	excludes=""
	if [ -f ${base_exclude} ]; then
		for exclude in `cat ${base_exclude}`; do
			if [ "${exclude}" == "$(head -1 ${base_exclude})" ]; then
				excludes="--exclude=${exclude}"
			else
				excludes="${excludes},${exclude}"
			fi
		done
	fi

		/usr/sbin/debootstrap --components=${components} --resolve-deps ${includes} ${excludes} --no-check-gpg ${DISTNAME} ${CHROOTPATH} file://${BUILD} ${SCRIPT}
}

#Fininishing touches to the chroot
finishchroot ( ) {
	echo "deb http://repo.steampowered.com/steamos/ brewmaster main contrib non-free" > ${CHROOTPATH}/etc/apt/sources.list
	echo "deb http://deb.debian.org/debian/ jessie main contrib non-free" > ${CHROOTPATH}/etc/apt/sources.list.d/debian.list
	echo "deb http://www.deb-multimedia.org jessie main" > ${CHROOTPATH}/etc/apt/sources.list.d/deb-multimedia.list
	echo "deb http://download.vaporos.net/vaporos/ brewmaster main contrib non-free" > ${CHROOTPATH}/etc/apt/sources.list.d/vaporos.list
	cp ${WORKDIR}/deb-multimedia-keyring.gpg ${CHROOTPATH}/etc/apt/trusted.gpg.d/deb-multimedia-repo.gpg
	cp ${WORKDIR}/vaporos-archive-keyring.gpg ${CHROOTPATH}/etc/apt/trusted.gpg.d/vaporos-repo.gpg
	chroot ${CHROOTPATH} dpkg --add-architecture i386
	chroot ${CHROOTPATH} apt-get update
	chroot ${CHROOTPATH} apt-get clean
	echo "KEYMAP=us" > ${CHROOTPATH}/etc/vconsole.conf
}

###########
# Getopts #
###########
#Setup command line arguments
while getopts "hb:" OPTION; do
	case ${OPTION} in
	h)
		usage
		exit 1
	;;
	b)
		BUILD="$(realpath ${OPTARG})"
	;;
	*)
		echo "${OPTION} - Unrecongnized option"
		usage
		exit 1
	;;
	esac
done

#############
# Execution #
#############
#Check if the script is run as root
checkroot

#Check dependencies
deps

#Replace ${CHROOTPATH} with an empty directory
scratch

#Build the chroot
createbasechroot

#Finishing touches to the chroot
finishchroot
