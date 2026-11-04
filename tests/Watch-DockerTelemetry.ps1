<#
.SYNOPSIS
    Periodically collects docker stats metrics and AW.Monitoring container logs and
    forwards them to the OpenTelemetry Collector as OTLP metrics/logs, wrapped in a
    trace that records how long each run took. Runs until ESC is pressed.

.PARAMETER OtlpEndpoint
    Base URL of the OTLP HTTP receiver (otel-collector).

.PARAMETER IntervalSeconds
    Delay between runs.

.PARAMETER ContainerNameFilter
    Regex used to select which running containers count as "AW.Monitoring containers".
#>

param(
    [string]$OtlpEndpoint = "http://localhost:34318",
    [int]$IntervalSeconds = 60,
    [string]$ContainerNameFilter = "awmonitoring"
)

$ErrorActionPreference = "Stop"

$unitMultipliers = @{
    "B" = 1
    "kB" = 1000; "KiB" = 1024
    "MB" = 1000 * 1000; "MiB" = 1024 * 1024
    "GB" = 1000 * 1000 * 1000; "GiB" = 1024 * 1024 * 1024
    "TB" = 1000 * 1000 * 1000 * 1000; "TiB" = 1024 * 1024 * 1024 * 1024
}

function New-HexId {
    param([int]$Bytes)
    $buffer = New-Object byte[] $Bytes
    [System.Security.Cryptography.RandomNumberGenerator]::Fill($buffer)
    -join ($buffer | ForEach-Object { $_.ToString("x2") })
}

function Get-UnixNano {
    param([datetime]$Time)
    $epoch = [datetime]::new(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)
    return [string](($Time.ToUniversalTime() - $epoch).Ticks * 100)
}

function ConvertTo-DoubleSafe {
    param([string]$Value)
    $parsed = 0.0
    if ([double]::TryParse($Value, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$parsed)) {
        return $parsed
    }
    return 0.0
}

function ConvertTo-Bytes {
    param([string]$Value)
    if ($Value -match '^([\d.]+)\s*([A-Za-z]*)$') {
        $number = [double]$Matches[1]
        $unit = if ([string]::IsNullOrEmpty($Matches[2])) { "B" } else { $Matches[2] }
        if ($unitMultipliers.ContainsKey($unit)) {
            return $number * $unitMultipliers[$unit]
        }
    }
    return 0.0
}

function Get-MonitoringContainerNames {
    param([string]$Filter)
    docker ps --format "{{.Names}}" | Where-Object { $_ -match $Filter }
}

function Send-OtlpPayload {
    param([string]$Path, [hashtable]$Payload, [string]$Description)
    try {
        $json = $Payload | ConvertTo-Json -Depth 20 -Compress
        Invoke-RestMethod -Uri "$OtlpEndpoint$Path" -Method Post -ContentType "application/json" -Body $json | Out-Null
        return $true
    }
    catch {
        Write-Warning "Failed to send $Description to ${OtlpEndpoint}${Path}: $_"
        return $false
    }
}

function New-MetricDataPoint {
    param([string]$ContainerName, [string]$TimeUnixNano, [double]$Value)
    [ordered]@{
        attributes = @(@{ key = "container.name"; value = @{ stringValue = $ContainerName } })
        timeUnixNano = $TimeUnixNano
        asDouble = $Value
    }
}

function Send-DockerStatsMetrics {
    param([string[]]$ContainerNames)

    $now = Get-UnixNano -Time (Get-Date)
    $rawStats = docker stats --no-stream --format "{{json .}}" | ForEach-Object { $_ | ConvertFrom-Json }
    $rawStats = $rawStats | Where-Object { $ContainerNames -contains $_.Name }

    $metricPoints = @{
        "docker.stats.cpu.percent" = @()
        "docker.stats.mem.usage.bytes" = @()
        "docker.stats.mem.limit.bytes" = @()
        "docker.stats.mem.percent" = @()
        "docker.stats.net.rx.bytes" = @()
        "docker.stats.net.tx.bytes" = @()
        "docker.stats.block.read.bytes" = @()
        "docker.stats.block.write.bytes" = @()
        "docker.stats.pids" = @()
    }

    foreach ($stat in $rawStats) {
        $memParts = $stat.MemUsage -split "/"
        $netParts = $stat.NetIO -split "/"
        $blockParts = $stat.BlockIO -split "/"

        $metricPoints["docker.stats.cpu.percent"] += New-MetricDataPoint $stat.Name $now (ConvertTo-DoubleSafe ($stat.CPUPerc.TrimEnd("%")))
        $metricPoints["docker.stats.mem.usage.bytes"] += New-MetricDataPoint $stat.Name $now (ConvertTo-Bytes $memParts[0])
        $metricPoints["docker.stats.mem.limit.bytes"] += New-MetricDataPoint $stat.Name $now (ConvertTo-Bytes $memParts[1])
        $metricPoints["docker.stats.mem.percent"] += New-MetricDataPoint $stat.Name $now (ConvertTo-DoubleSafe ($stat.MemPerc.TrimEnd("%")))
        $metricPoints["docker.stats.net.rx.bytes"] += New-MetricDataPoint $stat.Name $now (ConvertTo-Bytes $netParts[0])
        $metricPoints["docker.stats.net.tx.bytes"] += New-MetricDataPoint $stat.Name $now (ConvertTo-Bytes $netParts[1])
        $metricPoints["docker.stats.block.read.bytes"] += New-MetricDataPoint $stat.Name $now (ConvertTo-Bytes $blockParts[0])
        $metricPoints["docker.stats.block.write.bytes"] += New-MetricDataPoint $stat.Name $now (ConvertTo-Bytes $blockParts[1])
        $metricPoints["docker.stats.pids"] += New-MetricDataPoint $stat.Name $now (ConvertTo-DoubleSafe $stat.PIDs)
    }

    $metrics = foreach ($name in $metricPoints.Keys) {
        if ($metricPoints[$name].Count -eq 0) { continue }
        $unit = if ($name -like "*.percent") { "%" } elseif ($name -eq "docker.stats.pids") { "1" } else { "By" }
        [ordered]@{
            name = $name
            unit = $unit
            gauge = @{ dataPoints = $metricPoints[$name] }
        }
    }

    if (-not $metrics) { return 0 }

    $payload = [ordered]@{
        resourceMetrics = @(
            [ordered]@{
                resource = @{ attributes = @(@{ key = "service.name"; value = @{ stringValue = "docker-stats-collector" } }) }
                scopeMetrics = @(
                    [ordered]@{
                        scope = @{ name = "docker-stats" }
                        metrics = @($metrics)
                    }
                )
            }
        )
    }

    Send-OtlpPayload -Path "/v1/metrics" -Payload $payload -Description "docker stats metrics" | Out-Null
    return $rawStats.Count
}

# Per-container watermark (last point in time its logs have been successfully read up to),
# keyed by container name. A fixed "--since Ns" lookback re-evaluates "now" relative to when
# each docker logs call actually runs, so metric/log collection time plus the OTLP send time
# between two runs silently falls into neither run's window. Reading from an explicit
# watermark up to a single fixed "now" for the whole run closes that gap, and advancing the
# watermark only once the OTLP send has actually succeeded means a failed send simply widens
# next run's window instead of losing the lines.
$script:lastLogFetchTime = @{}

function Send-ContainerLogs {
    param([string[]]$ContainerNames, [datetime]$RunEndTime, [int]$FallbackSinceSeconds)

    $logRecords = @()
    $runEndArg = $RunEndTime.ToUniversalTime().ToString("o")

    foreach ($containerName in $ContainerNames) {
        $sinceTime = if ($script:lastLogFetchTime.ContainsKey($containerName)) {
            $script:lastLogFetchTime[$containerName]
        } else {
            # Commit the fallback start immediately, not just on a successful send - otherwise a
            # failed first attempt would recompute "RunEndTime - FallbackSinceSeconds" against the
            # next, later RunEndTime on retry, silently skipping the original window's earliest part.
            $initial = $RunEndTime.AddSeconds(-$FallbackSinceSeconds)
            $script:lastLogFetchTime[$containerName] = $initial
            $initial
        }
        $sinceArg = $sinceTime.ToUniversalTime().ToString("o")

        $lines = docker logs $containerName --since $sinceArg --until $runEndArg -t 2>&1
        foreach ($line in $lines) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }

            $timestampText, $body = $line -split ' ', 2
            $lineTime = Get-Date
            try { $lineTime = [datetime]::Parse($timestampText, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AdjustToUniversal) } catch {}

            $severityText = "INFO"
            $severityNumber = 9
            if ($body -match '(?i)\b(error|fatal|panic)\b') { $severityText = "ERROR"; $severityNumber = 17 }
            elseif ($body -match '(?i)\bwarn') { $severityText = "WARN"; $severityNumber = 13 }

            $logRecords += [ordered]@{
                timeUnixNano = Get-UnixNano -Time $lineTime
                severityText = $severityText
                severityNumber = $severityNumber
                body = @{ stringValue = $body }
                attributes = @(@{ key = "container.name"; value = @{ stringValue = $containerName } })
            }
        }
    }

    if ($logRecords.Count -eq 0) {
        foreach ($containerName in $ContainerNames) { $script:lastLogFetchTime[$containerName] = $RunEndTime }
        return 0
    }

    $payload = [ordered]@{
        resourceLogs = @(
            [ordered]@{
                resource = @{ attributes = @(@{ key = "service.name"; value = @{ stringValue = "docker-logs-collector" } }) }
                scopeLogs = @(
                    [ordered]@{
                        scope = @{ name = "docker-logs" }
                        logRecords = @($logRecords)
                    }
                )
            }
        )
    }

    $sent = Send-OtlpPayload -Path "/v1/logs" -Payload $payload -Description "container logs"
    if ($sent) {
        foreach ($containerName in $ContainerNames) { $script:lastLogFetchTime[$containerName] = $RunEndTime }
    }
    else {
        Write-Warning "Not advancing the log watermark for this run since the OTLP send failed; the next run will retry this window too."
    }

    return $logRecords.Count
}

function Send-RunTrace {
    param(
        [string]$TraceId,
        [string]$RootSpanId,
        [datetime]$RunStart,
        [datetime]$RunEnd,
        [string]$MetricsSpanId,
        [datetime]$MetricsStart,
        [datetime]$MetricsEnd,
        [string]$LogsSpanId,
        [datetime]$LogsStart,
        [datetime]$LogsEnd
    )

    $spans = @(
        [ordered]@{
            traceId = $TraceId
            spanId = $RootSpanId
            name = "docker-telemetry-run"
            kind = 1
            startTimeUnixNano = Get-UnixNano -Time $RunStart
            endTimeUnixNano = Get-UnixNano -Time $RunEnd
        },
        [ordered]@{
            traceId = $TraceId
            spanId = $MetricsSpanId
            parentSpanId = $RootSpanId
            name = "Collect and emit metrics"
            kind = 1
            startTimeUnixNano = Get-UnixNano -Time $MetricsStart
            endTimeUnixNano = Get-UnixNano -Time $MetricsEnd
        },
        [ordered]@{
            traceId = $TraceId
            spanId = $LogsSpanId
            parentSpanId = $RootSpanId
            name = "Collect logs for each AW.Monitoring Container"
            kind = 1
            startTimeUnixNano = Get-UnixNano -Time $LogsStart
            endTimeUnixNano = Get-UnixNano -Time $LogsEnd
        }
    )

    $payload = [ordered]@{
        resourceSpans = @(
            [ordered]@{
                resource = @{ attributes = @(@{ key = "service.name"; value = @{ stringValue = "docker-telemetry-script" } }) }
                scopeSpans = @(
                    [ordered]@{
                        scope = @{ name = "docker-telemetry-run" }
                        spans = $spans
                    }
                )
            }
        )
    }

    Send-OtlpPayload -Path "/v1/traces" -Payload $payload -Description "run trace" | Out-Null
}

function Invoke-MonitoringRun {
    param([int]$FallbackSinceSeconds)

    $traceId = New-HexId -Bytes 16
    $rootSpanId = New-HexId -Bytes 8
    $metricsSpanId = New-HexId -Bytes 8
    $logsSpanId = New-HexId -Bytes 8

    $runStart = Get-Date

    $containerNames = @(Get-MonitoringContainerNames -Filter $ContainerNameFilter)

    $metricsStart = Get-Date
    $containerCount = Send-DockerStatsMetrics -ContainerNames $containerNames
    $metricsEnd = Get-Date

    $logsStart = Get-Date
    $logLineCount = Send-ContainerLogs -ContainerNames $containerNames -RunEndTime $logsStart -FallbackSinceSeconds $FallbackSinceSeconds
    $logsEnd = Get-Date

    $runEnd = Get-Date

    Send-RunTrace -TraceId $traceId -RootSpanId $rootSpanId `
        -RunStart $runStart -RunEnd $runEnd `
        -MetricsSpanId $metricsSpanId -MetricsStart $metricsStart -MetricsEnd $metricsEnd `
        -LogsSpanId $logsSpanId -LogsStart $logsStart -LogsEnd $logsEnd

    Write-Host "[$($runEnd.ToString('HH:mm:ss'))] run complete - containers=$($containerNames.Count) metricSets=$containerCount logLines=$logLineCount traceId=$traceId"
}

function Wait-ForEscOrTimeout {
    param([int]$Seconds)
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    while ($stopwatch.Elapsed.TotalSeconds -lt $Seconds) {
        try {
            if ([Console]::KeyAvailable) {
                $key = [Console]::ReadKey($true)
                if ($key.Key -eq [ConsoleKey]::Escape) {
                    return $true
                }
            }
        }
        catch [System.InvalidOperationException] {
            # No console attached (e.g. input redirected) - ESC can't be detected, just keep timing the interval.
        }
        Start-Sleep -Milliseconds 200
    }
    return $false
}

Write-Host "Sending docker stats metrics, logs and a run trace to $OtlpEndpoint every $IntervalSeconds s. Press ESC to stop."

$stopRequested = $false
while (-not $stopRequested) {
    try {
        Invoke-MonitoringRun -FallbackSinceSeconds $IntervalSeconds
    }
    catch {
        Write-Warning "Monitoring run failed: $_"
    }

    $stopRequested = Wait-ForEscOrTimeout -Seconds $IntervalSeconds
}

Write-Host "ESC pressed - stopping."
