# Grafana

## Resources

- Official docs [here](https://grafana.com/docs/grafana/latest/).
- Main repository [here](https://github.com/grafana/grafana)

The role of this tools is to allow the user to visualize the collected data.

## How to Configure?

- [Configuration Docs](https://grafana.com/docs/grafana/latest/setup-grafana/configure-grafana/)

When the image is built we are copying [this](./conf.ini) configuration file into the folder `C:\grafana\conf` _inside_ the filesystem of the container.
If you want to update the configurations:

1. You can create a [bind mount](https://docs.docker.com/engine/storage/bind-mounts/) into a custom folder inside the container (Example: `C:\custom`). Please make sure it is outside of the folder `C:\grafana` from a local folder of the _Docker Host_.
   1. Then create a file named `custom.ini` which contains your custom configuration into the folder that you added as binded mount.
   1. In the `docker-compose.yaml` update the `command` for service `grafana`. Set the path for `config` to point towards the file that was binded: Example: `- "--config=C:\\custom\\custom.ini"`.

## How to update datasources?

Currently all datasources are configured in [datasources.yaml](./provisioning/datasources/datasources.yaml). It contains the required configuration for Loki, Prometheus and Tempo.

If you want to make any changes to the datasources please update the above mentioned file. For more details check the [docs](https://grafana.com/docs/grafana/latest/datasources/).

Make sure that you restart the service after any changes to the data sources: `docker compose up -d grafana`.

## How to persist Dashboards?

1. Follow documentation on how to create them: [docs](https://grafana.com/docs/grafana/latest/administration/provisioning/#dashboards).
1. Add all the files to the [dashboards folder](./provisioning/dashboards/).
1. Restart the grafana service: `docker compose up -d grafana`.

## How to patch or update?

The [Dockerfile](./Dockerfile) for the OpenTelemetry Collector has the following Build Arguments that can be used for Patching:

1. `IMAGE_VERSION`: This can be used to select a different version of [Nano Server](https://hub.docker.com/r/microsoft/windows-nanoserver)
1. `DOWNLOADER_IMAGE_VERSION`: This can be used to select a different image version for [Powershell](https://mcr.microsoft.com/en-us/artifact/mar/dotnet/sdk/tags/tags)
1. `GRAFANA_VERSION`: This can be used to select a specific version for Grafana. Please use versions from [GitHub Releases](https://github.com/grafana/grafana/releases).
