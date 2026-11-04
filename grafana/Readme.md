# Grafana

## Resources

- [Official docs](https://grafana.com/docs/grafana/latest/).
- [Main repository](https://github.com/grafana/grafana)

The role of this tools is to allow the user to visualize the collected data.

## How to Configure?

- [Configuration Docs](https://grafana.com/docs/grafana/latest/setup-grafana/configure-grafana/)

When the image is built we are copying [this](./conf.ini) configuration file into the folder `C:\grafana\conf` _inside_ the filesystem of the container.
If you want to update the configurations:

1. You can create a [bind mount](https://docs.docker.com/engine/storage/bind-mounts/) into a custom folder inside the container (Example: `C:\custom`). Please make sure it is outside of the folder `C:\grafana` from a local folder of the _Docker Host_.
   1. Then create a file named `custom.ini` which contains your custom configuration into the folder that you added as binded mount.
   1. In the `docker-compose.yaml` update the `command` for service `grafana`. Set the path for `config` to point towards the file that was binded: Example: `- "--config=C:\\custom\\custom.ini"`.

## How to enable HTTPS?

By default Grafana is served over plain HTTP. See [Hardening the Stack](../Readme.md#hardening-the-stack)
in the root Readme for how to switch it to HTTPS with your own certificate.

## How to update datasources?

Currently all datasources are configured in [datasources.yaml](./provisioning/datasources/datasources.yaml). It contains the required configuration for Loki, Prometheus and Tempo.

If you want to make any changes to the datasources please update the above mentioned file. For more details check the [docs](https://grafana.com/docs/grafana/latest/datasources/).

Make sure that you restart the service after any changes to the data sources: `docker compose up -d grafana`.

## How to persist Dashboards?

1. Follow documentation on how to create them: [docs](https://grafana.com/docs/grafana/latest/administration/provisioning/#dashboards).
1. Add all the files to the [dashboards folder](./provisioning/dashboards/).
1. Restart the grafana service: `docker compose up -d grafana`.

### A+W Cantor template dashboards

Dashboards shipped by A+W Cantor live under `./provisioning/dashboards/cantor/` and are provisioned into
a dedicated Grafana folder, **"A+W Cantor (Templates)"** (see `dashboards.yaml`). The name is intentional:
these are starting points customers/teams are expected to duplicate ("Save As" into another folder) and
adapt, not edit in place — the provider sets `allowUiUpdates: false`, so direct edits are rejected and any
in-place changes would be reverted on the next provisioning sync anyway.

To add another dashboard to this set:

1. Export it as classic-schema JSON (not the newer `dashboard.grafana.app/v2` export — Grafana 13's
   file-based provisioner rejects that format, see [grafana#122663](https://github.com/grafana/grafana/issues/122663)).
   If you only have a live dashboard, `GET /api/dashboards/uid/{uid}` on the source instance returns the
   classic model directly.
2. Strip the instance-specific `id` and `version` fields, but keep a fixed `uid` so re-provisioning updates
   the dashboard in place instead of creating a duplicate.
3. Set `tags` to exactly `["cantor", "<name-after-cantor->"]`, e.g. `cantor-services-health.json` gets
   `["cantor", "services-health"]`. The `cantor` tag lets every dashboard in this set be filtered for as a
   group; the second tag identifies the individual dashboard.
4. Drop the file into `./provisioning/dashboards/cantor/` and restart the grafana service.

## How to patch or update?

The [Dockerfile](./Dockerfile) for Grafana has the following Build Arguments that can be used for Patching:

1. `IMAGE_VERSION`: This can be used to select a different version of [Server Core](https://mcr.microsoft.com/artifact/mar/windows/servercore/tags), used for both the download stage and the final image.
   Grafana runs on Server Core rather than Nano Server because its embedded NATS server panics at startup on
   Nano Server ltsc2025 (`Failed to find PdhOpenQuery procedure in pdh.dll`, see
   [nats-io/nats-docker#260](https://github.com/nats-io/nats-docker/issues/260)).
1. `GRAFANA_VERSION`: This can be used to select a specific version for Grafana. Please use versions from [GitHub Releases](https://github.com/grafana/grafana/releases).
1. `INFINITY_DATASOURCE_VERSION`: This can be used to select a specific version of the
   [Infinity datasource plugin](https://github.com/grafana/grafana-infinity-datasource) bundled into the
   image. Please use versions from [GitHub Releases](https://github.com/grafana/grafana-infinity-datasource/releases).
   It is pinned and fetched via `ADD` (then unpacked straight into the plugins folder) rather than via
   `grafana cli plugins install`, because that CLI command resolves the latest version through
   `grafana.com/api/plugins/.../versions` at build time, which has proven unreliable behind a restrictive
   firewall/proxy (the plugin archive itself downloads fine - it's that metadata lookup that times out).
