---
title: "Sockeon Documentation"
description: "Complete guide to Sockeon - PHP WebSocket and HTTP server framework with attribute-based routing, namespaces, rooms, and built-in rate limiting"
og_image: "https://sockeon.com/assets/logo.png"
twitter_image: "https://sockeon.com/assets/logo.png"
---

# Sockeon Documentation

Welcome to the comprehensive documentation for Sockeon - a framework-agnostic PHP WebSocket and HTTP server library with attribute-based routing and powerful namespaces and rooms functionality.

## Table of Contents

### Getting Started
- [Installation](getting-started/installation.md)
- [Quick Start](getting-started/quick-start.md)
- [Basic Concepts](getting-started/basic-concepts.md)

### Core Components
- [Server Configuration](core/server-configuration.md)
- [Controllers](core/controllers.md)
- [Routing](core/routing.md)
- [Middleware](core/middleware.md)
- [Namespaces and Rooms](core/namespaces-rooms.md)

### WebSocket Features
- [WebSocket Events](websocket/events.md)
- [Connection Management](websocket/connections.md)
- [Broadcasting](websocket/broadcasting.md)
- [WebSocket Client](websocket/client.md)

### HTTP Features
- [HTTP Routing](http/routing.md)
- [Request and Response](http/request-response.md)
- [CORS Configuration](http/cors.md)

### Advanced Features
- [Rate Limiting](advanced/rate-limiting.md)
- [Logging](advanced/logging.md)
- [Error Handling](advanced/error-handling.md)

### API Reference
- [Server API](api/server.md)
- [Controller API](api/controller.md)
- [Router API](api/router.md)
- [Request API](api/request.md)
- [Response API](api/response.md)
- [Client API](api/client.md)

### Examples
- [Basic WebSocket Server](examples/basic-server.md)
- [HTTP API Server](examples/http-server.md)

## Features Overview

- **WebSocket and HTTP Combined Server** - Single server handling both protocols
- **Attribute-based Routing** - Clean, declarative routing with PHP 8 attributes
- **Namespaces and Rooms** - Organized client grouping and broadcasting
- **Middleware Support** - Flexible request/response processing with HTTP and WebSocket middleware
- **Rate Limiting** - Built-in protection against abuse with configurable limits
- **CORS Support** - Configurable cross-origin resource sharing
- **PSR-3 Logging** - Comprehensive logging with multiple levels
- **Zero Dependencies** - Built with PHP core functionality only
- **PHP Client** - Connect to Sockeon servers from PHP applications
- **WebSocket Authentication** - Key-based authentication for secure connections
- **Exception Handling** - Comprehensive error handling with contextual logging

## Requirements

- PHP >= 8.0
- ext-openssl
- ext-sockets

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
    public function onConnect(int $clientId): void
    {
        $this->emit($clientId, 'welcome', ['message' => 'Hello!']);
    }

    #[SocketOn('chat.message')]
    public function handleChatMessage(int $clientId, array $data): void
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

$config = new ServerConfig();
$config->host = '0.0.0.0';
$config->port = 6001;

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
