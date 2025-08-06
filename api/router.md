---
title: "Router API - Sockeon Documentation"
description: "Complete API reference for Sockeon Router class with route registration and dispatching methods"
og_image: "https://sockeon.com/assets/logo.png"
twitter_image: "https://sockeon.com/assets/logo.png"
---

# Router API Reference

The Router class manages event routing for both WebSocket events and HTTP requests in Sockeon. It handles attribute-based routing and middleware execution.

## Class: `Sockeon\Sockeon\Core\Router`

### Constructor

```php
public function __construct(Server $server)
```

Creates a new Router instance.

**Parameters:**
- `$server` (`Server`): The server instance

---

## Controller Registration

### register()

```php
public function register(SocketController $controller): void
```

Registers a controller and scans it for route attributes.

**Parameters:**
- `$controller` (`SocketController`): The controller instance to register

**Example:**
```php
$router = new Router($server);
$router->register(new ChatController());
$router->register(new GameController());
```

**Process:**
1. Sets the server instance on the controller
2. Uses reflection to scan all public methods
3. Registers methods with routing attributes (`#[SocketOn]`, `#[HttpRoute]`, `#[OnConnect]`, `#[OnDisconnect]`)
4. Stores middleware configuration for each route

---

## WebSocket Event Routing

### dispatch()

```php
public function dispatch(int $clientId, string $event, array $data): void
```

Routes a WebSocket event to the appropriate handler method.

**Parameters:**
- `$clientId` (`int`): The client ID that sent the event
- `$event` (`string`): The event name
- `$data` (`array<string, mixed>`): The event data

**Example:**
```php
// This is called internally by the server
$router->dispatch(123, 'chat.message', [
    'message' => 'Hello world!'
]);
```

**Process:**
1. Checks if a handler exists for the event
2. Executes event-specific middleware
3. Calls the handler method with client ID and data
4. Handles any exceptions and sends error responses

---

## HTTP Request Routing

### dispatchHttp()

```php
public function dispatchHttp(Request $request): mixed
```

Routes an HTTP request to the appropriate handler method.

**Parameters:**
- `$request` (`Request`): The request object

**Returns:** `mixed` - The HTTP response

**Example:**
```php
// This is called internally by the server
$response = $router->dispatchHttp($request);
```

**Process:**
1. Matches the method and path against registered routes
2. Extracts path parameters (e.g., `{id}` from `/users/{id}`)
3. Executes HTTP-specific middleware
4. Calls the handler method with the request
5. Returns the response or a 404 if no route matches

---

## Connection Event Routing

### routeConnect()

```php
public function routeConnect(int $clientId): void
```

Routes client connection events to registered connect handlers.

**Parameters:**
- `$clientId` (`int`): The newly connected client ID

**Example:**
```php
// Called when a client connects
$router->routeConnect(123);
```

### routeDisconnect()

```php
public function routeDisconnect(int $clientId): void
```

Routes client disconnection events to registered disconnect handlers.

**Parameters:**
- `$clientId` (`int`): The disconnected client ID

**Example:**
```php
// Called when a client disconnects
$router->routeDisconnect(123);
```

---

## Middleware Management

### addGlobalMiddleware()

```php
public function addGlobalMiddleware(string $middlewareClass): void
```

Adds a middleware class that will be executed for all routes.

**Parameters:**
- `$middlewareClass` (`string`): The fully qualified middleware class name

**Example:**
```php
$router->addGlobalMiddleware(AuthenticationMiddleware::class);
$router->addGlobalMiddleware(LoggingMiddleware::class);
```

### setGlobalMiddlewares()

```php
public function setGlobalMiddlewares(array $middlewares): void
```

Sets the complete list of global middleware classes.

**Parameters:**
- `$middlewares` (`array<string>`): Array of middleware class names

**Example:**
```php
$router->setGlobalMiddlewares([
    AuthenticationMiddleware::class,
    LoggingMiddleware::class
    // Note: Rate limiting is handled automatically via #[RateLimit] attribute
]);
```

---

## Route Information

### getWebSocketRoutes()

```php
public function getWebSocketRoutes(): array
```

Returns all registered WebSocket event routes.

**Returns:** `array<string, array>` - Associative array of event names to route info

**Example:**
```php
$routes = $router->getWebSocketRoutes();
/*
Returns:
[
    'chat.message' => [
        'controller' => ChatController::class,
        'method' => 'handleMessage',
        'middlewares' => [],
        'excludeGlobalMiddlewares' => []
    ],
    'user.login' => [
        'controller' => AuthController::class,
        'method' => 'handleLogin',
        'middlewares' => [],
        'excludeGlobalMiddlewares' => [AuthMiddleware::class]
    ]
]
*/
```

### getHttpRoutes()

```php
public function getHttpRoutes(): array
```

Returns all registered HTTP routes.

**Returns:** `array<string, array>` - Associative array of route patterns to route info

**Example:**
```php
$routes = $router->getHttpRoutes();
/*
Returns:
[
    'GET /api/users' => [
        'pattern' => '/api/users',
        'method' => 'GET',
        'controller' => UserController::class,
        'handler' => 'listUsers',
        'middlewares' => [AuthMiddleware::class],
        'excludeGlobalMiddlewares' => []
    ],
    'POST /api/users' => [
        'pattern' => '/api/users',
        'method' => 'POST',
        'controller' => UserController::class,
        'handler' => 'createUser',
        'middlewares' => [AuthMiddleware::class, ValidationMiddleware::class],
        'excludeGlobalMiddlewares' => []
    ]
]
*/
```

### getConnectHandlers()

```php
public function getConnectHandlers(): array
```

Returns all registered connection handlers.

**Returns:** `array<array>` - Array of connect handler info

**Example:**
```php
$handlers = $router->getConnectHandlers();
/*
Returns:
[
    [
        'controller' => ChatController::class,
        'method' => 'onConnect',
        'middlewares' => [],
        'excludeGlobalMiddlewares' => []
    ]
]
*/
```

### getDisconnectHandlers()

```php
public function getDisconnectHandlers(): array
```

Returns all registered disconnection handlers.

**Returns:** `array<array>` - Array of disconnect handler info

---

## Path Parameter Extraction

The router automatically extracts path parameters from HTTP routes and adds them to the request.

### Parameter Syntax

Use curly braces to define parameters in route paths:

```php
#[HttpRoute('GET', '/api/users/{id}')]
public function getUser(Request $request): Response
{
    $userId = $request->getParam('id');
    return Response::json(['user' => ['id' => $userId]]);
}

#[HttpRoute('GET', '/api/users/{userId}/posts/{postId}')]
public function getUserPost(Request $request): Response
{
    $userId = $request->getParam('userId');
    $postId = $request->getParam('postId');
    
    return Response::json([
        'user' => $userId,
        'post' => $postId
    ]);
}
```

### Matching Process

1. Route patterns are converted to regular expressions
2. Parameters are captured as named groups
3. Captured values are added to the request object
4. Parameters are available via `$request->getParam()`

---

## Middleware Execution

### WebSocket Middleware

Middleware for WebSocket events is executed in this order:

1. **Global middleware** (unless excluded)
2. **Route-specific middleware** (from `#[SocketOn]` attribute)

```php
class ChatController extends SocketController 
{
    #[SocketOn('private.message', middlewares: [AuthMiddleware::class, PrivacyMiddleware::class])]
    public function handlePrivateMessage(int $clientId, array $data): void
    {
        // Executed after global + auth + privacy middleware
    }

    #[SocketOn('public.message', excludeGlobalMiddlewares: [AuthMiddleware::class])]
    public function handlePublicMessage(int $clientId, array $data): void
    {
        // Executed after global middleware except auth
    }
}
```

### HTTP Middleware

Middleware for HTTP requests follows the same pattern:

```php
class ApiController extends SocketController 
{
    #[HttpRoute('POST', '/api/admin/users', middlewares: [AdminMiddleware::class])]
    public function createAdminUser(Request $request): Response
    {
        // Executed after global + admin middleware
    }

    #[HttpRoute('GET', '/api/public/status', excludeGlobalMiddlewares: [AuthMiddleware::class])]
    public function getPublicStatus(Request $request): Response
    {
        // Public endpoint - no auth required
    }
}
```

---

## Error Handling

### WebSocket Error Responses

When a WebSocket handler throws an exception, the router automatically sends an error event:

```php
// If this throws an exception:
#[SocketOn('risky.operation')]
public function riskyOperation(int $clientId, array $data): void
{
    throw new Exception('Something went wrong');
}

// The client receives:
{
    "event": "error",
    "data": {
        "message": "Something went wrong",
        "code": 500
    }
}
```

### HTTP Error Responses

For HTTP routes, exceptions are converted to appropriate HTTP responses:

```php
// If this throws an exception:
#[HttpRoute('GET', '/api/risky')]
public function riskyEndpoint(Request $request): Response
{
    throw new Exception('Server error');
}

// Returns HTTP 500 with JSON error response
```

---

## Complete Router Setup Example

```php
<?php

use Sockeon\Sockeon\Core\Router;
use Sockeon\Sockeon\Connection\Server;

// Create server and router
$server = new Server();
$router = new Router($server);

// Add global middleware
$router->setGlobalMiddlewares([
    LoggingMiddleware::class,
    AuthenticationMiddleware::class
    // Note: Rate limiting is handled automatically via #[RateLimit] attribute
]);

// Register controllers
$router->register(new ChatController());
$router->register(new UserController());
$router->register(new AdminController());
$router->register(new GameController());

// The router is now ready to handle events and requests
// The server will automatically use it for routing

// Start the server
$server->listen('0.0.0.0', 8080);
```

---

## Advanced Routing Patterns

### Nested Route Groups

While not directly supported, you can simulate route groups using consistent prefixes:

```php
class ApiController extends SocketController
{
    // User management routes
    #[HttpRoute('GET', '/api/v1/users')]
    public function listUsers(Request $request): Response { /* ... */ }

    #[HttpRoute('POST', '/api/v1/users')]
    public function createUser(Request $request): Response { /* ... */ }

    #[HttpRoute('GET', '/api/v1/users/{id}')]
    public function getUser(Request $request): Response { /* ... */ }

    // Admin routes with additional middleware
    #[HttpRoute('GET', '/api/v1/admin/users', middlewares: [AdminMiddleware::class])]
    public function adminListUsers(Request $request): Response { /* ... */ }

    #[HttpRoute('DELETE', '/api/v1/admin/users/{id}', middlewares: [AdminMiddleware::class])]
    public function adminDeleteUser(Request $request): Response { /* ... */ }
}
```

### Event Namespacing

Organize WebSocket events using dot notation:

```php
class ChatController extends SocketController
{
    // Room events
    #[SocketOn('room.join')]
    public function joinRoom(int $clientId, array $data): void { /* ... */ }

    #[SocketOn('room.leave')]
    public function leaveRoom(int $clientId, array $data): void { /* ... */ }

    #[SocketOn('room.message')]
    public function roomMessage(int $clientId, array $data): void { /* ... */ }

    // User events
    #[SocketOn('user.typing')]
    public function userTyping(int $clientId, array $data): void { /* ... */ }

    #[SocketOn('user.status')]
    public function userStatus(int $clientId, array $data): void { /* ... */ }

    // Admin events
    #[SocketOn('admin.kick', middlewares: [AdminMiddleware::class])]
    public function adminKick(int $clientId, array $data): void { /* ... */ }

    #[SocketOn('admin.broadcast', middlewares: [AdminMiddleware::class])]
    public function adminBroadcast(int $clientId, array $data): void { /* ... */ }
}
```

---

## Performance Considerations

1. **Route Caching**: Routes are cached in memory after initial scanning
2. **Middleware Efficiency**: Keep middleware lightweight for better performance
3. **Controller Organization**: Group related functionality in single controllers
4. **Error Handling**: Use specific exceptions for better error reporting

---

## See Also

- [Controller API](api/controller.md) - Controller base class methods
- [Middleware Guide](core/middleware.md) - Creating custom middleware
- [Routing Guide](core/routing.md) - Advanced routing patterns
- [Server API](api/server.md) - Server configuration and methods
