---
title: "Controller API - Sockeon Documentation"
description: "Complete API reference for Sockeon SocketController class with WebSocket and HTTP methods"
og_image: "https://sockeon.github.io/logo.png"
twitter_image: "https://sockeon.github.io/logo.png"
---

# Controller API Reference

The `SocketController` class is the base class for all controllers in Sockeon, providing access to server functionality and convenience methods for WebSocket and HTTP handling.

## Class: `Sockeon\Sockeon\Controllers\SocketController`

### Abstract Base Class

All controllers must extend this abstract class:

```php
use Sockeon\Sockeon\Controllers\SocketController;

class MyController extends SocketController
{
    // Your controller methods here
}
```

---

## Core Methods

### setServer()

```php
public function setServer(Server $server): void
```

Sets the server instance for this controller. This method is called automatically by the server when registering the controller.

**Parameters:**
- `$server` (`Server`): The server instance

**Note:** This method is called internally and should not be called manually.

---

## WebSocket Communication

### emit()

```php
public function emit(string $clientId, string $event, array $data): void
```

Sends an event to a specific client.

**Parameters:**
- `$clientId` (`string`): The client ID to send to
- `$event` (`string`): The event name
- `$data` (`array<string, mixed>`): The data to send

**Example:**
```php
#[SocketOn('user.request')]
public function handleUserRequest(string $clientId, array $data): void
{
    $this->emit($clientId, 'user.response', [
        'message' => 'Request processed',
        'timestamp' => time()
    ]);
}
```

### sendRaw()

```php
public function sendRaw(string $clientId, string $payload): void
```

Sends a raw WebSocket payload to a specific client without event framing.

---

## Broadcasting

### broadcast()

```php
public function broadcast(string $event, array $data, ?string $namespace = null, ?string $room = null): void
```

Broadcasts an event to clients. Can broadcast to all clients, clients in a namespace, or clients in a specific room.

**Parameters:**
- `$event` (`string`): The event name
- `$data` (`array<string, mixed>`): The data to broadcast
- `$namespace` (`string|null`): Optional namespace to broadcast within
- `$room` (`string|null`): Optional room to broadcast to

**Example:**
```php
#[SocketOn('chat.message')]
public function handleChatMessage(string $clientId, array $data): void
{
    // Broadcast to all clients
    $this->broadcast('chat.message', [
        'from' => $clientId,
        'message' => $data['message'],
        'timestamp' => time()
    ]);
    
    // Or broadcast to specific namespace
    $this->broadcast('chat.message', [
        'from' => $clientId,
        'message' => $data['message'],
        'timestamp' => time()
    ], '/game');
    
    // Or broadcast to specific room
    $this->broadcast('chat.message', [
        'from' => $clientId,
        'message' => $data['message'],
        'timestamp' => time()
    ], '/game', 'room1');
}
```

### broadcastToRoom()

```php
public function broadcastToRoom(string $event, array $data, string $namespace, string $room): void
```

Broadcasts an event to all clients in a specific room within a namespace.

**Parameters:**
- `$event` (`string`): The event name
- `$data` (`array<string, mixed>`): The data to broadcast
- `$namespace` (`string`): The namespace containing the room
- `$room` (`string`): The room name

**Example:**
```php
#[SocketOn('room.message')]
public function handleRoomMessage(string $clientId, array $data): void
{
    $room = $data['room'] ?? 'general';
    
    $this->broadcastToRoom('room.message', [
        'from' => $clientId,
        'message' => $data['message'],
        'room' => $room
    ], '/chat', $room);
}
```

### broadcastToNamespace()

```php
public function broadcastToNamespace(string $event, array $data, string $namespace): void
```

Broadcasts an event to all clients in a specific namespace.

**Parameters:**
- `$event` (`string`): The event name
- `$data` (`array<string, mixed>`): The data to broadcast
- `$namespace` (`string`): The namespace

**Example:**
```php
#[HttpRoute('POST', '/api/admin/announcement')]
public function sendAnnouncement(Request $request): Response
{
    $data = $request->all();
    
    $this->broadcastToNamespace('announcement', [
        'message' => $data['message'],
        'priority' => $data['priority'] ?? 'normal',
        'timestamp' => time()
    ], '/admin');
    
    return Response::json(['success' => true]);
}
```

---

## Room and Namespace Management

### joinRoom()

```php
public function joinRoom(string $clientId, string $room, string $namespace = '/'): void
```

Adds a client to a room within a namespace.

**Parameters:**
- `$clientId` (`string`): The client ID
- `$room` (`string`): The room name
- `$namespace` (`string`): The namespace (default: '/')

**Example:**
```php
#[SocketOn('chat.join')]
public function joinChatRoom(string $clientId, array $data): void
{
    $room = $data['room'] ?? 'general';
    
    $this->joinRoom($clientId, $room, '/chat');
    
    $this->emit($clientId, 'room.joined', [
        'room' => $room,
        'message' => "You joined {$room}"
    ]);
    
    $this->broadcastToRoom('user.joined', [
        'clientId' => $clientId
    ], '/chat', $room);
}
```

### leaveRoom()

```php
public function leaveRoom(string $clientId, string $room, string $namespace = '/'): void
```

Removes a client from a room within a namespace.

**Parameters:**
- `$clientId` (`string`): The client ID
- `$room` (`string`): The room name
- `$namespace` (`string`): The namespace (default: '/')

**Example:**
```php
#[SocketOn('chat.leave')]
public function leaveChatRoom(string $clientId, array $data): void
{
    $room = $data['room'] ?? 'general';
    
    $this->leaveRoom($clientId, $room, '/chat');
    
    $this->broadcastToRoom('user.left', [
        'clientId' => $clientId
    ], '/chat', $room);
    
    $this->emit($clientId, 'room.left', [
        'room' => $room
    ]);
}
```

### joinNamespace()

```php
public function joinNamespace(string $clientId, string $namespace = '/'): void
```

Joins a client to a namespace.

### leaveNamespace()

```php
public function leaveNamespace(string $clientId): void
```

Removes a client from their current namespace.

---

## Server Access

### getServer()

```php
public function getServer(): Server
```

Returns the server instance for direct access to server methods.

**Returns:** `Server` - The server instance

**Example:**
```php
#[HttpRoute('GET', '/api/status')]
public function getStatus(Request $request): Response
{
    $server = $this->getServer();
    
    return Response::json([
        'clients_connected' => $server->getClientCount(),
        'client_types' => $server->getClientTypes(),
        'rate_limiting_enabled' => $server->isRateLimitingEnabled()
    ]);
}

#[SocketOn('server.info')]
public function getServerInfo(string $clientId, array $data): void
{
    $server = $this->getServer();
    
    $this->emit($clientId, 'server.info', [
        'total_clients' => $server->getClientCount(),
        'your_id' => $clientId,
        'your_type' => $server->getClientType($clientId)
    ]);
}
```

---

## Targeted Broadcasting Helpers

### broadcastTo()

```php
public function broadcastTo(string $event, array $data, array $clientIds): void
```

Sends an event only to the provided client IDs.

### broadcastExcept()

```php
public function broadcastExcept(string $event, array $data, array $exceptClientIds): void
```

Broadcasts to all connected clients except the provided client IDs.

Use `broadcast()` to send to every connected client.

---

## Client and Room Introspection

### Client and connection methods

```php
public function getClientIds(): array
public function getClientCount(): int
public function isConnected(string $clientId): bool
public function getClientType(string $clientId): ?string
public function disconnect(string $clientId): void
public function getClientIp(string $clientId): ?string
```

### Client metadata methods

```php
public function allData(string $clientId): ?array
public function data(string $clientId, string $key): mixed
public function putData(string $clientId, string $key, mixed $value): void
public function hasData(string $clientId, string $key): bool
public function forgetData(string $clientId, ?string $key = null): void
```

`allData()` returns the full data bag for a connection. `data()` reads a single key. `forgetData()` removes one key, or all data when `$key` is omitted.

### Namespace and room query methods

```php
public function getClientsInNamespace(string $namespace = '/'): array
public function getClientNamespace(string $clientId): string
public function joinNamespace(string $clientId, string $namespace = '/'): void
public function leaveNamespace(string $clientId): void
public function getClientsInRoom(string $room, string $namespace = '/'): array
public function getRooms(string $namespace = '/'): array
public function getClientRooms(string $clientId): array
public function leaveAllRooms(string $clientId): void
```

---

## Runtime Metrics and Async Tasks

These methods expose server telemetry and queue support directly from controllers:

```php
public function getUptime(): ?int
public function getUptimeString(): ?string
public function getStartTime(): ?float
public function getServerStats(): array
public function getPerformanceMetrics(): array
public function getConnectionPoolStats(): array
public function getTaskQueueStats(): array
public function queueAsyncTask(string $type, array $data, int $priority = 0): void
public function recordMetric(string $type, float $value = 0): void
public function recordError(string $type): void
```

Example:

```php
#[HttpRoute('GET', '/api/server/metrics')]
public function metrics(Request $request): Response
{
    return Response::json([
        'uptime' => $this->getUptimeString(),
        'performance' => $this->getPerformanceMetrics(),
        'pool' => $this->getConnectionPoolStats(),
        'queue' => $this->getTaskQueueStats(),
    ]);
}
```

---

## Attribute-Based Routing

### WebSocket Event Attributes

#### `#[OnConnect]`

Marks a method to be called when a client connects.

```php
#[OnConnect]
public function onConnect(string $clientId): void
{
    $this->emit($clientId, 'welcome', [
        'message' => 'Welcome to the server!',
        'clientId' => $clientId
    ]);
}
```

#### `#[OnDisconnect]`

Marks a method to be called when a client disconnects.

```php
#[OnDisconnect]
public function onDisconnect(string $clientId): void
{
    $this->broadcast('user.left', [
        'clientId' => $clientId,
        'message' => "User {$clientId} has left"
    ]);
}
```

#### `#[SocketOn('event.name')]`

Marks a method to handle a specific WebSocket event.

```php
#[SocketOn('chat.message')]
public function handleChatMessage(string $clientId, array $data): void
{
    // Handle the chat message event
}

#[SocketOn('user.typing')]
public function handleTyping(string $clientId, array $data): void
{
    // Handle typing indicator
}
```

**With Middleware:**
```php
#[SocketOn('admin.command', middlewares: [AdminMiddleware::class])]
public function handleAdminCommand(string $clientId, array $data): void
{
    // Only admins can execute this
}

#[SocketOn('public.event', excludeGlobalMiddlewares: [AuthMiddleware::class])]
public function handlePublicEvent(string $clientId, array $data): void
{
    // Public event - no auth required
}
```

### HTTP Route Attributes

#### `#[HttpRoute('METHOD', '/path')]`

Marks a method to handle HTTP requests.

```php
#[HttpRoute('GET', '/api/users')]
public function listUsers(Request $request): Response
{
    return Response::json(['users' => []]);
}

#[HttpRoute('POST', '/api/users')]
public function createUser(Request $request): Response
{
    $data = $request->all();
    // Create user logic
    return Response::json(['success' => true], 201);
}

#[HttpRoute('GET', '/api/users/{id}')]
public function getUser(Request $request): Response
{
    $userId = $request->getParam('id');
    // Get user logic
    return Response::json(['user' => ['id' => $userId]]);
}
```

**With Middleware:**
```php
#[HttpRoute('GET', '/api/admin/users', middlewares: [AuthMiddleware::class, AdminMiddleware::class])]
public function adminListUsers(Request $request): Response
{
    // Requires auth and admin role
}

#[HttpRoute('GET', '/api/public/health', excludeGlobalMiddlewares: [AuthMiddleware::class])]
public function healthCheck(Request $request): Response
{
    // Public endpoint - no auth
    return Response::json(['status' => 'healthy']);
}
```

### Rate Limiting Attribute

#### `#[RateLimit(maxCount, timeWindow)]`

Applies rate limiting to a specific method.

```php
#[SocketOn('chat.message')]
#[RateLimit(maxCount: 10, timeWindow: 60)] // 10 messages per minute
public function handleChatMessage(string $clientId, array $data): void
{
    // Rate limited chat messages
}

#[HttpRoute('POST', '/api/upload')]
#[RateLimit(maxCount: 5, timeWindow: 300)] // 5 uploads per 5 minutes
public function uploadFile(Request $request): Response
{
    // Rate limited file uploads
}
```

---

## Complete Controller Examples

### Chat Controller

```php
<?php

use Sockeon\Sockeon\Controllers\SocketController;
use Sockeon\Sockeon\Http\Attributes\HttpRoute;
use Sockeon\Sockeon\Http\Request;
use Sockeon\Sockeon\Http\Response;
use Sockeon\Sockeon\WebSocket\Attributes\OnConnect;
use Sockeon\Sockeon\WebSocket\Attributes\OnDisconnect;
use Sockeon\Sockeon\WebSocket\Attributes\SocketOn;

class ChatController extends SocketController
{
    private array $userRooms = [];

    #[OnConnect]
    public function onConnect(string $clientId): void
    {
        // Add to chat namespace and default room
        $this->joinNamespace($clientId, '/chat');
        $this->joinRoom($clientId, 'general', '/chat');
        
        $this->userRooms[$clientId] = 'general';
        
        $this->emit($clientId, 'welcome', [
            'message' => 'Welcome to chat!',
            'room' => 'general'
        ]);
        
        $this->broadcastToRoom('user.joined', [
            'clientId' => $clientId
        ], '/chat', 'general');
    }

    #[OnDisconnect]
    public function onDisconnect(string $clientId): void
    {
        $room = $this->userRooms[$clientId] ?? 'general';
        
        $this->broadcastToRoom('user.left', [
            'clientId' => $clientId
        ], '/chat', $room);
        
        unset($this->userRooms[$clientId]);
    }

    #[SocketOn('chat.message')]
    public function handleMessage(string $clientId, array $data): void
    {
        $message = $data['message'] ?? '';
        $room = $this->userRooms[$clientId] ?? 'general';
        
        if (empty($message)) {
            $this->emit($clientId, 'error', ['message' => 'Message cannot be empty']);
            return;
        }
        
        $this->broadcastToRoom('chat.message', [
            'from' => $clientId,
            'message' => $message,
            'timestamp' => time()
        ], '/chat', $room);
    }

    #[SocketOn('room.switch')]
    public function switchRoom(string $clientId, array $data): void
    {
        $newRoom = $data['room'] ?? 'general';
        $oldRoom = $this->userRooms[$clientId] ?? 'general';
        
        // Leave old room
        $this->leaveRoom($clientId, $oldRoom, '/chat');
        $this->broadcastToRoom('user.left', ['clientId' => $clientId], '/chat', $oldRoom);
        
        // Join new room
        $this->joinRoom($clientId, $newRoom, '/chat');
        $this->userRooms[$clientId] = $newRoom;
        
        $this->emit($clientId, 'room.switched', ['room' => $newRoom]);
        $this->broadcastToRoom('user.joined', ['clientId' => $clientId], '/chat', $newRoom);
    }

    #[HttpRoute('GET', '/api/chat/rooms')]
    public function listRooms(Request $request): Response
    {
        $rooms = [];
        foreach ($this->userRooms as $clientId => $room) {
            if (!isset($rooms[$room])) {
                $rooms[$room] = 0;
            }
            $rooms[$room]++;
        }
        
        return Response::json(['rooms' => $rooms]);
    }

    #[HttpRoute('POST', '/api/chat/broadcast')]
    public function broadcastMessage(Request $request): Response
    {
        $data = $request->all();
        $message = $data['message'] ?? '';
        $room = $data['room'] ?? null;
        
        if (empty($message)) {
            return Response::json(['error' => 'Message required'], 400);
        }
        
        if ($room) {
            $this->broadcastToRoom('admin.message', [
                'message' => $message,
                'from' => 'admin'
            ], '/chat', $room);
        } else {
            $this->broadcastToNamespace('admin.message', [
                'message' => $message,
                'from' => 'admin'
            ], '/chat');
        }
        
        return Response::json(['success' => true]);
    }
}
```

### Game Controller

```php
<?php

class GameController extends SocketController
{
    private array $games = [];
    private array $playerGames = [];

    #[OnConnect]
    public function onConnect(string $clientId): void
    {
        $this->joinNamespace($clientId, '/game');
        $this->joinRoom($clientId, 'lobby', '/game');
        
        $this->emit($clientId, 'lobby.joined', [
            'message' => 'Welcome to the game lobby!'
        ]);
    }

    #[SocketOn('game.create')]
    public function createGame(string $clientId, array $data): void
    {
        $gameId = uniqid('game_');
        
        $this->games[$gameId] = [
            'id' => $gameId,
            'host' => $clientId,
            'players' => [$clientId],
            'status' => 'waiting',
            'created' => time()
        ];
        
        $this->playerGames[$clientId] = $gameId;
        
        // Move from lobby to game room
        $this->leaveRoom($clientId, 'lobby', '/game');
        $this->joinRoom($clientId, $gameId, '/game');
        
        $this->emit($clientId, 'game.created', [
            'gameId' => $gameId,
            'role' => 'host'
        ]);
        
        // Notify lobby
        $this->broadcastToRoom('game.available', [
            'gameId' => $gameId,
            'host' => $clientId
        ], '/game', 'lobby');
    }

    #[SocketOn('game.join')]
    public function joinGame(string $clientId, array $data): void
    {
        $gameId = $data['gameId'] ?? null;
        
        if (!isset($this->games[$gameId])) {
            $this->emit($clientId, 'error', ['message' => 'Game not found']);
            return;
        }
        
        $game = &$this->games[$gameId];
        
        if (count($game['players']) >= 2) {
            $this->emit($clientId, 'error', ['message' => 'Game is full']);
            return;
        }
        
        // Add player to game
        $game['players'][] = $clientId;
        $this->playerGames[$clientId] = $gameId;
        
        // Move from lobby to game room
        $this->leaveRoom($clientId, 'lobby', '/game');
        $this->joinRoom($clientId, $gameId, '/game');
        
        // Notify game players
        $this->broadcastToRoom('player.joined', [
            'playerId' => $clientId,
            'playerCount' => count($game['players'])
        ], '/game', $gameId);
        
        // Start game if full
        if (count($game['players']) >= 2) {
            $game['status'] = 'playing';
            $this->broadcastToRoom('game.started', [
                'players' => $game['players']
            ], '/game', $gameId);
        }
    }

    #[SocketOn('game.move')]
    public function makeMove(string $clientId, array $data): void
    {
        $gameId = $this->playerGames[$clientId] ?? null;
        
        if (!$gameId || !isset($this->games[$gameId])) {
            $this->emit($clientId, 'error', ['message' => 'Not in a game']);
            return;
        }
        
        $move = $data['move'] ?? null;
        
        // Broadcast move to other players
        $this->broadcastToRoom('game.move', [
            'player' => $clientId,
            'move' => $move,
            'timestamp' => time()
        ], '/game', $gameId);
    }

    #[OnDisconnect]
    public function onDisconnect(string $clientId): void
    {
        $gameId = $this->playerGames[$clientId] ?? null;
        
        if ($gameId && isset($this->games[$gameId])) {
            // Notify other players
            $this->broadcastToRoom('player.disconnected', [
                'playerId' => $clientId
            ], '/game', $gameId);
            
            // Remove game if host left
            if ($this->games[$gameId]['host'] === $clientId) {
                unset($this->games[$gameId]);
            }
        }
        
        unset($this->playerGames[$clientId]);
    }

    #[HttpRoute('GET', '/api/games')]
    public function listGames(Request $request): Response
    {
        $gameList = array_map(function($game) {
            return [
                'id' => $game['id'],
                'host' => $game['host'],
                'players' => count($game['players']),
                'status' => $game['status'],
                'created' => $game['created']
            ];
        }, $this->games);
        
        return Response::json(['games' => array_values($gameList)]);
    }
}
```

---

## Best Practices

1. **Use Type Hints**: Always specify parameter and return types
2. **Validate Input**: Check all incoming data before processing
3. **Handle Errors Gracefully**: Send appropriate error responses
4. **Keep Methods Focused**: Each method should handle one specific task
5. **Use Meaningful Names**: Choose descriptive method and event names
6. **Document Complex Logic**: Use PHPDoc for complex methods
7. **Clean Up Resources**: Always clean up in disconnect handlers

---

## See Also

- [Server API](/v3.0/api/server.md) - Server instance methods
- [Request API](/v3.0/api/request.md) - HTTP request handling
- [Response API](/v3.0/api/response.md) - HTTP response creation
- [Routing Guide](/v3.0/core/routing.md) - Advanced routing patterns
