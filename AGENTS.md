# AGENTS.md

Instructions for AI coding agents working in this repository.

## What is this repo?

A+W Monitoring packages a Docker Compose stack for collecting logs, traces, and metrics:

- OpenTelemetry Collector
- Loki (logs)
- Tempo (traces)
- Prometheus (metrics)
- Grafana (dashboards)
- MCP-Grafana (lets an AI chat query Grafana's data directly via MCP)

See the [root Readme](./Readme.md) for the full component breakdown, build/patch arguments, and how
to build, run, and switch Windows Server versions.

## `isolation: process` is required on every service

Every service in `docker-compose.yaml` sets `isolation: process`. **Do not remove it.** It was
originally added for Prometheus and Loki specifically to fix TSDB/file-access errors (rename
failures like `The system cannot find the path specified` during compaction) that occur under
Hyper-V isolation on Windows containers, then later generalized to all services for consistency.
It was removed once in the past and the file-access errors came back - if you
ever see Prometheus logging `compaction failed ... rename block dir` or similar Windows file errors,
check this setting first before assuming it's an application bug.

## Querying data via MCP-Grafana

The MCP-Grafana server (MCP server name `grafana`) can query logs, metrics, and traces from
Grafana. See [docs/aw-monitoring.md](./docs/aw-monitoring.md) for datasources, label conventions
(including a case-sensitivity gotcha that affects every query), and LogQL/TraceQL/PromQL examples.
For host/process metrics specifically, see [docs/host-metrics.md](./docs/host-metrics.md).

## Visualization in tables

When generating visualizations in tables, please use the following format:

- Numeric values should be aligned to the right.
- Text values should be aligned to the left.
- Use appropriate headers for each column.
- Add units of measurement where applicable.
- Convert bytes to KB, MB, or GB for better readability.
