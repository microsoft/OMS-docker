#
################# Dangerous to use appveyor links - the builds are removed after 6 months
#
#ARG FLUENTBIT_URL=https://ci.appveyor.com/api/buildjobs/37lho3xf8j5i6crj/artifacts/build%2Ftd-agent-bit-1.4.0-win64.zip

Write-Host ('Creating folder structure')
    New-Item -Type Directory -Path /installation -ErrorAction SilentlyContinue
        
    New-Item -Type Directory -Path /opt/fluent-bit
    New-Item -Type Directory -Path /opt/scripts/ruby

    New-Item -Type Directory -Path /etc/fluent-bit
    New-Item -Type Directory -Path /etc/fluent
    New-Item -Type Directory -Path /etc/omsagentwindows

    New-Item -Type Directory -Path /etc/config/settings/

Write-Host('Downloading windows fluentbit package')
    $windowsLogPackageUri = "https://github.com/r-dilip/goPlugins-fluentbit/releases/download/windowsakslog/windows-log-aks-package.zip" 
    $windowsLogAksPackageLocation = "\installation\windows-log-aks-package.zip"
    Invoke-WebRequest -Uri $windowsLogPackageUri -OutFile $windowsLogAksPackageLocation
Write-Host ("Finished downloading fluentbit package for windows logs")

Write-Host ("Extracting windows fluentbit container package")
    $omsAgentPath = "/opt/omsagentwindows"
    Expand-Archive -Path $windowsLogAksPackageLocation -Destination $omsAgentPath -ErrorAction SilentlyContinue
Write-Host ("Finished Extracting windows fluentbit package")


Write-Host ('Installing Fluent Bit'); 
    $fluentBitUri='https://github.com/bragi92/windowslog/raw/master/td-agent-bit-1.4.0-win64.zip'
    Invoke-WebRequest -Uri $fluentBitUri -OutFile /installation/td-agent-bit.zip
    Expand-Archive -Path /installation/td-agent-bit.zip -Destination /installation/fluent-bit
    Move-Item -Path /installation/fluent-bit/*/* -Destination /opt/fluent-bit/ -ErrorAction SilentlyContinue
Write-Host ('Finished Installing Fluentbit')


Write-Host ('Installing Visual C++ Redistributable Package')
    $vcRedistLocation = 'https://aka.ms/vs/16/release/vc_redist.x64.exe'
    $vcInstallerLocation = "\installation\vc_redist.x64.exe"
    $vcArgs = "/install /quiet /norestart"
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $vcRedistLocation -OutFile $vcInstallerLocation
    Start-Process $vcInstallerLocation -ArgumentList $vcArgs -NoNewWindow -Wait
    Copy-Item -Path /Windows/System32/msvcp140.dll -Destination /opt/fluent-bit/bin
    Copy-Item -Path /Windows/System32/vccorlib140.dll -Destination /opt/fluent-bit/bin 
    Copy-Item -Path /Windows/System32/vcruntime140.dll -Destination /opt/fluent-bit/bin
Write-Host ('Finished Installing Visual C++ Redistributable Package')

Write-Host ('Extracting Certificate Generator Package')
    Expand-Archive -Path /opt/omsagentwindows/certgenerator/CertificateGenerator.zip -Destination /opt/omsagentwindows/certgenerator/ -Force
Write-Host ('Finished Extracting Certificate Generator Package')

Remove-Item /installation -Recurse

Write-Host ("Removing Install folder")