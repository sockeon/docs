# PHP WebSocket Examples & Tutorials

This document provides comprehensive code examples and tutorials demonstrating how to implement WebSockets in PHP for various real-world use cases. Each example is designed to showcase specific features and capabilities of socket programming with practical implementation steps.

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
    
    #[SocketOn('connect')]
    public function onConnect(int $clientId, array $data)
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
