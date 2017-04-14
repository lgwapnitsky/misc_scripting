
# coding: utf-8

# In[ ]:

#!/usr/bin/python


# In[31]:

import os
import sys
import re
import bareos.bsock

from pwd import getpwnam
from shutil import copyfile


# In[32]:

clientPath = '/etc/bareos/bareos-dir.d/client/'
baseConf = 'base.conf.dist'

BareOSClientDropPath = '/opt/BareOSClientDrop/'

bInfo = getpwnam('bareos')


# In[33]:

file_list = next(os.walk(BareOSClientDropPath))[2]

sysRX = re.compile(r'(?i)(^.*(\-(wks$|lt$)))', re.MULTILINE)
for file in file_list:
    if re.match(sysRX, file):
        confFile = clientPath + file + '.conf'
        copyfile (clientPath+baseConf, confFile)
        with open(confFile, 'r+') as newConf:
            conf = newConf.read()
            conf = re.sub('XXXXXX', file, conf)
            newConf.seek(0)
            newConf.write(conf)
            newConf.truncate()
            os.chown(confFile, bInfo.pw_uid, bInfo.pw_gid)
            os.remove(BareOSClientDropPath + file)


# In[34]:

bPassRX = re.compile(r'^\ +Password\ =\ \"(.*)\"', re.MULTILINE)

dirPFind = bPassRX.findall(open('/etc/bareos/bareos-dir.d/director/bareos-dir.conf').read())
password = bareos.bsock.Password(dirPFind[0])
directorconsole = bareos.bsock.DirectorConsole(address="localhost", port=9101, password=password)
print directorconsole.call("reload")
print directorconsole.call("run "+ "job="+ file + " yes")

