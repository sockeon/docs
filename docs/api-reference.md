# API Reference

This document provides a comprehensive reference of all public classes, methods, and attributes available in the Sockeon library.

## Server Class

The `Server` class is the foundation of all Sockeon applications, providing the core functionality for handling WebSocket and HTTP connections.

### Constructor

```php
public function __construct(
    string $host = "0.0.0.0",  // The host address to bind to
    int $port = 6001,         // The port number to listen on
    bool $debug = false       // Enable verbose debug output
)
```

### Methods

#### Core Methods

```php
public function run(): void
public function registerController(SocketController $controller): void
public function addWebSocketMiddleware(callable $middleware): void
public function addHttpMiddleware(callable $middleware): void
```

#### Client Management

```php
public function getClientData(int $clientId, ?string $key = null): mixed
public function setClientData(int $clientId, string $key, mixed $value): void
public function disconnectClient(int $clientId): void
```

#### Broadcasting

```php
public function send(int $clientId, string $event, array $data): void
public function broadcast(string $event, array $data, ?string $namespace = null, ?string $room = null): void
```

#### Room Management

```php
public function joinRoom(int $clientId, string $room, string $namespace = '/'): void
public function leaveRoom(int $clientId, string $room, string $namespace = '/'): void
```

#### Getters

```php
public function getRouter(): Router
public function getNamespaceManager(): NamespaceManager
public function getHttpHandler(): HttpHandler
public function getMiddleware(): Middleware
```

## WebSocket Handler

### Methods

```php
public function handle(int $clientId, $client, string $data): bool
protected function performHandshake(int $clientId, $client, string $data): bool
protected function decodeWebSocketFrame(string $data): array
protected function encodeWebSocketFrame(string $payload, int $opcode = 1): string
```

## HTTP Handler

### Methods

```php
public function handle(int $clientId, $client, string $data): void
protected function parseHttpRequest(string $data): array
protected function processRequest(array $request): string
```

## SocketController

### Base Methods

```php
public function emit(int $clientId, string $event, array $data): void
public function broadcast(string $event, array $data, string $namespace = '/', ?string $room = null): void
public function joinRoom(int $clientId, string $room, string $namespace = '/'): void
public function leaveRoom(int $clientId, string $room, string $namespace = '/'): void
public function disconnectClient(int $clientId): void
```

## Attributes

### SocketOn

```php
#[Attribute]
class SocketOn
{
    public function __construct(string $event)
}
```

### HttpRoute

```php
#[Attribute]
class HttpRoute
{
    public function __construct(string $method, string $path)
}
```

## Router

### Methods

```php
public function addRoute(string $method, string $path, callable $handler): void
public function addSocketEvent(string $event, callable $handler): void
public function dispatch(int $clientId, string $event, array $data): mixed
public function dispatchHttp(array $request): mixed
```

## Request Class

### Constructor

```php
public function __construct(array $requestData)
```

### Methods

#### Core Methods

```php
public function getMethod(): string
public function getPath(): string
public function getProtocol(): string
public function getHeaders(): array
public function getHeader(string $name, mixed $default = null): mixed
```

#### Parameter Methods

```php
public function getQueryParams(): array
public function getQuery(string $name, mixed $default = null): mixed
public function getPathParams(): array
public function getParam(string $name, mixed $default = null): mixed
public function getBody(): mixed
```

#### Request Information 

```php
public function isJson(): bool
public function isAjax(): bool
public function isMethod(string $method): bool
public function getUrl(bool $includeQuery = true): string
public function getIpAddress(): ?string
```

#### Data Handling

```php
public static function fromArray(array $request): self
public function toArray(): array
public function setData(string $key, mixed $value): self
public function getData(string $key, mixed $default = null): mixed
```

## Response Class

### Constructor

```php
public function __construct(mixed $body = null, int $statusCode = 200, array $headers = [])
```

### Methods

#### Core Methods

```php
public function setBody(mixed $body): self
public function setStatusCode(int $statusCode): self
public function setContentType(string $contentType): self
public function setHeader(string $name, string $value): self
public function setHeaders(array $headers): self
```

#### Getters

```php
public function getStatusCode(): int
public function getBody(): mixed
public function getContentType(): string
public function getHeader(string $name): ?string
public function getHeaders(): array
public function toString(): string
```

#### Static Response Creators

```php
public static function json(mixed $data, int $statusCode = 200, array $headers = []): self
public static function ok(mixed $data = null, array $headers = []): self
public static function created(mixed $data = null, array $headers = []): self
public static function notFound(mixed $data = 'Not Found', array $headers = []): self
public static function badRequest(mixed $data = 'Bad Request', array $headers = []): self
public static function serverError(mixed $data = 'Internal Server Error', array $headers = []): self
public static function unauthorized(mixed $data = 'Unauthorized', array $headers = []): self
public static function forbidden(mixed $data = 'Forbidden', array $headers = []): self
public static function noContent(array $headers = []): self
public static function redirect(string $url, int $status = 302, array $headers = []): self
public static function download(string $content, string $filename, string $contentType = 'application/octet-stream', array $headers = []): self
```

## NamespaceManager

### Methods

```php
public function joinNamespace(int $clientId, string $namespace): void
public function leaveNamespace(int $clientId, string $namespace): void
public function joinRoom(int $clientId, string $room, string $namespace = '/'): void
public function leaveRoom(int $clientId, string $room, string $namespace = '/'): void
public function getClientsInRoom(string $room, string $namespace = '/'): array
```

## Middleware

### Methods

```php
public function addWebSocketMiddleware(Closure $middleware): void
public function addHttpMiddleware(Closure $middleware): void
public function runWebSocketStack(int $clientId, string $event, array $data, Closure $target): mixed
public function runHttpStack(Request $request, Closure $target): mixed
```

### Usage Example

```php
$server->addWebSocketMiddleware(function ($clientId, $event, $data, $next) {
    // Pre-processing
    $result = $next();
    // Post-processing
    return $result;
});

$server->addHttpMiddleware(function ($request, $next) {
    // Pre-processing for HTTP requests
    $response = $next();
    // Post-processing
    return $response;
});
```

For practical examples and use cases, see:
- [Examples](./examples.md)
- [Getting Started](./getting-started.md)
