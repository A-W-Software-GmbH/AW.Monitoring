# escape=`

# Used to configure the base image for the resulted image
ARG IMAGE_PATH="mcr.microsoft.com/windows/nanoserver"
# Used to configure the version of the base image for the resulted image
ARG IMAGE_VERSION="ltsc2022"

# Used to configure the base image for the Stage that downloads the binary
ARG DOWNLOADER_IMAGE_PATH="mcr.microsoft.com/powershell"
# Used to configure the version of the base image used for the Stage that downloads the binary
ARG DOWNLOADER_IMAGE_VERSION="lts-nanoserver-ltsc2022"

# Use a base Windows image
FROM $DOWNLOADER_IMAGE_PATH:$DOWNLOADER_IMAGE_VERSION as downloader

# Used to configure the version of the binary that is downloaded from Github
ARG COLLECTOR_VERSION="0.122.1"

SHELL ["pwsh", "-ExecutionPolicy","RemoteSigned", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue'; $InformationPreference = 'Continue';"]
RUN mkdir C:\collector\download && mkdir C:\collector\result;

# Download and extract and set up Collector
RUN `
    Invoke-WebRequest -URI "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v$($env:COLLECTOR_VERSION)/otelcol-contrib_$($env:COLLECTOR_VERSION)_windows_amd64.tar.gz" -Outfile "C:\collector\download\collector.tar.gz"; `
    cd C:\collector\download\; tar -vxf "C:\collector\download\collector.tar.gz"; `
    Copy-Item -LiteralPath 'C:\collector\download\otelcol-contrib.exe' -Destination 'C:\collector\result\otelcol-contrib.exe'; `
    New-Item -Path "C:\collector\result" -Name "config" -ItemType "directory" ; 

COPY ".\config\otel-colector.config.yaml" "C:\collector\result\config\otel-colector.config.yaml"

ARG IMAGE_PATH
ARG IMAGE_VERSION
FROM $IMAGE_PATH:$IMAGE_VERSION AS final

USER ContainerUser
COPY --from=downloader "C:\collector\result" "C:\collector"

HEALTHCHECK CMD curl -k -f http://localhost:13133/health/status || exit 1;

# Set entrypoint
ENTRYPOINT ["C:\\collector\\otelcol-contrib.exe"]
CMD ["--config=C:\\collector\\config\\otel-colector.config.yaml"]

