# escape=`
ARG IMAGE_PATH="mcr.microsoft.com/windows/nanoserver"
ARG IMAGE_VERSION="ltsc2022"
ARG DOWNLOADER_IMAGE_PATH="mcr.microsoft.com/dotnet/sdk"
ARG DOWNLOADER_IMAGE_VERSION="8.0-nanoserver-ltsc2022"

# Use a base Windows image
FROM $DOWNLOADER_IMAGE_PATH:$DOWNLOADER_IMAGE_VERSION as downloader
ARG GRAFANA_MCP_VERSION="2.2.0"
SHELL ["pwsh", "-ExecutionPolicy","RemoteSigned", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue'; $InformationPreference = 'Continue';"]

# Download and Unzip and set up Grafana
WORKDIR /mcp-grafana/result
WORKDIR /mcp-grafana/download
ADD ["https://github.com/grafana/mcp-grafana/releases/download/v${GRAFANA_MCP_VERSION}/mcp-grafana_Windows_x86_64.zip", "/mcp-grafana/download/mcp-grafana.zip"]
RUN Expand-Archive -Path "C:\mcp-grafana\download\mcp-grafana.zip" -DestinationPath "C:\mcp-grafana\result" -Force; `
    New-Item -Path "C:\mcp-grafana\result" -Name "extracted" -ItemType "directory" ; `
    Copy-Item "C:\mcp-grafana\result\mcp-grafana.exe" -Destination "C:\mcp-grafana\result\extracted\mcp-grafana.exe" -Force; `
    Copy-Item "C:\mcp-grafana\result\LICENSE" -Destination "C:\mcp-grafana\result\extracted\LICENSE" -Force;

ARG IMAGE_PATH
ARG IMAGE_VERSION
FROM $IMAGE_PATH:$IMAGE_VERSION AS final
ENV MCP_GRAFANA_TOKEN=
ENV GRAFANA_URL=http://grafana:3000
ENV GRAFANA_SERVICE_ACCOUNT_TOKEN=
# Comma-separated Host-header allowlist for mcp-grafana's DNS-rebinding guard, or "*" to
# disable it. Override in user.env - see mcp-grafana/Readme.md.
ENV MCP_ALLOWED_HOSTS=*
# Set to "true" in user.env to skip TLS verification against a https:// GRAFANA_URL - needed
# since GRAFANA_URL uses the in-network hostname "grafana", which self-signed certs are
# usually not issued for (they're typically issued for the browser-facing hostname instead).
# See mcp-grafana/Readme.md.
ENV GRAFANA_TLS_SKIP_VERIFY=false
USER ContainerUser
COPY --from=downloader "C:\mcp-grafana\result\extracted" "C:\mcp-grafana"
# Expose necessary ports
EXPOSE 8000
HEALTHCHECK CMD curl -k -f http://localhost:8000/healthz || exit 1;
# mcp-grafana itself always keeps serving plain HTTP on 0.0.0.0:8000, regardless of
# GRAFANA_TLS_SKIP_VERIFY - that flag only affects the outbound call to GRAFANA_URL.
# MCP_ALLOWED_HOSTS defaults to "*", which disables mcp-grafana's Host-header allowlist
# (DNS-rebinding guard) - otherwise it only accepts loopback variants of --address (e.g.
# localhost:8000) and rejects requests arriving via the docker-compose host port mapping
# (localhost:38000). "*" is only safe while this port isn't reachable from untrusted
# networks; narrow it to a comma-separated list (e.g. localhost:38000,127.0.0.1:38000) via
# user.env if that stops being true.
ENTRYPOINT ["cmd", "/S", "/C"]
CMD ["if /I \"%GRAFANA_TLS_SKIP_VERIFY%\"==\"true\" (C:\\mcp-grafana\\mcp-grafana.exe -t streamable-http --address 0.0.0.0:8000 --allowed-hosts %MCP_ALLOWED_HOSTS% --tls-skip-verify) else (C:\\mcp-grafana\\mcp-grafana.exe -t streamable-http --address 0.0.0.0:8000 --allowed-hosts %MCP_ALLOWED_HOSTS%)"]
