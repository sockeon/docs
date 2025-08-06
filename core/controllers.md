---
title: "Controllers - Sockeon Documentation"
description: "Learn how to create and use controllers in Sockeon framework with WebSocket events and HTTP routes"
og_image: "https://sockeon.com/assets/logo.png"
twitter_image: "https://sockeon.com/assets/logo.png"
---

# Controllers

Controllers are the heart of your Sockeon application. They contain your business logic and handle both WebSocket events and HTTP requests using PHP 8 attributes for clean, declarative routing.

## Controller Basics

All controllers must extend the `SocketController` base class:

```php
<?php

use Sockeon\Sockeon\Controllers\SocketController;

class MyController extends SocketController
{
    // Your controller methods here
}
```

## WebSocket Event Handling

### Connection Events

Handle client connections and disconnections with special attributes:

```php
use Sockeon\Sockeon\WebSocket\Attributes\OnConnect;
use Sockeon\Sockeon\WebSocket\Attributes\OnDisconnect;

class ChatController extends SocketController
{
    #[OnConnect]
    public function onConnect(int $clientId): void
    {
        // Called when a client connects
        $this->emit($clientId, 'welcome', [
            'message' => 'Welcome to the server!',
            'clientId' => $clientId,
            'timestamp' => time()
        ]);

        // Notify other clients
        $this->broadcast('user.joined', [
            'clientId' => $clientId,
            'message' => "User {$clientId} joined"
        ]);
    }

    #[OnDisconnect]
    public function onDisconnect(int $clientId): void
    {
        // Called when a client disconnects
        $this->broadcast('user.left', [
            'clientId' => $clientId,
            'message' => "User {$clientId} left"
        ]);
    }
}
```

### Custom Event Handlers

Handle custom WebSocket events using the `#[SocketOn]` attribute:

```php
use Sockeon\Sockeon\WebSocket\Attributes\SocketOn;

class ChatController extends SocketController
{
    #[SocketOn('chat.message')]
    public function handleChatMessage(int $clientId, array $data): void
    {
        // Validate message
        if (empty($data['message'])) {
            $this->emit($clientId, 'error', ['message' => 'Message cannot be empty']);
            return;
        }

        // Broadcast to all clients
        $this->broadcast('chat.message', [
            'clientId' => $clientId,
            'message' => $data['message'],
            'timestamp' => time()
        ]);
    }

    #[SocketOn('chat.private')]
    public function handlePrivateMessage(int $clientId, array $data): void
    {
        $targetId = $data['targetId'] ?? null;
        $message = $data['message'] ?? '';

        if (!$targetId || !$this->isClientConnected($targetId)) {
            $this->emit($clientId, 'error', ['message' => 'Target user not found']);
            return;
        }

        // Send to target client
        $this->emit($targetId, 'chat.private', [
            'from' => $clientId,
            'message' => $message,
            'timestamp' => time()
        ]);

        // Confirm to sender
        $this->emit($clientId, 'chat.private.sent', [
            'to' => $targetId,
            'message' => $message
        ]);
    }

    #[SocketOn('typing.start')]
    public function handleTypingStart(int $clientId, array $data): void
    {
        $room = $data['room'] ?? 'general';
        
        $this->broadcastToRoomClients('user.typing', [
            'clientId' => $clientId,
            'typing' => true
        ], $room);
    }

    #[SocketOn('typing.stop')]
    public function handleTypingStop(int $clientId, array $data): void
    {
        $room = $data['room'] ?? 'general';
        
        $this->broadcastToRoomClients('user.typing', [
            'clientId' => $clientId,
            'typing' => false
        ], $room);
    }
}
```

## HTTP Request Handling

Handle HTTP requests using the `#[HttpRoute]` attribute:

```php
use Sockeon\Sockeon\Http\Attributes\HttpRoute;
use Sockeon\Sockeon\Http\Request;
use Sockeon\Sockeon\Http\Response;

class ApiController extends SocketController
{
    #[HttpRoute('GET', '/api/status')]
    public function getStatus(Request $request): Response
    {
        return Response::json([
            'status' => 'online',
            'clients' => $this->getClientCount(),
            'uptime' => time() - $_SERVER['REQUEST_TIME'],
            'timestamp' => time()
        ]);
    }

    #[HttpRoute('GET', '/api/clients')]
    public function getClients(Request $request): Response
    {
        $clients = [];
        foreach (array_keys($this->getAllClients()) as $clientId) {
            $clients[] = [
                'id' => $clientId,
                'type' => $this->getClientType($clientId),
                'connected_at' => time() // You'd track this in your app
            ];
        }

        return Response::json([
            'count' => count($clients),
            'clients' => $clients
        ]);
    }

    #[HttpRoute('POST', '/api/broadcast')]
    public function broadcastMessage(Request $request): Response
    {
        $data = $request->all();
        
        if (!isset($data['event']) || !isset($data['data'])) {
            return Response::json([
                'error' => 'Missing required fields: event, data'
            ], 400);
        }

        $this->broadcast($data['event'], $data['data']);

        return Response::json(['success' => true]);
    }
}
```

### Path Parameters

Extract parameters from URL paths:

```php
#[HttpRoute('GET', '/api/users/{id}')]
public function getUser(Request $request): Response
{
    $userId = $request->getParam('id');
    
    // Validate ID
    if (!is_numeric($userId)) {
        return Response::json(['error' => 'Invalid user ID'], 400);
    }

    $user = $this->findUserById((int)$userId);
    
    if (!$user) {
        return Response::json(['error' => 'User not found'], 404);
    }

    return Response::json($user);
}

#[HttpRoute('PUT', '/api/users/{id}/profile')]
public function updateUserProfile(Request $request): Response
{
    $userId = $request->getParam('id');
    $data = $request->all();

    // Update user profile logic
    $this->updateUser($userId, $data);

    return Response::json(['success' => true]);
}

#[HttpRoute('GET', '/api/rooms/{room}/messages')]
public function getRoomMessages(Request $request): Response
{
    $room = $request->getParam('room');
    $limit = $request->getQuery('limit', 50);
    $offset = $request->getQuery('offset', 0);

    $messages = $this->getRoomMessages($room, $limit, $offset);

    return Response::json([
        'room' => $room,
        'messages' => $messages,
        'pagination' => [
            'limit' => $limit,
            'offset' => $offset
        ]
    ]);
}
```

### Query Parameters

Access URL query parameters:

```php
#[HttpRoute('GET', '/api/search')]
public function search(Request $request): Response
{
    $query = $request->getQuery('q');
    $type = $request->getQuery('type', 'all');
    $page = (int)$request->getQuery('page', 1);
    $limit = (int)$request->getQuery('limit', 20);

    if (empty($query)) {
        return Response::json(['error' => 'Query parameter required'], 400);
    }

    $results = $this->performSearch($query, $type, $page, $limit);

    return Response::json([
        'query' => $query,
        'type' => $type,
        'results' => $results,
        'pagination' => [
            'page' => $page,
            'limit' => $limit,
            'total' => count($results)
        ]
    ]);
}
```

## Room and Namespace Management

Controllers provide convenient methods for managing client groups:

```php
class GameController extends SocketController
{
    #[OnConnect]
    public function onConnect(int $clientId): void
    {
        // Add to game namespace and lobby
        $this->moveClientToNamespace($clientId, '/game');
        $this->joinRoom($clientId, 'lobby', '/game');
        
        $this->emit($clientId, 'game.status', [
            'location' => 'lobby',
            'namespace' => '/game'
        ]);
    }

    #[SocketOn('game.create')]
    public function createGame(int $clientId, array $data): void
    {
        $gameId = uniqid('game_');
        
        // Move creator from lobby to new game room
        $this->leaveRoom($clientId, 'lobby', '/game');
        $this->joinRoom($clientId, $gameId, '/game');
        
        $this->emit($clientId, 'game.created', [
            'gameId' => $gameId,
            'role' => 'host'
        ]);
        
        // Notify lobby about new game
        $this->broadcastToRoomClients('game.available', [
            'gameId' => $gameId,
            'host' => $clientId
        ], 'lobby', '/game');
    }

    #[SocketOn('game.join')]
    public function joinGame(int $clientId, array $data): void
    {
        $gameId = $data['gameId'] ?? null;
        
        if (!$gameId) {
            $this->emit($clientId, 'error', ['message' => 'Game ID required']);
            return;
        }

        // Move from lobby to game
        $this->leaveRoom($clientId, 'lobby', '/game');
        $this->joinRoom($clientId, $gameId, '/game');
        
        // Notify game participants
        $this->broadcastToRoomClients('player.joined', [
            'playerId' => $clientId
        ], $gameId, '/game');
        
        $this->emit($clientId, 'game.joined', [
            'gameId' => $gameId,
            'role' => 'player'
        ]);
    }

    #[SocketOn('game.leave')]
    public function leaveGame(int $clientId, array $data): void
    {
        $gameId = $data['gameId'] ?? null;
        
        if ($gameId) {
            // Leave game room and return to lobby
            $this->leaveRoom($clientId, $gameId, '/game');
            $this->joinRoom($clientId, 'lobby', '/game');
            
            // Notify remaining players
            $this->broadcastToRoomClients('player.left', [
                'playerId' => $clientId
            ], $gameId, '/game');
        }
    }

    #[OnDisconnect]
    public function onDisconnect(int $clientId): void
    {
        // Cleanup is automatic when client disconnects
        // But you might want to notify other players
        $this->broadcast('player.disconnected', [
            'playerId' => $clientId
        ], '/game');
    }
}
```

## Controller Utilities

### Available Methods

Controllers inherit these useful methods from `SocketController`:

#### WebSocket Communication
```php
// Send to specific client
$this->emit(int $clientId, string $event, array $data): void

// Send to all clients
$this->broadcast(string $event, array $data): void

// Send to clients in a specific room
$this->broadcastToRoomClients(string $event, array $data, string $room, string $namespace = '/'): void

// Send to clients in a specific namespace
$this->broadcastToNamespaceClients(string $event, array $data, string $namespace): void
```

#### Room Management
```php
// Add client to room
$this->joinRoom(int $clientId, string $room, string $namespace = '/'): void

// Remove client from room
$this->leaveRoom(int $clientId, string $room, string $namespace = '/'): void

// Move client to namespace
$this->moveClientToNamespace(int $clientId, string $namespace = '/'): void

// Note: There is no direct leaveNamespace method - clients are moved between namespaces
```

#### Server Access
```php
// Get server instance
$this->getServer(): Server

// Check if client is connected
$this->isClientConnected(int $clientId): bool

// Get all client IDs
$this->getAllClients(): array

// Get client count
$this->getClientCount(): int

// Get client type
$this->getClientType(int $clientId): ?string
```

### Advanced Examples

#### Data Processing Example

```php
#[HttpRoute('POST', '/api/process')]
public function processData(Request $request): Response
{
    $data = $request->all();
    
    if (empty($data['content'])) {
        return Response::json(['error' => 'Content required'], 400);
    }

    // Process the data
    $processedData = $this->processContent($data['content']);
    
    // Notify WebSocket clients about new data
    $this->broadcast('data.processed', [
        'content' => $processedData,
        'timestamp' => time()
    ]);

    return Response::json([
        'success' => true,
        'processed' => $processedData
    ]);
}

private function processContent(string $content): string
{
    // Example processing logic
    return strtoupper($content);
}
```

#### Real-time Notifications

```php
class NotificationController extends SocketController
{
    private array $userSubscriptions = [];

    #[SocketOn('notifications.subscribe')]
    public function subscribe(int $clientId, array $data): void
    {
        $userId = $data['userId'] ?? null;
        $topics = $data['topics'] ?? [];

        if (!$userId) {
            $this->emit($clientId, 'error', ['message' => 'User ID required']);
            return;
        }

        // Store subscription
        $this->userSubscriptions[$clientId] = [
            'userId' => $userId,
            'topics' => $topics
        ];

        $this->emit($clientId, 'notifications.subscribed', [
            'topics' => $topics
        ]);
    }

    #[HttpRoute('POST', '/api/notifications/send')]
    public function sendNotification(Request $request): Response
    {
        $data = $request->all();
        $topic = $data['topic'] ?? null;
        $message = $data['message'] ?? null;
        $targetUsers = $data['users'] ?? null; // Optional: specific users

        if (!$topic || !$message) {
            return Response::json(['error' => 'Topic and message required'], 400);
        }

        $sentCount = 0;
        foreach ($this->userSubscriptions as $clientId => $subscription) {
            // Check if client is subscribed to this topic
            if (!in_array($topic, $subscription['topics'])) {
                continue;
            }

            // Check if targeting specific users
            if ($targetUsers && !in_array($subscription['userId'], $targetUsers)) {
                continue;
            }

            $this->emit($clientId, 'notification', [
                'topic' => $topic,
                'message' => $message,
                'timestamp' => time()
            ]);

            $sentCount++;
        }

        return Response::json([
            'success' => true,
            'sent_to' => $sentCount
        ]);
    }

    #[OnDisconnect]
    public function onDisconnect(int $clientId): void
    {
        // Clean up subscriptions
        unset($this->userSubscriptions[$clientId]);
    }
}
```

## Controller Organization

### Single Responsibility

Keep controllers focused on specific functionality:

```php
// Good: Focused on chat functionality
class ChatController extends SocketController { ... }

// Good: Focused on game functionality  
class GameController extends SocketController { ... }

// Good: Focused on user management
class UserController extends SocketController { ... }

// Bad: Too many responsibilities
class EverythingController extends SocketController { ... }
```

### Multiple Controllers

Register multiple controllers for organized applications:

#### Method 1: Individual Registration

```php
$server = new Server($config);

// Register different controllers for different features
$server->registerController(new ChatController());
$server->registerController(new GameController());
$server->registerController(new UserController());
$server->registerController(new NotificationController());
$server->registerController(new ApiController());

$server->run();
```

#### Method 2: Bulk Registration

```php
$server = new Server($config);

// Register multiple controllers at once
$server->registerControllers([
    new ChatController(),
    new GameController(),
    new UserController(),
    new NotificationController(),
    new ApiController()
]);

$server->run();
```

#### Method 3: Class Name Registration

```php
$server = new Server($config);

// Register controllers by class name (they will be instantiated automatically)
$server->registerControllers([
    ChatController::class,
    GameController::class,
    UserController::class,
    NotificationController::class,
    ApiController::class
]);

$server->run();
```

#### Method 4: Mixed Registration

```php
$server = new Server($config);

// Mix instantiated controllers and class names
$server->registerControllers([
    new ChatController(),
    GameController::class,  // Will be instantiated automatically
    new UserController(),
    NotificationController::class,
    new ApiController()
]);

$server->run();
```

### Controller Dependencies

Use dependency injection for complex controllers:

```php
class UserController extends SocketController
{
    private UserRepository $userRepository;
    private AuthService $authService;

    public function __construct(UserRepository $userRepository, AuthService $authService)
    {
        $this->userRepository = $userRepository;
        $this->authService = $authService;
    }

    #[HttpRoute('GET', '/api/users/{id}')]
    public function getUser(Request $request): Response
    {
        $userId = $request->getParam('id');
        $user = $this->userRepository->findById($userId);
        
        if (!$user) {
            return Response::json(['error' => 'User not found'], 404);
        }

        return Response::json($user->toArray());
    }
}

// Register with dependencies
$userRepository = new UserRepository($database);
$authService = new AuthService($config);
$server->registerController(new UserController($userRepository, $authService));
```

## Best Practices

1. **Keep Methods Focused**: Each method should handle one specific event or request
2. **Validate Input**: Always validate data from clients before processing
3. **Handle Errors Gracefully**: Use try-catch blocks and send appropriate error responses
4. **Use Type Hints**: Leverage PHP's type system for better code quality
5. **Document Your Methods**: Use PHPDoc comments for complex methods
6. **Separate Concerns**: Use services and repositories for business logic
7. **Test Your Controllers**: Write unit tests for your controller methods

## Next Steps

- [Routing](core/routing.md) - Learn about advanced routing features
- [Middleware](core/middleware.md) - Add request/response processing
- [WebSocket Events](websocket/events.md) - Deep dive into WebSocket handling
- [HTTP Features](http/routing.md) - Advanced HTTP request handling
