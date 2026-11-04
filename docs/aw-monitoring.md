# A+W Monitoring

The A+W Monitoring stack is based on Grafana, Loki, Tempo, and Prometheus. It provides a
comprehensive solution for monitoring, logging, and tracing within the A+W environment. A+W tools
instrumented with the OpenTelemetry standard send metrics, logs, and traces to this monitoring
stack.

Grafana is used to visualize the collected data, while Loki handles log aggregation, Tempo manages
distributed tracing, and Prometheus is responsible for metrics collection.

## Default Datasources in Grafana

- Loki for logs
- Tempo for traces
- Prometheus for metrics

## For all datasources

All queries in Grafana are case-sensitive. Make sure to use the correct casing when specifying
labels and values.

### Case-Sensitive Log Levels

The `detected_level` label differs by service type:

| Service type | ERROR | WARNING | INFO | DEBUG |
|---|---|---|---|---|
| `Ca*.exe` (native apps) | `ERROR` | `WARNING` | `INFO` | `DEBUG` |
| `Cantor.*API` (.NET APIs) | `Error` | `Warning` | `Info` | `Debug` |
| `Cantor.*MessageBus` (EventStoreDB) | `error` | `warn` | `info` | `debug` |

To query across all service types, use a regex alternation:
- Error: `detected_level=~"ERROR|Error|error"`
- Warning: `detected_level=~"WARNING|Warning|warn"`
- Info: `detected_level=~"INFO|Info|info"`
- Debug: `detected_level=~"DEBUG|Debug|debug"`

## Service Names

Always filter by `service_name`. Known services:

| service_name | Description |
|---|---|
| `Cantor.ERP.API` | A+W Cantor Services for ERP (A+W Cantor) |
| `Cantor.CIM.API` | A+W Cantor Services for CIM (A+W Cantor CIM) |
| `CaMessageBusWorkerU.exe` | A+W Cantor Message Bus Worker process |
| `Cantor.MessageBus` | The message bus itself (EventStoreDB); deployments may name it `Cantor.ERP.MessageBus` or `Cantor.CIM.MessageBus` |
| `CaMainU.exe` | The A+W Cantor application |
| `CaSpManU.exe` | The A+W Cantor Spooler application |
| `CaSysU.exe` | The A+W Cantor System Manager application |
| `CaCCSBU.exe` | The A+W Cantor Communication Service Bus application for intra-company transport |
| Other `Ca*.exe` | Other A+W Cantor applications |

To match all Cantor services: `service_name=~"Ca.*exe|Cantor.*API|Cantor.*MessageBus"`

## How to query logs from Loki

**Indexed labels** (use in the stream selector `{...}` for best performance):
- `service_name`
- `deployment_environment_name` — e.g. `production`, `staging`, `test`. Ask the user if unsure.

**Non-indexed labels** (use in pipeline filters `|` after the stream selector):
- `detected_level`
- `host_name`
- `process_executable_name`
- `process_pid`
- `process_user_name`
- `scope_name`

Query rules:
1. Always put indexed labels in the stream selector `{...}`.
2. Filter on non-indexed labels in the pipeline using `|`.
3. Use `|=` for substring matches, `|~` for regex matches.
4. Combine multiple `|=` filters with `and` (implicit) or `or` for alternatives.
5. When the user does not specify a time range, use the last 1 hour as default.

Examples:

- All error logs from the A+W Cantor applications:
  ```logql
  {service_name=~"Ca.*exe|Cantor.*API"} | detected_level=~"ERROR|Error"
  ```
- Warnings from the ERP API:
  ```logql
  {service_name="Cantor.ERP.API"} | detected_level=~"WARNING|Warning"
  ```
- Logs from `CaMessageBusWorkerU.exe` containing both `SELECT COUNT(*)` **and** `PRODCONF WHERE CODE = 1`:
  ```logql
  {service_name="CaMessageBusWorkerU.exe"} |= `SELECT COUNT(*)` |= `PRODCONF WHERE CODE = 1`
  ```
- Logs from `CaMessageBusWorkerU.exe` containing either `SELECT * FROM` **or** `PRODCONF WHERE CODE = 1`:
  ```logql
  {service_name="CaMessageBusWorkerU.exe"} |= `SELECT * FROM` or `PRODCONF WHERE CODE = 1`
  ```

When a trace ID appears in a log line, mention that it can be correlated in Tempo.

## How to query traces from Tempo

Guidelines for querying spans and traces using TraceQL:

- The service name is not required.
- Filtering on `status` can be helpful. Common status values include `ok`, `error`, and `unset`.

Examples:

- All spans/traces with an error status:
  ```traceql
  status="error"
  ```
- All spans/traces that took longer than 500 milliseconds:
  ```traceql
  {duration>500ms}
  ```
- Spans/traces with a specific operation name, e.g. `POST int/v1/Login`:
  ```traceql
  {name="POST int/v1/Login"}
  ```

## How to query metrics from Prometheus

Metrics are collected by the OpenTelemetry Collector Contrib receivers:
- Host metrics receiver for Windows system metrics (see [host-metrics.md](./host-metrics.md)).
- SQL Query receiver for custom metrics.
- Docker Stats receiver for docker container metrics.
