# Grafana Tempo

## Resources

- [Official docs](https://grafana.com/docs/tempo/latest/).
- [Main repository](https://github.com/grafana/tempo)

The role of this tools is to ingest, store, search and filter all the `traces` that the applications generate.

## How to Configure?

- [Configuration Docs](https://grafana.com/docs/tempo/latest/configuration/)

When the image is built we are copying [this](./config/tempo.yaml) configuration file into the folder `C:\tempo\config\` _inside_ the filesystem of the container.
If you want to update the configurations:

1. You can create a [bind mount](https://docs.docker.com/engine/storage/bind-mounts/) into the folder `C:\tempo\config\` from a local folder of the _Docker Host_. Then create a file named `tempo.yaml` which contains your custom configuration. Please make sure that you copy the settings that you need from the original file since there is no inheritance in place.

## How to patch or update?

The [Dockerfile](./Dockerfile) for the Grafana Tempo has the following Build Arguments that can be used for Patching:

1. `IMAGE_VERSION`: This can be used to select a different version of [Server Core](https://mcr.microsoft.com/artifact/mar/windows/servercore/tags)
1. `DOWNLOADER_IMAGE_VERSION`: This can be used to select a different image version for [dotnet sdk](https://mcr.microsoft.com/artifact/mar/dotnet/sdk)
1. `TEMPO_VERSION`: This can be used to select a specific version for Grafana Tempo. Please use versions from [GitHub Releases](https://github.com/grafana/tempo/releases).
