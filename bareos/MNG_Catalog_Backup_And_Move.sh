#!/bin/sh
set -x

/usr/bin/perl /usr/lib/bareos/scripts/make_catalog_backup.pl MyCatalog
/bin/cp -v  /var/lib/bareos/*.sql /mnt/bareos_dump
/usr/bin/7z u -r /mnt/bareos_dump/config_files.zip /etc/bareos/*
/usr/bin/7z u -r /mnt/bareos_dump/scripts.zip /usr/lib/bareos/scripts/*
/usr/bin/rsync -altvhz /usr/lib/bareos/scripts/ /mnt/bareos_dump/scriptbackup/
