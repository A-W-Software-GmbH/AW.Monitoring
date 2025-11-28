# escape=`

# Used to configure the base image for the resulted image
ARG IMAGE_PATH="mcr.microsoft.com/windows/servercore"
# Used to configure the version of the base image for the resulted image
ARG IMAGE_VERSION="ltsc2022"

# Used to configure the base image for the Stage that downloads the binary
ARG DOWNLOADER_IMAGE_PATH="mcr.microsoft.com/dotnet/sdk"
# Used to configure the version of the base image used for the Stage that downloads the binary
ARG DOWNLOADER_IMAGE_VERSION="8.0-nanoserver-ltsc2022"

# Use a base Windows image
FROM $DOWNLOADER_IMAGE_PATH:$DOWNLOADER_IMAGE_VERSION as downloader

# Used to configure the version of the binary that is downloaded from Github
ARG COLLECTOR_VERSION="0.140.1"

SHELL ["pwsh", "-ExecutionPolicy","RemoteSigned", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue'; $InformationPreference = 'Continue';"]

# Download and extract and set up Collector
WORKDIR /collector/result
WORKDIR /collector/download
ADD ["https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${COLLECTOR_VERSION}/otelcol-contrib_${COLLECTOR_VERSION}_windows_amd64.tar.gz", "/collector/download/collector.tar.gz"]
RUN `
    tar -vxf "C:\collector\download\collector.tar.gz"; `
    Copy-Item -LiteralPath 'C:\collector\download\otelcol-contrib.exe' -Destination 'C:\collector\result\otelcol-contrib.exe';
WORKDIR /collector/result/config
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

