---
title: "Quick Start Guide - Sockeon Documentation"
description: "Build your first Sockeon application with WebSocket and HTTP server in minutes"
og_image: "https://sockeon.com/assets/logo.png"
twitter_image: "https://sockeon.com/assets/logo.png"
---

# Quick Start

This guide will help you create your first Sockeon application in just a few minutes.

## Creating Your First Server

Let's create a simple WebSocket and HTTP server that handles chat messages and provides a REST API.

### Step 1: Create the Project Structure

```
my-sockeon-app/
├── composer.json
├── server.php
└── src/
    └── Controllers/
        └── ChatController.php
```

### Step 2: Install Sockeon

Create `composer.json`:

```json
{
    "require": {
        "sockeon/sockeon": "^2.0"
    },
    "autoload": {
        "psr-4": {
            "App\\": "src/"
        }
    }
}
```

Install dependencies:

```bash
composer install
```

### Step 3: Create a Controller

Create `src/Controllers/ChatController.php`:

```php
<?php

namespace App\Controllers;

use Sockeon\Sockeon\Controllers\SocketController;
use Sockeon\Sockeon\Http\Attributes\HttpRoute;
use Sockeon\Sockeon\Http\Request;
use Sockeon\Sockeon\Http\Response;
use Sockeon\Sockeon\WebSocket\Attributes\OnConnect;
use Sockeon\Sockeon\WebSocket\Attributes\OnDisconnect;
use Sockeon\Sockeon\WebSocket\Attributes\SocketOn;

class ChatController extends SocketController
{
    /**
     * Handle new WebSocket connections
     */
    #[OnConnect]
    public function onConnect(int $clientId): void
    {
        // Welcome the new user
        $this->emit($clientId, 'welcome', [
            'message' => 'Welcome to the chat!',
            'clientId' => $clientId
        ]);

        // Notify others about the new user
        $this->broadcast('user.joined', [
            'clientId' => $clientId,
            'message' => "User {$clientId} joined the chat"
        ]);
    }

    /**
     * Handle WebSocket disconnections
     */
    #[OnDisconnect]
    public function onDisconnect(int $clientId): void
    {
        // Notify others about user leaving
        $this->broadcast('user.left', [
            'clientId' => $clientId,
            'message' => "User {$clientId} left the chat"
        ]);
    }

    /**
     * Handle chat messages
     */
    #[SocketOn('chat.message')]
    public function handleChatMessage(int $clientId, array $data): void
    {
        // Broadcast the message to all connected clients
        $this->broadcast('chat.message', [
            'clientId' => $clientId,
            'message' => $data['message'] ?? '',
            'timestamp' => time()
        ]);
    }

    /**
     * Handle room joining
     */
    #[SocketOn('room.join')]
    public function handleRoomJoin(int $clientId, array $data): void
    {
        $room = $data['room'] ?? 'general';
        
        // Add client to room
        $this->joinRoom($clientId, $room);
        
        // Confirm room join
        $this->emit($clientId, 'room.joined', [
            'room' => $room,
            'message' => "You joined room: {$room}"
        ]);
    }

    /**
     * HTTP endpoint to get server status
     */
    #[HttpRoute('GET', '/api/status')]
    public function getStatus(Request $request): Response
    {
        return Response::json([
            'status' => 'online',
            'clients' => $this->getClientCount(),
            'timestamp' => time()
        ]);
    }

    /**
     * HTTP endpoint to get connected clients
     */
    #[HttpRoute('GET', '/api/clients')]
    public function getClients(Request $request): Response
    {
        return Response::json([
            'count' => $this->getClientCount(),
            'clients' => array_keys($this->getAllClients())
        ]);
    }

    /**
     * HTTP endpoint to send a message via REST API
     */
    #[HttpRoute('POST', '/api/broadcast')]
    public function broadcastMessage(Request $request): Response
    {
        $data = $request->all();
        
        if (!isset($data['message'])) {
            return Response::json(['error' => 'Message is required'], 400);
        }

        // Broadcast message to all WebSocket clients
        $this->broadcast('api.message', [
            'message' => $data['message'],
            'source' => 'api',
            'timestamp' => time()
        ]);

        return Response::json(['success' => true]);
    }
}
```

### Step 4: Create the Server

Create `server.php`:

```php
<?php

require_once 'vendor/autoload.php';

use App\Controllers\ChatController;
use Sockeon\Sockeon\Config\ServerConfig;
use Sockeon\Sockeon\Connection\Server;

// Create server configuration
$config = new ServerConfig();
$config->host = '0.0.0.0';
$config->port = 6001;
$config->debug = true;

// Configure CORS for HTTP requests
$config->cors = [
    'allowed_origins' => ['*'],
    'allowed_methods' => ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    'allowed_headers' => ['Content-Type', 'Authorization']
];

// Create and configure the server
$server = new Server($config);

// Register the chat controller
$server->registerController(new ChatController());

echo "Starting Sockeon server on {$config->host}:{$config->port}\n";
echo "WebSocket endpoint: ws://{$config->host}:{$config->port}\n";
echo "HTTP API: http://{$config->host}:{$config->port}/api\n";

// Start the server
$server->run();
```

### Step 5: Run the Server

Start your server:

```bash
php server.php
```

You should see:
```
Starting Sockeon server on 0.0.0.0:6001
WebSocket endpoint: ws://0.0.0.0:6001
HTTP API: http://0.0.0.0:6001/api
```

## Testing Your Server

### Test WebSocket Connection

Create a simple HTML client to test WebSocket functionality:

```html
<!DOCTYPE html>
<html>
<head>
    <title>Sockeon Chat Test</title>
</head>
<body>
    <div id="messages"></div>
    <input type="text" id="messageInput" placeholder="Type a message...">
    <button onclick="sendMessage()">Send</button>
    <button onclick="joinRoom()">Join Room</button>

    <script>
        const ws = new WebSocket('ws://localhost:6001');
        const messages = document.getElementById('messages');

        ws.onopen = function(event) {
            addMessage('Connected to server');
        };

        ws.onmessage = function(event) {
            const data = JSON.parse(event.data);
            addMessage(`[${data.event}] ${JSON.stringify(data.data)}`);
        };

        ws.onclose = function(event) {
            addMessage('Disconnected from server');
        };

        function sendMessage() {
            const input = document.getElementById('messageInput');
            const message = input.value.trim();
            
            if (message) {
                ws.send(JSON.stringify({
                    event: 'chat.message',
                    data: { message: message }
                }));
                input.value = '';
            }
        }

        function joinRoom() {
            const room = prompt('Enter room name:');
            if (room) {
                ws.send(JSON.stringify({
                    event: 'room.join',
                    data: { room: room }
                }));
            }
        }

        function addMessage(message) {
            const div = document.createElement('div');
            div.textContent = `${new Date().toLocaleTimeString()}: ${message}`;
            messages.appendChild(div);
            messages.scrollTop = messages.scrollHeight;
        }

        // Send message on Enter key
        document.getElementById('messageInput').addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                sendMessage();
            }
        });
    </script>
</body>
</html>
```

### Test HTTP API

Test the HTTP endpoints:

```bash
# Get server status
curl http://localhost:6001/api/status

# Get connected clients
curl http://localhost:6001/api/clients

# Send a broadcast message
curl -X POST http://localhost:6001/api/broadcast \
     -H "Content-Type: application/json" \
     -d '{"message": "Hello from API!"}'
```

## What's Next?

Congratulations! You've created your first Sockeon application. Here's what you can explore next:

- [Basic Concepts](getting-started/basic-concepts.md) - Understand core Sockeon concepts
- [Server Configuration](core/server-configuration.md) - Learn about advanced configuration options
- [Middleware](core/middleware.md) - Add authentication and request processing
- [Rate Limiting](advanced/rate-limiting.md) - Protect your server from abuse
- [Examples](../examples/) - See more complex examples

## Common Issues

### Port Already in Use
If you get a "port already in use" error, either:
- Change the port in your configuration
- Kill the process using the port: `lsof -ti:6001 | xargs kill`

### Permission Denied
On some systems, you may need to run with elevated privileges:
```bash
sudo php server.php
```

### Connection Refused
Make sure:
- The server is running
- Firewall allows connections on the port
- You're connecting to the correct host and port
