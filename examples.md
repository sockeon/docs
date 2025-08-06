---
title: "Examples - Sockeon Documentation v1.0"
description: "Comprehensive code examples and tutorials for implementing WebSocket and HTTP endpoints in PHP. Learn to build real-time features with WebSockets alongside RESTful APIs in unified applications."
og_image: "https://sockeon.com/assets/logo.png"
twitter_image: "https://sockeon.com/assets/logo.png"
---

# WebSocket & HTTP Examples

This document provides comprehensive code examples and tutorials demonstrating how to implement both WebSockets and HTTP endpoints in PHP applications. Learn how to build real-time features with WebSockets alongside RESTful APIs and web content served through HTTP - all from a single unified server.

## Basic WebSocket and HTTP Example

The basic example demonstrates handling both WebSocket events and HTTP requests in a single controller:

```php
<?php

use Sockeon\Sockeon\Core\Server;
use Sockeon\Sockeon\Core\Contracts\SocketController;
use Sockeon\Sockeon\WebSocket\Attributes\SocketOn;
use Sockeon\Sockeon\Http\Attributes\HttpRoute;
use Sockeon\Sockeon\Http\Request;
use Sockeon\Sockeon\Http\Response;

class AppController extends SocketController
{
    #[SocketOn('message.send')]
    public function onMessageSend(int $clientId, array $data)
    {
        $this->broadcast('message.receive', [
            'from' => $this->server->getClientData($clientId, 'user')['name'],
            'message' => $data['message']
        ]);
    }

    #[SocketOn('room.join')]
    public function onRoomJoin(int $clientId, array $data)
    {
        $room = $data['room'] ?? null;
        if ($room) {
            $this->joinRoom($clientId, $room);
            $this->emit($clientId, 'room.joined', [
                'room' => $room
            ]);
        }
    }

    #[HttpRoute('GET', '/api/status')]
    public function getStatus(Request $request): Response
    {
        return Response::json([
            'status' => 'online',
            'time' => date('Y-m-d H:i:s')
        ]);
    }
}

$server = new Server("0.0.0.0", 8000, true);

// Add middleware for user data
$server->addWebSocketMiddleware(function ($clientId, $event, $data, $next) use ($server) {
    $server->setClientData($clientId, 'user', [
        'name' => 'User ' . $clientId,
        'id' => $clientId,
    ]);
    return $next();
});

$server->registerController(new AppController());
$server->run();
```

### Client Code

```html
<!DOCTYPE html>
<html>
<head>
    <title>Sockeon Chat</title>
    <style>
        .message-list {
            height: 400px;
            overflow-y: auto;
            border: 1px solid #ccc;
            padding: 10px;
            margin-bottom: 10px;
        }
    </style>
</head>
<body>
    <div class="message-list" id="messages"></div>
    <input type="text" id="messageInput" placeholder="Type your message...">
    <button onclick="sendMessage()">Send</button>
    
    <div>
        <input type="text" id="roomInput" placeholder="Room name">
        <button onclick="joinRoom()">Join Room</button>
    </div>

    <script>
        const socket = new WebSocket('ws://localhost:8000');
        const messages = document.getElementById('messages');
        const messageInput = document.getElementById('messageInput');
        const roomInput = document.getElementById('roomInput');
        let currentRoom = null;

        socket.onopen = () => {
            addMessage('System', 'Connected to server');
        };

        socket.onmessage = (event) => {
            const data = JSON.parse(event.data);
            
            if (data.event === 'message.receive') {
                addMessage(data.data.from, data.data.message);
            } else if (data.event === 'room.joined') {
                currentRoom = data.data.room;
                addMessage('System', `Joined room: ${currentRoom}`);
            }
        };

        function sendMessage() {
            const message = messageInput.value;
            if (message) {
                const data = {
                    message: message
                };
                
                if (currentRoom) {
                    data.room = currentRoom;
                }
                
                socket.send(JSON.stringify({
                    event: 'message.send',
                    data: data
                }));
                
                messageInput.value = '';
            }
        }

        function joinRoom() {
            const room = roomInput.value;
            if (room) {
                socket.send(JSON.stringify({
                    event: 'room.join',
                    data: { room: room }
                }));
                roomInput.value = '';
            }
        }

        function addMessage(from, text) {
            const div = document.createElement('div');
            div.textContent = `${from}: ${text}`;
            messages.appendChild(div);
            messages.scrollTop = messages.scrollHeight;
        }
    </script>
</body>
</html>
```

## Game Server Example

```php
class GameController extends SocketController
{
    protected array $games = [];

    #[SocketOn('game.create')]
    public function onGameCreate(int $clientId, array $data)
    {
        $gameId = uniqid();
        $this->games[$gameId] = [
            'id' => $gameId,
            'players' => [$clientId],
            'state' => 'waiting'
        ];
        
        $this->joinRoom($clientId, "game-{$gameId}");
        $this->emit($clientId, 'game.created', [
            'gameId' => $gameId
        ]);
    }

    #[SocketOn('game.join')]
    public function onGameJoin(int $clientId, array $data)
    {
        $gameId = $data['gameId'] ?? null;
        if ($gameId && isset($this->games[$gameId])) {
            $this->games[$gameId]['players'][] = $clientId;
            $this->joinRoom($clientId, "game-{$gameId}");
            
            $this->broadcast('game.playerJoined', [
                'gameId' => $gameId,
                'playerId' => $clientId
            ], '/', "game-{$gameId}");
        }
    }

    #[SocketOn('game.move')]
    public function onGameMove(int $clientId, array $data)
    {
        $gameId = $data['gameId'] ?? null;
        if ($gameId && isset($this->games[$gameId])) {
            $this->broadcast('game.moveUpdate', [
                'gameId' => $gameId,
                'playerId' => $clientId,
                'move' => $data['move']
            ], '/', "game-{$gameId}");
        }
    }
}
```

## Namespace Example

The namespace example demonstrates how to use namespaces and rooms for role-based WebSocket message broadcasting:

```php
<?php
require_once __DIR__ . '/../vendor/autoload.php';

use Sockeon\Sockeon\Core\Contracts\SocketController;
use Sockeon\Sockeon\Core\Server;
use Sockeon\Sockeon\WebSocket\Attributes\SocketOn;

class TestController extends SocketController
{
    #[SocketOn('test.event')]
    public function sendMessage($clientId, $data)
    {
        if ($data['role'] == 'admin') {
            $this->joinRoom($clientId, 'test.room', '/admin');
            $this->broadcast('test.event', [
                'message' => $data['message'] ?? 'Hello from server',
                'time' => date('H:i:s')
            ], '/admin', 'test.room');
        } else {
            $this->joinRoom($clientId, 'test.room', '/user');
            $this->broadcast('test.event', [
                'message' => $data['message'] ?? 'Hello from server',
                'time' => date('H:i:s')
            ], '/user', 'test.room');
        }
    }
}

// Initialize the WebSocket server
$server = new Server(
    port: 8000,
    debug: true,
);

$server->registerController(
    controller: new TestController(),
);

$server->run();
```

In this example:
- We create role-based namespaces ('/admin' and '/user')
- Messages are broadcast only to clients in the same namespace and room
- Different groups of users can communicate in isolation

## Advanced HTTP Example

The advanced HTTP example demonstrates the enhanced Request and Response features with several endpoints showcasing different capabilities:

```php
<?php
require __DIR__ . '/../vendor/autoload.php';

use Sockeon\Sockeon\Core\Server;
use Sockeon\Sockeon\Core\Contracts\SocketController;
use Sockeon\Sockeon\Http\Attributes\HttpRoute;
use Sockeon\Sockeon\Http\Request;
use Sockeon\Sockeon\Http\Response;

class AdvancedApiController extends SocketController
{
    private array $products = [
        1 => ['id' => 1, 'name' => 'Laptop', 'price' => 999.99, 'category' => 'electronics'],
        2 => ['id' => 2, 'name' => 'Smartphone', 'price' => 699.99, 'category' => 'electronics'],
        3 => ['id' => 3, 'name' => 'Coffee Maker', 'price' => 89.99, 'category' => 'appliances'],
    ];
    
    #[HttpRoute('GET', '/')]
    public function index(Request $request): Response
    {
        // Demonstrate Request methods
        $clientInfo = [
            'ip' => $request->getIpAddress(),
            'url' => $request->getUrl(),
            'isAjax' => $request->isAjax() ? 'Yes' : 'No',
            'method' => $request->getMethod(),
            'userAgent' => $request->getHeader('User-Agent', 'Unknown')
        ];
        
        // Content negotiation based on Accept header
        if (strpos($request->getHeader('Accept', ''), 'application/json') !== false) {
            return Response::json([
                'api' => 'Sockeon HTTP API',
                'client' => $clientInfo,
                'endpoints' => [/* endpoint listing */]
            ]);
        }
        
        // Return HTML by default
        $html = "... HTML content ...";
        return (new Response($html))
            ->setContentType('text/html')
            ->setHeader('X-Demo-Mode', 'enabled');
    }
    
    #[HttpRoute('GET', '/products/{id}')]
    public function getProduct(Request $request): Response
    {
        $id = (int)$request->getParam('id');
        
        if (!isset($this->products[$id])) {
            return Response::notFound([
                'error' => 'Product not found',
                'id' => $id
            ]);
        }
        
        return Response::json($this->products[$id]);
    }
    
}
```

This example showcases:
- Path parameters: `/products/{id}`
- Content negotiation based on Accept headers
- Various response types (JSON, HTML, errors, downloads)
- Enhanced Request methods (isAjax(), getUrl(), getIpAddress())
- Enhanced Response methods (notFound(), unauthorized(), redirect(), download())

To experiment with this API, run the example and use a tool like curl or Postman to make requests to different endpoints.

## CORS Configuration Example

This example shows how to configure Cross-Origin Resource Sharing (CORS) for your Sockeon server:

```php
<?php

use Sockeon\Sockeon\Core\Server;
use Sockeon\Sockeon\Core\Contracts\SocketController;
use Sockeon\Sockeon\WebSocket\Attributes\SocketOn;
use Sockeon\Sockeon\WebSocket\Attributes\OnConnect;
use Sockeon\Sockeon\Http\Attributes\HttpRoute;
use Sockeon\Sockeon\Http\Request;
use Sockeon\Sockeon\Http\Response;

// Define CORS configuration
$corsConfig = [
    'allowed_origins' => [
        'https://app.example.com',
        'http://localhost:8080',
        'http://localhost:3000'
    ],
    'allowed_methods' => ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    'allowed_headers' => ['Content-Type', 'X-Requested-With', 'Authorization'],
    'allow_credentials' => true,
    'max_age' => 86400
];

// Initialize server with CORS configuration
$server = new Server(
    host: "0.0.0.0",
    port: 8000,
    debug: true,
    corsConfig: $corsConfig
);

class ApiController extends SocketController
{
    #[HttpRoute('GET', '/api/data')]
    public function getData(Request $request): Response
    {
        return Response::json([
            'success' => true,
            'data' => ['item1', 'item2', 'item3']
        ]);
    }
    
    #[OnConnect]
    public function onConnect(int $clientId): void
    {
        $this->emit($clientId, 'welcome', [
            'message' => 'Connected to secure server'
        ]);
    }
}

$server->registerController(new ApiController());
$server->run();
```

With this configuration:
- Only requests from the specified origins will be allowed
- WebSocket connections will be validated against allowed origins
- HTTP responses will include appropriate CORS headers
- Credentials (cookies, HTTP authentication) will be allowed
- Preflight requests will be cached for 24 hours

## Logging Example

This example shows how to configure custom logging for your Sockeon server:

```php
<?php

use Sockeon\Sockeon\Core\Server;
use Sockeon\Sockeon\Core\Contracts\SocketController;
use Sockeon\Sockeon\WebSocket\Attributes\SocketOn;
use Sockeon\Sockeon\Logging\Logger;
use Sockeon\Sockeon\Logging\LogLevel;

// Define logger configuration
$logger = new Logger(
    minLogLevel: LogLevel::DEBUG,           // Capture all log levels
    logToConsole: true,                     // Show logs in console
    logToFile: true,                        // Write logs to file
    logDirectory: __DIR__ . '/app/logs',    // Custom log directory
    separateLogFiles: true                  // Create separate files by level
);

// Initialize server with custom logger
$server = new Server(
    host: "0.0.0.0",
    port: 8000,
    debug: true,
    corsConfig: [],
    logger: $logger
);

// Example controller with logging
class GameController extends SocketController
{
    #[SocketOn('join.game')]
    public function onJoinGame(int $clientId, array $data)
    {
        $gameId = $data['gameId'] ?? null;
        $playerName = $data['playerName'] ?? 'Anonymous';
        
        // Log player joining with context data
        $this->server->getLogger()->info("Player joined game", [
            'clientId' => $clientId,
            'gameId' => $gameId,
            'playerName' => $playerName
        ]);
        
        try {
            // Game logic...
            $this->joinRoom($clientId, "game.$gameId");
            
            $this->emit($clientId, 'game.joined', [
                'success' => true,
                'gameId' => $gameId
            ]);
            
            // Log successful join
            $this->server->getLogger()->debug("Player added to game room", [
                'room' => "game.$gameId"
            ]);
        } catch (\Throwable $e) {
            // Log the exception with context
            $this->server->getLogger()->exception($e, [
                'gameId' => $gameId,
                'clientId' => $clientId
            ]);
            
            // Notify client of error
            $this->emit($clientId, 'game.error', [
                'message' => 'Failed to join game'
            ]);
        }
    }
}

$server->registerController(new GameController());
$server->run();
```

With this configuration:
- All log events from DEBUG level and above will be captured
- Logs will be displayed in the console with color coding by severity
- Each log level will be written to a separate file (debug/yyyy-mm-dd.log, info/yyyy-mm-dd.log, etc.)
- Log files will be stored in the app/logs directory
- Exception details will be automatically captured with stack traces
- Context data is included in structured format
- Exceptions are logged with file, line number, code, and stack trace
- Daily log rotation happens automatically with date-stamped filenames

### Error Handling with Logger

Here's an example of using the Logger for error handling in a Sockeon application:

```php
<?php
// error_handler.php

use Sockeon\Sockeon\Core\Server;
use Sockeon\Sockeon\Logging\Logger;
use Sockeon\Sockeon\Logging\LogLevel;

// Create a custom logger
$logger = new Logger(
    minLogLevel: LogLevel::ERROR,
    logToConsole: true,
    logToFile: true,
    logDirectory: __DIR__ . '/logs',
    separateLogFiles: false
);

// Set up global PHP error handling
set_error_handler(function($errno, $errstr, $errfile, $errline) use ($logger) {
    $errorType = match($errno) {
        E_ERROR, E_USER_ERROR => 'ERROR',
        E_WARNING, E_USER_WARNING => 'WARNING',
        E_NOTICE, E_USER_NOTICE => 'NOTICE',
        default => 'DEBUG'
    };
    
    $logger->log($errorType, $errstr, [
        'file' => $errfile,
        'line' => $errline,
        'type' => $errno
    ]);
});

// Set up global exception handling
set_exception_handler(function(\Throwable $e) use ($logger) {
    $logger->exception($e, [
        'uncaught' => true,
        'timestamp' => date('Y-m-d H:i:s')
    ]);
    
    // Graceful shutdown
    echo "An error occurred. Please check logs for details.\n";
    exit(1);
});

// Initialize server with the custom logger
$server = new Server(
    host: "0.0.0.0",
    port: 8000,
    debug: false,
    corsConfig: [],
    logger: $logger
);

// Run server in try-catch block for added safety
try {
    $server->run();
} catch (\Throwable $e) {
    $logger->exception($e, ['fatal' => true]);
    exit(1);
}
```

## Special Events Example

This example demonstrates how to use special WebSocket events (`#[OnConnect]` and `#[OnDisconnect]`) to handle client lifecycle events automatically:

```php
<?php

use Sockeon\Sockeon\Core\Server;
use Sockeon\Sockeon\Core\Contracts\SocketController;
use Sockeon\Sockeon\WebSocket\Attributes\SocketOn;
use Sockeon\Sockeon\WebSocket\Attributes\OnConnect;
use Sockeon\Sockeon\WebSocket\Attributes\OnDisconnect;

// Initialize server
$server = new Server(
    host: "0.0.0.0",
    port: 8000,
    debug: true
);

// User management controller
class UserController extends SocketController
{
    private array $users = [];
    private array $userSessions = [];

    #[OnConnect]
    public function handleUserConnect(int $clientId): void
    {
        // Initialize user session
        $this->userSessions[$clientId] = [
            'connected_at' => time(),
            'last_activity' => time(),
            'is_authenticated' => false,
            'username' => null
        ];

        // Send welcome message
        $this->emit($clientId, 'welcome', [
            'message' => 'Welcome! Please authenticate to continue.',
            'clientId' => $clientId,
            'server_time' => date('Y-m-d H:i:s'),
            'online_users' => count($this->users)
        ]);

        // Log connection
        $this->server->getLogger()->info("New client connected", [
            'clientId' => $clientId,
            'total_connections' => count($this->userSessions)
        ]);
    }

    #[OnDisconnect]
    public function handleUserDisconnect(int $clientId): void
    {
        // Get user info before cleanup
        $username = $this->userSessions[$clientId]['username'] ?? 'Anonymous';
        $sessionDuration = time() - ($this->userSessions[$clientId]['connected_at'] ?? time());

        // Remove from active users if authenticated
        if (isset($this->users[$clientId])) {
            unset($this->users[$clientId]);
            
            // Notify other users about disconnection
            $this->broadcast('user.left', [
                'username' => $username,
                'clientId' => $clientId,
                'message' => "{$username} has left the chat",
                'timestamp' => time(),
                'online_users' => count($this->users)
            ]);
        }

        // Clean up session data
        unset($this->userSessions[$clientId]);

        // Log disconnection
        $this->server->getLogger()->info("Client disconnected", [
            'clientId' => $clientId,
            'username' => $username,
            'session_duration_seconds' => $sessionDuration,
            'remaining_connections' => count($this->userSessions)
        ]);
    }

    #[SocketOn('auth.login')]
    public function handleLogin(int $clientId, array $data): void
    {
        $username = $data['username'] ?? '';
        
        if (empty($username)) {
            $this->emit($clientId, 'auth.error', [
                'message' => 'Username is required'
            ]);
            return;
        }

        // Check if username is already taken
        $existingUser = array_search($username, array_column($this->users, 'username'));
        if ($existingUser !== false) {
            $this->emit($clientId, 'auth.error', [
                'message' => 'Username already taken'
            ]);
            return;
        }

        // Register user
        $this->users[$clientId] = [
            'username' => $username,
            'joined_at' => time()
        ];

        // Update session
        $this->userSessions[$clientId]['is_authenticated'] = true;
        $this->userSessions[$clientId]['username'] = $username;

        // Add to general chat room
        $this->joinRoom($clientId, 'general');

        // Confirm authentication
        $this->emit($clientId, 'auth.success', [
            'message' => 'Successfully authenticated',
            'username' => $username,
            'room' => 'general'
        ]);

        // Notify other users
        $this->broadcast('user.joined', [
            'username' => $username,
            'message' => "{$username} has joined the chat",
            'timestamp' => time(),
            'online_users' => count($this->users)
        ], null, 'general');

        $this->server->getLogger()->info("User authenticated", [
            'clientId' => $clientId,
            'username' => $username
        ]);
    }

    #[SocketOn('chat.message')]
    public function handleChatMessage(int $clientId, array $data): void
    {
        // Check if user is authenticated
        if (!isset($this->users[$clientId])) {
            $this->emit($clientId, 'error', [
                'message' => 'Please authenticate first'
            ]);
            return;
        }

        $username = $this->users[$clientId]['username'];
        $message = $data['message'] ?? '';

        if (empty($message)) {
            $this->emit($clientId, 'error', [
                'message' => 'Message cannot be empty'
            ]);
            return;
        }

        // Update last activity
        $this->userSessions[$clientId]['last_activity'] = time();

        // Broadcast message to all users in the room
        $this->broadcast('chat.message', [
            'username' => $username,
            'message' => $message,
            'timestamp' => time(),
            'clientId' => $clientId
        ], null, 'general');

        $this->server->getLogger()->debug("Chat message sent", [
            'clientId' => $clientId,
            'username' => $username,
            'message_length' => strlen($message)
        ]);
    }

    #[SocketOn('user.list')]
    public function handleUserList(int $clientId, array $data): void
    {
        $userList = array_map(function($user) {
            return [
                'username' => $user['username'],
                'joined_at' => $user['joined_at']
            ];
        }, $this->users);

        $this->emit($clientId, 'user.list', [
            'users' => array_values($userList),
            'total' => count($userList)
        ]);
    }
}

// Monitoring controller - demonstrates multiple special event handlers
class MonitoringController extends SocketController
{
    private array $connectionStats = [];

    #[OnConnect]
    public function trackConnection(int $clientId): void
    {
        $this->connectionStats[$clientId] = [
            'connected_at' => microtime(true),
            'events_handled' => 0
        ];

        // Log to monitoring system
        $this->server->getLogger()->debug("Connection tracked", [
            'clientId' => $clientId,
            'tracking_id' => uniqid('conn_')
        ]);
    }

    #[OnDisconnect]
    public function trackDisconnection(int $clientId): void
    {
        if (isset($this->connectionStats[$clientId])) {
            $duration = microtime(true) - $this->connectionStats[$clientId]['connected_at'];
            $eventsHandled = $this->connectionStats[$clientId]['events_handled'];

            // Log connection statistics
            $this->server->getLogger()->info("Connection statistics", [
                'clientId' => $clientId,
                'duration_seconds' => round($duration, 2),
                'events_handled' => $eventsHandled,
                'events_per_second' => $eventsHandled > 0 ? round($eventsHandled / $duration, 2) : 0
            ]);

            unset($this->connectionStats[$clientId]);
        }
    }

    #[SocketOn('*')] // Handle all events for monitoring
    public function trackEvent(int $clientId, array $data): void
    {
        if (isset($this->connectionStats[$clientId])) {
            $this->connectionStats[$clientId]['events_handled']++;
        }
    }
}

// Register controllers
$server->registerController(new UserController());
$server->registerController(new MonitoringController());

// Start server
$server->run();
```

This comprehensive example demonstrates:

### Special Event Features

1. **Automatic Triggering**: `#[OnConnect]` and `#[OnDisconnect]` methods are called automatically by the server
2. **Multiple Handlers**: Both `UserController` and `MonitoringController` have special event handlers that all execute
3. **Clean Architecture**: Separation of concerns with different controllers handling different aspects
4. **Proper Cleanup**: Disconnection handlers clean up user data and notify other clients
5. **Logging Integration**: All events are properly logged with relevant context
6. **Session Management**: Track user sessions and connection statistics

### Key Differences from Regular Events

- **No Manual Emission**: You don't emit 'connect' or 'disconnect' events - they're triggered by the server
- **Parameter Signature**: Special event handlers only receive `$clientId`, not event data
- **Execution Order**: All registered special event handlers execute in registration order
- **Error Handling**: Exceptions are logged but don't prevent other handlers from executing

### Client-Side Usage

To test this example, connect with a WebSocket client and send:

```javascript
// Authenticate
ws.send(JSON.stringify({
    event: 'auth.login',
    data: { username: 'Alice' }
}));

// Send chat message
ws.send(JSON.stringify({
    event: 'chat.message',
    data: { message: 'Hello everyone!' }
}));

// Get user list
ws.send(JSON.stringify({
    event: 'user.list',
    data: {}
}));
```

The special events (`OnConnect` and `OnDisconnect`) will be triggered automatically when you connect or disconnect your WebSocket client.