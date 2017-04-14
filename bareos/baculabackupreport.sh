#!/bin/bash
#
# baculabackupreport.sh
#
# waa - 20130428 - Generate basic Bacula backup report
# ----------------------------------------------------
#
# ----------------------------
# William A. Arlofski
# Reverse Polarity, LLC
# 860-824-2433 Office
# helpdesk@revpol.com
# http://www.revpol.com/bacula
# ----------------------------
#
# History
# -------
# 20130428 - Initial release
#            Generate and email basic Bacula backup reports
#            1st command line parameter is expected to be a
#            number of hours. No real error checking is done
#
# 20131224 - Removed "AND JobStatus='T'" to get all backup jobs
#            whether running, or completed with errors etc.
#          - Added Several fields "StartTime", "EndTime",
#            "JobFiles"
#          - Removed "JobType" because we are only selecting
#            jobs of type "Backup" (AND Type='B')
#          - Modified header lines and printf lines for better
#            formatting
#
# 20140107 - Modified script to include more information and cleaned
#            up the output formatting
#
# 20150704 - Added ability to work with MySQL or Postgresql
#
# 20150723 - Modified query, removed "Type='B'" clause to catch all jobs,
#            including Copy jobs, Admin jobs etc. Modified header, and
#            output string to match new query and include job's "Type"
#            column.
#
# 20170225 - Rewrote awk script so that a status/summary could be set in
#            the email report's subject. eg:
#            Subject: "serverName - All Jobs OK in the past x hours"
#            Subject: "serverName - x Jobs FAILED in the past y hours"
#
# 20170303 - Fixed output in cases where three are jobs running and there
#            is no "Stop Time" for a job.
#
# -------------------------------------------------------------------------
# Copyright (C) 2017 William A. Arlofski - waa-at-revpol-dot-com
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


# System variables
# ----------------
server="bsprdbak01"
admin="bacula_admin@mngdirect.com"
bcbin="/usr/sbin/bconsole"
sendmail="/usr/sbin/sendmail"
bcconfig="/etc/bareos/bconsole.conf"

# Database variables
# ------------------
dbtype="pgsql"
dbbin="/usr/bin/psql"
db="bareos"
dbuser="bareos"
# Uncomment and set db password if one is used
dbpass="Paradox."

# --------------------------------------------------
# Nothing should need to be modified below this line
# --------------------------------------------------

hist=${1}
if [ -z ${hist} ]; then
	echo "USE:"
	echo "$0 <history in hours>"
	exit
fi

header="
Backup History for the past ${1} hours
------------------------------------

JobId        Name           Start Time            Stop Time       Type  Level  Status   Files       Bytes
-----   --------------  -------------------  -------------------  ----  -----  ------  --------  -----------
"

# Build query based on dbtype. Good thing we have "standards"  sigh...
# --------------------------------------------------------------------
case ${dbtype} in
	mysql )
		query=$(echo "SELECT JobId, Name, StartTime, EndTime, Type, Level, JobStatus, JobFiles, JobBytes \
		FROM Job \
		WHERE RealEndTime >= DATE_ADD(NOW(), INTERVAL -${hist} HOUR) \
		ORDER BY JobID;" \
		| ${dbbin} ${db} -u ${dbuser} ${dbpass} \
		| sed '/^JobId/d' )
		;;

	pgsql )
		query=$(echo "SELECT JobId, Name, StartTime, EndTime, Type, Level, JobStatus, JobFiles, JobBytes \
		FROM Job \
		WHERE (RealEndTime >= CURRENT_TIMESTAMP(2) - cast('${hist} HOUR' as INTERVAL) OR JobStatus='R') \
		ORDER BY JobId;" \
		| ${dbbin} ${db} -U ${dbuser} ${dbpass}  -0t \
		| sed -e 's/|//g' -e '/^$/d' )
		;;

	* )
		echo "dbtype of '${dbtype}' invalid. Please set dbtype variable to 'mysql' or 'pgsql'"
		exit 1
		;;
esac

IFS=" "
msg=$(echo ${query} | \
awk 'BEGIN	{ awkerr = 0 }
						{ if ($7 == "R")
							{
								$11 = $9;
								$10 = $8;
								$9 = $7;
								$8 = $6;
								$7 = $5;
								$5 = "--=Still";
								$6 = "Running=-- ";
							}
						}
						{ printf("%-7s %-15s %s %-9s %s %-9s %4s %6s %7s %9d %9.2f GB\n", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11/(1024*1024*1024)); }
						{ if ($9 != "T" && $9 != "R")
							{ awkerr++ }
						}
END {exit awkerr}')

errors=$?

# Totally unnecessary, but, well...  OCD... :)
# --------------------------------------------
if [ ${errors} -ne 0 ]; then
	if [ ${errors} -eq 1 ]; then
		plural=""
			else
				plural="s"
	fi
	status="(${errors}) Job${plural} FAILED"
		else
			status="All Jobs OK"
fi

subject="Subject: $server - ${status} in the past ${1} hours"
echo "${subject} ${header}${msg}" | ${sendmail} -f ${admin} ${admin}

