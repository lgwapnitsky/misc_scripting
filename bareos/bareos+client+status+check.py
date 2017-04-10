
# coding: utf-8

# In[19]:

import os
import sys
import re
import bareos.bsock
import psycopg2
import psycopg2.extras
import nmap

from datetime import timedelta, datetime, date, time


# In[20]:

def confFileList():
    ## Import workstation/laptop config files, remove .conf extension, sort alphabetically
    
    clientPath = '/etc/bareos/bareos-dir.d/client/'
    compRX = re.compile(r'(?i)(^.*(\-(wks|lt))\.conf$)', re.MULTILINE)

    file_list = next(os.walk(clientPath))[2]
    file_list = [ file.split('.',1)[0] for file in file_list if re.match(compRX, file) ]
    file_list.sort()
    return file_list


# In[21]:

def NMScan(client):
    ## scan the specified client to see if port 9102 (bareos) is open
    ## return the state
    
    nm = nmap.PortScanner()
    nm_args = '-Pn -sT -p 9102'

    nm.scan(hosts=client, arguments=nm_args)
   
    try:
        host = nm.all_hosts()[0]
        proto = nm[host].all_protocols()[0]
        lport = nm[host][proto].keys()
        port = lport[0]
        state = nm[host][proto][port]['state']
    except:
        state = 'none'
    
    return state
    


# In[22]:

def JobStatus(client):
    ## connect to bareos database
    ## look for jobs related to specific client with status of Complete ("T") or Complete with Warnings ("W)
    conn_string = "host='localhost' dbname='bareos' user='bareosquery' password='vJd58c2C'"
    conn = psycopg2.connect(conn_string)
    cursor = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    
    cursor.execute("""select * from job where name LIKE %s AND (jobstatus like 'T' OR jobstatus like 'W') order by endtime """, (client,))

    x = cursor.fetchall()
    if cursor.rowcount > 1:
        ## if jobs are found with the proper status, find the last row and get the job's end time
        row = x[(cursor.rowcount)-1]

        jendTime = datetime.date(row["endtime"])
        delta = datetime.date(now) - jendTime

        #print delta
        if delta > timedelta(days=7):
            ## if the job ran more than a week ago, run a backup
            print ('JobID: %s\tName: %s\tEnd Time: %s\nStatus: %s\tErrors: %s' % (row["jobid"], row["name"], row["endtime"], row["jobstatus"], row["joberrors"]))
            runBareosJob(client)
        else:
            ## otherwise skip it
            print ('Job has been run in past 7 days for %s' % (client,))
    else:
        ## if NO jobs were found for a client with an active bareos connection, then run a backup
        print ('Job needs to run for %s' % (client,))
        runBareosJob(client)


# In[107]:

def runBareosJob(client):
    ## get the bareos password from the director's configuration file
    bPassRX = re.compile(r'^\ +Password\ =\ \"(.*)\"', re.MULTILINE)
    dirPFind = bPassRX.findall(open('/etc/bareos/bareos-dir.d/director/bareos-dir.conf').read())
    password = bareos.bsock.Password(dirPFind[0])
    directorconsole = bareos.bsock.DirectorConsole(address="localhost", port=9101, password=password)

    # test to see if client name matches one that is called
    clientInfo = (bytes(directorconsole.call("status client="+ client + '-fd')).split('\n'))
    fd_rx = re.compile(r"^(" + re.escape(client) + r"\-fd)", re.IGNORECASE)

    for line in clientInfo:
        # print line
        if fd_rx.search(line):
            ## run a backup job for the specified client
            print line
            print "Running %s" % client
            print directorconsole.call("run job="+ client + " yes")
            break
        #else:
        #    correct_rx1 = re.compile(r"^(.*-(lt|wks)\-fd)", re.IGNORECASE | re.MULTILINE)
        #    matches = correct_rx1.findall(line)
        #    if matches:
        #        m1 = str(matches[0][0]).lower()
        #        correct_rx2 = re.compile(r"(.*\ )?(.*-(lt|wks))$")
        #        m2 = correct_rx2.findall(m1)
        #        print m2
        #        val = m2[0][len(m2)]
        #        print "client should be %s" % (val)
                
        #        #print directorconsole.call("run job="+ val + " yes")
        #        break


# In[108]:

def main():
    global now 
    now = datetime.now()
    
    for file in confFileList():
        if NMScan(file) == "open": ## run a scan on hosts listed by configuration file
            JobStatus(file) ## get the latest job status, and run a backup depending on outcome
    


# In[109]:

if __name__ == "__main__":
    main()


# In[ ]:



