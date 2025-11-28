# escape=`
ARG IMAGE_PATH="mcr.microsoft.com/windows/nanoserver"
ARG IMAGE_VERSION="ltsc2022"
ARG DOWNLOADER_IMAGE_PATH="mcr.microsoft.com/dotnet/sdk"
ARG DOWNLOADER_IMAGE_VERSION="8.0-nanoserver-ltsc2022"

# Use a base Windows image
FROM $DOWNLOADER_IMAGE_PATH:$DOWNLOADER_IMAGE_VERSION as downloader
ARG GRAFANA_MCP_VERSION="0.7.9"
SHELL ["pwsh", "-ExecutionPolicy","RemoteSigned", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue'; $InformationPreference = 'Continue';"]

# Download and Unzip and set up Grafana
WORKDIR /mcp-grafana/result
WORKDIR /mcp-grafana/download
ADD ["https://github.com/grafana/mcp-grafana/releases/download/v${GRAFANA_MCP_VERSION}/mcp-grafana_Windows_x86_64.zip", "/mcp-grafana/download/mcp-grafana.zip"]
RUN Expand-Archive -Path "C:\mcp-grafana\download\mcp-grafana.zip" -DestinationPath "C:\mcp-grafana\result" -Force; `
    New-Item -Path "C:\mcp-grafana\result" -Name "extracted" -ItemType "directory" ; `
    Copy-Item "C:\mcp-grafana\result\mcp-grafana.exe" -Destination "C:\mcp-grafana\result\extracted\mcp-grafana.exe" -Force; 

ARG IMAGE_PATH
ARG IMAGE_VERSION
ENV MCP_GRAFANA_TOKEN=
ENV GRAFANA_URL=http://grafana:3000
ENV GRAFANA_SERVICE_ACCOUNT_TOKEN=
FROM $IMAGE_PATH:$IMAGE_VERSION AS final
USER ContainerUser
COPY --from=downloader "C:\mcp-grafana\result\extracted" "C:\mcp-grafana"
# Expose necessary ports
EXPOSE 8000
HEALTHCHECK CMD curl -k -f http://localhost:8000/healthz || exit 1;
# Set entrypoint
ENTRYPOINT ["C:\\mcp-grafana\\mcp-grafana.exe"]
# Use "--debug" in CMD for more verbose logging on the http traffic
CMD ["-t","streamable-http", "--address", "0.0.0.0:8000", "--tls-skip-verify"] 
