# escape=`
ARG IMAGE_PATH="mcr.microsoft.com/windows/nanoserver"
ARG IMAGE_VERSION="ltsc2022"
ARG DOWNLOADER_IMAGE_PATH="mcr.microsoft.com/dotnet/sdk"
ARG DOWNLOADER_IMAGE_VERSION="8.0-nanoserver-ltsc2022"

# Use a base Windows image
FROM $DOWNLOADER_IMAGE_PATH:$DOWNLOADER_IMAGE_VERSION as downloader
ARG GRAFANA_VERSION="13.0.1"
SHELL ["pwsh", "-ExecutionPolicy","RemoteSigned", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue'; $InformationPreference = 'Continue';"]

# Download and Unzip and set up Grafana
WORKDIR /download
ADD ["https://dl.grafana.com/oss/release/grafana-${GRAFANA_VERSION}.windows-amd64.zip", "/download/grafana.zip"]
RUN Expand-Archive -Path "C:\download\grafana.zip" -DestinationPath "C:\extracted" -Force
RUN Rename-Item -Path "C:\extracted\grafana-$($env:GRAFANA_VERSION)" -NewName "C:\extracted\grafana"
RUN & "C:\extracted\grafana\bin\grafana.exe" cli --homepath "C:\extracted\grafana" plugins install yesoreyeram-infinity-datasource;
WORKDIR /extracted/grafana/data
WORKDIR /extracted/grafana/logs
WORKDIR /extracted/grafana/plugins
WORKDIR /extracted/grafana/conf
COPY ".\conf.ini" "C:\extracted\grafana\conf\custom.ini"

ARG IMAGE_PATH
ARG IMAGE_VERSION
FROM $IMAGE_PATH:$IMAGE_VERSION AS final
USER ContainerUser
COPY --from=downloader "C:\extracted\grafana" "C:\grafana"
# Expose necessary ports
EXPOSE 3000
HEALTHCHECK CMD curl -k -f http://localhost:3000/api/health || exit 1;
# Set entrypoint
ENTRYPOINT ["C:\\grafana\\bin\\grafana.exe", "server"]
CMD ["--homepath=C:\\grafana" , "--config=C:\\grafana\\conf\\custom.ini"]
