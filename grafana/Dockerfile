# escape=`
ARG DOWNLOADER_IMAGE_PATH="mcr.microsoft.com/powershell"
ARG DOWNLOADER_IMAGE_VERSION="lts-nanoserver-1809"
ARG GRAFANA_VERSION="11.3.0"

# Use a base Windows image
FROM $DOWNLOADER_IMAGE_PATH:$DOWNLOADER_IMAGE_VERSION as downloader
SHELL ["pwsh", "-ExecutionPolicy","RemoteSigned", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue'; $InformationPreference = 'Continue';"]
RUN mkdir C:\grafana\download && mkdir C:\grafana\result;

# Download Grafana Windows binaries
ADD https://dl.grafana.com/oss/release/grafana-11.3.0.windows-amd64.zip C:\grafana\download\grafana.zip

# Unzip and set up Grafana
RUN pwsh -Command "Expand-Archive -Path C:\grafana\download\grafana.zip -DestinationPath C:\grafana\result -Force"

ARG IMAGE_PATH="mcr.microsoft.com/windows/nanoserver"
ARG IMAGE_VERSION="ltsc2019"
ARG GRAFANA_VERSION
FROM $IMAGE_PATH:$IMAGE_TAG AS final

RUN RUN mkdir C:\grafana\;
COPY --from=downloader C:\grafana\result\ C:\grafana\;
COPY .\conf.ini C:\grafana\conf\custom.ini;
# Expose necessary ports
EXPOSE 30000

# Set entrypoint
ENTRYPOINT ["C:\\grafana\\bin\\grafana-server.exe", "--homepath=C:\\grafana"]
