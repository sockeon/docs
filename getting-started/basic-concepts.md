---
title: "Basic Concepts - Sockeon Documentation"
description: "Learn the core concepts of Sockeon framework including controllers, events, namespaces, and rooms"
og_image: "https://sockeon.com/assets/logo.png"
twitter_image: "https://sockeon.com/assets/logo.png"
---

# Basic Concepts

Understanding these core concepts will help you build powerful applications with Sockeon.

## Architecture Overview

Sockeon is built around a few key concepts:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   HTTP Client   │    │ WebSocket Client│    │   PHP Client    │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          │         ┌────────────┼──────────────────────┘
          │         │            │
          ▼         ▼            ▼
    ┌─────────────────────────────────────┐
    │         Sockeon Server              │
    │  ┌─────────────┬─────────────────┐  │
    │  │HTTP Handler │ WebSocket Handler│  │
    │  └─────────────┴─────────────────┘  │
    │              Router                 │
    │          ┌─────────────┐            │
    │          │Controllers  │            │
    │          └─────────────┘            │
    │        Namespaces & Rooms           │
    └─────────────────────────────────────┘
```

## Server

The **Server** is the central component that:
- Listens for incoming connections
- Handles both HTTP and WebSocket protocols
- Manages client connections
- Routes requests to appropriate controllers
- Manages namespaces and rooms

```php
use Sockeon\Sockeon\Config\ServerConfig;
use Sockeon\Sockeon\Connection\Server;

$config = new ServerConfig();
$server = new Server($config);
```

## Controllers

**Controllers** contain your application logic. They extend `SocketController` and use attributes to define routes and event handlers.

```php
use Sockeon\Sockeon\Controllers\SocketController;

class MyController extends SocketController
{
    // Your application logic here
}
```

### Key Methods Available in Controllers

```php
// WebSocket methods
$this->emit($clientId, 'event', $data);                    // Send to specific client
$this->broadcast('event', $data);                          // Send to all clients
$this->broadcastToRoomClients('event', $data, 'room');     // Send to room
$this->broadcastToNamespaceClients('event', $data, 'ns');  // Send to namespace

// Room management
$this->joinRoom($clientId, 'room');
$this->leaveRoom($clientId, 'room');

// Server access
$this->getServer();                               // Access server instance
```

## Attributes and Routing

Sockeon uses PHP 8 attributes for clean, declarative routing:

### WebSocket Attributes

```php
#[OnConnect]                    // Called when client connects
#[OnDisconnect]                 // Called when client disconnects
#[SocketOn('event.name')]       // Handle specific WebSocket events
```

### HTTP Attributes

```php
#[HttpRoute('GET', '/path')]        // Handle HTTP GET requests
#[HttpRoute('POST', '/api/users')]  // Handle HTTP POST requests
#[HttpRoute('PUT', '/users/{id}')]  // Handle with path parameters
```

### Rate Limiting Attribute

```php
#[RateLimit(maxCount: 10, timeWindow: 60)]  // Limit to 10 requests per minute
```

## Events and Data Flow

### WebSocket Event Flow

1. **Client Connection**: Client establishes WebSocket connection
2. **Authentication**: Optional handshake middleware validates connection
3. **OnConnect Event**: Your `#[OnConnect]` methods are called
4. **Event Handling**: Client sends events, routed to `#[SocketOn]` methods
5. **OnDisconnect Event**: Your `#[OnDisconnect]` methods are called when client leaves

```php
class ChatController extends SocketController
{
    #[OnConnect]
    public function welcome(int $clientId): void
    {
        $this->emit($clientId, 'welcome', ['message' => 'Hello!']);
    }

    #[SocketOn('chat.message')]
    public function handleMessage(int $clientId, array $data): void
    {
        $this->broadcast('chat.message', $data);
    }

    #[OnDisconnect]
    public function goodbye(int $clientId): void
    {
        $this->broadcast('user.left', ['user' => $clientId]);
    }
}
```

### HTTP Request Flow

1. **HTTP Request**: Client sends HTTP request
2. **Routing**: Router matches request to controller method
3. **Middleware**: HTTP middleware processes request
4. **Controller**: Your method handles request and returns response
5. **Response**: Server sends HTTP response back to client

```php
#[HttpRoute('GET', '/api/users/{id}')]
public function getUser(Request $request): Response
{
    $id = $request->getParam('id');
    $user = $this->findUser($id);
    
    return Response::json($user);
}
```

## Namespaces and Rooms

### Namespaces

Namespaces provide logical separation of clients. Think of them as different "areas" of your application.

```php
// Default namespace is '/'
$this->joinNamespace($clientId, '/chat');
$this->joinNamespace($clientId, '/game');

// Broadcast to specific namespace
$this->broadcastToNamespaceClients('message', $data, '/chat');
```

### Rooms

Rooms are subdivisions within namespaces. They're perfect for organizing clients into groups.

```php
// Join a room within a namespace
$this->joinRoom($clientId, 'room1', '/chat');
$this->joinRoom($clientId, 'lobby', '/game');

// Broadcast to specific room
$this->broadcastToRoomClients('private.message', $data, 'room1', '/chat');
```

### Practical Example

```php
class GameController extends SocketController
{
    #[OnConnect]
    public function onConnect(int $clientId): void
    {
        // All game clients start in the lobby
        $this->joinNamespace($clientId, '/game');
        $this->joinRoom($clientId, 'lobby', '/game');
    }

    #[SocketOn('game.join')]
    public function joinGame(int $clientId, array $data): void
    {
        $gameId = $data['gameId'];
        
        // Move from lobby to specific game room
        $this->leaveRoom($clientId, 'lobby', '/game');
        $this->joinRoom($clientId, "game_{$gameId}", '/game');
        
        // Notify other players in the game
        $this->broadcastToRoomClients('player.joined', [
            'playerId' => $clientId
        ], "game_{$gameId}", '/game');
    }
}
```

## Middleware

Middleware allows you to process requests before they reach your controllers:

### HTTP Middleware

```php
use Sockeon\Sockeon\Contracts\Http\HttpMiddleware;

class AuthMiddleware implements HttpMiddleware
{
    public function handle(Request $request, callable $next, Server $server): mixed
    {
        // Check authentication
        if (!$this->isAuthenticated($request)) {
            return Response::json(['error' => 'Unauthorized'], 401);
        }
        
        return $next($request);
    }
}
```

### WebSocket Middleware

```php
use Sockeon\Sockeon\Contracts\WebSocket\WebsocketMiddleware;

class ChatMiddleware implements WebsocketMiddleware
{
    public function handle(int $clientId, string $event, array $data, callable $next, Server $server): mixed
    {
        // Validate message content
        if (isset($data['message']) && $this->containsProfanity($data['message'])) {
            return; // Block the message
        }
        
        return $next($clientId, $event, $data);
    }
}
```

### Applying Middleware

```php
// Global middleware (applies to all routes/events)
$server->addHttpMiddleware(AuthMiddleware::class);
$server->addWebSocketMiddleware(ChatMiddleware::class);

// Route-specific middleware
#[HttpRoute('POST', '/admin', middlewares: [AdminMiddleware::class])]
#[SocketOn('admin.command', middlewares: [AdminMiddleware::class])]
```

## Request and Response Objects

### HTTP Request

```php
#[HttpRoute('POST', '/users/{id}')]
public function updateUser(Request $request): Response
{
    $id = $request->getParam('id');           // Path parameter
    $name = $request->getQuery('name');       // Query parameter
    $data = $request->all();                  // Request body as array
    $header = $request->getHeader('Authorization'); // Header
    
    // Update user logic here
    
    return Response::json(['success' => true]);
}
```

### HTTP Response

```php
// JSON response
return Response::json(['data' => $data]);

// HTML response
return new Response('<h1>Hello World</h1>', 200, ['Content-Type' => 'text/html']);

// Custom status codes
return Response::json(['error' => 'Not found'], 404);

// With custom headers
return Response::json($data)->setHeader('Cache-Control', 'no-cache');
```

## Client Connections

### WebSocket Client (Built-in)

Sockeon includes a PHP WebSocket client for connecting to Sockeon servers:

```php
use Sockeon\Sockeon\Connection\Client;

$client = new Client('localhost', 6001);
$client->connect();

$client->on('welcome', function($data) {
    echo "Server says: " . $data['message'] . "\n";
});

$client->emit('chat.message', ['message' => 'Hello from PHP client!']);
$client->listen();
```

### JavaScript Client

```javascript
const ws = new WebSocket('ws://localhost:6001');

ws.onmessage = function(event) {
    const {event: eventName, data} = JSON.parse(event.data);
    console.log('Received:', eventName, data);
};

// Send an event
ws.send(JSON.stringify({
    event: 'chat.message',
    data: {message: 'Hello!'}
}));
```

## Configuration

Server behavior is controlled through the `ServerConfig` class:

```php
$config = new ServerConfig();
$config->host = '0.0.0.0';           // Bind address
$config->port = 6001;                // Port number
$config->debug = true;               // Enable debug logging
$config->authKey = 'secret';         // Optional authentication key

// CORS configuration
$config->cors = [
    'allowed_origins' => ['https://myapp.com'],
    'allowed_methods' => ['GET', 'POST'],
    'allowed_headers' => ['Content-Type']
];

// Rate limiting
$config->rateLimitConfig = new RateLimitConfig([
    'enabled' => true,
    'maxHttpRequestsPerIp' => 100,
    'httpTimeWindow' => 60
]);
```

## Error Handling

Sockeon provides comprehensive error handling:

```php
try {
    $server->run();
} catch (Exception $e) {
    echo "Server error: " . $e->getMessage() . "\n";
}
```

Controllers can handle errors gracefully:

```php
#[SocketOn('risky.operation')]
public function handleRiskyOperation(int $clientId, array $data): void
{
    try {
        $this->performRiskyOperation($data);
    } catch (Exception $e) {
        $this->emit($clientId, 'error', [
            'message' => 'Operation failed',
            'error' => $e->getMessage()
        ]);
    }
}
```

## Next Steps

Now that you understand the basic concepts, explore these topics:

- [Server Configuration](core/server-configuration.md) - Detailed configuration options
- [Controllers](core/controllers.md) - Advanced controller features
- [Middleware](core/middleware.md) - Create custom middleware
- [Examples](../examples/) - See real-world applications

## Best Practices

1. **Organize by Feature**: Group related functionality in dedicated controllers
2. **Use Namespaces**: Separate different parts of your application
3. **Implement Middleware**: Handle cross-cutting concerns like auth and logging
4. **Validate Input**: Always validate data from clients
5. **Handle Errors**: Implement proper error handling and user feedback
6. **Rate Limiting**: Protect your server from abuse
7. **Logging**: Use Sockeon's logging features for debugging and monitoring
