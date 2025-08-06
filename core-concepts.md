---
title: "Core Concepts - Sockeon Documentation v1.0"
description: "Understand the fundamental architecture and core components of Sockeon's dual-protocol server. Learn how WebSocket and HTTP connections are managed simultaneously in PHP applications."
og_image: "https://sockeon.com/assets/logo.png"
twitter_image: "https://sockeon.com/assets/logo.png"
---

# WebSocket and HTTP Server Architecture

This document outlines the fundamental architecture and core components of the Sockeon library, providing a comprehensive understanding of how the dual-protocol server manages both WebSocket and HTTP connections simultaneously. Learn how the system handles real-time communication alongside traditional HTTP requests.

## Server Architecture

The `Server` class serves as the central component and primary entry point for your application. It implements a unified approach to handling both WebSocket and HTTP connections simultaneously on a single port, eliminating the need for separate server instances.

### Key Components

- WebSocket Handler: Manages WebSocket connections and message framing
- HTTP Handler: Processes HTTP requests and responses
- Router: Routes incoming requests to appropriate controller methods
- Namespace Manager: Manages WebSocket namespaces and rooms
- Middleware: Processes requests before they reach controllers

```php
use Sockeon\Sockeon\Core\Server;

$server = new Server(
    host: "0.0.0.0",      // Listen on all interfaces
    port: 8000,           // Port number
    debug: false,         // Enable/disable debug mode
    corsConfig: [         // CORS configuration
        'allowed_origins' => ['*'], 
        'allowed_methods' => ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
        'allowed_headers' => ['Content-Type', 'X-Requested-With', 'Authorization'],
        'allow_credentials' => false,
        'max_age' => 86400
    ]
);
```

## Controllers

Controllers handle the business logic of your application. They extend `SocketController` and use attributes to define event handlers and routes.

### WebSocket Events

Use the `#[SocketOn]` attribute to handle WebSocket events:

```php
use Sockeon\Sockeon\WebSocket\Attributes\SocketOn;

#[SocketOn('message.send')]
public function onMessage(int $clientId, array $data)
{
    // Handle the message
}
```

### Special WebSocket Events

Sockeon provides special attributes for handling connection lifecycle events automatically:

#### Connection Events

Use the `#[OnConnect]` attribute to handle when a client connects:

```php
use Sockeon\Sockeon\WebSocket\Attributes\OnConnect;

#[OnConnect]
public function handleClientConnect(int $clientId): void
{
    // This method is called automatically when a client connects
    $this->emit($clientId, 'welcome', [
        'message' => 'Welcome to the server!',
        'clientId' => $clientId,
        'timestamp' => time()
    ]);
    
    // Log the connection
    $this->server->getLogger()->info("Client connected", [
        'clientId' => $clientId
    ]);
}
```

#### Disconnection Events

Use the `#[OnDisconnect]` attribute to handle when a client disconnects:

```php
use Sockeon\Sockeon\WebSocket\Attributes\OnDisconnect;

#[OnDisconnect]
public function handleClientDisconnect(int $clientId): void
{
    // This method is called automatically when a client disconnects
    // Notify other clients about the disconnection
    $this->broadcast('user.left', [
        'clientId' => $clientId,
        'message' => "Client {$clientId} has left the server",
        'timestamp' => time()
    ]);
    
    // Clean up any client-specific data
    $this->cleanupClientData($clientId);
    
    // Log the disconnection
    $this->server->getLogger()->info("Client disconnected", [
        'clientId' => $clientId
    ]);
}
```

#### Multiple Special Event Handlers

You can have multiple controllers with special event handlers. All registered handlers will be executed when the corresponding event occurs:

```php
class AuthController extends SocketController
{
    #[OnConnect]
    public function authenticate(int $clientId): void
    {
        // Handle authentication logic
        $this->emit($clientId, 'auth.required', [
            'message' => 'Please authenticate to continue'
        ]);
    }
}

class NotificationController extends SocketController
{
    #[OnConnect]
    public function setupNotifications(int $clientId): void
    {
        // Setup notification preferences
        $this->joinRoom($clientId, 'notifications');
    }
    
    #[OnDisconnect]
    public function cleanupNotifications(int $clientId): void
    {
        // Cleanup notification subscriptions
        $this->leaveRoom($clientId, 'notifications');
    }
}
```

**Important Notes:**
- Special event handlers receive only the `$clientId` parameter, not event data
- These events are triggered automatically by the server - you don't emit them manually
- Multiple handlers for the same event type will all be executed
- Special events run through the middleware stack like regular events
- Exceptions in special event handlers are logged but don't stop other handlers from executing

### HTTP Routes

Use the `#[HttpRoute]` attribute to handle HTTP requests:

```php
use Sockeon\Sockeon\Http\Attributes\HttpRoute;

// Basic route
#[HttpRoute('GET', '/api/status')]
public function getStatus(Request $request): Response
{
    return Response::json(['status' => 'online']);
}

// Route with path parameters
#[HttpRoute('GET', '/users/{id}')]
public function getUser(Request $request): Response
{
    $userId = $request->getParam('id');
    return Response::json(['userId' => $userId]);
}

// Route with query parameters
// Access via: /search?q=term&limit=10
#[HttpRoute('GET', '/search')]
public function search(Request $request): Response
{
    $query = $request->getQuery('q', '');
    $limit = $request->getQuery('limit', 10);
    return Response::json(['results' => []]);
}
```

#### Request Object

The `Request` class encapsulates HTTP request data and provides convenient methods to access headers, query parameters, path parameters, and the request body:

```php
use Sockeon\Sockeon\Http\Request;

// Example with path parameters
#[HttpRoute('GET', '/users/{id}')]
public function getUser(Request $request)
{
    // Access path parameters from URL segments
    $userId = $request->getParam('id');
    return Response::json(['userId' => $userId]);
}

// Example with JSON body handling
#[HttpRoute('POST', '/users')]
public function createUser(Request $request)
{
    // JSON bodies are automatically decoded when Content-Type is application/json
    if ($request->isJson()) {
        $userData = $request->getBody(); // Returns decoded array
        // $userData is already decoded from JSON
    }
    
    // Access query parameters from the URL string
    $format = $request->getQuery('format', 'json');
    
    // Access headers (case-insensitive)
    $userAgent = $request->getHeader('User-Agent');
    $contentType = $request->getHeader('Content-Type');
    
    // Request type checks
    if ($request->isJson()) {
        // Handle JSON request
    }
    
    if ($request->isAjax()) {
        // Handle AJAX request
    }
    
    if ($request->isMethod('POST')) {
        // Handle specific HTTP method
    }
    
    // Get client information
    $url = $request->getUrl();
    $ip = $request->getIpAddress();
    
    return Response::json(['status' => 'created']);
}
```

#### Response Object

The `Response` class provides a structured way to create HTTP responses with status codes, headers, and body content:

```php
use Sockeon\Sockeon\Http\Response;

#[HttpRoute('GET', '/api/products')]
public function listProducts(Request $request)
{
    // Headers are managed consistently through setHeader and getHeader
    $response = new Response(['products' => []]);
    $response->setHeader('X-Custom', 'Value');
    $response->setContentType('application/json'); // Also sets Content-Type header
    
    // Common response types
    return Response::json([
        'products' => $products,
        'count' => count($products)
    ]);
    
    // Status code responses
    return Response::ok(['message' => 'Success']);      // 200 OK
    return Response::created(['id' => 123]);            // 201 Created
    return Response::noContent();                       // 204 No Content
    return Response::badRequest('Invalid input');       // 400 Bad Request
    return Response::unauthorized('Login required');    // 401 Unauthorized
    return Response::forbidden('No access');            // 403 Forbidden
    return Response::notFound('Resource not found');    // 404 Not Found
    return Response::serverError('Server error');       // 500 Server Error
    
    // Specialized responses
    return Response::redirect('/login');                // 302 Redirect
    return Response::download($data, 'report.csv');     // File download
    
    // Custom response with fluent API
    return (new Response($html))
        ->setContentType('text/html')
        ->setHeader('X-Custom', 'Value')
        ->setStatusCode(200);
}
```

## Namespaces & Rooms

Sockeon provides a powerful system of namespaces and rooms for organizing WebSocket connections.

### Namespaces

Namespaces provide a way to separate concerns in your application:

```php
// In your controller
$this->broadcast('event', $data, '/admin');  // Broadcast to admin namespace
```

### Rooms

Rooms allow grouping clients for targeted messaging:

```php
// Join a room
$this->joinRoom($clientId, 'room1');

// Leave a room
$this->leaveRoom($clientId, 'room1');

// Broadcast to a room
$this->broadcast('event', $data, '/', 'room1');
```

## Middleware

Middleware allows you to process requests before they reach your controllers.

### WebSocket Middleware

```php
$server->addWebSocketMiddleware(function ($clientId, $event, $data, $next) {
    // Authenticate client
    if (!authenticate($clientId)) {
        return false;
    }
    
    // Continue to next middleware
    return $next();
});
```

### HTTP Middleware

```php
use Sockeon\Sockeon\Http\Request;

$server->addHttpMiddleware(function (Request $request, $next) {
    // Add request timestamp using the setData method
    $request->setData('timestamp', time());
    
    // Log the request
    error_log("Request to: " . $request->getUrl());
    
    // Continue to next middleware
    return $next();
});
```

## Message Flow

1. Client connects to server
2. Server performs WebSocket handshake (for WS connections)
3. Messages go through middleware chain
4. Router dispatches to appropriate controller method
5. Controller processes the request
6. Response sent back to client

## Event System

### Client to Server

```javascript
socket.send(JSON.stringify({
    event: 'message.send',
    data: {
        message: 'Hello'
    }
}));
```

### Server to Client

```php
// Send to specific client
$this->emit($clientId, 'message.receive', $data);

// Broadcast to all clients
$this->broadcast('message.receive', $data);

// Broadcast to room
$this->broadcast('message.receive', $data, '/', 'room1');
```

## Error Handling

```php
try {
    $server->run();
} catch (\Exception $e) {
    error_log("Server error: " . $e->getMessage());
}
```

## Cross-Origin Resource Sharing (CORS)

Sockeon provides built-in support for Cross-Origin Resource Sharing (CORS), which allows controlled access to resources from different origins.

### CORS Configuration

The `CorsConfig` class provides a flexible way to configure CORS settings:

```php
$corsConfig = [
    'allowed_origins' => ['https://example.com', 'https://app.example.com'], // Use ['*'] to allow all origins
    'allowed_methods' => ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    'allowed_headers' => ['Content-Type', 'X-Requested-With', 'Authorization'],
    'allow_credentials' => true, // Whether to allow cookies and credentials
    'max_age' => 86400 // Cache preflight requests for 24 hours
];

$server = new Server("0.0.0.0", 8000, false, $corsConfig);
```

### WebSocket Origin Validation

For WebSocket connections, Sockeon validates the `Origin` header against the list of allowed origins:

```php
// Only allow connections from these origins
$corsConfig = [
    'allowed_origins' => [
        'https://example.com',
        'https://app.example.com'
    ]
];
```

### HTTP CORS Headers

For HTTP requests, Sockeon automatically adds the appropriate CORS headers to responses based on the configuration:

- `Access-Control-Allow-Origin`
- `Access-Control-Allow-Methods`
- `Access-Control-Allow-Headers`
- `Access-Control-Allow-Credentials`
- `Access-Control-Max-Age`

## Logging System

Sockeon provides a comprehensive logging system that follows PSR-3 standards. The logging system offers flexible configuration options for both development and production environments.

### Configuration

When creating a Server instance, you can configure logging behavior:

```php
use Sockeon\Sockeon\Core\Server;
use Sockeon\Sockeon\Logging\Logger;
use Sockeon\Sockeon\Logging\LogLevel;

// Create a server with custom logging configuration
$server = new Server(
    host: "0.0.0.0", 
    port: 8000,
    debug: true,
    corsConfig: [],
    logger: new Logger(
        minLogLevel: LogLevel::INFO,        // Minimum log level to record
        logToConsole: true,                 // Output logs to console
        logToFile: true,                    // Write logs to file
        logDirectory: __DIR__ . '/logs',    // Custom log directory
        separateLogFiles: true              // Separate files by log level
    )
);
```

### Log File Organization

By default, log messages are written to a daily file in the format `sockeon-YYYY-MM-DD.log`. When `separateLogFiles` is enabled, logs are additionally written to level-specific subdirectories:

```
/logs
  ├── sockeon-2025-05-31.log     # All logs combined
  ├── debug/
  │   └── 2025-05-31.log        # Debug level logs only
  ├── info/
  │   └── 2025-05-31.log        # Info level logs only
  ├── warning/
  │   └── 2025-05-31.log        # Warning level logs only
  └── error/
      └── 2025-05-31.log        # Error level logs only
```

This organization makes it easier to filter logs by severity level while maintaining a complete record in the main log file.

### Log Levels

Sockeon supports the following log levels, in order of decreasing severity:

1. **EMERGENCY**: System is unusable
2. **ALERT**: Action must be taken immediately
3. **CRITICAL**: Critical conditions
4. **ERROR**: Error conditions
5. **WARNING**: Warning conditions
6. **NOTICE**: Normal but significant events
7. **INFO**: Informational messages
8. **DEBUG**: Detailed debug information

### Context Data in Logs

Logs can include structured context data, following PSR-3 recommendations. Context data is included in log messages for both console and file output:

```php
// Log with context data
$logger->info("User logged in", [
    'userId' => 12345,
    'email' => 'user@example.com',
    'ipAddress' => '192.168.1.1',
    'timestamp' => time()
]);

// Output: [2025-05-31 14:30:45] [INFO]: User logged in 
// {userId: 12345, email: user@example.com, ipAddress: 192.168.1.1, timestamp: 1748123445}
```

### Log Message Formatting

Console logs are automatically color-coded by severity level:
- Emergency: White on Red background
- Alert: Bold Red
- Critical: Bold Red
- Error: Red
- Warning: Yellow
- Notice: Cyan
- Info: Green
- Debug: Gray

### Logging in Controllers

You can access the logger from any controller:

```php
use Sockeon\Sockeon\Core\Contracts\SocketController;
use Sockeon\Sockeon\WebSocket\Attributes\SocketOn;
use Sockeon\Sockeon\WebSocket\Attributes\OnConnect;

class ChatController extends SocketController
{
    #[SocketOn('message.send')]
    public function onMessage(int $clientId, array $data)
    {
        // Log an informational message
        $this->server->getLogger()->info(
            "Message received", 
            ['clientId' => $clientId, 'message' => $data['message'] ?? null]
        );
        
        // Process message...
    }
    
    #[OnConnect]
    public function onConnect(int $clientId): void
    {
        // Log with context data
        $this->server->getLogger()->debug(
            "Client connected", 
            ['clientId' => $clientId]
        );
    }
    
    public function processPayment($payment)
    {
        try {
            // Processing code...
        } catch (\Throwable $e) {
            // Log exceptions with context
            $this->server->getLogger()->exception($e, [
                'paymentId' => $payment->id,
                'amount' => $payment->amount
            ]);
        }
    }
}
```