# escape=`
ARG IMAGE_PATH="mcr.microsoft.com/windows/nanoserver"
ARG IMAGE_VERSION="ltsc2022"
ARG DOWNLOADER_IMAGE_PATH="mcr.microsoft.com/powershell"
ARG DOWNLOADER_IMAGE_VERSION="lts-nanoserver-ltsc2022"

# Use a base Windows image
FROM $DOWNLOADER_IMAGE_PATH:$DOWNLOADER_IMAGE_VERSION as downloader
ARG LOKI_VERSION="3.4.2"
SHELL ["pwsh", "-ExecutionPolicy","RemoteSigned", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue'; $InformationPreference = 'Continue';"]

# Download and Unzip and set up Loki
RUN mkdir C:\loki\download && mkdir C:\loki\result; `
    Invoke-WebRequest -URI "https://github.com/grafana/loki/releases/download/v$($env:LOKI_VERSION)/loki-windows-amd64.exe.zip" -Outfile "C:\loki\download\loki.zip"; `
    Expand-Archive -Path "C:\loki\download\loki.zip" -DestinationPath "C:\loki\result" -Force; `
    New-Item -Path "C:\loki\result" -Name "extracted" -ItemType "directory" ; `
    Copy-Item "C:\loki\result\loki-windows-amd64.exe" -Destination "C:\loki\result\extracted\loki.exe" -Force; 

COPY ".\config\loki.yaml" "C:\loki\result\extracted\config\loki.yaml"

ARG IMAGE_PATH
ARG IMAGE_VERSION
FROM $IMAGE_PATH:$IMAGE_VERSION AS final

USER ContainerUser
COPY --from=downloader "C:\loki\result\extracted" "C:\loki"
HEALTHCHECK CMD curl -k -f http://localhost:3100/ready || exit 1;
# Set entrypoint
ENTRYPOINT ["C:\\loki\\loki.exe"]
CMD ["-config.file=C:\\loki\\config\\loki.yaml", "-print-config-stderr"]