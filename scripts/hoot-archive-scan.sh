#!/bin/bash
set +euxo pipefail
HOOT_REPO="${HOOT_REPO:-$HOME/hootenanny}"

if [ ! -d $HOOT_REPO/.git ]; then
    echo 'Please checkout Hootenanny repository first.'
    exit 1
fi

pushd $HOOT_REPO
cp LocalConfig.pri.orig LocalConfig.pri


# TODO: Do we add `ccache` like in original `BuildArchive.sh`?
#echo "QMAKE_CXX=ccache g++" >> LocalConfig.pri

# Temporarily allow undefined variables to allow us to source `SetupEnv.sh`.
set +u
source SetupEnv.sh
set -u

source conf/database/DatabaseConfig.sh

#Generate configure script.
aclocal
autoconf
autoheader
automake --add-missing --copy

# Run configure, enable R&D, services, and PostgreSQL.
./configure --quiet --with-rnd --with-services 

# --with-services
# Update the license headers.
./scripts/copyright/UpdateAllCopyrightHeaders.sh

make -j$(nproc)

echo "Start Fortify"

/opt/hp_fortify_sca/bin/sourceanalyzer -b hootenanny_2018_4_23 make -j$(nproc)

echo "End Fortify"
# Perform the scan
/opt/hp_fortify_sca/bin/sourceanalyzer -b hootenanny_2018_4_23 -64 -Xmx24G -scan -f Hootenanny_Core_2018_4_23.fpr


# Make the archive.
#make -j$(nproc) clean
#make -j$(nproc) archive

# Move the second maven run here, to see if we can get past the cache issue
#make -j$(nproc) archive

# Copy in source archive to RPM sources.

#e#cho "Current location"
pwd

cp -v hootenanny-[0-9]*.tar.gz /rpmbuild/SOURCES 
ls -la
pwd
ls -la /root/SOURCES && ls -la /root && ls -la /rpmbuild
popd
