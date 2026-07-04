---
title: "Performance Overview - Sockeon Documentation"
description: "What to expect from Sockeon 3.x on Swoole — latency, connections, broadcasting, and multi-node scale"
og_image: "https://sockeon.github.io/logo.png"
twitter_image: "https://sockeon.github.io/logo.png"
---

# Performance Overview

**Last updated:** July 2026  
**Sockeon version:** 3.x  
**Test environment:** Linux, PHP 8.5, Swoole 6.2

Sockeon 3.x was evaluated on the Swoole engine under controlled load. Numbers below help you plan capacity and choose the right engine and deployment model. **Your results will vary** with hardware, handler complexity, network distance, and PHP extensions.

---

## Summary

| Area | What we observed |
|---|---|
| HTTP health checks | Very high throughput on minimal endpoints (~100k+ req/s on localhost) |
| WebSocket latency (localhost) | Sub-millisecond median round-trip for trivial handlers |
| WebSocket latency (LAN) | Low single-digit ms median; network dominates over framework cost |
| Idle connections | 10,000 connections held stable for 5+ minutes on one node |
| Room broadcast | Hundreds of members notified in tens of milliseconds on localhost |
| Multi-node broadcast | Cross-server room delivery in tens of milliseconds with Redis |
| Middleware & validation | No measurable overhead vs plain handlers on localhost |
| Trivial database work | No measurable overhead vs plain handlers on localhost |

Use **`stream_select` for local development.** Use **Swoole** for production. Use **Redis** when you need multiple server nodes.

---

## Latency

### Localhost (same machine)

| Metric | Typical value |
|---|---|
| WebSocket ping/pong p50 | ~0.6 ms |
| WebSocket ping/pong p99 | ~0.7 ms |
| HTTP health p50 | ~0.9 ms |
| HTTP health p99 | ~4 ms |

These numbers reflect minimal handlers with no business logic. Real applications (database, cache, external APIs) will be dominated by your own code.

### LAN (client and server on same network)

| Metric | Observed |
|---|---|
| p50 | ~3 ms |
| p95 | ~10 ms |
| Average | ~7 ms |

Expect **network round-trip to dominate** once clients are off the same host. Plan for higher tails (p99) on Wi‑Fi or under load.

### What adds latency

- Handler work (queries, serialization, external calls)
- Geographic distance between client and server
- TLS termination at a reverse proxy
- Large message payloads

Framework routing, validation, and middleware added **no measurable cost** in testing with trivial handlers.

---

## Throughput

| Scenario | Observed |
|---|---|
| HTTP health (localhost) | ~111,000 requests/sec |
| Sustained WebSocket ping/pong (single client) | ~1,600 round-trips/sec |
| Concurrent WebSocket senders (8 clients) | ~13,000 aggregate round-trips/sec |

HTTP throughput is excellent for health checks and light API routes. WebSocket throughput depends heavily on how much work each event handler does.

---

## Connections

| Test | Result |
|---|---|
| 200 idle connections × 30 s | All held, health count stable |
| 1,000 idle × 60 s | All held, health count stable |
| 5,000 idle × 2 min | All held, peak memory ~350 MB |
| 10,000 idle × 5 min | All held, peak memory ~688 MB, CPU ~0.1% |

### Memory planning (Swoole, idle connections)

| Target connections | Rough RAM | Notes |
|---|---|---|
| 10,000 | 20–80 MB theoretical; **~688 MB peak observed** in a 10k soak | Modest VPS is viable |
| 50,000 | 100–400 MB | 4–8 GB VPS recommended |
| 100,000+ | 200–800 MB+ | Kernel tuning, high `ulimit`, dedicated hardware |

See [Swoole Engine](/v3.0/advanced/swoole-engine.md) for worker tuning and [Survivability](/v3.0/core/survivability.md) for connection caps.

---

## Broadcasting

Room fan-out was tested from a single publisher to many subscribers in the same room.

| Room size | Delivery | Time (localhost) |
|---|---|---|
| ~50 members | 49/49 | ~1 ms |
| ~200 members | 199/199 | ~35 ms |
| ~500 members | 499/499 | ~68 ms |

The publisher is not counted as a subscriber — **N clients in a room means N−1 deliveries** when one client sends.

### Multi-node (Redis cluster)

With two server nodes and shared Redis:

| Metric | Observed |
|---|---|
| Cross-node delivery | 49/49 subscribers |
| Time | ~30–40 ms |

Requires `scale.publisher=redis`, `scale.registry=redis`, and a **unique `node_id` per server**. See [Scaling and Clustering](/v3.0/advanced/scaling.md).

**Important:** Room broadcast across Swoole workers on a **single server** needs one worker or local room state. Redis scaling is for **multiple servers**, not splitting one machine across many workers.

---

## Engine comparison

| | Swoole (production) | stream_select (development) |
|---|---|---|
| HTTP throughput | ~79–111k req/s | ~15k req/s |
| Connection handling | Thousands–tens of thousands | Hundreds (dev/testing) |
| Handler latency | ~0.6 ms (trivial) | ~0.6 ms (trivial) |
| Multi-node | Redis pub/sub | Not supported |

---

## Choosing a deployment model

| Goal | Recommendation |
|---|---|
| Local dev, tests, CI | `engine=stream_select` |
| Single production server, up to ~10k–50k connections | `engine=swoole`, tune `survivability.max_connections` |
| Room broadcast on one server | `worker_num=1` or local namespace manager |
| Multiple servers behind a load balancer | `engine=swoole` + Redis registry and publisher |
| Health checks for load balancers | Built-in `health_check_path` — very fast on Swoole |

---

## What affects your production numbers

- **Handler complexity** — database, cache, and third-party APIs matter more than the framework
- **Network** — LAN and WAN add far more latency than Sockeon routing
- **Message size** — large payloads increase memory and transfer time
- **Connection count** — raise `survivability.max_connections` and match `swoole.max_connection` (defaults cap at 10k via `min()`); set `ulimit -n` above your target
- **Multi-node** — register client presence on connect when using Redis room registry

---

## Related guides

- [Engines](/v3.0/core/engines.md) — Swoole vs stream_select
- [Swoole Engine](/v3.0/advanced/swoole-engine.md) — workers, memory, and tuning
- [Scaling and Clustering](/v3.0/advanced/scaling.md) — multi-node Redis setup
- [Survivability](/v3.0/core/survivability.md) — caps and heartbeats
- [Broadcasting](/v3.0/websocket/broadcasting.md) — rooms and fan-out in your app
