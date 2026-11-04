# Introduction

The purpose of this repository is to offer a way the required configuration for collecting distributed logs, traces and metrics.

## Why?

When the landscape of installed services grows, the required effort to identify the possible bugs/issues of the system increases. Having all the traces, logs and metrics collected centrally and correlated will speed up the process of root cause analysis.

## What?

The stack relies on [Grafana](#grafana) as a dashboard solution, [Grafana Loki](#grafana-loki) for storing logs, [Grafana Tempo](#grafana-tempo) for storing the traces, [Prometheus](#prometheus) for storing the metrics, and the [OpenTelemetry Collector](#opentelemetry-collector) for proxying all the telemetry information from applications into the proper solution that stores them.

## OpenTelemetry Collector

See: [Collector docs](./otel-collector/Readme.md).

## Grafana

See: [Grafana Docs](./grafana/Readme.md).

## Grafana Loki

See: [Grafana Loki](./loki/Readme.md).

## Grafana Tempo

See: [Grafana Tempo](./tempo/Readme.md).

## Prometheus

See: [Prometheus](./prometheus/Readme.md).

## MCP-Grafana

See: [MCP-Grafana](./mcp-grafana/Readme.md)

## Third-Party Licenses

See: [Third-Party Software](./THIRD-PARTY.md) for the licenses and source code of the components in the images.

## Hardening the Stack

### How to enable HTTPS for Grafana?

By default Grafana is served over plain HTTP. To switch it to HTTPS with your own certificate:

1. Place your certificate and private key in [`./grafana/certs`](./grafana/certs) (the folder is
   git-ignored, so your files won't be committed). You can point at a different folder instead by
   setting `GRAFANA_CERTS_DIR` in your `.env`.
2. In your `.env` (or `.env.2022` / `.env.2025`), uncomment and set:

   ```bash
   GRAFANA_PROTOCOL=https
   GRAFANA_CERT_FILENAME=server.crt
   GRAFANA_CERT_KEYNAME=server.key
   GRAFANA_DOMAIN=your.actual.hostname
   ```

   Adjust the filenames if yours differ. `GRAFANA_DOMAIN` must be a hostname covered by the
   certificate's SAN, and must match what you actually type into the browser - see the warning
   below for why this one matters even when the cert itself is valid. `GRAFANA_PROTOCOL` defaults
   to `http` when unset, so leaving these commented out keeps the previous plain-HTTP behavior
   unchanged.
3. Recreate the service so the new environment and bind mount take effect:

   ```bash
   docker compose up -d grafana
   ```

Internally this maps to Grafana's `GF_SERVER_PROTOCOL`, `GF_SERVER_CERT_FILE` and `GF_SERVER_CERT_KEY`
environment variables (see [server config docs](https://grafana.com/docs/grafana/latest/setup-grafana/configure-grafana/#protocol)),
which take precedence over the `[server]` section in [`conf.ini`](./grafana/conf.ini). The certs
folder is bind-mounted read-only into the container at `C:\grafana\certs`.

**Why the browser can still say "Not secure" even with a perfectly valid cert:** `conf.ini` builds
`root_url` as `%(protocol)s://%(domain)s:23000/`, and that `%(...)s` interpolation is resolved from
`conf.ini`'s own (commented-out) `protocol`/`domain` values, not from the `GF_SERVER_PROTOCOL`
environment variable above - ini interpolation happens before env var overrides are applied. So
Grafana can be correctly serving HTTPS while still believing its own public URL is
`http://localhost:23000/`, and links/redirects it generates using that stale URL show up as
insecure mixed content in the browser. `GF_SERVER_DOMAIN` / `GF_SERVER_ROOT_URL` (driven by
`GRAFANA_DOMAIN` and `GRAFANA_PROTOCOL`) are set directly as environment variables in
`docker-compose.yaml` specifically to bypass this.

If you use a self-signed certificate, remember to update `GRAFANA_URL` in [`user.env`](./user.env)
to `https://grafana:3000` and set `GRAFANA_TLS_SKIP_VERIFY=true` there too - see
[`mcp-grafana/Readme.md`](./mcp-grafana/Readme.md#how-to-access-grafana-over-https) for why that's
needed (in short: the cert's SAN won't match the in-network hostname `grafana`). Otherwise the MCP
server won't be able to reach Grafana anymore.

#### Local alternative: `docker-compose.override.yaml`

Editing `.env` affects every deployment that uses this checkout. For a local/test machine, set the
same variables directly as container environment overrides in a `docker-compose.override.yaml`
instead - it's already excluded via [`.gitignore`](./.gitignore), Docker Compose picks it up
automatically (no extra flags needed), and it saves touching the tracked `.env` file at all:

```yaml
services:
  grafana:
    environment:
      - GF_SERVER_PROTOCOL=https
      - GF_SERVER_DOMAIN=your.actual.hostname
      - GF_SERVER_ROOT_URL=https://your.actual.hostname:23000/

  mcp-grafana:
    environment:
      - GRAFANA_URL=https://grafana:3000
      - GRAFANA_TLS_SKIP_VERIFY=true
```

`GF_SERVER_CERT_FILE`/`GF_SERVER_CERT_KEY` don't need to be repeated here if your certificate is
named `server.crt`/`server.key` in `./grafana/certs` - `docker-compose.yaml` already defaults to
those. `GF_SERVER_PROTOCOL`, `GF_SERVER_DOMAIN` and `GF_SERVER_ROOT_URL` must be overridden together
(see the mixed-content warning above). After adding or changing the file, recreate the containers (a
plain `restart` won't pick up new environment variables):

```bash
docker compose up -d grafana mcp-grafana
```

## General Patching Guidelines

Each service is relying on 4 build arguments that allow you to select the base image repository and version. Grafana only takes `IMAGE_PATH` and `IMAGE_VERSION`: it runs on Server Core and uses that image's Windows PowerShell for its download stage too.

1. `IMAGE_PATH`: It is used to select the repository for the base image used behind the resulted image.
1. `IMAGE_VERSION`: It is used to select the version for the base image used behind the resulted image.
1. `DOWNLOADER_IMAGE_PATH`: It is used to point towards the [dotnet sdk](https://mcr.microsoft.com/artifact/mar/dotnet/sdk) repository
1. `DOWNLOADER_IMAGE_VERSION`: It can be used to select a different image version for [dotnet sdk](https://mcr.microsoft.com/artifact/mar/dotnet/sdk/tags)

They are configured through the `build => args` section of each service from the [Docker Compose file](./docker-compose.yaml). It relies on values from [.env](./.env) and [Docker Compose interpolation](https://docs.docker.com/compose/how-tos/environment-variables/variable-interpolation/).

**Please be aware that the values set for build arguments in the `docker-compose.yaml` take precedence over the ones set in the Dockerfiles.**

You should consider updating the `MONITORING_VERSION` environment variable before building the patched images. In this way you will be able to rollback to the previous image without rebuilding it if it was running on this Virtual Machine before.

## How to use MCP-Grafana-Server

If you want to use the MCP-Grafana-Server, you have to do the following steps:

- Create a user or a service account in Grafana. **Grant it Viewer (read-only) rights by
  default** - that's sufficient for querying dashboards, logs, metrics and traces. Only grant
  Editor/Admin rights if you specifically need mcp-grafana's write tools (e.g. creating or
  updating dashboards); see [mcp-grafana/Readme.md](./mcp-grafana/Readme.md) for the current
  state of caller authentication on mcp-grafana's own endpoint before deciding how widely
  reachable that account's credentials should be.
- Enter the credentials or the token to the `user.env` file. **`user.env` is tracked in git -
  don't put real credentials in it directly.** Use a local, git-ignored override instead (see
  [Hardening the Stack](#hardening-the-stack)) or a proper secret store for real deployments.
- Use `docker compose --profile mcp <command>` instead of `docker compose <command>`.

## How to download the latest base image

The following command will pull the latest base image version and will rebuild the containers using that base image.

You should consider updating the `MONITORING_VERSION` environment variable before running this command. In this way you will be able to rollback to the previous image without rebuilding it if it was running on this Virtual Machine before.

1. Windows Server 2022

   ```sh
   docker compose --env-file ./.env build --pull
   ```

1. Windows Server 2025

   ```sh
   docker compose --env-file ./.env.2025 build --pull
   ```

## How to change between Windows Server Versions

1. Open a command prompt:

   **Please make sure that your current working of the shell is folder where the `docker-compose.yaml` file is located.**

1. How to run the monitoring poc on `Windows Server 2022`

   This is the default. So you just need to run it with defaults:

   ```sh
   docker compose up -d
   ```

   If you want to be specific:

   ```sh
   docker compose --env-file ./.env up -d
   ```

1. How to run the monitoring poc on `Windows Server 2025`

   ```sh
   docker compose --env-file ./.env.2025 up -d
   ```

   The alternative is to copy the content of `.env.2025` into `.env` and then run the command:

   ```sh
   docker compose up -d
   ```

**The current setup is using [Process Isolation](https://learn.microsoft.com/virtualization/windowscontainers/manage-containers/hyperv-container#process-isolation), which means that you need to respect the [Windows Server host OS compatibility for Process Isolation](https://learn.microsoft.com/virtualization/windowscontainers/deploy-containers/version-compatibility?tabs=windows-server-2025%2Cwindows-11#windows-server-host-os-compatibility).**

1. What values to use in the variables

    **The value for `*_IMAGE_VERSION` variables will differ for each Windows Server Version. Please consider [Windows Server host OS compatibility for Process Isolation](https://learn.microsoft.com/virtualization/windowscontainers/deploy-containers/version-compatibility?tabs=windows-server-2025%2Cwindows-11#windows-server-host-os-compatibility) when you pick the tag.**

    1. `NANOSERVER_IMAGE_PATH`

        The repository for services that use `Nano Server` as a baseimage. Currently we are using the repository provided by [Microsoft](https://mcr.microsoft.com/artifact/mar/windows/nanoserver/about)

        **Please don't change this unless you want to use your own base image**.

    1. `NANOSERVER_IMAGE_VERSION`

        The version of the `Nano Server` image that you want to use. This will differ for each Windows Server Version.

        For available tags see [docs](https://mcr.microsoft.com/artifact/mar/windows/nanoserver/tags).

    1. `DOWNLOADER_IMAGE_PATH`:

        The repository used for the `Powershell` base image. Currently using the repository provided by [Microsoft](https://mcr.microsoft.com/artifact/mar/dotnet/sdk).

        **Please don't change this unless you want to use your own powershell image**.

    1. `DOWNLOADER_IMAGE_VERSION`
        The version of the `Powershell` image that you want to use. This will differ for each Windows Server Version.

        For available tags see [docs](https://mcr.microsoft.com/artifact/mar/dotnet/sdk/tags).

    1. `SERVERCORE_IMAGE_PATH`

        The repository for services that use `Server Core` as a baseimage. Currently we are using the repository provided by [Microsoft](https://mcr.microsoft.com/artifact/mar/windows/servercore/about)

        **Please don't change this unless you want to use your own base image**.

    1. `SERVERCORE_IMAGE_VERSION`
        The version of the `Server Core` image that you want to use. This will differ for each Windows Server Version.

        For available tags see [docs](https://mcr.microsoft.com/artifact/mar/windows/servercore/tags).

    1. `MONITORING_VERSION`

        This variable can be used to version the images for each service. This can be useful if you want to build once all the images and maintain them in a Docker Registry.

## Renovate

```ps1
$env:LOG_LEVEL="debug"
$env:RENOVATE_PLATFORM="local"
$env:RENOVATE_CONFIG_FILE=".ci/renovate.json"
$env:RENOVATE_DRY_RUN="full"
$env:RENOVATE_REQUIRE_CONFIG="optional"
$env:RENOVATE_ONBOARDING="false"
$env:GITHUB_COM_TOKEN="<your-token>"
npx renovate --platform=local --dry-run=full
```
