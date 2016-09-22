#!/usr/local/bin/python
#-*- coding: utf-8 -*- 
#
#Copyright [2016] [Thilo Wening]
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#
# <bitbar.title>Icinga2</bitbar.title>
# <bitbar.version>v1.0</bitbar.version>
# <bitbar.author>Thilo Wening</bitbar.author>
# <bitbar.author.github>mkayontour</bitbar.author.github>
# <bitbar.desc>Plugin to display the current status of host and service with additional list of problems</bitbar.desc>
# <bitbar.dependencies></bitbar.dependencies>

import json, requests, warnings
from requests.auth import HTTPBasicAuth
warnings.filterwarnings("ignore")


class Icinga:
  icinga_host = ""
  icinga_user = ""
  icinga_pw = ""
  if icinga_user == "" or icinga_pw == "":
      raise SystemExit("Require api_user or api_secret")
  
  def getStuff(self, status, object):
    stuff=[]
    status=str(status)
    
    headers = { 'Accept': 'application/json', 'X-HTTP-Method-Override': 'GET' }
    if object == "host" or object == "service":
      if status == "1":
        url = "http://"+self.icinga_host+"/icingaweb2/monitoring/list/"+object+"s?"+object+"_state="+status+"&sort="+object+"_severity&"+object+"_unhandled=1&format=json"
      elif status == "2":
        url = "http://"+self.icinga_host+"/icingaweb2/monitoring/list/"+object+"s?"+object+"_state="+status+"&"+object+"_handled=0&format=json"
      else:
        url = "http://"+self.icinga_host+"/icingaweb2/monitoring/list/"+object+"s?"+object+"_problem="+ str(status) +"&format=json"
### list hostgroups and their status would be cool
    elif object == "hostgroup":
      url = "http://"+self.icinga_host+"/icingaweb2/monitoring/list/"+object+"s?format=json"
    try:
      r = requests.get(url, auth=HTTPBasicAuth(self.icinga_user, self.icinga_pw), verify=False, timeout=15, allow_redirects=False, headers=headers)
    except:
      print("fail|color=red")
      print("---")
      raise SystemExit("Icinga2 down or wrong credentials")
    if(r.status_code == 200):
      jresults = json.loads(r.content)
      for i in jresults:
        if object == "hostgroup":
          stuff.append(i[object+"_name"])
        else:
          stuff.append(i[object+"_display_name"])
    else:
      print("Fail|color=red")
      raise SystemExit("wrong status code"+str(r.status_code))
    return(stuff)
i = Icinga()


# Output ###########
down = i.getStuff(1,"host")
up = i.getStuff(0,"host")
servcrit = i.getStuff(2,"service")
servok = i.getStuff(0,"service")
servwarn = i.getStuff(1,"service")
hostgroups = i.getStuff(0,"hostgroup")

icinga_ref ="http://"+i.icinga_host+"/icingaweb2/monitoring"
#Print current status
if len(down) != 0:
  print( "❗️ "+ str(len(down))+" | color=red")
else:
  print(" ✅ "+ str(len(up))+" | color=green")

#Print host status
print("---")
if len(down) != 0:
  print("Hosts Down: \t"+str(len(down))+"| color=red href="+icinga_ref+"/list/hosts?host_problem=1&sort=host_severity&host_unhandled=1")
  for dumb in down:
    print("-- "+dumb+"| href="+icinga_ref+"/host/show?host="+dumb)
else:
  print("Hosts Down | color=gray href="+icinga_ref+"/list/hosts?host_problem=1")
print("Hosts UP: \t\t"+str(len(up))+"| color=green href="+icinga_ref+"/list/hosts?host_state=0")

#Print service status
print("---")
if len(servcrit) != 0:
  print("Services Critical: "+str(len(servcrit))+"|color=red  href="+icinga_ref+"/list/services?service_problem=1&sort=service_severity&service_unhandled=1")
  for c in servcrit:
    print("--"+c+"|href="+icinga_ref+"/host/show?service="+c)
else:
  print("Services Critical|color=gray  href="+icinga_ref+"/list/services?service_problem=1&sort=service_severity")
if len(servwarn) != 0:
  print("Services Warn: \t"+str(len(servwarn))+"|color=orange  href="+icinga_ref+"/list/services?service_state=1&sort=service_severity&service_unhandled=1")
  for w in servwarn:
    print("--"+w+"|href="+icinga_ref+"/host/show?service="+w)
else:
  print("Services Warning|color=gray  href="+icinga_ref+"/list/services?service_state=1&sort=service_severity")
print("Services OK: \t"+str(len(servok))+"|href="+icinga_ref+"/list/services?service_problem=0 color=green")

#Print hostgroups
print("---")
print("Hostgroups|color=gray size=14")
if len(hostgroups) != 0:
  for h in hostgroups:
    print(h+"| color=gray href="+icinga_ref+"/list/hosts?hostgroup_name="+h)




