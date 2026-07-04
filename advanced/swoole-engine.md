---
title: "Swoole Engine - Sockeon Documentation"
description: "Run Sockeon with OpenSwoole for high-concurrency WebSocket and HTTP workloads"
og_image: "https://sockeon.github.io/logo.png"
twitter_image: "https://sockeon.github.io/logo.png"
---

# Swoole Engine

The Swoole engine uses `Swoole\WebSocket\Server` in multi-process mode to handle tens of thousands of concurrent WebSocket connections on a single node. Routing, controllers, middleware, and the broadcast API are identical to the stream select engine — only transport changes.

## Requirements

Install OpenSwoole (or Swoole):

```bash
pecl install openswoole
```

Enable the extension in `php.ini`, then verify:

```bash
php -m | grep -i swoole
```

Composer lists the extension as a **suggested** dependency — it is not required for default `stream_select` installs.

## Enable the engine

```php
use Sockeon\Sockeon\Config\ServerConfig;

$config = new ServerConfig([
    'host' => '0.0.0.0',
    'port' => 6001,
    'engine' => 'swoole',
    'swoole' => [
        'worker_num' => 8,
        'max_connection' => 100_000,
    ],
]);
```

## Swoole configuration

All Swoole-specific options live under the `swoole` key:

```php
'swoole' => [
    'worker_num' => null,           // null = CPU core count
    'task_worker_num' => 0,         // background task workers (0 = disabled)
    'max_connection' => 100_000,    // Swoole connection limit (see effective cap below)
    'client_table_size' => null,    // auto-sized from max_connection
    'socket_buffer_size' => null,   // auto-sized from max_connection
    'buffer_output_size' => null,   // defaults to socket_buffer_size
    'memory_limit' => null,         // auto PHP memory_limit at startup
    'coroutine_dispatch' => true,   // run handlers in coroutines
],
```

### Effective connection ceiling

At runtime Sockeon passes Swoole:

```text
max_connection = min(swoole.max_connection, survivability.max_connections)
```

Out of the box that is `min(100_000, 10_000)` → **10,000** connections. Raise `survivability.max_connections` (and match `swoole.max_connection`) when you need more than the default survivability cap.

### worker_num

Number of worker processes. Defaults to `swoole_cpu_num()` when omitted or `null`. Set explicitly on containers with CPU limits:

```php
'worker_num' => (int) (getenv('SOCKEON_SWOOLE_WORKERS') ?: 0) ?: null,
```

### max_connection

Swoole's per-server connection ceiling. Align this with `survivability.max_connections`:

```php
'survivability' => ['max_connections' => 50_000],
'swoole' => ['max_connection' => 50_000],
```

### client_table_size

Rows in the shared memory table that maps Swoole file descriptors to Sockeon client IDs. When omitted, Sockeon sizes the table as `min(131072, max(2048, max_connection + 2048))` — e.g. `12_048` rows for `max_connection=10_000`.

### socket_buffer_size and buffer_output_size

Kernel socket buffer sizes passed to Swoole's `socket_buffer_size` and `buffer_output_size`. When omitted, Sockeon picks a tier from `swoole.max_connection`:

| `max_connection` | Default buffer size |
|------------------|---------------------|
| ≥ 10,000 | 32 KB (32768) |
| ≥ 5,000 | 64 KB (65536) |
| &lt; 5,000 | 128 KB (131072) |

`buffer_output_size` defaults to `socket_buffer_size`. At 10k+ connections the smaller 32 KB tier avoids multi-gigabyte kernel buffer budgets. Override explicitly if you send large frames to many clients at once.

### memory_limit

PHP `memory_limit` applied via `ini_set()` when the Swoole engine starts. When omitted, Sockeon derives a limit from `swoole.max_connection`:

| `max_connection` | Default |
|------------------|---------|
| ≥ 10,000 | `2G` |
| ≥ 5,000 | `1G` |
| &lt; 5,000 | `128M` + headroom (`max(256M, 128 + ceil(max_connection / 64))`) |

Set explicitly for containers with fixed cgroup memory:

```php
'memory_limit' => '1G',
```

### coroutine_dispatch

When `true` (default), controller and event handler work runs inside `Swoole\Coroutine::create()` so a slow handler does not block the worker's I/O loop.

### task_worker_num

Optional Swoole task workers for CPU-heavy background work. Sockeon does not route controller events through tasks by default; leave at `0` unless you add custom task integration.

## Heartbeats

Idle connection cleanup is configured via [Survivability](/v3.0/core/survivability.md):

```php
'survivability' => [
    'heartbeat_idle_time' => 600,
    'heartbeat_check_interval' => 60,
],
```

These map to Swoole's `heartbeat_idle_time` and `heartbeat_check_time` server settings.

## WebSocket framing

The stream select engine expects pre-framed WebSocket bytes (`framesOutboundWebSocket()` = `true`). Swoole frames outbound data for you (`framesOutboundWebSocket()` = `false`). Application code using `emit()` and `broadcast()` does not need to change.

## Client registry

Swoole workers share client state through a `Swoole\Table`:

| Column | Purpose |
|--------|---------|
| `clientId` | Sockeon client identifier |
| `fd` | Swoole file descriptor |
| `type` | Connection type (`ws`, `http`, etc.) |
| `workerId` | Owning worker process |

For room membership that spans workers in multi-worker mode, set `scale.registry` to `redis`. See [Scaling](/v3.0/advanced/scaling.md).

## Capacity planning

Rough per-connection memory on Linux: **2–8 KB** idle. Example sizing:

| Target connections | RAM (estimate) | Notes |
|-------------------|----------------|-------|
| 10,000 | 20–80 MB | Modest VPS; **688 MB peak observed** in a 10k/300s soak ([report](/v3.0/advanced/benchmark-report.md)) |
| 50,000 | 100–400 MB | 4–8 GB VPS recommended |
| 100,000 | 200–800 MB | Dedicated tuning, high `ulimit` |

One machine with OpenSwoole realistically holds **50k–500k** idle WebSocket connections depending on hardware and kernel tuning. Millions require a [multi-node cluster](/v3.0/advanced/scaling.md).

## Process model

```
Master process
├── Worker 1  (WebSocket + HTTP I/O, coroutine handlers)
├── Worker 2
├── ...
└── Worker N
```

Workers do not share PHP heap memory. Shared state for connections uses `Swoole\Table`; shared room state uses Redis when `scale.registry=redis`.

## Docker example

```dockerfile
FROM php:8.3-cli
RUN pecl install openswoole && docker-php-ext-enable openswoole
RUN docker-php-ext-install sockets
COPY . /app
WORKDIR /app
CMD ["php", "app/server.php"]
```

Set `SOCKEON_ENGINE=swoole` and raise container ulimits:

```yaml
services:
  chat:
    ulimits:
      nofile:
        soft: 65535
        hard: 65535
    environment:
      SOCKEON_ENGINE: swoole
      SOCKEON_SWOOLE_MAX_CONNECTION: 50000
```

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Startup error about missing Swoole class | Extension not installed | `pecl install openswoole` |
| Connections plateau below config | `ulimit -n` too low | Raise file descriptor limit |
| Rooms empty across workers | In-process registry per worker | `scale.registry=redis` |
| Slow clients accumulate | Write buffer growth | Lower `write_buffer_limit` or disconnect slow clients |

## Next steps

- [Performance Overview](/v3.0/advanced/benchmark-report.md) — 10k soak, latency, and broadcast measurements
- [Engines](/v3.0/core/engines.md) — when to use Swoole vs stream_select
- [Survivability](/v3.0/core/survivability.md) — caps and heartbeats
- [Scaling](/v3.0/advanced/scaling.md) — multi-node deployment
