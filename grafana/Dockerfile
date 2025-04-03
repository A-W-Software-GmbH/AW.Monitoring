# escape=`
ARG IMAGE_PATH="mcr.microsoft.com/windows/nanoserver"
ARG IMAGE_VERSION="ltsc2022"
ARG DOWNLOADER_IMAGE_PATH="mcr.microsoft.com/powershell"
ARG DOWNLOADER_IMAGE_VERSION="lts-nanoserver-ltsc2022"

# Use a base Windows image
FROM $DOWNLOADER_IMAGE_PATH:$DOWNLOADER_IMAGE_VERSION as downloader
ARG GRAFANA_VERSION="11.6.0"
SHELL ["pwsh", "-ExecutionPolicy","RemoteSigned", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue'; $InformationPreference = 'Continue';"]

# Download and Unzip and set up Grafana
RUN mkdir C:\grafana\download && mkdir C:\grafana\result;`
    Invoke-WebRequest -URI "https://dl.grafana.com/oss/release/grafana-$env:GRAFANA_VERSION.windows-amd64.zip" -Outfile "C:\grafana\download\grafana.zip"; `
    Expand-Archive -Path "C:\grafana\download\grafana.zip" -DestinationPath "C:\grafana\result" -Force; `
    $folderName = Get-ChildItem -Attributes d -Name -Path "C:\grafana\result\grafana-*" | select -first 1; `
    Copy-Item "C:\grafana\result\$folderName" -Destination "C:\grafana\result\extracted" -Recurse; `
    $versionExpression = '*{0}*' -f $env:GRAFANA_VERSION; `
    Get-Item "C:\grafana\result\extracted\VERSION" | Get-Content -raw | Where-Object { $_ -notlike $versionExpression } | ForEach { Write-Error "invalid version $_"}; `
    New-Item -Path "C:\grafana\result\extracted" -Name "data" -ItemType "directory" ; `
    New-Item -Path "C:\grafana\result\extracted" -Name "logs" -ItemType "directory" ; `
    New-Item -Path "C:\grafana\result\extracted" -Name "plugins" -ItemType "directory" ; 

COPY ".\conf.ini" "C:\grafana\result\extracted\conf\custom.ini"

ARG IMAGE_PATH
ARG IMAGE_VERSION
FROM $IMAGE_PATH:$IMAGE_VERSION AS final

USER ContainerUser
COPY --from=downloader "C:\grafana\result\extracted" "C:\\grafana"
# Expose necessary ports
EXPOSE 3000
HEALTHCHECK CMD curl -k -f http://localhost:3000/api/health || exit 1;
# Set entrypoint
ENTRYPOINT ["C:\\grafana\\bin\\grafana-server.exe"]
CMD ["--homepath=C:\\grafana" , "--config=C:\\grafana\\conf\\custom.ini"]
