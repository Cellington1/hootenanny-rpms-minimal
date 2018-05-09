#!/bin/bash
set +euxo pipefail
HOOT_REPO="${HOOT_REPO:-$HOME/hootenanny}"

if [ ! -d $HOOT_REPO/.git ]; then
    echo 'Please checkout Hootenanny repository first.'
    exit 1
fi

pushd $HOOT_REPO
cp LocalConfig.pri.orig LocalConfig.pri

# Temporarily allow undefined variables to allow us to source `SetupEnv.sh`.
set +u
source SetupEnv.sh
set -u

source conf/database/DatabaseConfig.sh

# Start postgres
su-exec postgres pg_ctl -D /var/lib/pgsql/9.5/data -s start


#Generate configure script.
aclocal
autoconf
autoheader
automake --add-missing --copy

# Run configure, enable R&D, services, and PostgreSQL.
./configure --quiet --with-rnd --with-services 

# Update the license headers.
./scripts/copyright/UpdateAllCopyrightHeaders.sh

echo "Start Fortify"

echo "Clean the compiled job"
/opt/hp_fortify_sca/bin/sourceanalyzer -b hootenanny_2018_ATO -clean

echo "Compile hootenanny"
/opt/hp_fortify_sca/bin/sourceanalyzer -b hootenanny_2018_ATO  -logfile comp.log make -j$(nproc)

echo "Scan hootenanny"
/opt/hp_fortify_sca/bin/sourceanalyzer -b hootenanny_2018_ATO -64 -Xmx24G -logfile scan.log -scan -f Hootenanny_Core_2018_ATO.fpr

popd

