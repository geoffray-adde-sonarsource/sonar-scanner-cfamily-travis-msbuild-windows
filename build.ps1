$ErrorActionPreference = 'Stop'
$MsbuildPath = "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe"

# use only one of SonarQube or SonarCloud

# Configuration for SonarQube
$SONAR_URL = "http://localhost:9000" # URL of the SonarQube server
$SONAR_TOKEN = "f5f56032a938d29cf76d78de33991eb8c273a0ea" # access token from SonarQube projet creation page -Dsonar.login=XXXX
$SONAR_PROJECT_KEY = "sonar_scanner_example" # project name from SonarQube projet creation page -Dsonar.projectKey=XXXX
$SONAR_PROJECT_NAME = "sonar_scanner_example" # project name from SonarName projet creation page -Dsonar.projectName=XXXX

# Configuration for SonarCloud
#$SONAR_TOKEN = # access token from SonarCloud projet creation page -Dsonar.login=XXXX
#$SONAR_PROJECT_KEY = # project name from SonarCloud projet creation page -Dsonar.projectKey=XXXX
#$SONAR_ORGANIZATION = # organization name from SonarCloud projet creation page -Dsonar.organization=ZZZZ

# Set default to SONAR_URL in not provided
$SONAR_URL = If ( $SONAR_URL ) { $SONAR_URL } else {"https://sonarcloud.io"}

# Download build-wrapper
rm build-wrapper-win-x86 -Recurse -Force -ErrorAction SilentlyContinue
rm build-wrapper-win-x86 -Force -ErrorAction SilentlyContinue
$path = ".\build-wrapper-win-x86.zip"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
(New-Object System.Net.WebClient).DownloadFile("${SONAR_URL}/static/cpp/build-wrapper-win-x86.zip", $path)
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($path, ".")
del $path

# Download sonar-scanner
rm sonar-scanner -Recurse -Force -ErrorAction SilentlyContinue
$path = ".\sonar-scanner-cli-4.2.0.1873-windows.zip"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
(New-Object System.Net.WebClient).DownloadFile("https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.2.0.1873-windows.zip", $path)
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($path, ".")
mv sonar-scanner-4.2.0.1873-windows sonar-scanner

# Build inside the build-wrapper
build-wrapper-win-x86/build-wrapper-win-x86-64 --out-dir build_wrapper_output_directory $MsbuildPath sonar_scanner_example.sln /t:rebuild

# Run sonar scanner (here, arguments are passed through the command line but most of them can be written in the sonar-project.properties file)
$SONAR_TOKEN_CMD_ARG = If ( $SONAR_TOKEN ) { "-D sonar.login=${SONAR_TOKEN}" }
$SONAR_ORGANIZATION_CMD_ARG = If ( $SONAR_ORGANIZATION ) { "-D sonar.organization=${SONAR_ORGANIZATION}" }
$SONAR_PROJECT_NAME_CMD_ARG = If ( $SONAR_PROJECT_NAME ) { "-D sonar.projectName=${SONAR_PROJECT_NAME}" }
$SONAR_OTHER_ARGS = @("-D sonar.projectVersion=1.0","-D sonar.sources=src","-D sonar.cfamily.build-wrapper-output=build_wrapper_output_directory","-D sonar.sourceEncoding=UTF-8")
sonar-scanner\bin\sonar-scanner.bat -D sonar.host.url=$SONAR_URL -D sonar.projectKey=$SONAR_PROJECT_KEY $SONAR_OTHER_ARGS $SONAR_PROJECT_NAME_CMD_ARG $SONAR_TOKEN_CMD_ARG $SONAR_ORGANIZATION_CMD_ARG

