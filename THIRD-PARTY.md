# Third-Party Software

The images built from this repository contain the unmodified official release binaries of the
components below. Their versions are the `*_VERSION` build arguments in
[docker-compose.yaml](./docker-compose.yaml) and the Dockerfiles; each source link points to the
release tag of that version.

| Image         | Component                       | License    | License text in the image                                      | Source code                                                                             |
| :------------ | :------------------------------ | :--------- | :------------------------------------------------------------- | :-------------------------------------------------------------------------------------- |
| `grafana`     | Grafana                         | AGPL-3.0   | `C:\grafana\LICENSE`, `C:\grafana\NOTICE.md`                   | `https://github.com/grafana/grafana/tree/v<GRAFANA_VERSION>`                            |
| `grafana`     | Infinity datasource plugin      | Apache-2.0 | `C:\grafana\plugins\yesoreyeram-infinity-datasource\LICENSE`   | `https://github.com/grafana/grafana-infinity-datasource/tree/v<INFINITY_DATASOURCE_VERSION>` |
| `loki`        | Grafana Loki                    | AGPL-3.0   | `C:\loki\LICENSE`, `C:\loki\LICENSING.md`                      | `https://github.com/grafana/loki/tree/v<LOKI_VERSION>`                                  |
| `tempo`       | Grafana Tempo                   | AGPL-3.0   | `C:\tempo\LICENSE`                                             | `https://github.com/grafana/tempo/tree/v<TEMPO_VERSION>`                                |
| `prometheus`  | Prometheus                      | Apache-2.0 | `C:\prometheus\LICENSE`, `C:\prometheus\NOTICE`                | `https://github.com/prometheus/prometheus/tree/v<PROMETHEUS_VERSION>`                   |
| `collector`   | OpenTelemetry Collector Contrib | Apache-2.0 | `C:\collector\LICENSE`, `C:\collector\NOTICE`                  | `https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/v<COLLECTOR_VERSION>` |
| `mcp-grafana` | Grafana MCP server              | Apache-2.0 | `C:\mcp-grafana\LICENSE`                                       | `https://github.com/grafana/mcp-grafana/tree/v<MCP_GRAFANA_VERSION>`                    |

The source code of the AGPL-3.0 components is the complete corresponding source of the shipped
binaries. The build and install scripts are the Dockerfiles and configuration files in this
repository.

## Windows base images

All images are based on Windows Nano Server or Windows Server Core images, which are licensed under
the
[Microsoft Software Supplemental License for Windows Container Base Image](https://learn.microsoft.com/virtualization/windowscontainers/images-eula).
They may only be used on a validly licensed Windows Server (or, for test and development, Windows)
host.
