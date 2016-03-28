#!/usr/bin/env bash
#

LINK=`readlink -f $0`
if [[ -z ${LINK} ]]; then
LINK=$0
fi
DIRNAME=`dirname ${LINK}`

exit_error() {
    echo $1;
    exit 1;
}

procParmL()
{ 
   [ -z "$1" ] && return 1 
   if [ "${2#$1=}" != "$2" ] ; then 
      cRes="${2#$1=}" 
      return 0 
   fi 
   return 1 
}

while [ 1 ] ; do 
   if procParmL "--threads" "$1" ; then 
      THREADS="$cRes" 
   elif [ -z "$1" ] ; then 
      break
   else 
      exit_error "Error: Invalid key"
   fi 
   shift 
done

if [ "${!THREADS[@]}" ]; then
    JOB_FLAG="-j"
    if [ $THREADS ]; then
        echo "Build using $THREADS threads"
    else
        echo "Build using MAX threads"
    fi
else
    echo "Build using single thread."
fi

RELEASE_VERSION="0.7.4.5"
SOURCE_DESTDIR=${DIRNAME}/dependencies
RELEASE_PUBLISH_DIR=releases
TARGET_PLATFORMS=("i686 x86_64")
WORKSPACE=${DIRNAME}

for CUR_PLATFORM in ${TARGET_PLATFORMS}; do
    if [ -z ${CUR_PLATFORM} ]; then
        exit_error "NO target platform given."
    fi

    # ensure platform base directory exist:
    platform_src_dir=${SOURCE_DESTDIR}/$CUR_PLATFORM
    [ -d ${platform_src_dir} ] || exit_error "INVALID platform given, or missing platformdir"

    mkdir -p ${WORKSPACE}/release-i686
    mkdir -p ${WORKSPACE}/release-x86_64
    
    # quite ugly case...
    case "${CUR_PLATFORM}" in
        i686)
            rm -f ${WORKSPACE}/release-i686/BitQuark-Qt.exe
            rm -f ${WORKSPACE}/release-i686/bitquarkd.exe

            # fetching BitQuark source code
	    echo " Fetching BitQuark source code.."
            git clone https://github.com/bitquarkcoin/BitQuark-0.8.3r20.git bitquark-i686
	    git clone https://github.com/bitquarkcoin/BitQuark-0.8.3r20.git bitquark-x86_64
            
            # patch qt
            echo "Patching bitquark-qt.."
            cp ${WORKSPACE}/patch/bitquark-qt.patch ${WORKSPACE}/bitquark-i686
            cp ${WORKSPACE}/patch/compat.patch ${WORKSPACE}/bitquark-i686/src
            cp ${WORKSPACE}/patch/bitcoingui-32bit.patch ${WORKSPACE}/bitquark-i686/src/qt
            cd ${WORKSPACE}/bitquark-i686 || exit_error "Failed to change to bitquark-qt dir"
            cp bitquark-qt.pro bitquark-qt.pro.org
            patch < bitquark-qt.patch || exit_error "BitQuark-Qt Patching Failed"
            cd ${WORKSPACE}/bitquark-i686/src || exit_error "Failed to change to bitquark-qt/src dir"
            cp compat.h compat.org.h
            patch < compat.patch || exit_error "BitQuark-Qt/src Patching Failed"
            cd ${WORKSPACE}/bitquark-i686/src/qt || exit_error "Failed to change to bitquark-qt/src/qt dir"
            cp bitcoingui.cpp bitcoingui.org.cpp
            patch < bitcoingui-32bit.patch || exit_error "BitQuark-Qt/src/qt Patching Failed"
            echo "Patching completed!"

            # qt client:
            echo "Building bitquark qt 32bit client..."
            cd ${WORKSPACE} || exit_error "Failed to change to workspace dir"
            #make distclean
            #make -C bitquark-i686 -f Makefile.Release clean
            make -C bitquark-i686/src -f makefile.unix clean
            make -C bitquark-i686/src -f makefile.linux-mingw clean
            echo "goto ${WORKSPACE}"
	    cd ${WORKSPACE}/bitquark-i686/src/leveldb
	    chmod +x build_detect_platform || exist_error "Failed to make LevelDB executable"
            cd ${WORKSPACE}/bitquark-i686 || exit_error "Failed to change to workspace dir"
            PATH=${platform_src_dir}/qt/bin:$PATH ${platform_src_dir}/qt/bin/qmake -makefile -spec unsupported/win32-g++-cross MINIUPNPC_LIB_PATH=${platform_src_dir}/miniupnpc-1.6 MINIUPNPC_INCLUDE_PATH=${platform_src_dir} BDB_LIB_PATH=${platform_src_dir}/db-4.8.30.NC/build_unix BDB_INCLUDE_PATH=${platform_src_dir}/db-4.8.30.NC/build_unix BOOST_LIB_PATH=${platform_src_dir}/boost_1_55_0/stage/lib BOOST_INCLUDE_PATH=${platform_src_dir}/boost_1_55_0 BOOST_LIB_SUFFIX=-mt-s BOOST_THREAD_LIB_SUFFIX=_win32-mt-s OPENSSL_LIB_PATH=${platform_src_dir}/openssl-1.0.1g OPENSSL_INCLUDE_PATH=${platform_src_dir}/openssl-1.0.1g/include QRENCODE_LIB_PATH=${platform_src_dir}/qrencode-3.4.2/.libs QRENCODE_INCLUDE_PATH=${platform_src_dir}/qrencode-3.4.2 USE_UPNP=1 USE_QRCODE=1 INCLUDEPATH=${platform_src_dir} DEFINES=BOOST_THREAD_USE_LIB QMAKE_LRELEASE=lrelease USE_BUILD_INFO=1 BITCOIN_NEED_QT_PLUGINS=1 RELEASE=1 USE_LEVELDB=1 || exit_error "qmake failed"
            PATH=${platform_src_dir}/qt/bin:$PATH make $JOB_FLAG $THREADS || exit_error "Make failed"
            cp -f ${WORKSPACE}/bitquark-i686/release/BitQuark-Qt.exe ${WORKSPACE}/release-i686

            # bitquark headless daemon:
            echo "Building bitquark headless daemon..."
            cd ${WORKSPACE}/bitquark-i686/src/ || exit_error "Failed to change to bitquark src/"
            #make distclean
            make -f makefile.unix clean
            make -f makefile.linux-mingw clean
            cd ${WORKSPACE}/bitquark-i686/src/ || exit_error "Failed to change to src/"
            export MINGW_EXTRALIBS_DIR=${platform_src_dir}
            make $JOB_FLAG $THREADS -f makefile.linux-mingw USE_LEVELDB=1 DEPSDIR=${platform_src_dir} || exit_error "make failed"
            i686-w64-mingw32-strip bitquarkd.exe || exit_error "strip failed"
            [ -f ${WORKSPACE}/bitquark-i686/src/bitquarkd.exe ] || exit_error "UNABLE to find generated bitquarkd.exe"
            echo "bitquarkd i686 compile success."
            cp -f ${WORKSPACE}/bitquark-i686/src/bitquarkd.exe ${WORKSPACE}/release-i686
            echo "Building bitquark 32-bit installer..."
            cd ${WORKSPACE}/bitquark-i686/share/ || exit_error "Failed to change to share/"
            makensis ./setup-win32.nsi || exit_error "Failed to build installer"
            cp -f ${WORKSPACE}/bitquark-i686/share/BitQuark-0.8.3.20-win32-setup.exe ${WORKSPACE}/release-i686 || exit_error "Failed to copy installer"

        ;;

        x86_64)
            rm -f ${WORKSPACE}/release-x86_64/BitQuark-Qt.exe
            rm -f ${WORKSPACE}/release-x86_64/bitquarkd.exe
            
            # patch qt
            echo "Patching bitquark-qt.."
            cp ${WORKSPACE}/patch/bitquark-qt.patch ${WORKSPACE}/bitquark-x86_64
            cp ${WORKSPACE}/patch/compat.patch ${WORKSPACE}/bitquark-x86_64/src
            cp ${WORKSPACE}/patch/bitcoingui-64bit.patch ${WORKSPACE}/bitquark-x86_64/src/qt
            cd ${WORKSPACE}/bitquark-x86_64 || exit_error "Failed to change to bitquark-qt dir"
            cp bitquark-qt.pro bitquark-qt.pro.org
            patch < bitquark-qt.patch || exit_error "BitQuark-Qt Patching Failed"
            cd ${WORKSPACE}/bitquark-x86_64/src || exit_error "Failed to change to bitquark-qt/src dir"
            cp compat.h compat.org.h
            patch < compat.patch || exit_error "BitQuark-Qt/src Patching Failed"
            cd ${WORKSPACE}/bitquark-x86_64/src/qt || exit_error "Failed to change to bitquark-qt/src/qt dir"
            cp bitcoingui.cpp bitcoingui.org.cpp
            patch < bitcoingui-64bit.patch || exit_error "BitQuark-Qt/src/qt Patching Failed"
            echo "Patching completed!"

            # qt client:
            echo "Building bitquark qt 64bit client..."
            cd ${WORKSPACE} || exit_error "Failed to change to workspace dir"
            #make distclean
            make -C bitquark-x86_64 -f Makefile.Release clean
            make -C bitquark-x86_64/src -f makefile.unix clean
            make -C bitquark-x86_64/src -f makefile.linux-mingw64 clean
            echo "goto ${WORKSPACE}"
	    cd ${WORKSPACE}/bitquark-x86_64/src/leveldb
	    chmod +x ./build_detect_platform || exist_error "Failed to make LevelDB executable"
            cd ${WORKSPACE}/bitquark-x86_64 || exit_error "Failed to change to workspace dir"
            PATH=${WORKSPACE}/dependencies/x86_64/qt/bin:$PATH ${WORKSPACE}/dependencies/x86_64/qt/bin/qmake -makefile -spec unsupported/win32-g++-cross MINIUPNPC_LIB_PATH=${WORKSPACE}/dependencies/x86_64/miniupnpc-1.6 MINIUPNPC_INCLUDE_PATH=${WORKSPACE}/dependencies/x86_64 BDB_LIB_PATH=${WORKSPACE}/dependencies/x86_64/db-4.8.30.NC/build_unix BDB_INCLUDE_PATH=${WORKSPACE}/dependencies/x86_64/db-4.8.30.NC/build_unix BOOST_LIB_PATH=${WORKSPACE}/dependencies/x86_64/boost_1_55_0/stage/lib BOOST_INCLUDE_PATH=${WORKSPACE}/dependencies/x86_64/boost_1_55_0 BOOST_LIB_SUFFIX=-mt-s BOOST_THREAD_LIB_SUFFIX=_win32-mt-s OPENSSL_LIB_PATH=${WORKSPACE}/dependencies/x86_64/openssl-1.0.1g OPENSSL_INCLUDE_PATH=${WORKSPACE}/dependencies/x86_64/openssl-1.0.1g/include QRENCODE_LIB_PATH=${WORKSPACE}/dependencies/x86_64/qrencode-3.4.2/.libs QRENCODE_INCLUDE_PATH=${WORKSPACE}/dependencies/x86_64/qrencode-3.4.2 USE_UPNP=1 USE_QRCODE=1 INCLUDEPATH=${WORKSPACE}/dependencies/x86_64 DEFINES=BOOST_THREAD_USE_LIB QMAKE_LRELEASE=lrelease USE_BUILD_INFO=1 BITCOIN_NEED_QT_PLUGINS=1 RELEASE=1 || exit_error "qmake failed"
            PATH=${WORKSPACE}/dependencies/x86_64/qt/bin:$PATH make $JOB_FLAG $THREADS || exit_error "Make failed"
            cp -f ${WORKSPACE}/bitquark-x86_64/release/BitQuark-Qt.exe ${WORKSPACE}/release-x86_64

            # bitquark headless daemon:
            echo "Building bitquark x86_64 headless daemon..."
            cd ${WORKSPACE}/bitquark-x86_64/src/ || exit_error "Failed to change to bitquark src/"
            #make distclean
            make -f makefile.unix clean
            make -f makefile.linux-mingw64 clean
            cd ${WORKSPACE}/bitquark-x86_64/src/ || exit_error "Failed to change to src/"
            export MINGW_EXTRALIBS_DIR=${WORKSPACE}/dependencies/x86_64
            make $JOB_FLAG $THREADS -f makefile.linux-mingw64 DEPSDIR=${WORKSPACE}/dependencies/x86_64 TARGET_PLATFORM=x86_64 || exit_error "make failed"
            x86_64-w64-mingw32-strip bitquarkd.exe || exit_error "strip failed"
            [ -f ${WORKSPACE}/bitquark-x86_64/src/bitquarkd.exe ] || exit_error "UNABLE to find generated bitquarkd.exe"
            echo "bitquarkd x86_64 compile success."
            cp -f ${WORKSPACE}/bitquark-x86_64/src/bitquarkd.exe ${WORKSPACE}/release-x86_64
            echo "Building bitquark 64-bit installer..."
            cd ${WORKSPACE}/bitquark-x86_64/share/ || exit_error "Failed to change to share/"
            makensis ./setup-win64.nsi || exit_error "Failed to build installer"
            cp -f ${WORKSPACE}/bitquark-x86_64/share/BitQuark-0.8.3.20-win64-setup.exe ${WORKSPACE}/release-x86_64 || exit_error "Failed to copy installer"

        ;;


        *)
            exit_error "Not Yet Implemented"
        ;;
    esac

done

