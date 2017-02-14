#!/usr/bin/python

import os
import sys
from pwd import getpwnam
from shutil import copyfile
import re
import bareos.bsock

clientPath = '/etc/bareos/bareos-dir.d/client/'

bInfo = getpwnam('bareos')

with open('/mnt/bareos_dump/system_names.txt', 'r') as f:
    data = list(f)
    for x in data:
        y = re.sub('\r\n','',x)
        confFile = clientPath + y +'.conf'
        if not (os.path.exists(confFile)):
            copyfile (clientPath+"base.conf.dist", confFile)
            with open(confFile, 'r+') as newConf:
                conf = newConf.read()
                conf = re.sub('XXXXXX',y,conf)
                newConf.seek(0)
                newConf.write(conf)
                newConf.truncate()
                os.chown(confFile, bInfo.pw_uid, bInfo.pw_gid)

regex = re.compile(r'^\ +Password\ =\ \"(.*)\"', re.MULTILINE)
                
dirPFind = regex.findall(open('/etc/bareos/bareos-dir.d/director/bareos-dir.conf').read())
password = bareos.bsock.Password(dirPFind[0])
directorconsole=bareos.bsock.DirectorConsole(address="localhost", port=9101, password=password)
print directorconsole.call("reload")

