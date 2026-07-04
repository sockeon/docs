---
title: "Survivability - Sockeon Documentation"
description: "Configure connection limits, heartbeats, and write buffers to keep Sockeon stable under load"
og_image: "https://sockeon.github.io/logo.png"
twitter_image: "https://sockeon.github.io/logo.png"
---

# Survivability

Survivability settings are **hard limits** enforced at accept time and by the engine runtime. They protect your server from running out of file descriptors or memory when connection volume spikes.

Configure them under the `survivability` key in `ServerConfig`:

```php
use Sockeon\Sockeon\Config\ServerConfig;

$config = new ServerConfig([
    'host' => '0.0.0.0',
    'port' => 6001,
    'survivability' => [
        'max_connections' => 10_000,
        'write_buffer_limit' => 65536,
        'heartbeat_idle_time' => 600,
        'heartbeat_check_interval' => 60,
    ],
]);
```

## Options

### max_connections

- **Type:** `int`
- **Default:** `10000`
- **Enforced at:** connection accept (both engines)

When the server is at capacity, new TCP connections are rejected before the WebSocket handshake completes. This replaces the hardcoded `10000` cap from earlier versions and is now fully configurable.

`RateLimitConfig.maxGlobalConnections` is also enforced at accept time. Set both to the same value in production, or rely on `survivability.max_connections` as the authoritative hard cap.

```php
'survivability' => [
    'max_connections' => 50_000,
],
'swoole' => [
    'max_connection' => 50_000,  // align with survivability (see note below)
],
```

On the Swoole engine, the value passed to Swoole is `min(swoole.max_connection, survivability.max_connections)`. With defaults (`100_000` and `10_000`), the effective ceiling is **10,000** until you raise survivability.

### write_buffer_limit

- **Type:** `int` (bytes)
- **Default:** `65536` (64 KB)

Configured via `SurvivabilityConfig` for application-level slow-client policies. Kernel-level outbound buffering on Swoole is tuned separately via `swoole.socket_buffer_size` and `swoole.buffer_output_size` — see [Swoole Engine](/v3.0/advanced/swoole-engine.md).

### heartbeat_idle_time

- **Type:** `int` (seconds)
- **Default:** `600` (10 minutes)

Maximum idle time before Swoole considers a connection stale. Passed to Swoole's `heartbeat_idle_time` setting.

### heartbeat_check_interval

- **Type:** `int` (seconds)
- **Default:** `60`

How often Swoole scans for idle connections. Passed to `heartbeat_check_time`.

Heartbeats apply to the **Swoole engine** only. The stream select engine does not run native idle detection; use application-level ping/pong events if you need them on `stream_select`.

## SurvivabilityConfig API

```php
use Sockeon\Sockeon\Config\SurvivabilityConfig;

$survivability = new SurvivabilityConfig([
    'max_connections' => 10_000,
    'write_buffer_limit' => 65536,
    'heartbeat_idle_time' => 300,
    'heartbeat_check_interval' => 60,
]);

$config->setSurvivabilityConfig($survivability);

// Getters
$config->getSurvivabilityConfig()->getMaxConnections();
$config->getSurvivabilityConfig()->getWriteBufferLimit();
$config->getSurvivabilityConfig()->getHeartbeatIdleTime();
$config->getSurvivabilityConfig()->getHeartbeatCheckInterval();
```

## Connection rate limiting

Per-IP connection limits from `RateLimitConfig` are enforced alongside survivability caps:

```php
'rate_limit' => [
    'enabled' => true,
    'maxConnectionsPerIp' => 50,
    'maxGlobalConnections' => 10_000,
],
```

| Setting | Layer | Effect |
|---------|-------|--------|
| `survivability.max_connections` | Hard cap | Reject when total clients ≥ limit |
| `rate_limit.maxGlobalConnections` | Rate limiter | Same enforcement at accept |
| `rate_limit.maxConnectionsPerIp` | Rate limiter | Reject excess connections from one IP |

See [Rate Limiting](/v3.0/advanced/rate-limiting.md) for the full rate limit configuration.

## OS limits

Survivability config cannot exceed what the operating system allows. Before raising `max_connections`:

```bash
ulimit -n          # should be >= your target + headroom for files/sockets
cat /proc/sys/fs/file-max
```

For Swoole deployments targeting 50k+ connections, also tune kernel parameters (`net.core.somaxconn`, `net.ipv4.ip_local_port_range`, etc.). See [Swoole Engine](/v3.0/advanced/swoole-engine.md) for tuning.

## Production example

```php
$config = new ServerConfig([
    'engine' => 'swoole',
    'survivability' => [
        'max_connections' => 50_000,
        'heartbeat_idle_time' => 300,
        'heartbeat_check_interval' => 60,
    ],
    'swoole' => [
        'max_connection' => 50_000,
        'worker_num' => 8,
    ],
    'rate_limit' => [
        'enabled' => true,
        'maxGlobalConnections' => 50_000,
        'maxConnectionsPerIp' => 100,
    ],
]);
```

## Next steps

- [Engines](/v3.0/core/engines.md) — pick stream_select vs swoole
- [Swoole Engine](/v3.0/advanced/swoole-engine.md) — align Swoole `max_connection` with survivability
