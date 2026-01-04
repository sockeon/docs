---
title: "Sockeon Documentation v1.0"
description: "Learn how to set up Sockeon in your PHP project and create a dual-protocol server that handles both WebSockets and HTTP requests. Build real-time applications with unified WebSocket and HTTP endpoints."
og_image: "https://sockeon.com/assets/logo.png"
twitter_image: "https://sockeon.com/assets/logo.png"
---

# Getting Started with Sockeon

This comprehensive guide will help you set up Sockeon in your PHP project and create a dual-protocol server that handles both WebSockets and HTTP requests. Learn how to build real-time applications with WebSockets while simultaneously serving HTTP content and RESTful APIs from the same codebase.

## System Requirements

- PHP 8.1 or higher
- Composer dependency manager
- ext-sockets PHP extension enabled

## Installation

Install Sockeon using Composer:

```bash
composer require sockeon/sockeon
```

## Basic Usage

### 1. Creating a Server Instance

```php
use Sockeon\Sockeon\Core\Server;

// Initialize server on localhost:8000
$server = new Server(
    host: "0.0.0.0", 
    port: 8000,
    debug: false,
    corsConfig: [
        'allowed_origins' => ['*'],
        'allowed_methods' => ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
        'allowed_headers' => ['Content-Type', 'X-Requested-With', 'Authorization'],
        'allow_credentials' => false,
        'max_age' => 86400
    ],
    logger: new \Sockeon\Sockeon\Logging\Logger(
        minLogLevel: \Sockeon\Sockeon\Logging\LogLevel::INFO,
        logToConsole: true,
        logToFile: true,
        logDirectory: __DIR__ . '/logs'
    )
);

// Start the server
$server->run();
```

### 2. Create a Controller

```php
use Sockeon\Sockeon\Core\Contracts\SocketController;
use Sockeon\Sockeon\WebSocket\Attributes\SocketOn;
use Sockeon\Sockeon\Http\Attributes\HttpRoute;
use Sockeon\Sockeon\Http\Request;
use Sockeon\Sockeon\Http\Response;

class ChatController extends SocketController
{
    #[SocketOn('message.send')]
    public function onMessage(int $clientId, array $data)
    {
        // Handle incoming message
        $this->broadcast('message.receive', [
            'from' => $clientId,
            'message' => $data['message']
        ]);
    }

    #[HttpRoute('GET', '/status')]
    public function getStatus(Request $request)
    {
        return Response::json([
            'status' => 'online',
            'time' => date('Y-m-d H:i:s')
        ]);
    }
}
```

### 3. Register the Controller

```php
$server->registerController(new ChatController());
```

### 4. Add Middleware (Optional)

```php
// Add WebSocket middleware
$server->addWebSocketMiddleware(function ($clientId, $event, $data, $next) {
    echo "WebSocket Event: $event from client $clientId\n";
    return $next();
});

// Add HTTP middleware
$server->addHttpMiddleware(function (Request $request, $next) {
    echo "HTTP Request: {$request->getMethod()} {$request->getPath()}\n";
    return $next();
});
```

## WebSocket Client Example

```javascript
const socket = new WebSocket('ws://localhost:8000');

socket.onopen = () => {
    console.log('Connected to server');
    
    // Send a message
    socket.send(JSON.stringify({
        event: 'message.send',
        data: {
            message: 'Hello, World!'
        }
    }));
};

socket.onmessage = (event) => {
    const data = JSON.parse(event.data);
    console.log('Received:', data);
};
```

## Cross-Origin Resource Sharing (CORS)

Sockeon provides built-in support for CORS, allowing you to control which origins can connect to your server:

```php
// Configure CORS when creating the server
$server = new Server(
    host: "0.0.0.0",
    port: 8000,
    debug: false,
    corsConfig: [
        'allowed_origins' => ['https://example.com', 'https://app.example.com'],
        'allowed_methods' => ['GET', 'POST', 'PUT', 'DELETE'],
        'allowed_headers' => ['Content-Type', 'Authorization'],
        'allow_credentials' => true,
        'max_age' => 86400
    ]
);
```

For WebSocket connections, the origin header is validated against the allowed origins list. For HTTP requests, appropriate CORS headers are automatically added to responses.

## Logging

Sockeon provides a flexible logging system that follows PSR-3 standards:

```php
// Import the necessary classes
use Sockeon\Sockeon\Core\Server;
use Sockeon\Sockeon\Logging\Logger;
use Sockeon\Sockeon\Logging\LogLevel;

// Create a server with custom logger
$server = new Server(
    host: "0.0.0.0",
    port: 8000,
    debug: false,
    corsConfig: [],
    logger: new Logger(
        minLogLevel: LogLevel::INFO,        // Only log INFO and higher
        logToConsole: true,                 // Output to console
        logToFile: true,                    // Write to file
        logDirectory: __DIR__ . '/logs',    // Store logs here
        separateLogFiles: false             // Single log file
    )
);

// Using the logger in your application
$server->getLogger()->info("Server starting on port 8000");
$server->getLogger()->error("Database connection failed", ['host' => 'db.example.com']);

// Log an exception with context data
try {
    // Some code that might throw an exception
} catch (\Exception $e) {
    $server->getLogger()->exception($e, [
        'requestId' => $requestId,
        'user' => $userId
    ]);
}
```

### Environment-Specific Logging

For development environments, enable detailed logging:

```php
$logger = new Logger(
    minLogLevel: LogLevel::DEBUG,    // Capture all log levels
    logToConsole: true,              // Show logs in console for immediate feedback
    logToFile: true,                 // Also write to file
    logDirectory: __DIR__ . '/logs', 
    separateLogFiles: false          // Single combined file for easier review
);
```

For production environments, configure more focused logging:

```php
$logger = new Logger(
    minLogLevel: LogLevel::WARNING,  // Only capture significant issues
    logToConsole: false,             // Don't output to console for performance
    logToFile: true,                 // Write all logs to file
    logDirectory: '/var/log/sockeon',
    separateLogFiles: true           // Separate files for easier filtering
);
```

## Using Rooms

```php
#[SocketOn('room.join')]
public function onJoinRoom(int $clientId, array $data)
{
    $room = $data['room'] ?? null;
    if ($room) {
        $this->joinRoom($clientId, $room);
        $this->emit($clientId, 'room.joined', [
            'room' => $room
        ]);
    }
}

#[SocketOn('message.room')]
public function onRoomMessage(int $clientId, array $data)
{
    $room = $data['room'] ?? null;
    if ($room) {
        $this->broadcast('message.receive', [
            'from' => $clientId,
            'message' => $data['message']
        ], '/', $room);
    }
}
```

## Special Events

Sockeon provides special attributes to handle connection lifecycle events automatically:

```php
use Sockeon\Sockeon\WebSocket\Attributes\OnConnect;
use Sockeon\Sockeon\WebSocket\Attributes\OnDisconnect;

class ChatController extends SocketController
{
    #[OnConnect]
    public function onClientConnect(int $clientId): void
    {
        // Called automatically when a client connects
        $this->emit($clientId, 'welcome', [
            'message' => 'Welcome to the chat!',
            'clientId' => $clientId
        ]);
        
        $this->server->getLogger()->info("Client connected", [
            'clientId' => $clientId
        ]);
    }

    #[OnDisconnect]  
    public function onClientDisconnect(int $clientId): void
    {
        // Called automatically when a client disconnects
        $this->broadcast('user.left', [
            'clientId' => $clientId,
            'message' => "Client {$clientId} has left"
        ]);
        
        $this->server->getLogger()->info("Client disconnected", [
            'clientId' => $clientId  
        ]);
    }
}
```

These special events are triggered automatically by the server - you don't need to emit them manually. They're perfect for initialization, cleanup, and notification tasks.