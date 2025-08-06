---
title: "Namespaces and Rooms - Sockeon Documentation"
description: "Learn how to organize WebSocket clients using namespaces and rooms in Sockeon framework"
og_image: "https://sockeon.com/assets/logo.png"
twitter_image: "https://sockeon.com/assets/logo.png"
---

# Namespaces and Rooms

Namespaces and rooms provide powerful organization and grouping capabilities for WebSocket clients. They allow you to create logical separations and targeted broadcasting, essential for building scalable real-time applications.

## Understanding Namespaces and Rooms

### Namespaces

Namespaces provide the top-level organization for your application. Think of them as different "areas" or "sections" of your application:

- `/` - Default namespace (all clients start here)
- `/chat` - Chat application namespace
- `/game` - Game namespace
- `/admin` - Admin panel namespace

### Rooms

Rooms are subdivisions within namespaces. They're perfect for organizing clients into smaller groups:

- `general` - General chat room
- `room_123` - Specific chat room
- `game_456` - Specific game session
- `user_789` - Private user space

### Hierarchy

```
Namespace: /chat
├── Room: general
│   ├── Client 1
│   ├── Client 2
│   └── Client 3
├── Room: room_123
│   ├── Client 4
│   └── Client 5
└── Room: private_456
    └── Client 6

Namespace: /game
├── Room: lobby
│   ├── Client 7
│   └── Client 8
└── Room: game_789
    ├── Client 9
    └── Client 10
```

## Working with Namespaces

### Joining Namespaces

Clients are automatically placed in the default namespace (`/`) when they connect. You can move them to other namespaces:

```php
class ChatController extends SocketController
{
    #[OnConnect]
    public function onConnect(int $clientId): void
    {
        // Client is automatically in '/' namespace
        
        // Move to chat namespace
        $this->moveClientToNamespace($clientId, '/chat');
        
        $this->emit($clientId, 'namespace.joined', [
            'namespace' => '/chat',
            'message' => 'Welcome to the chat namespace!'
        ]);
    }

    #[SocketOn('namespace.switch')]
    public function switchNamespace(int $clientId, array $data): void
    {
        $targetNamespace = $data['namespace'] ?? '/';
        
        // Validate namespace
        $allowedNamespaces = ['/', '/chat', '/game', '/admin'];
        if (!in_array($targetNamespace, $allowedNamespaces)) {
            $this->emit($clientId, 'error', ['message' => 'Invalid namespace']);
            return;
        }

        // Move to new namespace
        $this->moveClientToNamespace($clientId, $targetNamespace);
        
        $this->emit($clientId, 'namespace.switched', [
            'namespace' => $targetNamespace
        ]);
    }
}
```

### Broadcasting to Namespaces

Send messages to all clients in a specific namespace:

```php
class NotificationController extends SocketController
{
    #[HttpRoute('POST', '/api/notifications/broadcast')]
    public function broadcastToNamespace(Request $request): Response
    {
        $data = $request->all();
        $namespace = $data['namespace'] ?? '/';
        $message = $data['message'] ?? '';

        // Broadcast to all clients in the namespace
        $this->broadcastToNamespaceClients('notification', [
            'message' => $message,
            'timestamp' => time(),
            'type' => 'system'
        ], $namespace);

        return Response::json(['success' => true]);
    }

    #[SocketOn('admin.announcement')]
    public function adminAnnouncement(int $clientId, array $data): void
    {
        $message = $data['message'] ?? '';
        $targetNamespace = $data['namespace'] ?? '/';

        // Send announcement to specific namespace
        $this->broadcastToNamespaceClients('announcement', [
            'message' => $message,
            'from' => 'admin',
            'timestamp' => time()
        ], $targetNamespace);

        // Confirm to admin
        $this->emit($clientId, 'announcement.sent', [
            'namespace' => $targetNamespace,
            'message' => $message
        ]);
    }
}
```

## Working with Rooms

### Joining and Leaving Rooms

```php
class ChatController extends SocketController
{
    #[OnConnect]
    public function onConnect(int $clientId): void
    {
        // Move to chat namespace
        $this->moveClientToNamespace($clientId, '/chat');
        
        // Join default room
        $this->joinRoom($clientId, 'general', '/chat');
        
        // Notify room about new user
        $this->broadcastToRoomClients('user.joined', [
            'clientId' => $clientId,
            'message' => "User {$clientId} joined the room"
        ], 'general', '/chat');
    }

    #[SocketOn('room.join')]
    public function joinChatRoom(int $clientId, array $data): void
    {
        $room = $data['room'] ?? 'general';
        $namespace = '/chat';

        // Leave current room(s) first (optional)
        $this->leaveAllRooms($clientId, $namespace);
        
        // Join new room
        $this->joinRoom($clientId, $room, $namespace);
        
        // Confirm to user
        $this->emit($clientId, 'room.joined', [
            'room' => $room,
            'namespace' => $namespace
        ]);
        
        // Notify room members
        $this->broadcastToRoomClients('user.joined', [
            'clientId' => $clientId,
            'room' => $room
        ], $room, $namespace);
    }

    #[SocketOn('room.leave')]
    public function leaveChatRoom(int $clientId, array $data): void
    {
        $room = $data['room'] ?? 'general';
        $namespace = '/chat';

        // Leave the room
        $this->leaveRoom($clientId, $room, $namespace);
        
        // Notify remaining room members
        $this->broadcastToRoomClients('user.left', [
            'clientId' => $clientId,
            'room' => $room
        ], $room, $namespace);
        
        // Confirm to user
        $this->emit($clientId, 'room.left', [
            'room' => $room
        ]);
    }
}
```

### Broadcasting to Rooms

Send messages to all clients in a specific room:

```php
class ChatController extends SocketController
{
    #[SocketOn('chat.message')]
    public function sendMessage(int $clientId, array $data): void
    {
        $message = $data['message'] ?? '';
        $room = $data['room'] ?? 'general';
        $namespace = '/chat';

        if (empty($message)) {
            $this->emit($clientId, 'error', ['message' => 'Message cannot be empty']);
            return;
        }

        // Broadcast to room
        $this->broadcastToRoomClients('chat.message', [
            'clientId' => $clientId,
            'message' => $message,
            'room' => $room,
            'timestamp' => time()
        ], $room, $namespace);
    }

    #[SocketOn('chat.private')]
    public function sendPrivateMessage(int $clientId, array $data): void
    {
        $targetId = $data['targetId'] ?? null;
        $message = $data['message'] ?? '';

        if (!$targetId || !$this->isClientConnected($targetId)) {
            $this->emit($clientId, 'error', ['message' => 'Target user not found']);
            return;
        }

        // Create private room name
        $privateRoom = 'private_' . min($clientId, $targetId) . '_' . max($clientId, $targetId);
        
        // Ensure both users are in the private room
        $this->joinRoom($clientId, $privateRoom, '/chat');
        $this->joinRoom($targetId, $privateRoom, '/chat');
        
        // Send message to private room
        $this->broadcastToRoomClients('chat.private', [
            'from' => $clientId,
            'message' => $message,
            'timestamp' => time()
        ], $privateRoom, '/chat');
    }
}
```

## Advanced Room Management

### Dynamic Room Creation

```php
class GameController extends SocketController
{
    private array $games = [];

    #[SocketOn('game.create')]
    public function createGame(int $clientId, array $data): void
    {
        $gameName = $data['name'] ?? 'Untitled Game';
        $maxPlayers = $data['maxPlayers'] ?? 4;
        $gameId = uniqid('game_');
        
        // Store game info
        $this->games[$gameId] = [
            'id' => $gameId,
            'name' => $gameName,
            'host' => $clientId,
            'maxPlayers' => $maxPlayers,
            'players' => [$clientId],
            'status' => 'waiting',
            'created' => time()
        ];

        // Move host to game namespace and room
        $this->moveClientToNamespace($clientId, '/game');
        $this->joinRoom($clientId, $gameId, '/game');
        
        // Notify host
        $this->emit($clientId, 'game.created', [
            'gameId' => $gameId,
            'game' => $this->games[$gameId]
        ]);
        
        // Notify lobby about new game
        $this->broadcastToRoomClients('game.available', [
            'gameId' => $gameId,
            'name' => $gameName,
            'host' => $clientId,
            'players' => 1,
            'maxPlayers' => $maxPlayers
        ], 'lobby', '/game');
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
        
        // Check if game is full
        if (count($game['players']) >= $game['maxPlayers']) {
            $this->emit($clientId, 'error', ['message' => 'Game is full']);
            return;
        }

        // Add player to game
        $game['players'][] = $clientId;
        
        // Move player to game namespace and room
        $this->moveClientToNamespace($clientId, '/game');
        $this->joinRoom($clientId, $gameId, '/game');
        
        // Notify all players in the game
        $this->broadcastToRoomClients('player.joined', [
            'playerId' => $clientId,
            'playerCount' => count($game['players']),
            'maxPlayers' => $game['maxPlayers']
        ], $gameId, '/game');
        
        // If game is now full, start it
        if (count($game['players']) >= $game['maxPlayers']) {
            $game['status'] = 'playing';
            $this->broadcastToRoomClients('game.started', [
                'gameId' => $gameId,
                'players' => $game['players']
            ], $gameId, '/game');
        }
    }

    #[OnDisconnect]
    public function onDisconnect(int $clientId): void
    {
        // Clean up games when host disconnects
        foreach ($this->games as $gameId => $game) {
            if ($game['host'] === $clientId) {
                // Notify players
                $this->broadcastToRoomClients('game.ended', [
                    'reason' => 'Host disconnected'
                ], $gameId, '/game');
                
                // Remove game
                unset($this->games[$gameId]);
            } elseif (in_array($clientId, $game['players'])) {
                // Remove player from game
                $this->games[$gameId]['players'] = array_filter(
                    $game['players'], 
                    fn($id) => $id !== $clientId
                );
                
                // Notify remaining players
                $this->broadcastToRoomClients('player.left', [
                    'playerId' => $clientId,
                    'playerCount' => count($this->games[$gameId]['players'])
                ], $gameId, '/game');
            }
        }
    }
}
```

### Room Information and Management

```php
class RoomManagerController extends SocketController
{
    #[HttpRoute('GET', '/api/rooms')]
    public function listRooms(Request $request): Response
    {
        $namespace = $request->getQuery('namespace', '/');
        $rooms = $this->getServer()->getNamespaceManager()->getRoomsInNamespace($namespace);
        
        return Response::json([
            'namespace' => $namespace,
            'rooms' => $rooms
        ]);
    }

    #[HttpRoute('GET', '/api/rooms/{room}/clients')]
    public function getRoomClients(Request $request): Response
    {
        $room = $request->getParam('room');
        $namespace = $request->getQuery('namespace', '/');
        
        $clients = $this->getServer()->getNamespaceManager()->getClientsInRoom($room, $namespace);
        
        return Response::json([
            'room' => $room,
            'namespace' => $namespace,
            'clients' => $clients,
            'count' => count($clients)
        ]);
    }

    #[SocketOn('room.list')]
    public function listAvailableRooms(int $clientId, array $data): void
    {
        $namespace = $data['namespace'] ?? '/';
        $rooms = $this->getServer()->getNamespaceManager()->getRoomsInNamespace($namespace);
        
        $roomList = [];
        foreach ($rooms as $room => $clients) {
            $roomList[] = [
                'name' => $room,
                'clientCount' => count($clients),
                'clients' => array_values($clients)
            ];
        }
        
        $this->emit($clientId, 'room.list', [
            'namespace' => $namespace,
            'rooms' => $roomList
        ]);
    }
}
```

## Real-World Examples

### Multi-Tenant Chat Application

```php
class MultiTenantChatController extends SocketController
{
    #[OnConnect]
    public function onConnect(int $clientId): void
    {
        // Clients start in default namespace
        $this->emit($clientId, 'connected', [
            'clientId' => $clientId,
            'message' => 'Please select a tenant to join'
        ]);
    }

    #[SocketOn('tenant.join')]
    public function joinTenant(int $clientId, array $data): void
    {
        $tenantId = $data['tenantId'] ?? null;
        $userId = $data['userId'] ?? null;
        
        if (!$tenantId || !$userId) {
            $this->emit($clientId, 'error', ['message' => 'Tenant ID and User ID required']);
            return;
        }

        // Create tenant-specific namespace
        $namespace = "/tenant_{$tenantId}";
        
        // Join tenant namespace
        $this->moveClientToNamespace($clientId, $namespace);
        
        // Join general room in tenant
        $this->joinRoom($clientId, 'general', $namespace);
        
        // Store user info
        $this->setClientData($clientId, 'userId', $userId);
        $this->setClientData($clientId, 'tenantId', $tenantId);
        
        // Notify tenant about new user
        $this->broadcastToNamespaceClients('user.joined', [
            'userId' => $userId,
            'clientId' => $clientId,
            'tenantId' => $tenantId
        ], $namespace);
        
        $this->emit($clientId, 'tenant.joined', [
            'tenantId' => $tenantId,
            'namespace' => $namespace
        ]);
    }

    #[SocketOn('chat.message')]
    public function sendMessage(int $clientId, array $data): void
    {
        $userId = $this->getClientData($clientId, 'userId');
        $tenantId = $this->getClientData($clientId, 'tenantId');
        
        if (!$tenantId) {
            $this->emit($clientId, 'error', ['message' => 'Not connected to any tenant']);
            return;
        }

        $message = $data['message'] ?? '';
        $room = $data['room'] ?? 'general';
        $namespace = "/tenant_{$tenantId}";
        
        // Broadcast to tenant room
        $this->broadcastToRoomClients('chat.message', [
            'userId' => $userId,
            'message' => $message,
            'room' => $room,
            'timestamp' => time()
        ], $room, $namespace);
    }
}
```

### Real-Time Collaboration

```php
class CollaborationController extends SocketController
{
    #[SocketOn('document.join')]
    public function joinDocument(int $clientId, array $data): void
    {
        $documentId = $data['documentId'] ?? null;
        $userId = $data['userId'] ?? null;
        
        if (!$documentId || !$userId) {
            $this->emit($clientId, 'error', ['message' => 'Document ID and User ID required']);
            return;
        }

        // Join collaboration namespace
        $namespace = '/collaboration';
        $this->moveClientToNamespace($clientId, $namespace);
        
        // Join document-specific room
        $room = "doc_{$documentId}";
        $this->joinRoom($clientId, $room, $namespace);
        
        // Store user info
        $this->setClientData($clientId, 'userId', $userId);
        $this->setClientData($clientId, 'documentId', $documentId);
        
        // Notify other collaborators
        $this->broadcastToRoomClients('user.joined.document', [
            'userId' => $userId,
            'documentId' => $documentId,
            'clientId' => $clientId
        ], $room, $namespace);
        
        $this->emit($clientId, 'document.joined', [
            'documentId' => $documentId,
            'room' => $room
        ]);
    }

    #[SocketOn('document.edit')]
    public function editDocument(int $clientId, array $data): void
    {
        $userId = $this->getClientData($clientId, 'userId');
        $documentId = $this->getClientData($clientId, 'documentId');
        
        if (!$documentId) {
            $this->emit($clientId, 'error', ['message' => 'Not connected to any document']);
            return;
        }

        $namespace = '/collaboration';
        $room = "doc_{$documentId}";
        
        // Broadcast edit to all collaborators except sender
        $this->broadcastToRoomClients('document.edit', [
            'userId' => $userId,
            'documentId' => $documentId,
            'operation' => $data['operation'] ?? null,
            'position' => $data['position'] ?? null,
            'content' => $data['content'] ?? null,
            'timestamp' => time()
        ], $room, $namespace);
    }

    #[SocketOn('cursor.position')]
    public function updateCursorPosition(int $clientId, array $data): void
    {
        $userId = $this->getClientData($clientId, 'userId');
        $documentId = $this->getClientData($clientId, 'documentId');
        
        if (!$documentId) {
            return;
        }

        $namespace = '/collaboration';
        $room = "doc_{$documentId}";
        
        // Broadcast cursor position to other collaborators
        $this->broadcastToRoomClients('cursor.position', [
            'userId' => $userId,
            'position' => $data['position'] ?? null,
            'selection' => $data['selection'] ?? null
        ], $room, $namespace);
    }
}
```

## Best Practices

### 1. Namespace Organization

```php
// Good - clear separation by feature
'/chat'        // Chat functionality
'/game'        // Game functionality  
'/admin'       // Admin panel
'/api'         // API connections

// Bad - unclear or too nested
'/app/chat/general'  // Too nested
'/stuff'             // Unclear purpose
```

### 2. Room Naming

```php
// Good - descriptive and consistent
'general'           // General chat room
'room_123'         // Specific room with ID
'game_456'         // Game session
'private_1_2'      // Private room between users 1 and 2

// Bad - unclear or inconsistent  
'r123'             // Unclear abbreviation
'TheAwesomeRoom'   // Inconsistent casing
```

### 3. Automatic Cleanup

Always clean up when clients disconnect:

```php
#[OnDisconnect]
public function onDisconnect(int $clientId): void
{
    // Sockeon automatically removes clients from namespaces and rooms
    // But you should handle application-specific cleanup
    
    $this->cleanupClientData($clientId);
    $this->notifyClientLeft($clientId);
}
```

### 4. Error Handling

Handle invalid namespace/room operations:

```php
#[SocketOn('room.join')]
public function joinRoom(int $clientId, array $data): void
{
    $room = $data['room'] ?? null;
    
    if (!$room || !$this->isValidRoomName($room)) {
        $this->emit($clientId, 'error', ['message' => 'Invalid room name']);
        return;
    }
    
    if (!$this->canUserJoinRoom($clientId, $room)) {
        $this->emit($clientId, 'error', ['message' => 'Access denied']);
        return;
    }
    
    $this->joinRoom($clientId, $room);
}
```

## Next Steps

- [WebSocket Events](websocket/events.md) - Advanced event handling
- [Broadcasting](websocket/broadcasting.md) - Targeted message broadcasting
- [Examples](examples/) - See namespaces and rooms in real applications
