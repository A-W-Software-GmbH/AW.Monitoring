# escape=`
# Server Core rather than Nano Server: Grafana's embedded NATS server panics at startup on Nano Server
# ltsc2025, whose pdh.dll lacks PdhOpenQuery (https://github.com/nats-io/nats-docker/issues/260).
ARG IMAGE_PATH="mcr.microsoft.com/windows/servercore"
ARG IMAGE_VERSION="ltsc2022"

FROM $IMAGE_PATH:$IMAGE_VERSION AS downloader
ARG GRAFANA_VERSION="13.3.0"
# Pinned explicitly because "grafana cli plugins install" resolving the latest version via
# grafana.com/api at build time is unreliable behind a restrictive firewall/proxy (timeouts).
ARG INFINITY_DATASOURCE_VERSION="4.1.5"
SHELL ["powershell", "-ExecutionPolicy","RemoteSigned", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue'; $InformationPreference = 'Continue';"]

# Download and Unzip and set up Grafana
WORKDIR /download
ADD ["https://dl.grafana.com/oss/release/grafana-${GRAFANA_VERSION}.windows-amd64.zip", "/download/grafana.zip"]
# Fetched via ADD (resolves through a short-lived redirect to Google Cloud Storage) instead of
# letting "grafana cli plugins install" query grafana.com/api/plugins/.../versions itself - that
# metadata lookup is what timed out behind the firewall, even though the actual zip download works.
ADD ["https://grafana.com/api/plugins/yesoreyeram-infinity-datasource/versions/${INFINITY_DATASOURCE_VERSION}/download", "/download/yesoreyeram-infinity-datasource.zip"]
RUN Expand-Archive -Path "C:\download\grafana.zip" -DestinationPath "C:\extracted" -Force
RUN Rename-Item -Path "C:\extracted\grafana-$($env:GRAFANA_VERSION)" -NewName "C:\extracted\grafana"
WORKDIR /extracted/grafana/data
WORKDIR /extracted/grafana/logs
WORKDIR /extracted/grafana/plugins
WORKDIR /extracted/grafana/conf
COPY ".\conf.ini" "C:\extracted\grafana\conf\custom.ini"
# "grafana cli --pluginUrl" only accepts http(s) URLs (errors on file:// with "unsupported
# protocol scheme"), so the already-downloaded archive is extracted directly instead - the zip's
# top-level folder is already named "yesoreyeram-infinity-datasource", matching what Grafana
# expects under pluginsDir. This is the same mechanism "cli plugins install" uses internally.
RUN Expand-Archive -Path "C:\download\yesoreyeram-infinity-datasource.zip" -DestinationPath "C:\extracted\grafana\plugins" -Force

FROM $IMAGE_PATH:$IMAGE_VERSION AS final
USER ContainerUser
COPY --from=downloader "C:\extracted\grafana" "C:\grafana"
# Expose necessary ports
EXPOSE 3000
HEALTHCHECK CMD curl -k -f http://localhost:3000/api/health || exit 1;
# Set entrypoint
ENTRYPOINT ["C:\\grafana\\bin\\grafana.exe", "server"]
CMD ["--homepath=C:\\grafana" , "--config=C:\\grafana\\conf\\custom.ini"]
