---
title: "Migrating to Sockeon 3.x - Sockeon Documentation"
description: "Step-by-step guide for upgrading from Sockeon 2.x to 3.x with engines, survivability, and scaling"
og_image: "https://sockeon.github.io/logo.png"
twitter_image: "https://sockeon.github.io/logo.png"
---

# Migrating to Sockeon 3.x

Sockeon 3.x introduces pluggable engines, survivability caps, Swoole high-concurrency mode, and Redis-backed clustering. Controllers, routing attributes, and middleware patterns remain the same — most migrations are configuration changes plus a small set of API renames (see below).

## What changed

| Area | 2.x | 3.x |
|------|-----|-----|
| Transport | Hardcoded `stream_select` | Pluggable `stream_select` or `swoole` |
| Connection caps | Hardcoded 10,000 | Configurable `survivability.max_connections` |
| High concurrency | Limited by reactor | `engine=swoole` with OpenSwoole |
| Multi-node | Not supported | `scale` config with Redis pub/sub |
| Connection rate limits | HTTP/WS message limits only | `maxGlobalConnections` and `maxConnectionsPerIp` enforced at accept |
| PHP version | `>= 8.0` | `>= 8.3` |

## Step 1: Update Composer

```bash
composer require sockeon/sockeon:^3.0
```

Confirm PHP 8.3+:

```bash
php -v
```

## Step 2: Run the upgrade script

Sockeon ships a codemod that renames v2 API calls and patches common config defaults:

```bash
# Preview changes
vendor/bin/sockeon-upgrade . --dry-run

# Apply to your project
vendor/bin/sockeon-upgrade .

# Controllers only
vendor/bin/sockeon-upgrade app/Controllers --code-only

# Config only
vendor/bin/sockeon-upgrade config/sockeon.php --config-only
```

The script updates:

- **Code:** `send` → `emit`, `sendToClient` → `sendRaw`, controller renames, `broadcastTo` / `broadcastExcept` argument order, `broadcastToRoom` namespace/room order, `getClientData` → `data` / `allData`
- **Config:** adds `engine`, `survivability.max_connections`, and `rate_limit` connection caps when missing

Review the diff after running — complex `broadcastToRoom()` calls may still need a manual pass. See the rename table below.

## Step 3: Engine (optional)

Sockeon 2.x always used `stream_select` internally. There was no config key to change the transport — the reactor was hardcoded.

3.x adds an optional `engine` key that defaults to the same behavior:

```php
// 3.x — optional; omit for default
'engine' => 'stream_select',
```

No code changes are required for the default engine. Controllers, `emit()`, `broadcast()`, and middleware work unchanged.

## Step 4: Add survivability settings

2.x enforced a hardcoded 10,000 connection cap. 3.x makes this configurable:

```php
'survivability' => [
    'max_connections' => 10_000,  // match your 2.x effective limit, or raise
],
```

If you previously relied on the implicit 10k cap, set `max_connections` to `10000` explicitly. For production, align with `rate_limit.maxGlobalConnections`. See [Survivability](/v3.0/core/survivability.md).

## Step 5: Review rate limit enforcement

In 3.x, **connection limits are enforced at accept time** when `rate_limit` config is present — independent of the `enabled` flag for HTTP/WebSocket message rate limiting.

| Setting | Enforced at accept? |
|---------|---------------------|
| `maxGlobalConnections` | Yes |
| `maxConnectionsPerIp` | Yes |
| `maxHttpRequestsPerIp` | No (HTTP middleware) |
| `maxWebSocketMessagesPerClient` | No (WebSocket middleware) |

The `enabled` flag still controls HTTP and WebSocket **message** rate limiting only.

**Migration impact:** If you had `rate_limit` in config with default `maxGlobalConnections` (50,000) but never intended connection limiting, connections were not capped in 2.x. In 3.x, those defaults apply at accept.

**Fix options:**

```php
// Option A: Disable connection limits by omitting rate_limit
// (survivability.max_connections still applies)

// Option B: Set explicit limits matching your capacity plan
'rate_limit' => [
    'enabled' => true,  // message rate limiting
    'maxGlobalConnections' => 10_000,
    'maxConnectionsPerIp' => 100,
],

// Option C: Whitelist trusted IPs (load balancers, health checks)
'rate_limit' => [
    'whitelist' => ['10.0.0.0/8'],
],
```

See [Rate Limiting](/v3.0/advanced/rate-limiting.md).

## Step 6: Optional — enable Swoole engine

For deployments needing more than ~1,000–2,000 concurrent connections on one node:

```bash
pecl install openswoole
```

```php
'engine' => 'swoole',
'swoole' => [
    'worker_num' => 8,
    'max_connection' => 50_000,
],
'survivability' => [
    'max_connections' => 50_000,
    'heartbeat_idle_time' => 300,
    'heartbeat_check_interval' => 60,
],
```

See [Engines](/v3.0/core/engines.md) and [Swoole Engine](/v3.0/advanced/swoole-engine.md).

## Step 7: Optional — enable cluster scaling

For multi-node deployments behind a load balancer:

```bash
# ext-redis required
pecl install redis
```

```php
'engine' => 'swoole',
'scale' => [
    'node_id' => getenv('SOCKEON_NODE_ID') ?: gethostname(),
    'publisher' => 'redis',
    'registry' => 'redis',
    'redis' => [
        'host' => getenv('REDIS_HOST') ?: '127.0.0.1',
        'port' => 6379,
    ],
],
```

See [Scaling](/v3.0/advanced/scaling.md).

## Configuration mapping

### New keys

| 3.x key | Purpose |
|---------|---------|
| `engine` | `stream_select` (default) or `swoole` |
| `survivability` | Hard connection caps, heartbeats, write buffer limits |
| `swoole` | Worker count, max connections, buffer/memory auto-tuning, coroutine dispatch |
| `scale` | `node_id`, `publisher`, `registry`, Redis settings |

### Unchanged keys

These work the same in 3.x:

- `host`, `port`, `debug`
- `auth_key`
- `cors`
- `rate_limit` (with accept-time enforcement noted above)
- `trust_proxy`, `proxy_headers`, `health_check_path`
- `logger`, `queue_file`
- `max_message_size`, `register_system_controllers`

### Side-by-side example

**2.x config:**

```php
return [
    'host' => '0.0.0.0',
    'port' => 6001,
    'debug' => false,
    'auth_key' => getenv('SOCKEON_AUTH_KEY'),
    'cors' => ['allowed_origins' => ['*']],
    'rate_limit' => [
        'enabled' => true,
        'maxHttpRequestsPerIp' => 100,
    ],
    'health_check_path' => '/health',
];
```

**3.x equivalent:**

```php
return [
    'host' => '0.0.0.0',
    'port' => 6001,
    'debug' => false,
    'engine' => 'stream_select',
    'survivability' => [
        'max_connections' => 10_000,
    ],
    'auth_key' => getenv('SOCKEON_AUTH_KEY'),
    'cors' => ['allowed_origins' => ['*']],
    'rate_limit' => [
        'enabled' => true,
        'maxHttpRequestsPerIp' => 100,
        'maxGlobalConnections' => 10_000,
        'maxConnectionsPerIp' => 100,
    ],
    'health_check_path' => '/health',
];
```

## Application code changes

**No changes required** for typical applications, except the public API renames below.

### API method renames (3.x)

| Old name | New name | Layer |
|----------|----------|-------|
| `Server::send()` | `Server::emit()` | Server |
| `Server::sendToClient()` | `Server::sendRaw()` | Server |
| `broadcastToRoomClients()` | `broadcastToRoom($event, $data, $namespace, $room)` | Controller |
| `broadcastToNamespaceClients()` | `broadcastToNamespace()` | Controller |
| `moveClientToNamespace()` | `joinNamespace()` | Controller |
| `getAllClients()` | `getClientIds()` | Controller |
| `broadcastToAll()` | `broadcast()` | Controller (removed alias) |
| `broadcastTo($clients, ...)` | `broadcastTo($event, $data, $clientIds)` | Controller |
| `broadcastExcept($excepts, ...)` | `broadcastExcept($event, $data, $exceptClientIds)` | Controller |
| `disconnectClient()` | `disconnect()` | Controller |
| `isClientConnected()` | `isConnected()` | Controller |
| `getClientIpAddress()` | `getClientIp()` | Controller |
| `getClientData()` | `data()` / `allData()` | Controller / Server |
| `setClientData()` | `putData()` | Controller / Server |
| `hasClientData()` | `hasData()` | Controller / Server |
| `forgetClientData()` | `forgetData()` | Server |
| `forgetData()` | new in 3.x | Controller |

Run `vendor/bin/sockeon-upgrade` to apply most of these automatically.

**Optional improvements:**

- Set `engine` explicitly in config rather than relying on defaults
- Add `survivability` limits matching your deployment size
- Enable `/health` polling if behind a load balancer

## Verification checklist

- [ ] `composer update` succeeds on PHP 8.3+
- [ ] `vendor/bin/sockeon-upgrade . --dry-run` reviewed and applied
- [ ] Server starts with `engine=stream_select` (default behavior)
- [ ] WebSocket connect, emit, and broadcast work
- [ ] HTTP routes respond correctly
- [ ] Rate limits behave as expected (test connection caps if `rate_limit` is set)
- [ ] `/health` returns healthy (if configured)

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Connections rejected unexpectedly | Check `survivability.max_connections` and `rate_limit.maxGlobalConnections` |
| "Swoole extension required" | Install `ext-openswoole` or use `engine=stream_select` |
| Room broadcast misses remote clients | Add `scale.publisher=redis` and `scale.registry=redis` |
| Performance regression on stream_select | Expected for same engine; 3.x fixes the ~200 connection degradation from 2.x |

## Next steps

- [Performance Overview](/v3.0/advanced/benchmark-report.md) — Swoole 3.x capacity and latency
- [Engines](/v3.0/core/engines.md) — engine selection guide
- [Survivability](/v3.0/core/survivability.md) — connection limits
- [Swoole Engine](/v3.0/advanced/swoole-engine.md) — high-concurrency tuning
- [Scaling](/v3.0/advanced/scaling.md) — multi-node clusters
- [Server Configuration](/v3.0/core/server-configuration.md) — full reference
- [Installation](/v3.0/getting-started/installation.md) — requirements and extensions
