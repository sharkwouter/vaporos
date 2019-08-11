#!/bin/bash
###############
# Script Info #
###############
# Author: Wouter Wijsman aka sharkwouter
# Description:
# This script can be used to generate modified versions of the SteamOS ISO with different packages.

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
FIRMWAREFILE="${WORKDIR}/firmware.txt"
PACKAGES="${WORKDIR}/packages"
ADDITIONSPATH="${WORKDIR}/additions"
ISOPATH=${WORKDIR}

# Base ISO:
UPSTREAMURL="http://repo.steampowered.com/download/"
STEAMINSTALLFILE="SteamOSDVD.iso"
MD5SUMFILE="MD5SUMS"

# ISO info:
DISTNAME="brewmaster"
ISONAME="vaporos-latest.iso"
ISOVNAME="VaporOS"
ISODESCRIPTION="VaporOS Brewmaster is SteamOS with extras"

# Other info:
DEPS="xorriso lftp 7z rsync reprepro wget"

#############
# Functions #
#############
#Show how to use gen.sh
usage ( )
{
	cat <<EOF
	$0 [OPTION]
	-h		  Print this message
	-d		  Only download the base ISO
	-f		  Return filename of base ISO
	-n		  Set the name for the ISO
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

	#Make sure isohdpfx.bin exists
	if [ -f "isohdpfx.bin" ]; then
		SYSLINUX="isohdpfx.bin"
	elif [ -f "/usr/lib/ISOLINUX/isohdpfx.bin" ]; then
		SYSLINUX="/usr/lib/ISOLINUX/isohdpfx.bin"
	else
		echo "Error: isohdpfx.bin not found! Try putting it in ${WORKDIR}."
		exit 1
	fi
}

#Remove the ${BUILD} directory to start from scratch
scratch ( ) {
	if [ -d "${BUILD}" ]; then
		echo "Building ${BUILD} from scratch"
		rm -fr "${BUILD}"
	fi

	#Create new directory
	mkdir -p ${BUILD}
}

#Get the checksum of the current ISO
getchecksum ( ) {
	#Get the checksum of the upstream version
	echo "Upstream checksum:"
	upstreaminstallermd5sum=$(wget --quiet -O- ${UPSTREAMURL}/${MD5SUMFILE} | grep ${STEAMINSTALLFILE}$ | cut -f1 -d' ')
	echo ${upstreaminstallermd5sum}

	#Get the checksum of our version
	echo "local checksum:"
	if [ ! -f ${ISOPATH}/${STEAMINSTALLFILE} ]; then
		echo "No file found"
		return
	fi

	localinstallermd5sum=$(md5sum ${ISOPATH}/${STEAMINSTALLFILE} | cut -f1 -d' ')
	echo ${localinstallermd5sum}

	#Return if they are the same
	[ "${upstreaminstallermd5sum}" = "${localinstallermd5sum}" ]
}

#Download the iso, if needed
download ( ) {
	steaminstallerurl="${UPSTREAMURL}/${STEAMINSTALLFILE}"

	#Make we have the latest version
	if getchecksum; then
		echo "Using existing ${STEAMINSTALLFILE}"
	else
		if [ ! -f ${ISOPATH}/${STEAMINSTALLFILE} ]; then
			echo "The downloaded version doesn't match the upstream version, deleting..."
			rm ${ISOPATH}/${STEAMINSTALLFILE}
		fi
	fi

	#Download if the iso doesn't exist or the -d flag was passed
	if [ ! -f ${STEAMINSTALLFILE} ] || [ -n "${redownload}" ]; then
		if [ -f ${STEAMINSTALLFILE} ];then
			rm ${STEAMINSTALLFILE}
		fi
		echo "Downloading ${steaminstallerurl} ..."
		if lftp -e "pget -n 8 ${steaminstallerurl};exit"; then
			if getchecksum; then
			    echo "Download succeeded"
			else
			    echo "The downloaded version has been corrupted, deleting..."
			    rm ${ISOPATH}/${STEAMINSTALLFILE}
			    exit 1
			fi
		else
			echo "Error downloading ${steaminstallerurl}!"
			exit 1
		fi
	fi
}

#Extract the ISO into the ${BUILD} 
extract ( ) {
	#Extract SteamOSDVD.iso into BUILD
	if 7z x ${STEAMINSTALLFILE} -o${BUILD}; then
		:
	else
		echo "Error extracting ${STEAMINSTALLFILE} into ${BUILD}!"
		exit 1
	fi
	rm -fr ${BUILD}/\[BOOT\]
}

#Make changes to ${BUILD}
createbuildroot ( ) {
	#Generate our new repos
	echo "Generating pool.."
	mv ${BUILD}/pool ${BUILD}/poolbase
	rm -rf ${BUILD}/dists
	mkdir ${BUILD}/conf
	/bin/echo -e "Origin: ${ISOVNAME}\nLabel:${ISOVNAME}\nSuite: stable\nCodename: ${DISTNAME}\nComponents: main contrib non-free\nUDebComponents: main\nArchitectures: i386 amd64\nDescription: ${ISODESCRIPTION}\nContents: udebs . .gz\nUDebIndices: Packages . .gz" > ${BUILD}/conf/distributions
	reprepro -Vb ${BUILD} includedeb ${DISTNAME} ${BUILD}/poolbase/*/*/*/*.deb > /dev/null
	reprepro -Vb ${BUILD} includeudeb ${DISTNAME} ${BUILD}/poolbase/*/*/*/*.udeb > /dev/null
	reprepro -Vb ${BUILD} includedeb ${DISTNAME} ${PACKAGES}/*.deb > /dev/null #This adds packages from the pool directory
	rm -rf ${BUILD}/poolbase ${BUILD}/db ${BUILD}/conf

	#Copy additions directory
	echo "Copying configuration files"
	rsync -av ${ADDITIONSPATH}/ ${BUILD}/

	#Make symlinks based on the firmwares mentioned in the config
	echo "Creating firmware symlinks..."
	for f in `cat ${FIRMWAREFILE}`; do
		package="$(find buildroot/pool/ -name ${f}_*_*.deb|head -1)"
		if [ "${package}" ];then
			ln -s $(find ${BUILD}/pool/ -name ${f}_*_*.deb|head -1) ${BUILD}/firmware
		else
			echo "Error: Couln't find ${f} firmware package"
			exit 1
		fi
	done

	#Generate new md5sum.txt for the iso
	echo "Creating md5sum.txt file" 
	cd ${BUILD}
	find . -type f -print0 | xargs -0 md5sum > md5sum.txt
	cd -
}

#Generate the ISO from ${BUILD}
createiso ( ) {
	#Remove old ISO
	if [ -f ${ISOPATH}/${ISONAME} ]; then
		echo "Removing old ISO ${ISOPATH}/${ISONAME}"
		rm -f "${ISOPATH}/${ISONAME}"
	fi

	#Build the ISO
	echo "Building ${ISOPATH}/${ISONAME} ..."
	xorriso -as mkisofs -r -checksum_algorithm_iso md5,sha1,sha256,sha512 \
		-V "${ISOVNAME}" -o ${ISOPATH}/${ISONAME} \
		-J -isohybrid-mbr ${SYSLINUX} \
		-joliet-long -b isolinux/isolinux.bin \
		-c isolinux/boot.cat -no-emul-boot -boot-load-size 4 \
		-boot-info-table -eltorito-alt-boot -e boot/grub/efi.img \
		-no-emul-boot -isohybrid-gpt-basdat -isohybrid-apm-hfsplus ${BUILD}
}

#Create md5sum of the created ISO
createmd5sum ( ) {
    echo "Generating checksum..."
	md5sum ${ISONAME} > "${ISONAME}.md5"
	if [ -f ${ISONAME}.md5 ]; then
		echo "Checksum saved in ${ISONAME}.md5"
	else
		echo "Failed to save checksum"
	fi
}

###########
# Getopts #
###########
#Setup command line arguments
while getopts "hdfn:" OPTION; do
	case ${OPTION} in
	h)
		usage
		exit 1
	;;
	d)
		if which "lftp" >/dev/null 2>&1; then
			:
		else
			echo "Missing dependency: lftp"
			exit 1
		fi
		download
		exit 0
	;;
	n)
		ISOVNAME="${OPTARG}"
		ISONAME=$(echo "${OPTARG}.iso"|tr '[:upper:]' '[:lower:]'|tr "\ " "-")
	;;
	f)
		echo "${ISOPATH}/${STEAMINSTALLFILE}"
		exit 0
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

#Replace ${BUILD} with an empty directory
scratch

#Download the base ISO
download

#Extract the ISO into ${BUILD}
extract

#Make changes/additions to ${BUILD}
createbuildroot

#Build the actual ISO
createiso

#Generate a file with the md5sum of our newly created ISO
createmd5sum
