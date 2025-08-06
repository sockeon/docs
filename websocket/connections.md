---
title: "WebSocket Connection Management - Sockeon Documentation"
description: "Learn how to manage WebSocket connections, client data, and connection lifecycle in Sockeon framework"
og_image: "https://sockeon.com/assets/logo.png"
twitter_image: "https://sockeon.com/assets/logo.png"
---

# Connection Management

Learn how to manage WebSocket connections in Sockeon.

## Connection Lifecycle

### Connection Events

Sockeon provides connection events that you can hook into:

```php
use Sockeon\Sockeon\WebSocket\Attributes\OnConnect;
use Sockeon\Sockeon\WebSocket\Attributes\OnDisconnect;

class ConnectionController extends SocketController
{
    #[OnConnect]
    public function onConnect(int $clientId): void
    {
        // Welcome the new client
        $this->emit($clientId, 'welcome', [
            'message' => 'Welcome to the server!',
            'clientId' => $clientId
        ]);
        
        // Notify other clients
        $this->broadcast('user.connected', [
            'clientId' => $clientId,
            'timestamp' => time()
        ]);
    }

    #[OnDisconnect]
    public function onDisconnect(int $clientId): void
    {
        // Notify other clients
        $this->broadcast('user.disconnected', [
            'clientId' => $clientId,
            'timestamp' => time()
        ]);
    }
}
```

## Client Information

### Getting Client Information

```php
class ClientInfoController extends SocketController
{
    #[SocketOn('client.info')]
    public function getClientInfo(int $clientId, array $data): void
    {
        $clientInfo = [
            'id' => $clientId,
            'type' => $this->getClientType($clientId),
            'connected' => $this->isClientConnected($clientId)
        ];
        
        $this->emit($clientId, 'client.info', $clientInfo);
    }
    
    #[SocketOn('server.stats')]
    public function getServerStats(int $clientId, array $data): void
    {
        $stats = [
            'total_clients' => $this->getClientCount(),
            'client_ids' => array_keys($this->getAllClients())
        ];
        
        $this->emit($clientId, 'server.stats', $stats);
    }
}
```

## Client Data Storage

### Storing Client Data

```php
class ClientDataController extends SocketController
{
    #[OnConnect]
    public function onConnect(int $clientId): void
    {
        // Store initial client data
        $this->setClientData($clientId, 'connected_at', time());
        $this->setClientData($clientId, 'status', 'online');
    }

    #[SocketOn('user.update')]
    public function updateUser(int $clientId, array $data): void
    {
        $name = $data['name'] ?? '';
        $email = $data['email'] ?? '';
        
        // Store user data
        $this->setClientData($clientId, 'name', $name);
        $this->setClientData($clientId, 'email', $email);
        
        $this->emit($clientId, 'user.updated', [
            'name' => $name,
            'email' => $email
        ]);
    }

    #[SocketOn('user.info')]
    public function getUserInfo(int $clientId, array $data): void
    {
        $name = $this->getClientData($clientId, 'name');
        $email = $this->getClientData($clientId, 'email');
        $connectedAt = $this->getClientData($clientId, 'connected_at');
        
        $this->emit($clientId, 'user.info', [
            'name' => $name,
            'email' => $email,
            'connected_at' => $connectedAt
        ]);
    }
}
```

## Namespace Management

### Moving Clients Between Namespaces

```php
class NamespaceController extends SocketController
{
    #[SocketOn('namespace.join')]
    public function joinNamespace(int $clientId, array $data): void
    {
        $namespace = $data['namespace'] ?? '';
        
        if (empty($namespace)) {
            $this->emit($clientId, 'error', ['message' => 'Namespace is required']);
            return;
        }
        
        // Move client to namespace
        $this->moveClientToNamespace($clientId, $namespace);
        
        $this->emit($clientId, 'namespace.joined', [
            'namespace' => $namespace
        ]);
    }

    #[SocketOn('namespace.leave')]
    public function leaveNamespace(int $clientId, array $data): void
    {
        // Move client to default namespace
        $this->moveClientToNamespace($clientId, '/');
        
        $this->emit($clientId, 'namespace.left', [
            'message' => 'Left namespace'
        ]);
    }
}
```

## Room Management

### Joining and Leaving Rooms

```php
class RoomController extends SocketController
{
    #[SocketOn('room.join')]
    public function joinRoom(int $clientId, array $data): void
    {
        $room = $data['room'] ?? '';
        
        if (empty($room)) {
            $this->emit($clientId, 'error', ['message' => 'Room is required']);
            return;
        }
        
        // Join room
        $this->joinRoom($clientId, $room);
        
        $this->emit($clientId, 'room.joined', [
            'room' => $room
        ]);
        
        // Notify others in the room
        $this->broadcastToRoomClients('room.user_joined', [
            'clientId' => $clientId,
            'room' => $room
        ], $room);
    }

    #[SocketOn('room.leave')]
    public function leaveRoom(int $clientId, array $data): void
    {
        $room = $data['room'] ?? '';
        
        if (empty($room)) {
            $this->emit($clientId, 'error', ['message' => 'Room is required']);
            return;
        }
        
        // Leave room
        $this->leaveRoom($clientId, $room);
        
        $this->emit($clientId, 'room.left', [
            'room' => $room
        ]);
        
        // Notify others in the room
        $this->broadcastToRoomClients('room.user_left', [
            'clientId' => $clientId,
            'room' => $room
        ], $room);
    }
}
```
