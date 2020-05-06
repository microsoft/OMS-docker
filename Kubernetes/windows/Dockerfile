FROM mcr.microsoft.com/azuremonitor/containerinsights/cidev:winakslogbase-04212020

SHELL ["powershell"]

#EXPOSE 24224 5140

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

ENV AGENT_VERSION "winakslogprivatepreview"
ENV OS_TYPE "windows"
ENV APPLICATIONINSIGHTS_AUTH "OTQzNWI0M2YtOTdkNS00ZGVkLThkOTAtYjA0Nzk1OGU2ZTg3"
ENV AZMON_COLLECT_ENV False

ENTRYPOINT ["powershell", "C:\\opt\\omsagentwindows\\scripts\\powershell\\main.ps1"]