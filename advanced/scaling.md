---
title: "Scaling and Clustering - Sockeon Documentation"
description: "Deploy multi-node Sockeon clusters with Redis pub/sub, sticky load balancing, and capacity planning"
og_image: "https://sockeon.github.io/logo.png"
twitter_image: "https://sockeon.github.io/logo.png"
---

# Scaling and Clustering

Sockeon 3.x scales horizontally by running multiple server nodes behind a load balancer. Each node handles its own WebSocket connections; **Redis** coordinates cross-node broadcasts and shared room membership.

Single-node capacity tops out around **50k–500k** idle connections with the [Swoole engine](/v3.0/advanced/swoole-engine.md). Millions of concurrent users require a cluster.

## Architecture

```
                    ┌─────────────┐
                    │   NGINX     │  sticky sessions (ip_hash)
                    │  load bal.  │
                    └──────┬──────┘
           ┌───────────────┼───────────────┐
           ▼               ▼               ▼
    ┌────────────┐  ┌────────────┐  ┌────────────┐
    │  Node A    │  │  Node B    │  │  Node C    │
    │ engine:    │  │ engine:    │  │ engine:    │
    │ swoole     │  │ swoole     │  │ swoole     │
    └─────┬──────┘  └─────┬──────┘  └─────┬──────┘
          │               │               │
          └───────────────┼───────────────┘
                          ▼
                   ┌─────────────┐
                   │    Redis    │
                   │  pub/sub +  │
                   │  room sets  │
                   └─────────────┘
```

| Component | Role |
|-----------|------|
| Load balancer | Terminates TLS, distributes new connections, keeps clients on one node |
| Sockeon node | Owns local WebSocket I/O and controller logic |
| Redis publisher | Fan-out `broadcast()` to all nodes via pub/sub |
| Redis registry | Shared namespace/room membership across nodes |

## Scale configuration

All cluster settings live under the `scale` key in `ServerConfig`:

```php
use Sockeon\Sockeon\Config\ServerConfig;

$config = new ServerConfig([
    'engine' => 'swoole',
    'scale' => [
        'node_id' => 'node-west-2a',
        'publisher' => 'redis',
        'registry' => 'redis',
        'presence_ttl' => 300,
        'redis' => [
            'host' => '10.0.0.5',
            'port' => 6379,
            'password' => null,
            'database' => 0,
            'channel' => 'sockeon:broadcast',
            'prefix' => 'sockeon:',
        ],
    ],
]);
```

### node_id

- **Type:** `string`
- **Default:** `'node-1'`
- **Required in cluster:** Yes — must be unique per running instance

The node ID prefixes room membership keys in Redis (`node-west-2a:client-abc`) so each node can filter which clients it owns locally. Set via environment variable in production:

```php
'scale' => [
    'node_id' => getenv('SOCKEON_NODE_ID') ?: gethostname(),
],
```

### publisher

- **Type:** `'local'` | `'redis'`
- **Default:** `'local'`

| Value | Behavior |
|-------|----------|
| `local` | `broadcast()` delivers only to clients on this node |
| `redis` | Publishes to Redis channel; all nodes receive and deliver locally |

Cross-node broadcast requires `publisher=redis` **and** `engine=swoole`. The Redis subscriber runs in a Swoole coroutine. With `stream_select`, Redis publish still works outbound, but inbound cross-node delivery is limited — use Swoole for cluster nodes.

### registry

- **Type:** `'local'` | `'redis'`
- **Default:** `'local'`

| Value | Behavior |
|-------|----------|
| `local` | Namespace and room membership stored in-process (per worker on Swoole) |
| `redis` | Shared membership in Redis; `getClientsInRoom()` returns only clients on the local node |

Set `registry=redis` when rooms span multiple nodes or Swoole workers. Room joins are written to Redis sets; broadcasts target clients that are both in the room **and** connected locally.

### Redis options

| Key | Default | Description |
|-----|---------|-------------|
| `host` | `127.0.0.1` | Redis server hostname |
| `port` | `6379` | Redis port |
| `password` | `null` | Optional auth |
| `database` | `0` | Redis DB index |
| `channel` | `sockeon:broadcast` | Pub/sub channel for broadcasts |
| `prefix` | `sockeon:` | Key prefix for registry data |

### presence_ttl

- **Type:** `int` (seconds)
- **Default:** `300`

How long a node's presence key lives in Redis after room activity. Used for operational visibility, not connection routing.

## Requirements

| Extension | When needed |
|-----------|-------------|
| `ext-openswoole` or `ext-swoole` | All cluster nodes (`engine=swoole`) |
| `ext-redis` | `publisher=redis` or `registry=redis` |

Composer lists both as **suggested** dependencies — they are optional for single-node `stream_select` installs.

## NGINX sticky load balancing

WebSocket connections are long-lived. Without sticky sessions, a reconnect may land on a different node and miss in-memory state. Use **IP hash** or cookie-based stickiness:

```nginx
upstream sockeon_cluster {
    ip_hash;  # sticky by client IP
    server 10.0.1.10:6001 max_fails=3 fail_timeout=30s;
    server 10.0.1.11:6001 max_fails=3 fail_timeout=30s;
    server 10.0.1.12:6001 max_fails=3 fail_timeout=30s;
}

server {
    listen 443 ssl http2;
    server_name ws.example.com;

    location / {
        proxy_pass http://sockeon_cluster;
        proxy_http_version 1.1;

        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_connect_timeout 7d;
        proxy_send_timeout 7d;
        proxy_read_timeout 7d;
    }

    location /health {
        proxy_pass http://sockeon_cluster/health;
        proxy_http_version 1.1;
    }
}
```

Configure `trust_proxy` and `health_check_path` on each Sockeon node. See [Reverse Proxy and Load Balancing](/v3.0/advanced/reverse-proxy.md) for header and health-check details.

With `registry=redis`, room broadcasts work across nodes even when clients are on different machines. Sticky sessions still help for direct `emit($clientId, ...)` targeting and reduce Redis registry churn.

## Multi-node example

Run three nodes with distinct IDs on the same host (production: separate machines):

```bash
SOCKEON_NODE_ID=node-1 SOCKEON_PORT=6001 php app/server.php &
SOCKEON_NODE_ID=node-2 SOCKEON_PORT=6002 php app/server.php &
SOCKEON_NODE_ID=node-3 SOCKEON_PORT=6003 php app/server.php &
```

Each node's config:

```php
'engine' => 'swoole',
'scale' => [
    'node_id' => getenv('SOCKEON_NODE_ID'),
    'publisher' => 'redis',
    'registry' => 'redis',
    'redis' => [
        'host' => getenv('REDIS_HOST') ?: '127.0.0.1',
        'port' => (int) (getenv('REDIS_PORT') ?: 6379),
    ],
],
'survivability' => ['max_connections' => 50_000],
'swoole' => ['max_connection' => 50_000, 'worker_num' => 8],
'health_check_path' => '/health',
```

## Capacity math

### Per-node estimates

Rough idle WebSocket memory: **2–8 KB per connection** on Linux.

| Connections per node | RAM (connections only) | Suggested hardware |
|---------------------|------------------------|-------------------|
| 10,000 | 20–80 MB | 2 vCPU, 2 GB |
| 50,000 | 100–400 MB | 4–8 vCPU, 8 GB |
| 100,000 | 200–800 MB | 8+ vCPU, 16 GB |

Add headroom for PHP workers, Redis client buffers, and OS page cache. Align `survivability.max_connections`, `swoole.max_connection`, and `rate_limit.maxGlobalConnections` to the same ceiling.

### Cluster totals

```
cluster_capacity = nodes × per_node_max_connections
```

| Target | Example layout |
|--------|-----------------|
| 100k | 2 nodes × 50k |
| 500k | 10 nodes × 50k |
| 1M | 20 nodes × 50k (or 10 nodes × 100k with tuned hardware) |

Redis pub/sub handles broadcast fan-out; registry memory grows with total room membership, not connection count. A dedicated Redis instance (or cluster) with ≥ 2 GB RAM is typical for 1M-user deployments.

### OS limits

Each node needs `ulimit -n` ≥ target connections + headroom. See [Swoole Engine](/v3.0/advanced/swoole-engine.md) for kernel tuning.

## How cross-node broadcast works

1. Controller calls `$this->broadcast('chat.message', $data, '/', 'lobby')`.
2. `RedisPublisher` delivers locally, then publishes JSON to the Redis channel.
3. Other nodes' subscribers receive the message, skip messages from their own `node_id`, and deliver locally.
4. With `registry=redis`, only clients in the room **on that node** receive the event.

Origin node ID is included in every pub/sub payload to prevent echo loops.

## Production checklist

- [ ] **Unique `node_id`** per instance (hostname, pod name, or explicit env var)
- [ ] **`engine=swoole`** on all cluster nodes
- [ ] **`publisher=redis`** and **`registry=redis`** when rooms span nodes
- [ ] **`ext-redis`** installed and Redis reachable from every node
- [ ] **Aligned caps:** `survivability.max_connections` = `swoole.max_connection` = `rate_limit.maxGlobalConnections`
- [ ] **Raised `ulimit -n`** on every node (≥ 65535 for 50k targets)
- [ ] **NGINX `ip_hash`** or equivalent sticky sessions in front of WebSocket upstream
- [ ] **`trust_proxy`** set to load balancer IPs only (never `true` in production)
- [ ] **`health_check_path`** enabled; load balancer health checks configured
- [ ] **Redis persistence** — pub/sub is fire-and-forget; use Redis for registry only, not message durability
- [ ] **Monitoring** — poll `/health` per node; alert on `clients` approaching `max_connections`
- [ ] **Graceful deploys** — drain connections via LB before stopping a node

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Broadcasts only reach local clients | `publisher=local` | Set `publisher=redis` |
| Room members missing on other nodes | `registry=local` | Set `registry=redis` |
| Cross-node delivery silent on stream_select | No Swoole coroutine subscriber | Use `engine=swoole` on cluster nodes |
| Duplicate messages | Misconfigured `node_id` collision | Ensure unique `node_id` per instance |
| Redis connection errors at startup | Missing `ext-redis` or wrong host | Install extension; verify `scale.redis` settings |

## Next steps

- [Swoole Engine](/v3.0/advanced/swoole-engine.md) — per-node worker and connection tuning
- [Survivability](/v3.0/core/survivability.md) — hard connection caps and heartbeats
- [Reverse Proxy and Load Balancing](/v3.0/advanced/reverse-proxy.md) — proxy headers and health checks
- [Server Configuration](/v3.0/core/server-configuration.md) — full config reference
