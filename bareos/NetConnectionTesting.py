
# coding: utf-8

# In[1]:

import nmap
import os
import sys
import re


# In[2]:

nm = nmap.PortScanner()
nm_args = '-Pn -sT -p 9102'


# In[3]:

clientPath = '/etc/bareos/bareos-dir.d/client/'

file_list = next(os.walk(clientPath))[2]
file_list.sort()
#file_list = ["dummy-lt.conf"]

sysRX = re.compile(r'(?i)(^.*(\-(wks|lt)))', re.MULTILINE)

for file in file_list:
    #print file
    if re.match(sysRX, file):
        m = re.match(sysRX, file)
        #print m.group(0)
        nm.scan(hosts=m.group(0), arguments=nm_args)
        print nm.all_hosts()
        for host in nm.all_hosts():
            print('----------------------------------------------------')
            print('Host : %s (%s)' % (host, nm[host].hostname()))
            # print('State : %s' % nm[host].state())
            for proto in nm[host].all_protocols():
                # print('----------')
                print('Protocol : %s' % proto)
                lport = nm[host][proto].keys()
                lport.sort()
                for port in lport:
                    print port
                    print ('port : %s\tstate : %s' % (port, nm[host][proto][port]['state']))


# In[ ]:




# In[ ]:



