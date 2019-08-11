#!/bin/bash
###############
# Script Info #
###############
# Author: Wouter Wijsman aka sharkwouter
# Description:
# This script downloads packages with their dependencies for vaporos.
# It knows which packages are needed by looking at the base_include and default.preseed files.

##########
# Script #
##########
#Change directory to the directory of this script
cd "$(dirname "$0")"

###################
# Basic variables #
###################
# Directories:
WORKDIR="${PWD}"
TARGETDIR="${WORKDIR}/packages"
BUILD="${WORKDIR}/iso"
CHROOTDIR="${WORKDIR}/chroot"
ADDITIONSDIR="${WORKDIR}/additions"

# Scripts:
GENSCRIPT="${WORKDIR}/gen.sh"
CHROOTSCRIPT="${WORKDIR}/create-chroot.sh"

# Other variables:
DEPS="7z rsync"
ADDITIONALPACKAGES=""
# Since we need tasksel tasks as well, which are not referenced in any file, some additional packages have been hardcoded here.

#############
# Functions #
#############
#Show how to use add-packages.sh
usage ( )
{
	cat <<EOF
	$0 [OPTION]
	-h		  Print this message
EOF
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

# Download with ISO and set the ISOFILE variable to it with gen.sh
download ( ) {
	${GENSCRIPT} -d
	ISOFILE="$(${GENSCRIPT} -f)"
}

# Extract the ISO which was downloaded by gen.sh
extract ( ) {
	#Extract SteamOSDVD.iso into BUILD
	if 7z x ${ISOFILE} -o${BUILD}; then
		:
	else
		echo "Error extracting ${ISOFILE} into ${BUILD}!"
		exit 1
	fi
	rm -fr ${BUILD}/\[BOOT\]
}

# Create the chroot and transfer the packages we already have into it
createchroot ( ) {
	echo "Creating chroot.."
	sudo ${CHROOTSCRIPT} -b ${BUILD}

	# Copy the packages we already have into the apt cache of the chroot. This will prevent unnecessarily redownloading packages
	if [ -d ${TARGETDIR} ]; then
		sudo rsync -av ${TARGETDIR}/ ${CHROOTDIR}/var/cache/apt/archives/
	fi
}

# Compiles a list of packages to download, downloads them and transfers them to ${TARGET}
getpackages ( ) {
	# Get the packages listed in the base_include file
	include="$(cat ${ADDITIONSDIR}/.disk/base_include)"

	# Get the packages listed in the default.preseed
	pkgsel=$(grep "^d-i pkgsel/include" ${ADDITIONSDIR}/default.preseed|cut -d' ' -f4-)

	# Download all packages needed
	echo "Downloading packages.."
	sudo chroot ${CHROOTDIR} apt-get install -d -y ${include} ${pkgsel} ${ADDITIONALPACKAGES}

	# Transfer them to the target directory
	mkdir -p ${TARGETDIR}
	echo "Transfering packages into ${TARGET}.."
	rsync -av --exclude 'lock' --exclude 'partial' ${CHROOTDIR}/var/cache/apt/archives/ ${TARGETDIR}/
}

# Remove directory in which the iso was extracted
cleanup ( ) {
	rm -rf ${BUILD}
}

###########
# Getopts #
###########
#Setup command line arguments
while getopts "h" OPTION; do
	case ${OPTION} in
	h)
		usage
		exit 1
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
#Check dependencies
deps

#Download the base ISO
download

#Extract the ISO into ${BUILD}
extract

#Create the chroot
createchroot

#Download the packages
getpackages

#Clean up the extracted iso
cleanup
