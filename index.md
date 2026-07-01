---
title: "Sockeon Documentation"
description: "Complete guide to Sockeon - PHP WebSocket and HTTP server framework with attribute-based routing, namespaces, rooms, and built-in rate limiting"
og_image: "https://sockeon.github.io/logo.png"
twitter_image: "https://sockeon.github.io/logo.png"
---

# Sockeon Documentation

Welcome to the comprehensive documentation for Sockeon - a framework-agnostic PHP WebSocket and HTTP server library with attribute-based routing and powerful namespaces and rooms functionality.

## Table of Contents

### Getting Started
- [Installation](/v3.0/getting-started/installation.md)
- [Quick Start](/v3.0/getting-started/quick-start.md)
- [Basic Concepts](/v3.0/getting-started/basic-concepts.md)
- [Migrating to 3.x](/v3.0/getting-started/migration-v3.md)

### Core Components
- [Server Configuration](/v3.0/core/server-configuration.md)
- [Engines](/v3.0/core/engines.md)
- [Survivability](/v3.0/core/survivability.md)
- [Controllers](/v3.0/core/controllers.md)
- [Routing](/v3.0/core/routing.md)
- [Middleware](/v3.0/core/middleware.md)
- [Namespaces and Rooms](/v3.0/core/namespaces-rooms.md)

### WebSocket Features
- [WebSocket Events](/v3.0/websocket/events.md)
- [Connection Management](/v3.0/websocket/connections.md)
- [Broadcasting](/v3.0/websocket/broadcasting.md)
- [WebSocket Client](/v3.0/websocket/client.md)

### HTTP Features
- [HTTP Routing](/v3.0/http/routing.md)
- [Request and Response](/v3.0/http/request-response.md)
- [CORS Configuration](/v3.0/http/cors.md)

### Data Validation and Sanitization
- [Data Validation](/v3.0/validation/validation.md)
- [Data Sanitization](/v3.0/validation/sanitization.md)

### Advanced Features
- [Swoole Engine](/v3.0/advanced/swoole-engine.md)
- [Scaling and Clustering](/v3.0/advanced/scaling.md)
- [Rate Limiting](/v3.0/advanced/rate-limiting.md)
- [Logging](/v3.0/advanced/logging.md)
- [Error Handling](/v3.0/advanced/error-handling.md)
- [Reverse Proxy and Load Balancing](/v3.0/advanced/reverse-proxy.md)

### API Reference
- [Server API](/v3.0/api/server.md)
- [Controller API](/v3.0/api/controller.md)
- [Router API](/v3.0/api/router.md)
- [Request API](/v3.0/api/request.md)
- [Response API](/v3.0/api/response.md)
- [Client API](/v3.0/api/client.md)
- [Event API](/v3.0/api/event.md)

### Examples
- [Basic WebSocket Server](/v3.0/examples/basic-server.md)
- [HTTP API Server](/v3.0/examples/http-server.md)

## Features Overview

- **WebSocket and HTTP Combined Server** - Single server handling both protocols
- **Pluggable Engines** - `stream_select` for zero-deps installs or `swoole` for high concurrency
- **Swoole Scaling** - Tens of thousands of concurrent WebSocket connections per node
- **Redis Cluster** - Multi-node broadcast and room membership via pub/sub
- **Attribute-based Routing** - Clean, declarative routing with PHP 8 attributes
- **Namespaces and Rooms** - Organized client grouping and broadcasting
- **Middleware Support** - Flexible request/response processing with HTTP and WebSocket middleware
- **Rate Limiting** - Built-in protection against abuse with configurable limits
- **CORS Support** - Configurable cross-origin resource sharing
- **Reverse Proxy Support** - Full compatibility with nginx, Apache, and load balancers
- **Health Check Endpoints** - Built-in health check for load balancer integration
- **Server Uptime Tracking** - Monitor server uptime and performance
- **PSR-3 Logging** - Comprehensive logging with multiple levels
- **Zero Dependencies** - Built with PHP core functionality only
- **PHP Client** - Connect to Sockeon servers from PHP applications
- **WebSocket Authentication** - Key-based authentication for secure connections
- **Unified Validation System** - Shared validation and sanitization for HTTP and WebSocket data
- **Exception Handling** - Comprehensive error handling with contextual logging

## Requirements

- PHP >= 8.3
- ext-openssl
- ext-sockets

### Optional Extensions

- **ext-openswoole** (or ext-swoole) — required for `engine=swoole` high-concurrency mode
- **ext-redis** — required for `scale.publisher=redis` or `scale.registry=redis` multi-node clustering

Both are listed as Composer **suggested** dependencies and are not needed for default single-node `stream_select` deployments.

## Quick Example

```php
<?php

use Sockeon\Sockeon\Config\ServerConfig;
use Sockeon\Sockeon\Connection\Server;
use Sockeon\Sockeon\Controllers\SocketController;
use Sockeon\Sockeon\Http\Attributes\HttpRoute;
use Sockeon\Sockeon\Http\Request;
use Sockeon\Sockeon\Http\Response;
use Sockeon\Sockeon\WebSocket\Attributes\SocketOn;
use Sockeon\Sockeon\WebSocket\Attributes\OnConnect;

class MyController extends SocketController
{
    #[OnConnect]
    public function onConnect(string $clientId): void
    {
        $this->emit($clientId, 'welcome', ['message' => 'Hello!']);
    }

    #[SocketOn('chat.message')]
    public function handleChatMessage(string $clientId, array $data): void
    {
        $this->broadcast('chat.message', [
            'user' => $clientId,
            'message' => $data['message']
        ]);
    }

    #[HttpRoute('GET', '/api/users')]
    public function getUsers(Request $request): Response
    {
        return Response::json(['users' => ['John', 'Jane']]);
    }
}

$config = new ServerConfig([
    'host' => '0.0.0.0',
    'port' => 6001
]);

$server = new Server($config);
$server->registerController(new MyController());
$server->run();
```

## Community

- [GitHub Repository](https://github.com/sockeon/sockeon)
- [Issues](https://github.com/sockeon/sockeon/issues)
- [Discussions](https://github.com/sockeon/sockeon/discussions)

## License

Sockeon is open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).
