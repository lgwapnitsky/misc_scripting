#!/bin/sh
#
# Copyright 2006-2011 Dan Langille
#
# This script should be read in conjunction with
# http://www.freebsddiary.org/tape-testing.php
#

# Change this to the location of your script
#
#MTX="/usr/local/sbin/mtx-changer"
MTX="/usr/lib/bareos/scripts/mtx-changer"

CHANGER="/dev/${1}"
DRIVE="/dev/${2}"

LOGGER=/usr/bin/logger
ECHO=/bin/echo

SLOTS="1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45"

for slot in $SLOTS
do
    ${ECHO} loading $slot
    ${MTX} ${CHANGER} load $slot ${DRIVE} 0

    mt -f ${DRIVE} rewind
    mt -f ${DRIVE} weof
    mt -f ${DRIVE} rewind

    # now label that slot
    echo | bconsole <<EOF
label barcodes pool=Scratch storage=OverlandNEO_Changer slot=${slot} drive=0
yes
wait
EOF

    echo 'umount storage=OverlandNEO_Changer' | bconsole

    ${ECHO} unloading $slot
    ${MTX} ${CHANGER} unload $slot ${DRIVE} 0
    
done
