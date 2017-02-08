#!/usr/bin/env bash
#
# 1.env-setup.sh :
#
# Fetches BitQuark dependencies once.
#

LINK=`readlink -f $0`
if [[ -z ${LINK} ]]; then
LINK=$0
fi
DIRNAME=`dirname ${LINK}`

SOURCE_DESTDIR=${DIRNAME}/dependencies

#ENABLE_DEPS=("OPENSSL BDB MINIUPNPC BOOST ZLIB PNGLIB QT")
#ENABLE_PLATFORMS=("mingw32 mingw64 linux64")
ENABLE_DEPS=("OPENSSL BDB MINIUPNPC BOOST QT QR_ENCODE")
ENABLE_PLATFORMS=("i686 x86_64")

OPENSSL_SRC="http://www.openssl.org/source/openssl-1.0.1g.tar.gz"
OPENSSL_OUT_BASENAME="openssl-1.0.1g.tar.gz"
BDB_SRC="http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz"
BDB_OUT_BASENAME="db-4.8.30.NC.tar.gz"
MINIUPNPC_SRC="http://miniupnp.tuxfamily.org/files/download.php?file=miniupnpc-1.9.tar.gz"
MINIUPNPC_OUT_BASENAME="miniupnpc-1.9.tar.gz"
BOOST_SRC="http://sourceforge.net/projects/boost/files/boost/1.55.0/boost_1_55_0.tar.bz2/download"
BOOST_OUT_BASENAME="boost_1_55_0.tar.bz2"
#ZLIB_SRC="https://downloads.sourceforge.net/project/libpng/zlib/1.2.6/zlib-1.2.6.tar.gz"
#ZLIB_OUT_BASENAME="zlib-1.2.6.tar.gz"
#PNGLIB_SRC="https://downloads.sourceforge.net/project/libpng/libpng15/older-releases/1.5.9/libpng-1.5.9.tar.gz"
#PNGLIB_OUT_BASENAME="libpng-1.5.9.tar.gz"
QT_SRC="https://download.qt.io/archive/qt/4.8/4.8.6/qt-everywhere-opensource-src-4.8.6.tar.gz"
QT_OUT_BASENAME="qt-everywhere-opensource-src-4.8.6.tar.gz"
#QT_OUT_BASENAME="qt-everywhere-opensource-src-4.8.tar.gz"
QR_ENCODE_SRC="http://fukuchi.org/works/qrencode/qrencode-3.4.2.tar.gz"
QR_ENCODE_OUT_BASENAME="qrencode-3.4.2.tar.gz"

WGET_TIMEOUT=20
WGET_TRIES=2

# ############################################################################
exit_error() {
    echo $1;
    exit 1;
}

# ensure we can store dependencies sources:
[ -d ${SOURCE_DESTDIR} ] || mkdir -p ${SOURCE_DESTDIR}
[ -d ${SOURCE_DESTDIR} ] || exit_error "Cannot create SOURCE_DESTDIR="${SOURCE_DESTDIR}
echo "Dependencies SOURCE_DESTDIR exists."

# retrieving dependencies one by one when needed:
for dep in ${ENABLE_DEPS}; do
    echo "Processing enabled dependency: "$dep

    dep_src=$dep"_SRC"
    dep_base=$dep"_OUT_BASENAME"
    dep_basename=${!dep_base}
    dep_src_url=${!dep_src}
    dep_file=${SOURCE_DESTDIR}"/"${dep_basename}

    echo " URL: "${dep_src_url}
    echo " BASENAME: "${dep_basename}
    echo " OUTPUT: "${dep_file}

    if [ -z ${dep_file} ] ; then
        exit_error "BUILT FILE is empty"
    fi

    if [ -f ${dep_file} ] ; then
        echo " Skipping ${dep} fetch ; already have file."
    else
        echo " Fetching dependency from url="${dep_src_url}
        wget --tries ${WGET_TRIES} --timeout ${WGET_TIMEOUT} -q ${dep_src_url} -O ${dep_file} || exit_error "FAILED TO RETRIEVE FILE"


        echo " Dependency fetch complete"
    fi

    # extract each dependency for each target platforms:
    for target_p in ${ENABLE_PLATFORMS}; do
        echo " Processing platform: "${target_p}" ..."
        target_p_dir=${SOURCE_DESTDIR}"/"${target_p}
        dep_already_extracted_marker=${target_p_dir}"/extracted_"${dep}

        if [ -f ${dep_already_extracted_marker} ]; then
            echo "Skipping platform, previously done."
        else
            echo " Extracting files from archive for platform="${target_p}" ..."
            [ -d ${target_p_dir} ] || mkdir ${target_p_dir}
            [ -d ${target_p_dir} ] || exit_error "FAILED TO CREATE TARGETPLATFORM DIR: "${target_p_dir}

            case "${dep_file}" in
                *.bz2) tar jxf ${dep_file} -C ${target_p_dir} || exit_error "EXTRACTION FAILED" ;;
                *.gz) tar zxf ${dep_file} -C ${target_p_dir} || exit_error "EXTRACTION FAILED" ;;
                *) exit_error "UNPROCESSED FILE EXTENSION." ;;
            esac
            touch ${dep_already_extracted_marker}
        fi
        echo " Platform="${target_p}" processing done."
    done

done

echo "Dependencies fetch and extraction complete."


