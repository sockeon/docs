---
title: "Server API - Sockeon Documentation"
description: "Complete API reference for Sockeon Server class with methods for client management and broadcasting"
og_image: "https://sockeon.com/assets/logo.png"
twitter_image: "https://sockeon.com/assets/logo.png"
---

# Server API Reference

The `Server` class is the core component of Sockeon, managing WebSocket and HTTP connections, routing, and client communication.

## Class: `Sockeon\Sockeon\Connection\Server`

### Constructor

```php
public function __construct(ServerConfig $config)
```

Creates a new server instance with the provided configuration.

**Parameters:**
- `$config` (`ServerConfig`): Server configuration object

**Example:**
```php
use Sockeon\Sockeon\Config\ServerConfig;
use Sockeon\Sockeon\Connection\Server;

$config = new ServerConfig();
$config->host = '0.0.0.0';
$config->port = 6001;

$server = new Server($config);
```

---

## Core Methods

### run()

```php
public function run(): void
```

Starts the server and begins listening for connections. This method blocks until the server is stopped.

**Example:**
```php
$server->run(); // Server starts and blocks here
```

---

## Controller Management

### registerController()

```php
public function registerController(SocketController $controller): void
```

Registers a controller with the server. All routes and event handlers in the controller are automatically registered.

**Parameters:**
- `$controller` (`SocketController`): Controller instance to register

**Example:**
```php
$chatController = new ChatController();
$server->registerController($chatController);
```

---

## Client Management

### getClients()

```php
public function getClients(): array
```

Returns an array of all connected client resources.

**Returns:** `array<int, resource>` - Array of client IDs and their socket resources

**Example:**
```php
$clients = $server->getClients();
foreach ($clients as $clientId => $resource) {
    echo "Client {$clientId} is connected\n";
}
```

### getClientTypes()

```php
public function getClientTypes(): array
```

Returns an array mapping client IDs to their connection types.

**Returns:** `array<int, string>` - Array of client IDs and their types ('ws' for WebSocket, 'http' for HTTP)

**Example:**
```php
$types = $server->getClientTypes();
foreach ($types as $clientId => $type) {
    echo "Client {$clientId} type: {$type}\n";
}
```

### getClientIds()

```php
public function getClientIds(): array
```

Returns an array of all connected client IDs.

**Returns:** `array<int, int>` - Array of client IDs

**Example:**
```php
$clientIds = $server->getClientIds();
echo "Connected clients: " . implode(', ', $clientIds) . "\n";
```

### getClientCount()

```php
public function getClientCount(): int
```

Returns the number of currently connected clients.

**Returns:** `int` - Number of connected clients

**Example:**
```php
$count = $server->getClientCount();
echo "Total connected clients: {$count}\n";
```

### isClientConnected()

```php
public function isClientConnected(int $clientId): bool
```

Checks if a specific client is currently connected.

**Parameters:**
- `$clientId` (`int`): Client ID to check

**Returns:** `bool` - True if connected, false otherwise

**Example:**
```php
if ($server->isClientConnected(123)) {
    echo "Client 123 is connected\n";
}
```

### getClientType()

```php
public function getClientType(int $clientId): ?string
```

Gets the connection type for a specific client.

**Parameters:**
- `$clientId` (`int`): Client ID to check

**Returns:** `string|null` - Client type ('ws' or 'http') or null if not found

**Example:**
```php
$type = $server->getClientType(123);
if ($type === 'ws') {
    echo "Client 123 is a WebSocket connection\n";
}
```

---

## Communication Methods

### send()

```php
public function send(int $clientId, string $event, array $data): void
```

Sends a WebSocket message to a specific client.

**Parameters:**
- `$clientId` (`int`): Target client ID
- `$event` (`string`): Event name
- `$data` (`array<string, mixed>`): Event data

**Example:**
```php
$server->send(123, 'notification', [
    'message' => 'Hello!',
    'timestamp' => time()
]);
```

### sendToClient()

```php
public function sendToClient(int $clientId, string $message): void
```

Sends raw message data to a specific client.

**Parameters:**
- `$clientId` (`int`): Target client ID
- `$message` (`string`): Raw message data

**Example:**
```php
$server->sendToClient(123, 'Hello, client!');
```

### broadcast()

```php
public function broadcast(string $event, array $data, ?string $namespace = null, ?string $room = null): void
```

Broadcasts a message to multiple clients with optional namespace and room filtering.

**Parameters:**
- `$event` (`string`): Event name
- `$data` (`array<string, mixed>`): Event data
- `$namespace` (`string|null`): Optional namespace filter
- `$room` (`string|null`): Optional room filter

**Example:**
```php
// Broadcast to all clients
$server->broadcast('announcement', ['message' => 'Server maintenance in 5 minutes']);

// Broadcast to specific namespace
$server->broadcast('game.update', ['state' => 'updated'], '/game');

// Broadcast to specific room in namespace
$server->broadcast('chat.message', ['text' => 'Hello room!'], '/chat', 'general');
```

---

## Namespace and Room Management

### moveClientToNamespace()

```php
public function moveClientToNamespace(int $clientId, string $namespace = '/'): void
```

Moves a client to a namespace.

**Parameters:**
- `$clientId` (`int`): Client ID
- `$namespace` (`string`): Namespace to move to (default: '/')

**Example:**
```php
$server->moveClientToNamespace(123, '/chat');
```

### joinRoom()

```php
public function joinRoom(int $clientId, string $room, string $namespace = '/'): void
```

Adds a client to a room within a namespace.

**Parameters:**
- `$clientId` (`int`): Client ID
- `$room` (`string`): Room name
- `$namespace` (`string`): Namespace containing the room (default: '/')

**Example:**
```php
$server->joinRoom(123, 'general', '/chat');
```

### leaveRoom()

```php
public function leaveRoom(int $clientId, string $room, string $namespace = '/'): void
```

Removes a client from a room within a namespace.

**Parameters:**
- `$clientId` (`int`): Client ID
- `$room` (`string`): Room name
- `$namespace` (`string`): Namespace containing the room (default: '/')

**Example:**
```php
$server->leaveRoom(123, 'general', '/chat');
```

---

## Middleware Management

### addHttpMiddleware()

```php
public function addHttpMiddleware(string $middleware): void
```

Adds global HTTP middleware to the server.

**Parameters:**
- `$middleware` (`string`): Middleware class name implementing `HttpMiddleware`

**Example:**
```php
$server->addHttpMiddleware(AuthMiddleware::class);
$server->addHttpMiddleware(CorsMiddleware::class);
```

### addWebSocketMiddleware()

```php
public function addWebSocketMiddleware(string $middleware): void
```

Adds global WebSocket middleware to the server.

**Parameters:**
- `$middleware` (`string`): Middleware class name implementing `WebsocketMiddleware`

**Example:**
```php
$server->addWebSocketMiddleware(AuthMiddleware::class);
// Note: Rate limiting is handled automatically via #[RateLimit] attribute
```

### addHandshakeMiddleware()

```php
public function addHandshakeMiddleware(string $middleware): void
```

Adds WebSocket handshake middleware to the server.

**Parameters:**
- `$middleware` (`string`): Middleware class name implementing `HandshakeMiddleware`

**Example:**
```php
$server->addHandshakeMiddleware(WebSocketAuthMiddleware::class);
```

---

## Router Access

### getRouter()

```php
public function getRouter(): Router
```

Returns the server's router instance.

**Returns:** `Router` - The router instance

**Example:**
```php
$router = $server->getRouter();
$httpRoutes = $router->getHttpRoutes();
$wsRoutes = $router->getWebSocketRoutes();
```

---

## Rate Limiting

### getRateLimitConfig()

```php
public function getRateLimitConfig(): ?RateLimitConfig
```

Returns the rate limiting configuration.

**Returns:** `RateLimitConfig|null` - Rate limiting configuration or null if disabled

**Example:**
```php
$rateLimitConfig = $server->getRateLimitConfig();
if ($rateLimitConfig && $rateLimitConfig->isEnabled()) {
    echo "Rate limiting is enabled\n";
}
```

### isRateLimitingEnabled()

```php
public function isRateLimitingEnabled(): bool
```

Checks if rate limiting is enabled.

**Returns:** `bool` - True if rate limiting is enabled, false otherwise

**Example:**
```php
if ($server->isRateLimitingEnabled()) {
    echo "Rate limiting is active\n";
}
```

---

## Usage Examples

### Basic Server Setup

```php
<?php

use Sockeon\Sockeon\Config\ServerConfig;
use Sockeon\Sockeon\Connection\Server;

// Create configuration
$config = new ServerConfig();
$config->host = '0.0.0.0';
$config->port = 6001;
$config->debug = true;

// Create server
$server = new Server($config);

// Add middleware
$server->addHttpMiddleware(CorsMiddleware::class);
$server->addWebSocketMiddleware(AuthMiddleware::class);

// Register controllers
$server->registerController(new ChatController());
$server->registerController(new ApiController());

// Start server
echo "Starting server on {$config->host}:{$config->port}\n";
$server->run();
```

### Server Monitoring

```php
<?php

// Create a monitoring endpoint
class MonitorController extends SocketController
{
    #[HttpRoute('GET', '/api/server/status')]
    public function getServerStatus(Request $request): Response
    {
        $server = $this->getServer();
        
        return Response::json([
            'status' => 'online',
            'clients' => [
                'total' => $server->getClientCount(),
                'websocket' => count(array_filter(
                    $server->getClientTypes(), 
                    fn($type) => $type === 'ws'
                )),
                'http' => count(array_filter(
                    $server->getClientTypes(), 
                    fn($type) => $type === 'http'
                ))
            ],
            'rate_limiting' => [
                'enabled' => $server->isRateLimitingEnabled(),
                'config' => $server->getRateLimitConfig()?->toArray()
            ],
            'uptime' => time() - $_SERVER['REQUEST_TIME_FLOAT']
        ]);
    }

    #[HttpRoute('GET', '/api/server/clients')]
    public function getClientList(Request $request): Response
    {
        $server = $this->getServer();
        $clients = [];
        
        foreach ($server->getClientIds() as $clientId) {
            $clients[] = [
                'id' => $clientId,
                'type' => $server->getClientType($clientId),
                'connected' => $server->isClientConnected($clientId)
            ];
        }
        
        return Response::json([
            'clients' => $clients,
            'total' => count($clients)
        ]);
    }
}
```

### Dynamic Client Management

```php
<?php

class ClientManagerController extends SocketController
{
    #[HttpRoute('POST', '/api/clients/{clientId}/kick')]
    public function kickClient(Request $request): Response
    {
        $clientId = (int)$request->getParam('clientId');
        $reason = $request->all()['reason'] ?? 'Kicked by admin';
        
        if (!$this->getServer()->isClientConnected($clientId)) {
            return Response::json(['error' => 'Client not found'], 404);
        }
        
        // Send kick message to client
        $this->getServer()->send($clientId, 'kicked', [
            'reason' => $reason,
            'timestamp' => time()
        ]);
        
        // Disconnect the client (you'd implement this)
        $this->disconnectClient($clientId);
        
        return Response::json(['success' => true]);
    }

    #[HttpRoute('POST', '/api/broadcast')]
    public function broadcastMessage(Request $request): Response
    {
        $data = $request->all();
        $event = $data['event'] ?? 'announcement';
        $message = $data['message'] ?? '';
        $namespace = $data['namespace'] ?? null;
        $room = $data['room'] ?? null;
        
        if (empty($message)) {
            return Response::json(['error' => 'Message is required'], 400);
        }
        
        $this->getServer()->broadcast($event, [
            'message' => $message,
            'from' => 'server',
            'timestamp' => time()
        ], $namespace, $room);
        
        return Response::json(['success' => true]);
    }
}
```

---

## Error Handling

The Server class methods generally follow these error handling patterns:

- **Connection methods** return `bool` or throw exceptions for critical failures
- **Communication methods** fail silently for invalid clients (check with `isClientConnected()` first)
- **Configuration methods** throw `InvalidArgumentException` for invalid parameters

### Safe Client Communication

```php
// Always check if client is connected before sending
if ($server->isClientConnected($clientId)) {
    $server->send($clientId, 'message', ['data' => 'value']);
} else {
    echo "Client {$clientId} is not connected\n";
}

// Or use a helper method
function safeSend(Server $server, int $clientId, string $event, array $data): bool
{
    if ($server->isClientConnected($clientId)) {
        $server->send($clientId, $event, $data);
        return true;
    }
    return false;
}
```

---

## See Also

- [Controller API](api/controller.md) - Controller base class methods
- [Router API](api/router.md) - Routing system API
