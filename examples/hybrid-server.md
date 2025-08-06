---
title: "Hybrid Server Example - Sockeon Documentation"
description: "Complete example of a hybrid WebSocket and HTTP server using Sockeon framework"
og_image: "https://sockeon.com/assets/logo.png"
twitter_image: "https://sockeon.com/assets/logo.png"
---

# Hybrid Server Example

A server that handles both WebSocket and HTTP requests simultaneously.

## Server Code

```php
<?php

require_once __DIR__ . '/../vendor/autoload.php';

use Sockeon\Sockeon\Config\ServerConfig;
use Sockeon\Sockeon\Connection\Server;
use Sockeon\Sockeon\Controllers\SocketController;
use Sockeon\Sockeon\WebSocket\Attributes\OnConnect;
use Sockeon\Sockeon\WebSocket\Attributes\OnDisconnect;
use Sockeon\Sockeon\WebSocket\Attributes\SocketOn;
use Sockeon\Sockeon\Http\Attributes\HttpRoute;
use Sockeon\Sockeon\Http\Request;
use Sockeon\Sockeon\Http\Response;

// Hybrid Controller - handles both WebSocket and HTTP
class HybridController extends SocketController
{
    // WebSocket Events
    #[OnConnect]
    public function onConnect(int $clientId): void
    {
        echo "WebSocket client {$clientId} connected\n";
        
        $this->emit($clientId, 'welcome', [
            'message' => 'Welcome to the hybrid server!',
            'clientId' => $clientId
        ]);
    }

    #[OnDisconnect]
    public function onDisconnect(int $clientId): void
    {
        echo "WebSocket client {$clientId} disconnected\n";
    }

    #[SocketOn('chat.message')]
    public function handleChatMessage(int $clientId, array $data): void
    {
        $message = $data['message'] ?? '';
        
        if (empty($message)) {
            $this->emit($clientId, 'error', ['message' => 'Message cannot be empty']);
            return;
        }

        $this->broadcast('chat.message', [
            'from' => $clientId,
            'message' => $message,
            'timestamp' => time()
        ]);
    }

    #[SocketOn('notification.send')]
    public function sendNotification(int $clientId, array $data): void
    {
        $message = $data['message'] ?? '';
        $type = $data['type'] ?? 'info';
        
        $this->broadcast('notification', [
            'message' => $message,
            'type' => $type,
            'from' => $clientId,
            'timestamp' => time()
        ]);
    }

    // HTTP Routes
    #[HttpRoute('GET', '/api/status')]
    public function getStatus(Request $request): Response
    {
        return Response::json([
            'status' => 'online',
            'websocket_clients' => $this->getClientCount(),
            'timestamp' => time()
        ]);
    }

    #[HttpRoute('POST', '/api/broadcast')]
    public function broadcastMessage(Request $request): Response
    {
        $data = $request->all();
        $message = $data['message'] ?? '';
        $type = $data['type'] ?? 'info';
        
        if (empty($message)) {
            return Response::json([
                'error' => 'Message is required'
            ], 400);
        }
        
        // Broadcast to all WebSocket clients
        $this->broadcast('notification', [
            'message' => $message,
            'type' => $type,
            'from' => 'http-api',
            'timestamp' => time()
        ]);
        
        return Response::json([
            'message' => 'Broadcast sent successfully',
            'recipients' => $this->getClientCount()
        ]);
    }

    #[HttpRoute('GET', '/api/clients')]
    public function getClients(Request $request): Response
    {
        $clients = array_keys($this->getAllClients());
        
        return Response::json([
            'clients' => $clients,
            'count' => count($clients)
        ]);
    }

    #[HttpRoute('POST', '/api/message/{clientId}')]
    public function sendToClient(Request $request): Response
    {
        $clientId = (int)$request->getParam('clientId');
        $data = $request->all();
        $message = $data['message'] ?? '';
        
        if (empty($message)) {
            return Response::json([
                'error' => 'Message is required'
            ], 400);
        }
        
        if (!$this->isClientConnected($clientId)) {
            return Response::json([
                'error' => 'Client not connected'
            ], 404);
        }
        
        // Send message to specific client
        $this->emit($clientId, 'private.message', [
            'message' => $message,
            'from' => 'http-api',
            'timestamp' => time()
        ]);
        
        return Response::json([
            'message' => 'Message sent successfully',
            'clientId' => $clientId
        ]);
    }
}

// Create server configuration
$config = new ServerConfig();
$config->host = '0.0.0.0';
$config->port = 8080;
$config->debug = true;

// Configure CORS for HTTP
$config->cors = [
    'allowed_origins' => ['*'],
    'allowed_methods' => ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    'allowed_headers' => ['Content-Type', 'Authorization'],
    'allow_credentials' => true
];

// Create server
$server = new Server($config);

// Register controller
$server->registerController(new HybridController());

echo "Starting hybrid server on:\n";
echo "  WebSocket: ws://localhost:8080\n";
echo "  HTTP: http://localhost:8080\n";
echo "\nAvailable HTTP endpoints:\n";
echo "  GET  /api/status\n";
echo "  POST /api/broadcast\n";
echo "  GET  /api/clients\n";
echo "  POST /api/message/{clientId}\n";
echo "\nWebSocket events:\n";
echo "  chat.message\n";
echo "  notification.send\n";
echo "\nPress Ctrl+C to stop\n";

// Start server
$server->run();
```

## How to Run

1. Save the code as `hybrid-server.php`
2. Run the server:
   ```bash
   php hybrid-server.php
   ```

## Features

### WebSocket Features
- **Connection Management**: Track client connections
- **Chat Messages**: Broadcast chat messages to all clients
- **Notifications**: Send notifications to all clients
- **Private Messages**: Send messages to specific clients

### HTTP API Features
- **Server Status**: Get server and client information
- **Broadcast Messages**: Send messages to all WebSocket clients via HTTP
- **Client List**: Get list of connected WebSocket clients
- **Direct Messages**: Send messages to specific WebSocket clients

## Usage Examples

### WebSocket Client
```javascript
const ws = new WebSocket('ws://localhost:8080');

ws.onmessage = function(event) {
    const data = JSON.parse(event.data);
    console.log('Received:', data);
};

// Send chat message
ws.send(JSON.stringify({
    event: 'chat.message',
    data: { message: 'Hello from browser!' }
}));

// Send notification
ws.send(JSON.stringify({
    event: 'notification.send',
    data: { message: 'Important update!', type: 'warning' }
}));
```

### HTTP API Calls
```bash
# Get server status
curl http://localhost:8080/api/status

# Broadcast message to all WebSocket clients
curl -X POST http://localhost:8080/api/broadcast \
  -H "Content-Type: application/json" \
  -d '{"message":"Server maintenance in 5 minutes","type":"warning"}'

# Get connected clients
curl http://localhost:8080/api/clients

# Send message to specific client
curl -X POST http://localhost:8080/api/message/1 \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello client 1!"}'
```

## Use Cases

- **Real-time Dashboard**: HTTP API for data, WebSocket for live updates
- **Chat Application**: WebSocket for chat, HTTP for user management
- **Notification System**: HTTP for sending notifications, WebSocket for delivery
- **Monitoring**: HTTP for status checks, WebSocket for real-time metrics 