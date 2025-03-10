# Introduction

The purpose of this repository is to offer a way the required configuration for collecting distributed logs, traces and metrics.

## Why?

When the landscape of installed services grows, the required effort to identify the possible bugs/issues of the system increases. Having all the traces, logs and metrics collected centrally and correlated will speed up the process of root cause analysis.

## What?

The stack relies on [Grafana](#grafana) as a dashboarding solution, [Grafana Loki](#grafana-loki) for storing logs, [Grafana Tempo](#grafana-tempo) for storing the traces, [Prometheus](#prometheus) for storing the metrics, and the [OpenTelemetry Collector](#opentelemetry-collector) for proxying all the telemetry information from applications into the proper solution that stores them.

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

## General Patching Guidelines

Each service is relying on 4 build arguments that allow you to select the base image repository and version.

1. `IMAGE_PATH`: It is used to select the repository for the base image used behind the resulted image.
1. `IMAGE_VERSION`: It is used to select the version for the base image used behind the resulted image.
1. `DOWNLOADER_IMAGE_PATH`: It is used to point towards the [Powershell](https://mcr.microsoft.com/en-us/artifact/mar/powershell) repository
1. `DOWNLOADER_IMAGE_VERSION`: It can be used to select a different image version for [Powershell](https://mcr.microsoft.com/en-us/artifact/mar/powershell/tags)

They are configured through the `build => args` section of each service from the [Docker Compose file](./docker-compose.yaml). It relies on values from [.env](./.env) and [Docker Compose interpolation](https://docs.docker.com/compose/how-tos/environment-variables/variable-interpolation/).

**Please be aware that the values set for build arguments in the `docker-compose.yaml` take precedence over the ones set in the Dockerfiles.**

You should consider updating the `MONITORING_VERSION` environment variable before building the patched images. In this way you will be able to rollback to the previous image without rebuilding it if it was running on this Virtual Machine before.

## How to download the latest base image

The following command will pull the latest base image version and will rebuild the containers using that base image.

You should consider updating the `MONITORING_VERSION` environment variable before running this command. In this way you will be able to rollback to the previous image without rebuilding it if it was running on this Virtual Machine before.

1. Windows Server 2022

   ```
   docker compose --env-file ./.env build --pull
   ```

1. Windows Server 2019

   ```
   docker compose --env-file ./.env.2019 build --pull
   ```

## How to change between Windows Server Versions

1. Open a command prompt:

   **Please make sure that your current working of the shell is folder where the `docker-compose.yaml` file is located.**

1. How to run the monitoring poc on `Windows Server 2022`

   This is the default. So you just need to run it with defaults:

   ```
   docker compose up -d
   ```

   If you want to be specific:

   ```
   docker compose --env-file ./.env up -d
   ```

1. How to run the monitoring poc on `Windows Server 2019`

   ```
   docker compose --env-file ./.env.2019 up -d
   ```

   The alternative is to copy the content of `.env.2019` into `.env` and then run the command:

   ```
   docker compose up -d
   ```

**The current setup is using [Process Isolation](https://learn.microsoft.com/en-us/virtualization/windowscontainers/manage-containers/hyperv-container#process-isolation), which means that you need to respect the [Windows Server host OS compatibility for Process Isolation](https://learn.microsoft.com/en-us/virtualization/windowscontainers/deploy-containers/version-compatibility?tabs=windows-server-2025%2Cwindows-11#windows-server-host-os-compatibility).**

1.  What values to use in the variables

    **The value for `*_IMAGE_VERSION` variables will differ for each Windows Server Version. Please consider [Windows Server host OS compatibility for Process Isolation](https://learn.microsoft.com/en-us/virtualization/windowscontainers/deploy-containers/version-compatibility?tabs=windows-server-2025%2Cwindows-11#windows-server-host-os-compatibility) when you pick the tag.**

    1.  `NANOSERVER_IMAGE_PATH`

        The repository for services that use `Nano Server` as a baseimage. Currently we are using the repository provided by [Microsoft](https://mcr.microsoft.com/en-us/artifact/mar/windows/nanoserver/about)

        **Please don't change this unless you want to use your own base image**.

    1.  `NANOSERVER_IMAGE_VERSION`

        The version of the `Nano Server` image that you want to use. This will differ for each Windows Server Version.

        For available tags see [docs](https://mcr.microsoft.com/en-us/artifact/mar/windows/nanoserver/tags).

    1.  `DOWNLOADER_IMAGE_PATH`:

        The repository used for the `Powershell` base image. Currently using the repository provided by [Microsoft](https://mcr.microsoft.com/artifact/mar/powershell).

        **Please don't change this unless you want to use your own powershell image**.

    1.  `DOWNLOADER_IMAGE_VERSION`
        The version of the `Powershell` image that you want to use. This will differ for each Windows Server Version.

        For available tags see [docs](https://mcr.microsoft.com/en-us/artifact/mar/powershell/tags).

    1.  `SERVERCORE_IMAGE_PATH`

        The repository for services that use `Server Core` as a baseimage. Currently we are using the repository provided by [Microsoft](https://mcr.microsoft.com/en-us/artifact/mar/windows/servercore/about)

        **Please don't change this unless you want to use your own base image**.

    1.  `SERVERCORE_IMAGE_VERSION`
        The version of the `Server Core` image that you want to use. This will differ for each Windows Server Version.

        For available tags see [docs](https://mcr.microsoft.com/en-us/artifact/mar/windows/servercore/tags).

    1.  `MONITORING_VERSION`

        This variable can be used to version the images for each service. This can be useful if you want to build once all the images and maintain them in a Docker Registry.
