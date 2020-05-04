echo "Checking if fluent-bit is running"

tasklist /fi "imagename eq fluent-bit.exe" /fo "table"  | findstr fluent-bit

IF ERRORLEVEL 1 (
    echo "Fluent-Bit is not running"
    exit /b 1
) ELSE (
    echo "Fluent-Bit is running"
)

echo "Checking if config map has been updated since agent start"

IF EXIST C:\etc\omsagentwindows\filesystemwatcher.txt (
    echo "Config Map Updated since agent started"
    exit /b  1
) ELSE (
    echo "Config Map not Updated since agent start"
)

echo "Checking if certificate needs to be renewed (aka agent restart required)"

IF EXIST C:\etc\omsagentwindows\renewcertificate.txt (
    echo "Certificate needs to be renewed"
    exit /b  1
) ELSE (
    echo "Certificate does NOT need to be renewd"
)

echo "Checking if fluentd service is running"
sc query fluentdwinaks | findstr /i STATE | findstr RUNNING

IF ERRORLEVEL 1 (
    echo "Fluentd Service is NOT Running"
    exit /b  1
) ELSE (
    echo "Fluentd Service is Running"
)

exit /b 0




