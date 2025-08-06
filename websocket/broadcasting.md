---
title: "WebSocket Broadcasting - Sockeon Documentation"
description: "Learn how to broadcast messages to WebSocket clients using namespaces and rooms in Sockeon framework"
og_image: "https://sockeon.com/assets/logo.png"
twitter_image: "https://sockeon.com/assets/logo.png"
---

# Broadcasting

Learn how to broadcast messages to multiple clients using Sockeon's broadcasting system.

## Types of Broadcasting

### Global Broadcasting

Send messages to all connected clients:

```php
class GlobalBroadcastController extends SocketController
{
    #[SocketOn('server.announcement')]
    public function serverAnnouncement(int $clientId, array $data): void
    {
        $message = $data['message'] ?? '';
        
        // Broadcast to all connected clients
        $this->broadcast('server.announcement', [
            'message' => $message,
            'from' => 'server',
            'timestamp' => time()
        ]);
        
        // Confirm to sender
        $this->emit($clientId, 'announcement.sent', [
            'message' => 'Announcement sent to all clients'
        ]);
    }
}
```

### Namespace Broadcasting

Send messages to all clients in a specific namespace:

```php
class NamespaceBroadcastController extends SocketController
{
    #[SocketOn('namespace.broadcast')]
    public function namespaceBroadcast(int $clientId, array $data): void
    {
        $namespace = $data['namespace'] ?? '/';
        $message = $data['message'] ?? '';
        
        // Broadcast to specific namespace
        $this->broadcastToNamespaceClients('namespace.message', [
            'message' => $message,
            'from_client' => $clientId,
            'namespace' => $namespace,
            'timestamp' => time()
        ], $namespace);
        
        $this->emit($clientId, 'broadcast.sent', [
            'namespace' => $namespace
        ]);
    }
}
```

### Room Broadcasting

Send messages to all clients in a specific room:

```php
class RoomBroadcastController extends SocketController
{
    #[SocketOn('room.message')]
    public function roomMessage(int $clientId, array $data): void
    {
        $room = $data['room'] ?? '';
        $message = $data['message'] ?? '';
        
        if (empty($room)) {
            $this->emit($clientId, 'error', ['message' => 'Room is required']);
            return;
        }
        
        // Broadcast to specific room
        $this->broadcastToRoomClients('room.message', [
            'message' => $message,
            'from_client' => $clientId,
            'room' => $room,
            'timestamp' => time()
        ], $room);
        
        $this->emit($clientId, 'message.sent', [
            'room' => $room
        ]);
    }
}
```

## Broadcasting Patterns

### Chat Application

```php
class ChatController extends SocketController
{
    #[SocketOn('chat.message')]
    public function handleMessage(int $clientId, array $data): void
    {
        $message = $data['message'] ?? '';
        $room = $data['room'] ?? 'general';
        
        if (empty($message)) {
            $this->emit($clientId, 'error', ['message' => 'Message cannot be empty']);
            return;
        }
        
        // Broadcast to room
        $this->broadcastToRoomClients('chat.message', [
            'from' => $clientId,
            'message' => $message,
            'room' => $room,
            'timestamp' => time()
        ], $room);
    }

    #[SocketOn('chat.typing')]
    public function handleTyping(int $clientId, array $data): void
    {
        $isTyping = $data['typing'] ?? false;
        $room = $data['room'] ?? 'general';
        
        // Broadcast typing status to room
        $this->broadcastToRoomClients('chat.typing', [
            'clientId' => $clientId,
            'typing' => $isTyping,
            'room' => $room
        ], $room);
    }
}
```

### Game Broadcasting

```php
class GameController extends SocketController
{
    #[SocketOn('game.move')]
    public function handleMove(int $clientId, array $data): void
    {
        $gameId = $data['gameId'] ?? '';
        $move = $data['move'] ?? '';
        
        if (empty($gameId)) {
            $this->emit($clientId, 'error', ['message' => 'Game ID is required']);
            return;
        }
        
        // Broadcast move to game room
        $this->broadcastToRoomClients('game.move', [
            'player' => $clientId,
            'move' => $move,
            'gameId' => $gameId,
            'timestamp' => time()
        ], $gameId);
    }

    #[SocketOn('game.chat')]
    public function handleGameChat(int $clientId, array $data): void
    {
        $gameId = $data['gameId'] ?? '';
        $message = $data['message'] ?? '';
        
        // Broadcast chat to game room
        $this->broadcastToRoomClients('game.chat', [
            'player' => $clientId,
            'message' => $message,
            'gameId' => $gameId,
            'timestamp' => time()
        ], $gameId);
    }
}
```

## Broadcasting Methods

### Available Methods

```php
class BroadcastingExamples extends SocketController
{
    #[SocketOn('example.broadcast')]
    public function exampleBroadcast(int $clientId, array $data): void
    {
        // Broadcast to all clients
        $this->broadcast('event.name', ['data' => 'value']);
        
        // Broadcast to specific namespace
        $this->broadcastToNamespaceClients('event.name', ['data' => 'value'], '/namespace');
        
        // Broadcast to specific room
        $this->broadcastToRoomClients('event.name', ['data' => 'value'], 'room_name');
        
        // Send to specific client
        $this->emit($clientId, 'event.name', ['data' => 'value']);
    }
}
```
