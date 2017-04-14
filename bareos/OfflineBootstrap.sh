#!/bin/bash
#
# waa - 20150704 - Initial Release
#                - A simple script that tars all of the bootstrap files
#                  and uses the "sendEmail" program to email the tar file
#                  to our helpdesk after the catalog backup job.
#                - This script may be called manually, by a cron job, or
#                  in a RunScript (RunsWhen = after) resource in the
#                  Bacula catalog backup job.
# waa - 20160320 - Used ${servername} variable in the ${tgzfile} filename variable
#                - Added support for multiple directories ${dirs}
# -----------------------------------------------------------------------
#
#
# By: William A. Arlofski
#     Reverse Polarity, LLC
#     http://www.revpol.com/bacula
#     office: 860-824-2433
#
#
#
# Sample RunScript stanza in the Catalog backup job resource
# ----------------------------------------------------------
#       # waa - 20150627 - Email all BSR files to helpdesk, append %i so
#       #                  that the JobId can be listed in the email that
#       #                  is sent to our helpdesk
#       # ---------------------------------------------------------------
#       RunScript {
#         RunsWhen = after
#         RunsOnClient = no
#         RunsOnFailure = yes # May as well email a copy of bootstrap files
#         FailJobOnError = yes # Admin will be notified to check into issue
#         Command = "/etc/bacula/include/scripts/email_bsr_files.sh %i"
#       }
#
# -------------------------------------------------------------------------
# Copyright (C) 2015 William A. Arlofski - waa-at-revpol-dot-com
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License, version 2, as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
# or visit http://www.gnu.org/licenses/gpl.txt
# -------------------------------------------------------------------------

# Do a simple check for a JobId
# -----------------------------
if [ -z $1 ]; then
    echo "Please submit a jobid as the first parameter."
    echo "This is only used in the Subject of the email generated"
    exit
fi

# Set some variables
# ------------------
now=$(date +"%Y%m%d-%H%M%S")
#servername="Revpol"
servername="BSPRDBAK01"
#from="backups@example.com"
from="Bareos_no-reply@mngdirect.com"
#to="backups@example.com"
to="larry.wapnitsky@mngdirect.com"

#dirs="/var/lib/bacula/bootstrap_files"
dirs="/mnt/bareos_dump/bootstraps"
tgzfile="/tmp/${servermame}-bacula-bsr_files-jobid${1}-${now}.tgz"
tgzlisting=$(tar -cvzf ${tgzfile} ${dirs})

# Send the tar file and listing via sendEmail program
# ---------------------------------------------------
sendEmail -s vfprdlnx01.mngdirect.com -f ${from} -t ${to} -u "${servername} - Bootstrap Files JobId=${1}" \
	  -m "${servername} - Bootstrap files as of ${now}\n\nFrom Directories: \
${dirs}\n\nListing of tgz file \"${tgzfile}\"\n----8<----\n${tgzlisting}\n----8<----\n" \
	  -a ${tgzfile} -o tls=no

err="$?"

# If there is a problem mailing tgz file exit with error to cause the job to fail
# and leave the tgz file around for an admin to take a look at or to manually copy
# --------------------------------------------------------------------------------
if [ ${err} -ne 0 ]; then
    echo "There was a problem emailing BSR files. sendEmail exit code was '${err}'."
    echo "Leaving ${tgzfile} in place."
else
    rm ${tgzfile}
fi

echo "--[ $0 script exit code ${err} ]--"
exit ${err}
