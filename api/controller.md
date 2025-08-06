---
title: "Controller API - Sockeon Documentation"
description: "Complete API reference for Sockeon SocketController class with WebSocket and HTTP methods"
og_image: "https://sockeon.com/assets/logo.png"
twitter_image: "https://sockeon.com/assets/logo.png"
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
public function emit(int $clientId, string $event, array $data): void
```

Sends an event to a specific client.

**Parameters:**
- `$clientId` (`int`): The client ID to send to
- `$event` (`string`): The event name
- `$data` (`array<string, mixed>`): The data to send

**Example:**
```php
#[SocketOn('user.request')]
public function handleUserRequest(int $clientId, array $data): void
{
    $this->emit($clientId, 'user.response', [
        'message' => 'Request processed',
        'timestamp' => time()
    ]);
}
```

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
public function handleChatMessage(int $clientId, array $data): void
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

### broadcastToRoomClients()

```php
public function broadcastToRoomClients(string $event, array $data, string $room, string $namespace = '/'): void
```

Broadcasts an event to all clients in a specific room within a namespace.

**Parameters:**
- `$event` (`string`): The event name
- `$data` (`array<string, mixed>`): The data to broadcast
- `$room` (`string`): The room name
- `$namespace` (`string`): The namespace (default: '/')

**Example:**
```php
#[SocketOn('room.message')]
public function handleRoomMessage(int $clientId, array $data): void
{
    $room = $data['room'] ?? 'general';
    
    $this->broadcastToRoomClients('room.message', [
        'from' => $clientId,
        'message' => $data['message'],
        'room' => $room
    ], $room, '/chat');
}
```

### broadcastToNamespaceClients()

```php
public function broadcastToNamespaceClients(string $event, array $data, string $namespace): void
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
    
    $this->broadcastToNamespaceClients('announcement', [
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
public function joinRoom(int $clientId, string $room, string $namespace = '/'): void
```

Adds a client to a room within a namespace.

**Parameters:**
- `$clientId` (`int`): The client ID
- `$room` (`string`): The room name
- `$namespace` (`string`): The namespace (default: '/')

**Example:**
```php
#[SocketOn('chat.join')]
public function joinChatRoom(int $clientId, array $data): void
{
    $room = $data['room'] ?? 'general';
    
    $this->joinRoom($clientId, $room, '/chat');
    
    $this->emit($clientId, 'room.joined', [
        'room' => $room,
        'message' => "You joined {$room}"
    ]);
    
    $this->broadcastToRoomClients('user.joined', [
        'clientId' => $clientId
    ], $room, '/chat');
}
```

### leaveRoom()

```php
public function leaveRoom(int $clientId, string $room, string $namespace = '/'): void
```

Removes a client from a room within a namespace.

**Parameters:**
- `$clientId` (`int`): The client ID
- `$room` (`string`): The room name
- `$namespace` (`string`): The namespace (default: '/')

**Example:**
```php
#[SocketOn('chat.leave')]
public function leaveChatRoom(int $clientId, array $data): void
{
    $room = $data['room'] ?? 'general';
    
    $this->leaveRoom($clientId, $room, '/chat');
    
    $this->broadcastToRoom($room, 'user.left', [
        'clientId' => $clientId
    ], '/chat');
    
    $this->emit($clientId, 'room.left', [
        'room' => $room
    ]);
}
```

### moveClientToNamespace()

```php
public function moveClientToNamespace(int $clientId, string $namespace = '/'): void
```

Moves a client to a namespace.

**Parameters:**
- `$clientId` (`int`): The client ID
- `$namespace` (`string`): The namespace (default: '/')

**Example:**
```php
#[OnConnect]
public function onConnect(int $clientId): void
{
    // Move client to chat namespace
    $this->moveClientToNamespace($clientId, '/chat');
    
    $this->emit($clientId, 'namespace.joined', [
        'namespace' => '/chat',
        'welcome' => 'Welcome to chat!'
    ]);
}
```

### leaveNamespace()

```php
public function leaveNamespace(int $clientId): void
```

Removes a client from their current namespace.

**Parameters:**
- `$clientId` (`int`): The client ID

**Example:**
```php
#[SocketOn('namespace.switch')]
public function switchNamespace(int $clientId, array $data): void
{
    $newNamespace = $data['namespace'] ?? '/';
    
    // Move to new namespace
    $this->moveClientToNamespace($clientId, $newNamespace);
    
    $this->emit($clientId, 'namespace.switched', [
        'namespace' => $newNamespace
    ]);
}
```

---

## Server Access

### getServer()

```php
protected function getServer(): Server
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
public function getServerInfo(int $clientId, array $data): void
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

## Attribute-Based Routing

### WebSocket Event Attributes

#### `#[OnConnect]`

Marks a method to be called when a client connects.

```php
#[OnConnect]
public function onConnect(int $clientId): void
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
public function onDisconnect(int $clientId): void
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
public function handleChatMessage(int $clientId, array $data): void
{
    // Handle the chat message event
}

#[SocketOn('user.typing')]
public function handleTyping(int $clientId, array $data): void
{
    // Handle typing indicator
}
```

**With Middleware:**
```php
#[SocketOn('admin.command', middlewares: [AdminMiddleware::class])]
public function handleAdminCommand(int $clientId, array $data): void
{
    // Only admins can execute this
}

#[SocketOn('public.event', excludeGlobalMiddlewares: [AuthMiddleware::class])]
public function handlePublicEvent(int $clientId, array $data): void
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
public function handleChatMessage(int $clientId, array $data): void
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
    public function onConnect(int $clientId): void
    {
        // Add to chat namespace and default room
        $this->moveClientToNamespace($clientId, '/chat');
        $this->joinRoom($clientId, 'general', '/chat');
        
        $this->userRooms[$clientId] = 'general';
        
        $this->emit($clientId, 'welcome', [
            'message' => 'Welcome to chat!',
            'room' => 'general'
        ]);
        
        $this->broadcastToRoom('general', 'user.joined', [
            'clientId' => $clientId
        ], '/chat');
    }

    #[OnDisconnect]
    public function onDisconnect(int $clientId): void
    {
        $room = $this->userRooms[$clientId] ?? 'general';
        
        $this->broadcastToRoom($room, 'user.left', [
            'clientId' => $clientId
        ], '/chat');
        
        unset($this->userRooms[$clientId]);
    }

    #[SocketOn('chat.message')]
    public function handleMessage(int $clientId, array $data): void
    {
        $message = $data['message'] ?? '';
        $room = $this->userRooms[$clientId] ?? 'general';
        
        if (empty($message)) {
            $this->emit($clientId, 'error', ['message' => 'Message cannot be empty']);
            return;
        }
        
        $this->broadcastToRoom($room, 'chat.message', [
            'from' => $clientId,
            'message' => $message,
            'timestamp' => time()
        ], '/chat');
    }

    #[SocketOn('room.switch')]
    public function switchRoom(int $clientId, array $data): void
    {
        $newRoom = $data['room'] ?? 'general';
        $oldRoom = $this->userRooms[$clientId] ?? 'general';
        
        // Leave old room
        $this->leaveRoom($clientId, $oldRoom, '/chat');
        $this->broadcastToRoom($oldRoom, 'user.left', ['clientId' => $clientId], '/chat');
        
        // Join new room
        $this->joinRoom($clientId, $newRoom, '/chat');
        $this->userRooms[$clientId] = $newRoom;
        
        $this->emit($clientId, 'room.switched', ['room' => $newRoom]);
        $this->broadcastToRoom($newRoom, 'user.joined', ['clientId' => $clientId], '/chat');
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
            $this->broadcastToRoom($room, 'admin.message', [
                'message' => $message,
                'from' => 'admin'
            ], '/chat');
        } else {
            $this->broadcastToNamespace('/chat', 'admin.message', [
                'message' => $message,
                'from' => 'admin'
            ]);
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
    public function onConnect(int $clientId): void
    {
        $this->moveClientToNamespace($clientId, '/game');
        $this->joinRoom($clientId, 'lobby', '/game');
        
        $this->emit($clientId, 'lobby.joined', [
            'message' => 'Welcome to the game lobby!'
        ]);
    }

    #[SocketOn('game.create')]
    public function createGame(int $clientId, array $data): void
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
        $this->broadcastToRoom('lobby', 'game.available', [
            'gameId' => $gameId,
            'host' => $clientId
        ], '/game');
    }

    #[SocketOn('game.join')]
    public function joinGame(int $clientId, array $data): void
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
        $this->broadcastToRoom($gameId, 'player.joined', [
            'playerId' => $clientId,
            'playerCount' => count($game['players'])
        ], '/game');
        
        // Start game if full
        if (count($game['players']) >= 2) {
            $game['status'] = 'playing';
            $this->broadcastToRoom($gameId, 'game.started', [
                'players' => $game['players']
            ], '/game');
        }
    }

    #[SocketOn('game.move')]
    public function makeMove(int $clientId, array $data): void
    {
        $gameId = $this->playerGames[$clientId] ?? null;
        
        if (!$gameId || !isset($this->games[$gameId])) {
            $this->emit($clientId, 'error', ['message' => 'Not in a game']);
            return;
        }
        
        $move = $data['move'] ?? null;
        
        // Broadcast move to other players
        $this->broadcastToRoom($gameId, 'game.move', [
            'player' => $clientId,
            'move' => $move,
            'timestamp' => time()
        ], '/game');
    }

    #[OnDisconnect]
    public function onDisconnect(int $clientId): void
    {
        $gameId = $this->playerGames[$clientId] ?? null;
        
        if ($gameId && isset($this->games[$gameId])) {
            // Notify other players
            $this->broadcastToRoom($gameId, 'player.disconnected', [
                'playerId' => $clientId
            ], '/game');
            
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

- [Server API](api/server.md) - Server instance methods
- [Request API](api/request.md) - HTTP request handling
- [Response API](api/response.md) - HTTP response creation
- [Routing Guide](core/routing.md) - Advanced routing patterns
