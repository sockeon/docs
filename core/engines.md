---
title: "Engines - Sockeon Documentation"
description: "Choose between stream_select and Swoole engines for your Sockeon server"
og_image: "https://sockeon.github.io/logo.png"
twitter_image: "https://sockeon.github.io/logo.png"
---

# Engines

Sockeon 3.x decouples transport from routing and handlers. The **engine** owns the event loop, socket I/O, and connection lifecycle. Your controllers, middleware, and routing code stay the same regardless of which engine you pick.

## Available engines

| Engine | Config value | Extension | Typical use |
|--------|--------------|-----------|-------------|
| Stream select | `stream_select` (default) | None beyond core PHP | Development, small deployments, zero-extra-deps installs |
| Swoole | `swoole` | `ext-swoole` or `ext-openswoole` | High concurrency — tens of thousands of idle WebSocket connections per node |

## Configuration

Set the engine in `ServerConfig`:

```php
use Sockeon\Sockeon\Config\ServerConfig;

$config = new ServerConfig([
    'host' => '0.0.0.0',
    'port' => 6001,
    'engine' => 'stream_select',  // or 'swoole'
]);
```

Or via environment variable in your config file:

```php
'engine' => getenv('SOCKEON_ENGINE') ?: 'stream_select',
```

If you request `engine=swoole` without the Swoole extension installed, Sockeon throws a clear runtime error at startup:

```
The Swoole extension is required for engine=swoole. Install ext-swoole or ext-openswoole.
```

## How engines fit in

```
┌─────────────────────────────────────────┐
│              Server                     │
│  controllers · routing · middleware     │
│  namespaces · rooms · broadcast API     │
└─────────────────┬───────────────────────┘
                  │ EngineInterface
        ┌─────────┴─────────┐
        ▼                   ▼
 StreamSelectEngine    SwooleEngine
 (stream_select loop)  (multi-worker WS)
```

The public `Server` API — `emit()`, `broadcast()`, `getClientCount()`, controller registration — is unchanged. Internally, outbound messages go through `$this->engine->send()` instead of writing directly to client sockets.

## Stream select engine

The default engine uses PHP's `stream_select()` reactor. It requires only `ext-sockets` and `ext-openssl`, keeping Composer installs lightweight.

**Strengths:**

- No optional extensions
- Familiar blocking I/O model
- Fine for hundreds to low thousands of concurrent connections with tuned `ulimit`

**Limits:**

- Single-threaded reactor bounded by OS file-descriptor limits (`FD_SETSIZE`, typically 256–1024)
- CPU-bound under heavy broadcast load

Version 3.x removes the per-client `stream_select()` call that caused premature degradation around ~200 connections. See [Survivability](/v3.0/core/survivability.md) for connection caps.

## Swoole engine

The Swoole engine uses `Swoole\WebSocket\Server` in multi-process mode. It handles WebSocket framing internally (`framesOutboundWebSocket()` returns `false`), runs controller work in coroutines, and maps file descriptors to Sockeon client IDs via a shared memory table.

See [Swoole Engine](/v3.0/advanced/swoole-engine.md) for worker tuning, heartbeat settings, and capacity planning.

## Choosing an engine

| Scenario | Recommended engine |
|----------|-------------------|
| Local development | `stream_select` |
| Shared hosting / minimal deps | `stream_select` |
| Production chat with < 2k concurrent users on one box | `stream_select` with raised `ulimit` |
| Production real-time app with 10k+ concurrent WebSockets | `swoole` |
| Multi-node cluster behind a load balancer | `swoole` + [Scaling](/v3.0/advanced/scaling.md) |

## Engine interface

Engines implement `EngineInterface`:

- `start()` — bind and run the event loop
- `send(string $clientId, string $payload)` — deliver data to a client
- `closeConnection()` / `forgetClient()` — tear down or detach tracking
- `framesOutboundWebSocket()` — whether callers must frame outbound WebSocket bytes
- `getName()` — `stream_select` or `swoole`

You do not implement this interface in application code. Sockeon selects the engine from config via `EngineFactory`.

## Next steps

- [Performance Overview](/v3.0/advanced/benchmark-report.md) — measured latency, soak, and broadcast results
- [Survivability](/v3.0/core/survivability.md) — connection caps, heartbeats, write buffers
- [Swoole Engine](/v3.0/advanced/swoole-engine.md) — worker and concurrency tuning
- [Scaling](/v3.0/advanced/scaling.md) — multi-node Redis pub/sub
- [Server Configuration](/v3.0/core/server-configuration.md) — full config reference
