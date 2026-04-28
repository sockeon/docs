---
title: "Client API - Sockeon Documentation"
description: "Accurate API reference for Sockeon PHP Client wrapper and WebSocket client usage"
og_image: "https://sockeon.com/logo.png"
twitter_image: "https://sockeon.com/logo.png"
---

# Client API Reference

Sockeon's PHP client entrypoint is `Sockeon\Sockeon\Connection\Client`.

## Class: `Sockeon\Sockeon\Connection\Client`

### Constructor

```php
public function __construct(string $host, int $port, string $path = '/', int $timeout = 10)
```

Creates a client for a WebSocket endpoint.

### Connection methods

```php
public function connect(array $headers = []): bool
public function disconnect(): bool
public function isConnected(): bool
```

### Event methods

```php
public function on(string $event, callable $callback): self
public function emit(string $event, array $data = []): bool
```

### Runtime methods

```php
public function run(?callable $callback = null, int $checkInterval = 50): void
public function setAutoReconnect(bool $enabled, int $maxAttempts = 5, int $delay = 3): self
public function resetReconnectAttempts(): self
```

## Example

```php
use Sockeon\Sockeon\Connection\Client;
use RuntimeException;

$client = (new Client('localhost', 6001))
    ->setAutoReconnect(true, 5, 3)
    ->on('welcome', function (array $data): void {
        echo "Server says: " . ($data['message'] ?? 'hello') . PHP_EOL;
    })
    ->on('chat.message', function (array $data): void {
        echo '[' . ($data['from'] ?? 'unknown') . '] ' . ($data['message'] ?? '') . PHP_EOL;
    });

if (!$client->connect()) {
    throw new RuntimeException('Connection failed');
}

$client->emit('chat.join', ['room' => 'general']);
$client->emit('chat.message', ['message' => 'Hello from PHP client']);

$client->run();
```

## Important Notes

- `Client` does not expose low-level receive APIs like `receive()` or `receiveEvent()`.
- `Client` also does not include callback helpers like `onMessage()` or timeout mutators like `setTimeout()`.
- Use `on()` callbacks plus `run()` for long-lived listening behavior.
- `emit()` expects Sockeon event format (`event` + `data`) and returns `false` on failure.

## See Also

- [Server API](/v2.0/api/server.md)
- [WebSocket Events](/v2.0/websocket/events.md)
- [WebSocket Client Guide](/v2.0/websocket/client.md)
