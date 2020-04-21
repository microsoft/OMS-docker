FROM mcr.microsoft.com/azuremonitor/containerinsights/cidev:winakslog-1809

# # Do not split this into multiple RUN!
# # Docker creates a layer for every RUN-Statement
# RUN powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))"

# # Fluentd depends on cool.io whose fat gem is only available for Ruby < 2.5, so need to specify --platform ruby when install Ruby > 2.5 and install msys2 to get dev tools
# RUN choco install -y ruby --version 2.6.5.1 --params "'/InstallDir:C:\ruby26'" \
# && choco install -y msys2 --params "'/NoPath /NoUpdate /InstallDir:C:\ruby26\msys64'"
# RUN refreshenv \
# && ridk install 2 3 \
# && echo gem: --no-document >> C:\ProgramData\gemrc \
# && gem install cool.io -v 1.5.4 --platform ruby \
# && gem install oj -v 3.3.10 \
# && gem install json -v 2.2.0 \
# && gem install fluentd -v 1.9.3 \
# && gem install win32-service -v 1.0.1 \
# && gem install win32-ipc -v 0.7.0 \
# && gem install win32-event -v 0.6.3 \
# && gem install windows-pr -v 1.2.6 \
# && gem sources --clear-all

# RUN choco install vim -y
# RUN gem install tomlrb

# # Remove gem cache and chocolatey
# RUN powershell -Command "Remove-Item -Force C:\ruby26\lib\ruby\gems\2.6.0\cache\*.gem; Remove-Item -Recurse -Force 'C:\ProgramData\chocolatey'"

# COPY fluent.conf /fluent/conf/fluent.conf

SHELL ["powershell"]

EXPOSE 24224 5140

ENV tmpdir /opt/omsagentwindows/scripts/powershell

WORKDIR /opt/omsagentwindows/scripts/powershell
COPY ./omsagentwindows/certgenerator/* /opt/omsagentwindows/certgenerator/
COPY ./scripts/powershell/setup.ps1 /opt/omsagentwindows/scripts/powershell
RUN ./setup.ps1

COPY ./scripts/powershell/main.ps1 /opt/omsagentwindows/scripts/powershell
COPY ./scripts/powershell/filesystemwatcher.ps1 /opt/omsagentwindows/scripts/powershell
COPY ./scripts/cmd/livenessprobe.cmd /opt/omsagentwindows/scripts/cmd/

# copy ruby scripts to /opt folder
COPY ./scripts/ruby/*.rb /opt/omsagentwindows/scripts/ruby/

# COPY out_oms.so
COPY ./omsagentwindows/out_oms.so /opt/omsagentwindows/out_oms.so

COPY ./fluent/fluent.conf /etc/fluent/
COPY ./fluent/rubyKeepCertificateAlive/*.rb /etc/fluent/plugin/
COPY ./fluent-bit/fluent-bit.conf /etc/fluent-bit
COPY ./omsagentwindows/out_oms.conf /etc/omsagentwindows

ENV CONTROLLER_TYPE="DaemonSet"
ENV AGENT_VERSION="winakslogprivatepreview"
ENV OS_TYPE "windows"
ENV APPLICATIONINSIGHTS_AUTH "NzAwZGM5OGYtYTdhZC00NThkLWI5NWMtMjA3ZjM3NmM3YmRi"

ENTRYPOINT ["powershell", "C:\\opt\\omsagentwindows\\scripts\\powershell\\main.ps1"]
#ENTRYPOINT ["powershell"]