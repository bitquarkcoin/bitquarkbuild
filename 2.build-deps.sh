#!/usr/bin/env bash
#
# 2.build-deps.sh :
#
# Build project, including dependencies for given platform (1st argument)
# (for a list of valid platforms, see 1.env-setup.sh)
#

LINK=`readlink -f $0`
if [[ -z ${LINK} ]]; then
LINK=$0
fi
DIRNAME=`dirname ${LINK}`

RELEASE_VERSION="0.7.5"
SOURCE_DESTDIR=${DIRNAME}/dependencies
RELEASE_PUBLISH_DIR=releases
TARGET_PLATFORMS=("i686 x86_64")
WORKSPACE=${DIRNAME}

exit_error() {
    echo $1;
    exit 1;
}

for CUR_PLATFORM in ${TARGET_PLATFORMS}; do
    if [ -z ${CUR_PLATFORM} ]; then
        exit_error "NO target platform given."
    fi

    # ensure platform base directory exist:
    platform_src_dir=${SOURCE_DESTDIR}/$CUR_PLATFORM
    [ -d ${platform_src_dir} ] || exit_error "INVALID platform given, or missing platformdir"

    # quite ugly case...
    case "${CUR_PLATFORM}" in
        i686)
            echo "Building dependencies for i686 platform..."

            # qrencode
            # first check if we really want to rebuilt this (70 days old):
            need_rebuild=1
            if [ -f ${platform_src_dir}/qrencode-3.4.2/.libs/libqrencode.a ]; then
                echo "libqrencode.a already built, checking its oldness..."
                last_mtime=`stat -c "%Z" ${platform_src_dir}/qrencode-3.4.2/.libs/libqrencode.a`
                now_time=`date +"%s"`
                let now_time=now_time-6048000
                if [ ${last_mtime} -gt ${now_time} ]; then
                    echo "libqrencode.a generated less than 70 days ago, not rebuilding..."
                    need_rebuild=0
                fi

            fi
            if [ ${need_rebuild} -eq 1 ]; then
                echo "Building qrencode..."
                cd ${platform_src_dir}/qrencode-3.4.2/ || exit_error "Failed to change to qrencode-3.4.2/ dir"
                PATH=$PATH:/usr/i686-w64-mingw32/bin ./configure --host=i686-w64-mingw32 --prefix=/usr/i686-w64-mingw32 --disable-sdltest --without-tools --without-tests --enable-static --disable-shared || exit_error "configure failed"
                PATH=$PATH:/usr/i686-w64-mingw32/bin make || exit_error "make failed"
                if [ ! -f ${platform_src_dir}/qrencode-3.4.2/.libs/libqrencode.a ]; then
                    exit_error "UNABLE TO FIND generated libqrencode.a"
                fi
            fi

            # openssl
            # first check if we really want to rebuilt this (70 days old):
            need_rebuild=1
            if [ -f ${platform_src_dir}/openssl-1.0.1g/libcrypto.a ]; then
                echo "libcrypto.a already built, checking its oldness..."
                last_mtime=`stat -c "%Z" ${platform_src_dir}/openssl-1.0.1g/libcrypto.a`
                now_time=`date +"%s"`
                let now_time=now_time-6048000
                if [ ${last_mtime} -gt ${now_time} ]; then
                    echo "libcrypto.a generated less than 70 days ago, not rebuilding..."
                    need_rebuild=0
                fi

            fi
            if [ ${need_rebuild} -eq 1 ]; then
                echo "Building openssl..."
                cd ${platform_src_dir}/openssl-1.0.1g/ || exit_error "Failed to change to openssl-1.0.1g/ dir"
                CROSS_COMPILE="i686-w64-mingw32-" ./Configure mingw no-asm no-shared --prefix=/usr/i686-w64-mingw32 || exit_error "configure failed"
                PATH=$PATH:/usr/i686-w64-mingw32/bin make depend || exit_error "depend failed"
                PATH=$PATH:/usr/i686-w64-mingw32/bin make || exit_error "make failed"
                if [ ! -f ${platform_src_dir}/openssl-1.0.1g/libcrypto.a ]; then
                    exit_error "UNABLE TO FIND generated libcrypto.a"
                fi
            fi

            # berkeley DB
            need_rebuild=1
            if [ -f ${platform_src_dir}/db-4.8.30.NC/build_unix/libdb_cxx.a ]; then
                echo "libdb_cxx.a already built, checking its oldness..."
                last_mtime=`stat -c "%Z" ${platform_src_dir}/db-4.8.30.NC/build_unix/libdb_cxx.a`
                now_time=`date +"%s"`
                let now_time=now_time-6048000
                if [ ${last_mtime} -gt ${now_time} ]; then
                    echo "libdb_cxx.a generated less than 70 days ago, not rebuilding..."
                    need_rebuild=0
                fi
            fi
            if [ ${need_rebuild} -eq 1 ]; then
                echo "Building libdb_cxx..."
                cd ${platform_src_dir}/db-4.8.30.NC/build_unix/ || exit_error "Failed to chainge to db-4.8.30.NC/build_unix/ dir"
                sh ../dist/configure --host=i686-w64-mingw32 --disable-replication --enable-cxx --enable-mingw || exit_error "configure failed"
                make || exit_error "make failed"
                if [ ! -f ${platform_src_dir}/db-4.8.30.NC/build_unix/libdb_cxx.a ]; then
                    exit_error "UNABLE TO FIND generated libdb_cxx.a"
                fi
            fi

            # miniupnpc
            need_rebuild=1
            if [ -f ${platform_src_dir}/miniupnpc-1.9/libminiupnpc.a ]; then
                echo "libminiupnpc.a already built, checking its oldness..."
                last_mtime=`stat -c "%Z" ${platform_src_dir}/miniupnpc-1.9/libminiupnpc.a`
                now_time=`date +"%s"`
                let now_time=now_time-6048000
                if [ ${last_mtime} -gt ${now_time} ]; then
                    echo "libminiupnpc.a generated less than 70 days ago, not rebuilding..."
                    need_rebuild=0
                fi
            fi
            if [ ${need_rebuild} -eq 1 ]; then
                echo "Building miniupnpc..."
                cd ${platform_src_dir}/miniupnpc-1.9/ || exit_error "Failed to change to miniupnpc-1.9/ dir"
                sed -i 's/CC = gcc/CC = i686-w64-mingw32-gcc/' Makefile.mingw
#                sed -i 's/wingenminiupnpcstrings \$/wine \.\/wingenminiupnpcstrings \$/' Makefile.mingw
                sed -i '/\twingenminiupnpcstrings $< $@/d' Makefile.mingw
                echo "#ifndef __MINIUPNPCSTRINGS_H__" > miniupnpcstrings.h
                echo "#define __MINIUPNPCSTRINGS_H__" >> miniupnpcstrings.h
                echo "#define OS_STRING \"MSWindows/5.1.2600\"" >> miniupnpcstrings.h
                echo "#define MINIUPNPC_VERSION_STRING \"1.6\"" >> miniupnpcstrings.h
                echo "#endif" >> miniupnpcstrings.h
                
                sed -i 's/\tdllwrap/\ti686-w64-mingw32-dllwrap/' Makefile.mingw
                sed -i 's/driver-name gcc/driver-name i686-w64-mingw32-gcc/' Makefile.mingw
                AR=i686-w64-mingw32-ar make -f Makefile.mingw
                if [ ! -f ${platform_src_dir}/miniupnpc-1.9/libminiupnpc.a ]; then
                    exit_error "UNABLE TO FIND generated libminiupnpc.a"
                fi
            fi
            [ -h ${platform_src_dir}/miniupnpc ] || ln -s ${platform_src_dir}/miniupnpc-1.9 ${platform_src_dir}/miniupnpc
            
            # boost
            need_rebuild=1
            if [ -f ${platform_src_dir}/boost_1_55_0/stage/lib/libboost_system-mt.a ]; then
                echo "libboost_system-mt.a already built, checking its oldness..."
                last_mtime=`stat -c "%Z" ${platform_src_dir}/boost_1_55_0/stage/lib/libboost_system-mt.a`
                now_time=`date +"%s"`
                let now_time=now_time-6048000
                if [ ${last_mtime} -gt ${now_time} ]; then
                    echo "libboost_system-mt.a generated less than 70 days ago, not rebuilding..."
                    need_rebuild=0
                fi
            fi
            if [ ${need_rebuild} -eq 1 ]; then
                echo "Building boost..."
                cd ${platform_src_dir}/boost_1_55_0/ || exit_error "Failed to change to boost_1_55_0/ dir"
                ./bootstrap.sh --without-icu || exit_error "bootstrap failed"
                echo "using gcc : mingw32 : i686-w64-mingw32-g++ : <rc>i686-w64-mingw32-windres <archiver>i686-w64-mingw32-ar <ranlib>i686-w64-mingw32-ranlib ;" > user-config.jam
                ./bjam toolset=gcc target-os=windows variant=release threading=multi threadapi=win32 link=static runtime-link=static --prefix=/usr/i686-w64-mingw32 --user-config=user-config.jam -j 2 --without-mpi --without-python -sNO_BZIP2=1 --layout=tagged stage
            fi

            # qt
            need_rebuild=1
            if [ -f ${platform_src_dir}/qt/lib/libQtCore.a ]; then
                echo "libQtCore.a already built, checking its oldness..."
                last_mtime=`stat -c "%Z" ${platform_src_dir}/qt/lib/libQtCore.a`
                now_time=`date +"%s"`
                let now_time=now_time-6048000
                if [ ${last_mtime} -gt ${now_time} ]; then
                    echo "libQtCore.a generated less than 70 days ago, not rebuilding..."
                    need_rebuild=0
                fi
            fi

            if [ ${need_rebuild} -eq 1 ]; then
                echo "Patching qt.."
                cp ${DIRNAME}/patch/qt-patch.patch ${SOURCE_DESTDIR}/$CUR_PLATFORM/qt-everywhere-opensource-src-4.8.6/src/gui/dialogs/
                cd ${SOURCE_DESTDIR}/$CUR_PLATFORM/qt-everywhere-opensource-src-4.8.6/src/gui/dialogs/ || exit_error "Failed to change to qt source dir"
                cp qfiledialog.cpp qfiledialog.org.cpp
                patch < qt-patch.patch || exit_error "Patching Failed"
                echo "Patching completed!"
                echo "Building qt..."
                cd ${platform_src_dir}/qt-everywhere-opensource-src-4.8.6/ || exit_error "Failed to change to qt source dir"
                sed 's/$TODAY/2011-01-30/' -i configure
                sed 's/i686-pc-mingw32-/i686-w64-mingw32-/' -i mkspecs/unsupported/win32-g++-cross/qmake.conf
                sed --posix 's|QMAKE_CFLAGS\t\t= -pipe|QMAKE_CFLAGS\t\t= -pipe -isystem /usr/i686-w64-mingw32/include/ -frandom-seed=qtbuild|' -i mkspecs/unsupported/win32-g++-cross/qmake.conf
                sed 's/QMAKE_CXXFLAGS_EXCEPTIONS_ON = -fexceptions -mthreads/QMAKE_CXXFLAGS_EXCEPTIONS_ON = -fexceptions/' -i mkspecs/unsupported/win32-g++-cross/qmake.conf
                sed 's/QMAKE_LFLAGS_EXCEPTIONS_ON = -mthreads/QMAKE_LFLAGS_EXCEPTIONS_ON = -lmingwthrd/' -i mkspecs/unsupported/win32-g++-cross/qmake.conf
                sed --posix 's/QMAKE_MOC\t\t= i686-w64-mingw32-moc/QMAKE_MOC\t\t= moc/' -i mkspecs/unsupported/win32-g++-cross/qmake.conf
                sed --posix 's/QMAKE_RCC\t\t= i686-w64-mingw32-rcc/QMAKE_RCC\t\t= rcc/' -i mkspecs/unsupported/win32-g++-cross/qmake.conf
                sed --posix 's/QMAKE_UIC\t\t= i686-w64-mingw32-uic/QMAKE_UIC\t\t= uic/' -i mkspecs/unsupported/win32-g++-cross/qmake.conf

                [ -d ${platform_src_dir}/qt ] || mkdir ${platform_src_dir}/qt
                ./configure -prefix ${platform_src_dir}/qt -confirm-license -release -opensource -static -no-qt3support -xplatform unsupported/win32-g++-cross -no-multimedia -no-audio-backend -no-phonon -no-phonon-backend -no-declarative -no-script -no-scripttools -no-javascript-jit -no-webkit -no-svg -no-xmlpatterns -no-sql-sqlite -no-nis -no-cups -no-dbus -no-gif -no-libtiff -no-opengl -nomake examples -nomake demos -nomake docs -no-feature-style-plastique -no-feature-style-cleanlooks -no-feature-style-motif -no-feature-style-cde -no-feature-style-windowsce -no-feature-style-windowsmobile -no-feature-style-s60 || exit_error "configure failed"
                make || exit_error "make failed"
                make install || exit_error "make install failed"
            fi
        ;;

        x86_64)
            echo "Building dependencies for x86_64 platform..."

            # qrencode
            # first check if we really want to rebuilt this (70 days old):
            need_rebuild=1
            if [ -f ${platform_src_dir}/qrencode-3.4.2/.libs/libqrencode.a ]; then
                echo "libqrencode.a already built, checking its oldness..."
                last_mtime=`stat -c "%Z" ${platform_src_dir}/qrencode-3.4.2/.libs/libqrencode.a`
                now_time=`date +"%s"`
                let now_time=now_time-6048000
                if [ ${last_mtime} -gt ${now_time} ]; then
                    echo "libqrencode.a generated less than 70 days ago, not rebuilding..."
                    need_rebuild=0
                fi

            fi
            if [ ${need_rebuild} -eq 1 ]; then
                echo "Building qrencode..."
                cd ${platform_src_dir}/qrencode-3.4.2/ || exit_error "Failed to change to qrencode-3.4.2/ dir"
                PATH=$PATH:/usr/x86_64-w64-mingw32/bin ./configure --host=x86_64-w64-mingw32 --prefix=/usr/x86_64-w64-mingw32 --without-tools --enable-static --disable-shared || exit_error "configure failed"
                PATH=$PATH:/usr/x86_64-w64-mingw32/bin make || exit_error "make failed"
                if [ ! -f ${platform_src_dir}/qrencode-3.4.2/.libs/libqrencode.a ]; then
                    exit_error "UNABLE TO FIND generated libqrencode.a"
                fi
            fi

            # openssl
            # first check if we really want to rebuilt this (70 days old):
            need_rebuild=1
            if [ -f ${platform_src_dir}/openssl-1.0.1g/libcrypto.a ]; then
                echo "libcrypto.a already built, checking its oldness..."
                last_mtime=`stat -c "%Z" ${platform_src_dir}/openssl-1.0.1g/libcrypto.a`
                now_time=`date +"%s"`
                let now_time=now_time-6048000
                if [ ${last_mtime} -gt ${now_time} ]; then
                    echo "libcrypto.a generated less than 70 days ago, not rebuilding..."
                    need_rebuild=0
                fi

            fi
            if [ ${need_rebuild} -eq 1 ]; then
                echo "Building openssl..."
                cd ${platform_src_dir}/openssl-1.0.1g/ || exit_error "Failed to change to openssl-1.0.1g/ dir"
                CROSS_COMPILE="x86_64-w64-mingw32-" ./Configure mingw64 no-asm no-shared --prefix=/usr/x86_64-w64-mingw32 || exit_error "configure failed"
                PATH=$PATH:/usr/x86_64-w64-mingw32/bin make depend || exit_error "depend failed"
                PATH=$PATH:/usr/x86_64-w64-mingw32/bin make || exit_error "make failed"
                if [ ! -f ${platform_src_dir}/openssl-1.0.1g/libcrypto.a ]; then
                    exit_error "UNABLE TO FIND generated libcrypto.a"
                fi
            fi

            # berkeley DB
            need_rebuild=1
            if [ -f ${platform_src_dir}/db-4.8.30.NC/build_unix/libdb_cxx.a ]; then
                echo "libdb_cxx.a already built, checking its oldness..."
                last_mtime=`stat -c "%Z" ${platform_src_dir}/db-4.8.30.NC/build_unix/libdb_cxx.a`
                now_time=`date +"%s"`
                let now_time=now_time-6048000
                if [ ${last_mtime} -gt ${now_time} ]; then
                    echo "libdb_cxx.a generated less than 70 days ago, not rebuilding..."
                    need_rebuild=0
                fi
            fi
            if [ ${need_rebuild} -eq 1 ]; then
                echo "Building libdb_cxx..."
                cd ${platform_src_dir}/db-4.8.30.NC/build_unix/ || exit_error "Failed to chainge to db-4.8.30.NC/build_unix/ dir"
                sh ../dist/configure --host=x86_64-w64-mingw32 --disable-replication --enable-cxx --enable-mingw || exit_error "configure failed"
                make || exit_error "make failed"
                if [ ! -f ${platform_src_dir}/db-4.8.30.NC/build_unix/libdb_cxx.a ]; then
                    exit_error "UNABLE TO FIND generated libdb_cxx.a"
                fi
            fi

            # miniupnpc
            need_rebuild=1
            if [ -f ${platform_src_dir}/miniupnpc-1.9/libminiupnpc.a ]; then
                echo "libminiupnpc.a already built, checking its oldness..."
                last_mtime=`stat -c "%Z" ${platform_src_dir}/miniupnpc-1.9/libminiupnpc.a`
                now_time=`date +"%s"`
                let now_time=now_time-6048000
                if [ ${last_mtime} -gt ${now_time} ]; then
                    echo "libminiupnpc.a generated less than 70 days ago, not rebuilding..."
                    need_rebuild=0
                fi
            fi
            if [ ${need_rebuild} -eq 1 ]; then
                echo "Building miniupnpc..."
                cd ${platform_src_dir}/miniupnpc-1.9/ || exit_error "Failed to change to miniupnpc-1.9/ dir"
                sed -i 's/CC = gcc/CC = x86_64-w64-mingw32-gcc/' Makefile.mingw
#                sed -i 's/wingenminiupnpcstrings \$/wine \.\/wingenminiupnpcstrings \$/' Makefile.mingw
                sed -i '/\twingenminiupnpcstrings $< $@/d' Makefile.mingw
                echo "#ifndef __MINIUPNPCSTRINGS_H__" > miniupnpcstrings.h
                echo "#define __MINIUPNPCSTRINGS_H__" >> miniupnpcstrings.h
                echo "#define OS_STRING \"MSWindows/5.1.2600\"" >> miniupnpcstrings.h
                echo "#define MINIUPNPC_VERSION_STRING \"1.6\"" >> miniupnpcstrings.h
                echo "#endif" >> miniupnpcstrings.h
                
                sed -i 's/\tdllwrap/\tx86_64-w64-mingw32-dllwrap/' Makefile.mingw
                sed -i 's/driver-name gcc/driver-name x86_64-w64-mingw32-gcc/' Makefile.mingw
                AR=x86_64-w64-mingw32-ar make -f Makefile.mingw
                if [ ! -f ${platform_src_dir}/miniupnpc-1.9/libminiupnpc.a ]; then
                    exit_error "UNABLE TO FIND generated libminiupnpc.a"
                fi
            fi
            [ -h ${platform_src_dir}/miniupnpc ] || ln -s ${platform_src_dir}/miniupnpc-1.9 ${platform_src_dir}/miniupnpc
            
            # boost
            need_rebuild=1
            if [ -f ${platform_src_dir}/boost_1_55_0/stage/lib/libboost_system-mt.a ]; then
                echo "libboost_system-mt.a already built, checking its oldness..."
                last_mtime=`stat -c "%Z" ${platform_src_dir}/boost_1_55_0/stage/lib/libboost_system-mt.a`
                now_time=`date +"%s"`
                let now_time=now_time-6048000
                if [ ${last_mtime} -gt ${now_time} ]; then
                    echo "libboost_system-mt.a generated less than 70 days ago, not rebuilding..."
                    need_rebuild=0
                fi
            fi
            if [ ${need_rebuild} -eq 1 ]; then
                echo "Building boost..."
                cd ${platform_src_dir}/boost_1_55_0/ || exit_error "Failed to change to boost_1_55_0/ dir"
                ./bootstrap.sh --without-icu || exit_error "bootstrap failed"
                echo "using gcc : mingw32 : x86_64-w64-mingw32-g++ : <rc>x86_64-w64-mingw32-windres <archiver>x86_64-w64-mingw32-ar ;" > user-config.jam
                ./bjam toolset=gcc address-model=64 target-os=windows variant=release threading=multi threadapi=win32 link=static runtime-link=static --prefix=/usr/x86_64-w64-mingw32 --user-config=user-config.jam -j 2 --without-mpi --without-python -sNO_BZIP2=1 --layout=tagged stage stage
            fi

            # qt
            need_rebuild=1
            if [ -f ${platform_src_dir}/qt/lib/libQtCore.a ]; then
                echo "libQtCore.a already built, checking its oldness..."
                last_mtime=`stat -c "%Z" ${platform_src_dir}/qt/lib/libQtCore.a`
                now_time=`date +"%s"`
                let now_time=now_time-6048000
                if [ ${last_mtime} -gt ${now_time} ]; then
                    echo "libQtCore.a generated less than 70 days ago, not rebuilding..."
                    need_rebuild=0
                fi
            fi

            if [ ${need_rebuild} -eq 1 ]; then
                echo "Patching qt.."
                cp ${DIRNAME}/patch/qt-patch.patch ${SOURCE_DESTDIR}/$CUR_PLATFORM/qt-everywhere-opensource-src-4.8.6/src/gui/dialogs/
                cd ${SOURCE_DESTDIR}/$CUR_PLATFORM/qt-everywhere-opensource-src-4.8.6/src/gui/dialogs/ || exit_error "Failed to change to qt source dir"
                cp qfiledialog.cpp qfiledialog.org.cpp
                patch < qt-patch.patch || exit_error "Patching Failed"
                echo "Patching completed!"
                echo "Building qt..."
                cd ${platform_src_dir}/qt-everywhere-opensource-src-4.8.6/ || exit_error "Failed to change to qt source dir"
                sed 's/$TODAY/2011-01-30/' -i configure
                sed 's/i686-pc-mingw32-/x86_64-w64-mingw32-/' -i mkspecs/unsupported/win32-g++-cross/qmake.conf
                sed --posix 's|QMAKE_CFLAGS\t\t= -pipe|QMAKE_CFLAGS\t\t= -pipe -isystem /usr/x86_64-w64-mingw32/include/ -frandom-seed=qtbuild|' -i mkspecs/unsupported/win32-g++-cross/qmake.conf
                sed 's/QMAKE_CXXFLAGS_EXCEPTIONS_ON = -fexceptions -mthreads/QMAKE_CXXFLAGS_EXCEPTIONS_ON = -fexceptions/' -i mkspecs/unsupported/win32-g++-cross/qmake.conf
                sed 's/QMAKE_LFLAGS_EXCEPTIONS_ON = -mthreads/QMAKE_LFLAGS_EXCEPTIONS_ON = -lmingwthrd/' -i mkspecs/unsupported/win32-g++-cross/qmake.conf
                sed --posix 's/QMAKE_MOC\t\t= x86_64-w64-mingw32-moc/QMAKE_MOC\t\t= moc/' -i mkspecs/unsupported/win32-g++-cross/qmake.conf
                sed --posix 's/QMAKE_RCC\t\t= x86_64-w64-mingw32-rcc/QMAKE_RCC\t\t= rcc/' -i mkspecs/unsupported/win32-g++-cross/qmake.conf
                sed --posix 's/QMAKE_UIC\t\t= x86_64-w64-mingw32-uic/QMAKE_UIC\t\t= uic/' -i mkspecs/unsupported/win32-g++-cross/qmake.conf

                [ -d ${platform_src_dir}/qt ] || mkdir ${platform_src_dir}/qt
		cd ../qt
                ../qt-everywhere-opensource-src-4.8.6/configure -prefix ${platform_src_dir}/qt -confirm-license -release -opensource -static -no-qt3support -xplatform unsupported/win32-g++-cross -no-multimedia -no-audio-backend -no-phonon -no-phonon-backend -no-declarative -no-script -no-scripttools -no-javascript-jit -no-webkit -no-svg -no-xmlpatterns -no-sql-sqlite -no-nis -no-cups -no-dbus -no-gif -no-libtiff -no-opengl -nomake examples -nomake demos -nomake docs -no-feature-style-plastique -no-feature-style-cleanlooks -no-feature-style-motif -no-feature-style-cde -no-feature-style-windowsce -no-feature-style-windowsmobile -no-feature-style-s60 || exit_error "configure failed"
                make || exit_error "make failed"
                make install || exit_error "make install failed"
            fi
        ;;


        *)
            exit_error "Not Yet Implemented"
        ;;
    esac

done
