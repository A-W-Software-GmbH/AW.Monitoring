# escape=`
ARG IMAGE_PATH="mcr.microsoft.com/windows/nanoserver"
ARG IMAGE_VERSION="ltsc2022"
ARG DOWNLOADER_IMAGE_PATH="mcr.microsoft.com/dotnet/sdk"
ARG DOWNLOADER_IMAGE_VERSION="8.0-nanoserver-ltsc2022"

# Use a base Windows image
FROM $DOWNLOADER_IMAGE_PATH:$DOWNLOADER_IMAGE_VERSION as downloader
ARG TEMPO_VERSION="2.8.1"
SHELL ["pwsh", "-ExecutionPolicy","RemoteSigned", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue'; $InformationPreference = 'Continue';"]
RUN mkdir C:\tempo\download && mkdir C:\tempo\result;

# Download and extract and set up tempo
RUN `
    Invoke-WebRequest -URI "https://github.com/grafana/tempo/releases/download/v$($env:TEMPO_VERSION)/tempo_$($env:TEMPO_VERSION)_windows_amd64.tar.gz" -Outfile "C:\tempo\download\tempo.tar.gz"; `
    cd C:\tempo\download\; tar -vxf "C:\tempo\download\tempo.tar.gz"; `
    Copy-Item -Path 'C:\tempo\download\*' -Destination 'C:\tempo\result\'; `
    New-Item -Path "C:\tempo\result" -Name "config" -ItemType "directory" ; 

COPY ".\config\tempo.yaml" "C:\tempo\result\config\tempo.yaml"

ARG IMAGE_PATH
ARG IMAGE_VERSION
FROM $IMAGE_PATH:$IMAGE_VERSION AS final

USER ContainerUser
COPY --from=downloader "C:\tempo\result" "C:\tempo"

HEALTHCHECK CMD curl -k -f http://localhost:3200/ready || exit 1;

# Set entrypoint
ENTRYPOINT ["C:\\tempo\\tempo.exe"]
CMD ["-config.file=C:\\tempo\\config\\tempo.yaml"]
