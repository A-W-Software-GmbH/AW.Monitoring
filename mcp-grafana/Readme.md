# MCP Grafana

## Resources

- [Main repository](https://github.com/grafana/mcp-grafana)

The role of this tools is to provide a MCP-Server that interacts with grafana..

## How to Configure?

- [Configuration Docs](https://github.com/grafana/mcp-grafana)

There are environment variables to configure the MCP-Server:

- **GRAFANA_URL** The url to access grafana `http://grafana:3000`.
- **GRAFANA_SERVICE_ACCOUNT_TOKEN** The token for the authentication.
- **GRAFANA_USERNAME** The user for the authentication.
- **GRAFANA_PASSWORD** The password for the authentication.
- **MCP_ALLOWED_HOSTS** Host-header allowlist for mcp-grafana's own HTTP endpoint (comma-separated,
  or `*` to disable). See "How to reach mcp-grafana through the docker-compose port mapping?" below.
- **GRAFANA_TLS_SKIP_VERIFY** Set `true` to always skip TLS verification when calling `GRAFANA_URL`.
  See "How to access Grafana over HTTPS?" below.
- **MCP_GRAFANA_SERVER_TOKEN** Sets a bearer token that mcp-grafana's own HTTP endpoint requires
  from every caller. As of the `MCP_GRAFANA_VERSION` pinned here (2.2.0), the binary reads this
  environment variable directly as a fallback for `--server-auth-token` - no change to the
  container's `CMD` is needed for it to take effect. **It is unset by default**, and until you set
  it, mcp-grafana logs this at startup: `SECURITY: serving on a non-loopback address with NO caller
  authentication` - Grafana has stated this will become a hard startup error in a future release.
  With no token set, anyone who can reach port `38000` can invoke MCP tools with whatever Grafana
  credentials this server is configured with; `MCP_ALLOWED_HOSTS` does **not** cover this - the
  Host-header allowlist only guards against DNS rebinding, it is not an authentication mechanism.
  **Set this variable in [`user.env`](../user.env) to a locally-held secret for any deployment
  reachable from outside the docker host:**

  ```
  MCP_GRAFANA_SERVER_TOKEN=<a locally generated secret, not committed anywhere>
  ```

  Even with the token set, also restrict network reachability as defense in depth - e.g. bind the
  host port to loopback only via a local `docker-compose.override.yaml`
  (see [Hardening the Stack](../Readme.md#hardening-the-stack) in the root Readme for the override
  pattern used for Grafana's own HTTPS setup). Compose merges `ports:` lists from the base file and
  overrides together rather than replacing them, so simply repeating the key does **not** remove the
  original, unrestricted port mapping - use the `!override` merge key to replace it outright:

  ```yaml
  services:
    mcp-grafana:
      ports: !override
        - "127.0.0.1:38000:8000"
  ```

  `!override` requires Compose Specification support for merge keys (recent `docker compose`
  versions); confirm with `docker compose ... config` that only the loopback-bound entry remains.

  mcp-grafana also always serves its own endpoint over plain HTTP, with no TLS option currently
  wired up in this image - keep that in mind if you widen reachability beyond loopback, since
  credentials and tool calls would then also travel unencrypted.

## How to access Grafana over HTTPS?

mcp-grafana itself always keeps serving plain HTTP on port 8000 — this only affects how it calls
`GRAFANA_URL`. Set `GRAFANA_URL` to `https://grafana:3000` (see
[`grafana/Readme.md`](../grafana/Readme.md#how-to-enable-https) for enabling HTTPS on Grafana
itself), and set `GRAFANA_TLS_SKIP_VERIFY=true` in [`user.env`](../user.env).

Skipping verification (rather than trusting Grafana's cert via a CA file) is a shortcut, not a
secure default: certificate hostname matching would still apply, and `GRAFANA_URL` uses the
docker-compose service name (`grafana`), while certs are typically issued for the browser-facing
hostname you actually type into a URL bar (e.g. `*.example.com`), and those two essentially never match
without a SAN specifically covering `grafana`.

**This is not mitigated by network isolation.** `docker-compose.yaml` attaches every service to the
external Windows NAT network (`name: nat`, `external: true`) rather than a network created and
owned exclusively by this stack - other containers on the same Windows host can join that same
network and potentially observe or intercept this traffic. Treat `GRAFANA_TLS_SKIP_VERIFY=true` as
an explicitly insecure test/exception setting, not as something made safe by network membership.

The regular, secure path is to either issue/reconfigure the certificate so its SAN covers the
hostname mcp-grafana actually connects to (`grafana`), or to trust Grafana's CA via a CA bundle
instead of skipping verification - neither is currently wired up in this image.

## How to reach mcp-grafana through the docker-compose port mapping?

mcp-grafana rejects requests whose `Host` header isn't in its allowlist (a DNS-rebinding guard),
which by default only accepts loopback variants of its own `--address` (`localhost:8000`). Calls
through the docker-compose port mapping (`38000:8000`) arrive with `Host: localhost:38000` instead,
so they get `403 forbidden: host not allowed` unless `MCP_ALLOWED_HOSTS` in [`user.env`](../user.env)
covers that host:port too. It defaults to `*` (allow everything), which is only safe as long as port
`38000` isn't reachable from outside the docker host — narrow it to a comma-separated list (e.g.
`localhost:38000,127.0.0.1:38000`) if that stops being true.

## Why does mcp-grafana stop working after restarting Grafana?

mcp-grafana resolves and caches the `grafana` hostname when it starts. If only the `grafana`
container is restarted afterwards, it comes back with a new internal IP, and mcp-grafana keeps
calling the old (now dead) one until it is restarted too - calls then fail with
`dial tcp <old-ip>:3000: i/o timeout`. Always restart both together:
`docker compose restart grafana mcp-grafana`.

## How to patch or update?

The [Dockerfile](./Dockerfile) for the MCP-Grafana has the following Build Arguments that can be used for Patching:

1. `IMAGE_VERSION`: This can be used to select a different version of [Nano Server](https://hub.docker.com/r/microsoft/windows-nanoserver)
1. `DOWNLOADER_IMAGE_VERSION`: This can be used to select a different image version for [dotnet sdk](https://mcr.microsoft.com/artifact/mar/dotnet/sdk)
1. `MCP_GRAFANA_VERSION`: This can be used to select a specific version for MCP-Grafana. Please use versions from [GitHub Releases](https://github.com/grafana/mcp-grafana/releases).
