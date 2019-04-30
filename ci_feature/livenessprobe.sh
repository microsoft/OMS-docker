#!/bin/bash

#test to exit non zero value
(ps -ef | grep omsagent | grep -v "grep") && (ps -ef | grep td-agent-bit | grep -v "grep")
if [ $? -eq 0 ] && [ ! -s "inotifyoutput.txt" ]
then
  # inotifyoutput file is empty and the grep commands for omsagent and td-agent-bit succeeded
  exit 0
else
  # inotifyoutput file has data(config map was applied) and the grep commands for omsagent or td-agent-bit failed
  exit 1
fi