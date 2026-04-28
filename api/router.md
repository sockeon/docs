---
title: "Router API - Sockeon Documentation"
description: "Accurate API reference for Sockeon Router route registration and dispatch methods"
og_image: "https://sockeon.com/logo.png"
twitter_image: "https://sockeon.com/logo.png"
---

# Router API Reference

The router maps WebSocket events and HTTP routes declared with attributes on controllers.

## Class: `Sockeon\Sockeon\Core\Router`

## Method Summary

```php
public function setServer(Server $server): void
public function register(SocketController $controller): void
public function dispatch(string $clientId, string $event, array $data): void
public function dispatchSpecialEvent(string $clientId, string $eventType): void
public function dispatchHttp(Request $request): mixed
public function getHttpRoutes(): array
public function getWebSocketRoutes(): array
```

## Typical Usage

You normally do not instantiate or call the router directly. `Server` handles this when you register controllers.

```php
$server = new Server($config);
$server->registerController(new ChatController());
$server->registerController(new ApiController());
$server->run();
```

## Route Registration Behavior

When `register()` runs, Sockeon scans controller methods and maps:

- `#[SocketOn('event.name')]` to WebSocket event routes
- `#[OnConnect]` and `#[OnDisconnect]` to special lifecycle handlers
- `#[HttpRoute('METHOD', '/path')]` to HTTP routes (with path parameters)

## Introspection Helpers

`getWebSocketRoutes()` and `getHttpRoutes()` return internal route arrays used by the framework runtime.  
These are useful for debugging tooling but are not intended as stable schema contracts.

## See Also

- [Controller API](/v2.0/api/controller.md)
- [WebSocket Events](/v2.0/websocket/events.md)
- [HTTP Routing](/v2.0/http/routing.md)
