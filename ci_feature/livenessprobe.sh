#!/bin/bash

#test to exit non zero value
(ps -ef | grep omsagent | grep -v "grep") && (ps -ef | grep td-agent-bit | grep -v "grep")
if [ -s "inotifyoutput.txt" ]
then
        exit 1
        # do something as file has data
else
        exit 0
        # do something as file is empty
fi