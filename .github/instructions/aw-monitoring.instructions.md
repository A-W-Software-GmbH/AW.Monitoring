# A+W Monitoring

The A+W Monitoring stack is based on Grafana, loki, tempo, and prometheus. It provides a comprehensive solution for monitoring, logging, and tracing within the A+W environment. The A+W tools using the OpenTelemetry standard are instrumented to send metrics, logs, and traces to this monitoring stack.

Grafana is used to visualize the collected data, while Loki handles log aggregation, Tempo manages distributed tracing, and Prometheus is responsible for metrics collection.

A+W Monitoring includes the MCP-Grafana container, which can be used by an an AI Chat like Copilot.

## Default Datasources in Grafana

The A+W Monitoring stack includes the following default datasources:

- Loki for logs
- Tempo for traces
- Prometheus for metrics

## For all datasources

All queries in Grafana are case-sensitive. Make sure to use the correct casing when specifying labels and values.

It is important to use different writings. For example the detected level for an information is `INFO` in all `Ca.*exe` services and `Info` in all `Cantor.*API` services.

Here a list where this behavior is relevant:

- Loki
  - detected_level label

## How to query logs from Loki

Here are some guidelines for querying logs from Loki using LogQL:

- Always use the `service_name` label to filter logs by service. Possible values are:
  - `Cantor.ERP.API` - The A+W Cantor Services for ERP (A+W Cantor).
  - `Cantor.CIM.API` - The A+W Cantor Services for CIM (A+W Cantor CIM).
  - `CaMessageBusWorkerU.exe` - The A+W Cantor Message Bus Worker process.
  - `CaMainU.exe` - The A+W Cantor application.
  - `CaSpManU.exe` - The A+W Cantor Spooler application.
  - `CaSysU.exe` - The A+W Cantor System Manager application.
  - `CaCCSBU.exe` - The A+W Cantor Communication Service Bus application for the intra company transport.
  - Others `Ca*.exe` - Other A+W Cantor applications.
- The log level can be filtered using the `detected_level` label. Common log levels include `INFO`, `WARNING`, `ERROR`, and `DEBUG` for the service names `Ca.*exe` and `Info`, `Warning`, `Error`, and `Debug` for the service names `Cantor.*API`.

Examples:

- To retrieve all error logs from the A+W Cantor applications:
  ```
  {service_name=~"Ca.*exe|Cantor.*API"} | detected_level=~`ERROR|Error`|= ``
  ```
- To get all logs from the `CaMessageBusWorkerU.exe` service containing the text parts `SELECT COUNT(*)` **and** `PRODCONF WHERE CODE = 1`:
  ```
  {service_name="CaMessageBusWorkerU.exe"} |= `SELECT COUNT(*)` |= `PRODCONF WHERE CODE = 1`
  ```
- To get all logs from the `CaMessageBusWorkerU.exe` service containing the text parts `SELECT * FROM` **or** `PRODCONF WHERE CODE = 1`:
  ```
  {service_name="CaMessageBusWorkerU.exe"} |= `SELECT * FROM` or `PRODCONF WHERE CODE = 1`
  ```

## How to query traces from Tempo

Here are some guidelines for querying spans and traces from Tempo using TraceQL:

- The service names are not required.
- Filter on the `status` can be helpful. Common status values include `ok`, `error`, and `unset`.

Examples:

- To retrieve all spans/traces with an error status:
  ```
  status="error"
  ```
- To get all spans/traces that took longer than 500 milliseconds:
  ```
  {duration>500ms}
  ```
- To find spans/traces that contain a specific operation name, such as `POST int/v1/Logi`:
  ```
  {name="POST int/v1/Login"}
```

## How to query metrics from Prometheus

Here are some guidelines for querying metrics from Prometheus using PromQL:

- Metrics will be collected be the OpenTelemetry Collector Contrib receivers.
  - Host metrics receiver for Windows system metrics.
  - SQL Query receiver for custom metrics.
  - Docker Stats receiver for docker container metrics.