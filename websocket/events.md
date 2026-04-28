---
title: "WebSocket Events - Sockeon Documentation"
description: "Learn how to handle WebSocket events and create real-time applications with Sockeon framework"
og_image: "https://sockeon.com/logo.png"
twitter_image: "https://sockeon.com/logo.png"
---

# WebSocket Events

Learn how to handle WebSocket events in Sockeon using attribute-based event handlers.

## Event System Overview

WebSocket events in Sockeon follow a simple pattern:

1. **Client sends event** → JSON message with `event` and `data` fields
2. **Server routes event** → Based on `#[SocketOn]` attributes
3. **Controller handles event** → Your business logic
4. **Server responds** → Emit back to client or broadcast to others

## Basic Event Handling

### Defining Event Handlers

Use the `#[SocketOn]` attribute to define event handlers:

```php
use Sockeon\Sockeon\Controllers\SocketController;
use Sockeon\Sockeon\WebSocket\Attributes\SocketOn;

class ChatController extends SocketController
{
    #[SocketOn('chat.message')]
    public function handleMessage(string $clientId, array $data): void
    {
        $message = $data['message'] ?? '';
        
        if (empty($message)) {
            $this->emit($clientId, 'error', ['message' => 'Message cannot be empty']);
            return;
        }

        // Broadcast to all connected clients
        $this->broadcast('chat.message', [
            'from' => $clientId,
            'message' => $message,
            'timestamp' => time()
        ]);
    }

    #[SocketOn('user.typing')]
    public function handleTyping(string $clientId, array $data): void
    {
        $isTyping = $data['typing'] ?? false;
        
        // Broadcast typing status to others
        $this->broadcast('user.typing', [
            'clientId' => $clientId,
            'typing' => $isTyping
        ]);
    }
}
```

### Connection Events

Handle special connection events:

```php
use Sockeon\Sockeon\WebSocket\Attributes\OnConnect;
use Sockeon\Sockeon\WebSocket\Attributes\OnDisconnect;

class ConnectionController extends SocketController
{
    #[OnConnect]
    public function onConnect(string $clientId): void
    {
        // Called automatically when a client connects
        $this->emit($clientId, 'welcome', [
            'message' => 'Welcome to the server!',
            'clientId' => $clientId
        ]);

        // Notify others about the new connection
        $this->broadcast('user.connected', [
            'clientId' => $clientId,
            'message' => "User {$clientId} joined the server"
        ]);
    }

    #[OnDisconnect]
    public function onDisconnect(string $clientId): void
    {
        // Called automatically when a client disconnects
        $this->broadcast('user.disconnected', [
            'clientId' => $clientId,
            'message' => "User {$clientId} left the server"
        ]);
    }
}
```

## Event Naming Conventions

Use hierarchical naming with dots for organization:

```php
class GameController extends SocketController
{
    #[SocketOn('game.join')]
    public function joinGame(string $clientId, array $data): void
    {
        $gameId = $data['gameId'] ?? '';
        $this->moveClientToNamespace($clientId, "/game/{$gameId}");
        
        $this->emit($clientId, 'game.joined', ['gameId' => $gameId]);
    }

    #[SocketOn('game.move')]
    public function handleMove(string $clientId, array $data): void
    {
        $move = $data['move'] ?? '';
        $this->broadcast('game.move', [
            'clientId' => $clientId,
            'move' => $move
        ]);
    }

    #[SocketOn('game.chat')]
    public function handleGameChat(string $clientId, array $data): void
    {
        $message = $data['message'] ?? '';
        $this->broadcast('game.chat', [
            'clientId' => $clientId,
            'message' => $message
        ]);
    }
}
```

## Event Data Handling

```php
class DataController extends SocketController
{
    #[SocketOn('user.update')]
    public function updateUser(string $clientId, array $data): void
    {
        $name = $data['name'] ?? '';
        $email = $data['email'] ?? '';
        
        // Validate data
        if (empty($name) || empty($email)) {
            $this->emit($clientId, 'error', ['message' => 'Name and email are required']);
            return;
        }
        
        // Update user data
        $this->setClientData($clientId, 'name', $name);
        $this->setClientData($clientId, 'email', $email);
        
        $this->emit($clientId, 'user.updated', [
            'name' => $name,
            'email' => $email
        ]);
    }

    #[SocketOn('user.info')]
    public function getUserInfo(string $clientId, array $data): void
    {
        $name = $this->getClientData($clientId, 'name');
        $email = $this->getClientData($clientId, 'email');
        
        $this->emit($clientId, 'user.info', [
            'name' => $name,
            'email' => $email
        ]);
    }
}
```

## Custom Event Classes

For cross-process or non-controller broadcasting, use `Sockeon\Sockeon\Core\Event` with a custom class implementing `EventableContract`.

```php
<?php

use Sockeon\Sockeon\Contracts\WebSocket\EventableContract;

final class OrderStatusUpdated implements EventableContract
{
    public function __construct(
        private readonly string $orderId,
        private readonly string $status,
    ) {
    }

    public function broadcastAs(): string
    {
        return 'orders.status.updated';
    }

    public function broadcastWith(): array
    {
        return [
            'orderId' => $this->orderId,
            'status' => $this->status,
            'updatedAt' => time(),
        ];
    }

    public function broadcastOn(): ?array
    {
        // Event will be broadcast to each room in this list
        return ['ops', 'admin'];
    }

    public function broadcastNamespace(): ?string
    {
        return '/orders';
    }
}
```

Broadcast the event from anywhere in your app:

```php
use Sockeon\Sockeon\Core\Event;

Event::broadcast(new OrderStatusUpdated('ord_123', 'shipped'));
```

### How it works

- `Event::broadcast()` writes a broadcast payload to Sockeon's queue file.
- The running server consumes that queue and dispatches to clients.
- `broadcastOn()` should return one or more room names; if it returns `null` or an empty array, nothing is broadcast.
- `broadcastNamespace()` defaults to `/` when `null`.
