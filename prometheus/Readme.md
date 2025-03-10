# Prometheus

## Resources:

- Official docs [here](https://prometheus.io/docs/introduction/overview/).
- Main repository [here](https://github.com/prometheus/prometheus)

The role of this tools is to ingest, store, search and filter all the `metrics` that the applications generate.

## How to Configure?

- [Configuration Docs](https://prometheus.io/docs/prometheus/latest/configuration/configuration/)

When the image is built we are copying [this](./config/prometheus.yaml) configuration file into the folder `C:\prometheus\config\` _inside_ the filesystem of the container.
If you want to update the configurations:

1. You can create a [bind mount](https://docs.docker.com/engine/storage/bind-mounts/) into the folder `C:\prometheus\config\` from a local folder of the _Docker Host_. Then create a file named `prometheus.yaml` which contains your custom configuration. Please make sure that you copy the settings that you need from the original file since there is no inheritance in place.

## How to patch or update?

The [Dockerfile](./Dockerfile) for the Prometheus has the following Build Arguments that can be used for Patching:

1. `IMAGE_VERSION`: This can be used to select a different version of [Server Core](https://mcr.microsoft.com/en-us/artifact/mar/windows/servercore/tags)
1. `DOWNLOADER_IMAGE_VERSION`: This can be used to select a different image version for [Powershell](https://mcr.microsoft.com/en-us/artifact/mar/powershell/tags)
1. `PROMETHEUS_VERSION`: This can be used to select a specific version for Prometheus. Please use versions from [GitHub Releases](https://github.com/prometheus/prometheus/releases).
