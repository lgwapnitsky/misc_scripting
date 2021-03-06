#!/bin/sh

# This script is intended to be sourced by
# bareos-database-common postinstall script
# on Debian based distributions.
# It helps to configure dbconfig
# when migrating to dbconfig.

LIB=/usr/lib/bareos/scripts/bareos-config-lib.sh

if ! [ -r "$LIB" ]; then
    echo "failed to read library $LIB" >&2
else
    . $LIB

    #dbc_dbserver=
    #dbc_dbport=
    dbname=`get_database_name bareos`
    dbuser=`get_database_user bareos`
    dbpass=`get_database_password`
    case "`get_database_driver`" in
        postgresql)
            dbtype="pgsql"
            ;;
        mysql)
            dbtype="mysql"
            ;;
        sqlite3)
            dbtype="sqlite3"
            basepath="`get_working_dir`"
            ;;
    esac
fi
