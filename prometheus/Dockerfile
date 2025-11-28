# escape=`
ARG IMAGE_PATH="mcr.microsoft.com/windows/nanoserver"
ARG IMAGE_VERSION="ltsc2022"
ARG DOWNLOADER_IMAGE_PATH="mcr.microsoft.com/dotnet/sdk"
ARG DOWNLOADER_IMAGE_VERSION="8.0-nanoserver-ltsc2022"

# Use a base Windows image
FROM $DOWNLOADER_IMAGE_PATH:$DOWNLOADER_IMAGE_VERSION as downloader
ARG PROMETHEUS_VERSION="3.7.3"
SHELL ["pwsh", "-ExecutionPolicy","RemoteSigned", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue'; $InformationPreference = 'Continue';"]

# Download and Unzip and set up prometheus
WORKDIR /prometheus/result
WORKDIR /prometheus/download
ADD ["https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.windows-amd64.zip", "/prometheus/download/prometheus.zip"]
RUN `
    Expand-Archive -Path "C:\prometheus\download\prometheus.zip" -DestinationPath "C:\prometheus\result" -Force; `
    $folderName = Get-ChildItem -Attributes d -Name -Path "C:\prometheus\result\prometheus-*" | select -first 1; `
    Copy-Item "C:\prometheus\result\$folderName" -Destination "C:\prometheus\result\extracted" -Recurse;
WORKDIR /prometheus/result/extracted/data
COPY ".\config\prometheus.yaml" "C:\prometheus\result\extracted\config\prometheus.yaml"

ARG IMAGE_PATH
ARG IMAGE_VERSION
FROM $IMAGE_PATH:$IMAGE_VERSION AS final
USER ContainerUser
COPY --from=downloader "C:\prometheus\result\extracted\" "C:\prometheus"
WORKDIR C:\prometheus
HEALTHCHECK CMD curl -k -f http://localhost:9090/-/healthy || exit 1;
# Set entrypoint
ENTRYPOINT ["C:\\prometheus\\prometheus.exe"]
CMD ["--storage.tsdb.path=C:\\d", "--config.file=C:\\prometheus\\config\\prometheus.yaml" ]