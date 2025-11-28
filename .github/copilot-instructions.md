# Instructions for GitHub Copilot

A+W Monitoring include these services:

- OpenTelemetry Collector
- Loki
- Tempo
- Prometheus
- Grafana
- MCP-Grafana

## MCP-Grafana Server

A+W Monitoring includes the MCP-Grafana container, which can be used by an AI Chat like Copilot.

The MCP-Grafana server (mcp server name is `grafana`) is able to query data from grafana. It provides logs, metrics, and traces.

For more details about the A+W Monitoring stack and its components, please check the [A+W Monitoring Instructions](./instructions/aw-monitoring.instructions.md).

## Visualization in tables

When generating visualizations in tables, please use the following format:

- Numeric values should be aligned to the right.
- Text values should be aligned to the left.
- Use appropriate headers for each column.
- Add units of measurement where applicable.
- Convert bytes to KB, MB, or GB for better readability.
