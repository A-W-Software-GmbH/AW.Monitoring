# MCP Grafana

## Resources

- [Main repository](https://github.com/grafana/mcp-grafana)

The role of this tools is to provide a MCP-Server that interacts with grafana..

## How to Configure?

- [Configuration Docs](https://github.com/grafana/mcp-grafana)

There are environment variables to configure the MCP-Server:

- **GRAFANA_URL** The url to access grafana `http://grafana:3000`.
- **GRAFANA_SERVICE_ACCOUNT_TOKEN** The token for the authentication.
- **GRAFANA_USERNAME** The user for the authentication.
- **GRAFANA_PASSWORD** The password for the authentication.

## How to patch or update?

The [Dockerfile](./Dockerfile) for the MCP-Grafana has the following Build Arguments that can be used for Patching:

1. `IMAGE_VERSION`: This can be used to select a different version of [Nano Server](https://hub.docker.com/r/microsoft/windows-nanoserver)
1. `DOWNLOADER_IMAGE_VERSION`: This can be used to select a different image version for [dotnet sdk](https://mcr.microsoft.com/artifact/mar/dotnet/sdk)
1. `MCP_GRAFANA_VERSION`: This can be used to select a specific version for MCP-Grafana. Please use versions from [GitHub Releases](https://github.com/grafana/mcp-grafana/releases).
