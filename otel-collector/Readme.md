# OpenTelemetry Collector

## Resources

- [Official docs](https://opentelemetry.io/docs/collector/).
- [Main repository](https://github.com/open-telemetry/opentelemetry-collector-contrib)

The role of this tools is to act as a proxy for Logs, Metrics and Traces. All applications are sending all telemetry to the collector which will forward them to the appropriate tool.

## How to Configure?

- [Configuration Docs](https://opentelemetry.io/docs/collector/configuration/)

When the image is built we are copying [this](./config/otel-colector.config.yaml) configuration file into the folder `C:\collector\config\` _inside_ the filesystem of the container.
If you want to update the configurations:

1. You can create a [bind mount](https://docs.docker.com/engine/storage/bind-mounts/) into the folder `C:\collector\config\` from a local folder of the _Docker Host_. Then create a file named `otel-colector.config.yaml` which contains your custom configuration. Please make sure that you copy the settings that you need from the original file since there is no inheritance in place.

### How to debug

In the current architecture the role of the OpenTelemetry Collector is to proxy all `logs`, `traces` and `metrics` that the applications are generating into the service that is persisting and analyzing them.
One of the recurrent problems that developers have is to identify which `logs`, `traces` or `metrics` are received by the Collector but not present in the downstream service. That can be identified by following the steps:

1. Open the configuration file for OpenTelemetry Collector: [otel-colector.config.yaml](./config/otel-colector.config.yaml)
1. Go to section: `service => pipelines`.
1. Add `debug` to the `exporters` section of the debugged telemetry. This relies on the [debug exporter](https://github.com/open-telemetry/opentelemetry-collector/blob/main/exporter/debugexporter/README.md).
1. Check the console logs for the OpenTelemetry Collector. Now it should contain all the received data for that `telemetry` by the Collector.

For more details please check [troubleshooting docs](https://opentelemetry.io/docs/collector/troubleshooting/).

## How to patch or update?

The [Dockerfile](./Dockerfile) for the OpenTelemetry Collector has the following Build Arguments that can be used for Patching:

1. `IMAGE_VERSION`: This can be used to select a different version of [Nano Server](https://hub.docker.com/r/microsoft/windows-nanoserver)
1. `DOWNLOADER_IMAGE_VERSION`: This can be used to select a different image version for [dotnet sdk](https://mcr.microsoft.com/artifact/mar/dotnet/sdk)
1. `COLLECTOR_VERSION`: This can be used to select a specific version for OpenTelemetry Collector. Please use versions from [GitHub Releases](https://github.com/open-telemetry/opentelemetry-collector-releases/releases).
