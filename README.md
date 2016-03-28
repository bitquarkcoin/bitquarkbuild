BitQuark Builder
====================

Copyright (c) 2014-2016 BitQuark Developers

BitQuark Dev Team ([bitquarkcoin@gmail.com](mailto:bitquarkcoin@gmail.com))


Intro
---------------------
BitQuark Builder is a free open source Cross-compiler for Linux to Windows 32bit and 64bit client.


Setup
--------------------
You need the follow libraries & applications installed to run BitQuark Builder. On Debian or Ubuntu:

`sudo apt-get install git-core pkg-config automake faketime bsdmainutils zip g++-mingw-w64 mingw-w64 autoconf libtool g++ nsis openssh-server cmake libcap-dev libz-dev libbz2-dev g++-multilib binutils-gold libstdc++6-4.6-pic libboost-all-dev`

Then you just need to change to the "bitquarkbuilder" directory and run the files in order as shown below from your Linux terminal:

`./1.env-setup.sh`

Once the Env. Setup has completed, then run the next file:

`./2.build-deps.sh`

And last run the final build file:

`./3.build-linux-mingw.sh`

Once everything has finished, you will see the Windows 32-bit Qt client, daemon, and Installer located in the "release-i686" folder.  The Windows 64-bit versions will be located in the "release-x86_64" folder.
