---
title: "Routing - Sockeon Documentation"
description: "Learn how to use attribute-based routing in Sockeon framework for HTTP routes and WebSocket events"
og_image: "https://sockeon.com/assets/logo.png"
twitter_image: "https://sockeon.com/assets/logo.png"
---

# Routing

Sockeon's routing system uses PHP 8 attributes to provide clean, declarative routing for both WebSocket events and HTTP requests. This guide covers all routing features and advanced patterns.

## Attribute-Based Routing

Sockeon uses attributes instead of traditional route configuration files, making your routes self-documenting and co-located with your handler code.

### WebSocket Event Routing

```php
use Sockeon\Sockeon\WebSocket\Attributes\SocketOn;
use Sockeon\Sockeon\WebSocket\Attributes\OnConnect;
use Sockeon\Sockeon\WebSocket\Attributes\OnDisconnect;

class ChatController extends SocketController
{
    #[OnConnect]
    public function handleConnection(int $clientId): void
    {
        // Automatically called when client connects
    }

    #[OnDisconnect] 
    public function handleDisconnection(int $clientId): void
    {
        // Automatically called when client disconnects
    }

    #[SocketOn('chat.message')]
    public function handleMessage(int $clientId, array $data): void
    {
        // Called when client sends 'chat.message' event
    }

    #[SocketOn('user.typing')]
    public function handleTyping(int $clientId, array $data): void
    {
        // Called when client sends 'user.typing' event
    }
}
```

### HTTP Route Routing

```php
use Sockeon\Sockeon\Http\Attributes\HttpRoute;

class ApiController extends SocketController
{
    #[HttpRoute('GET', '/api/users')]
    public function listUsers(Request $request): Response
    {
        // Handle GET /api/users
    }

    #[HttpRoute('POST', '/api/users')]
    public function createUser(Request $request): Response
    {
        // Handle POST /api/users
    }

    #[HttpRoute('PUT', '/api/users/{id}')]
    public function updateUser(Request $request): Response
    {
        // Handle PUT /api/users/123
    }

    #[HttpRoute('DELETE', '/api/users/{id}')]
    public function deleteUser(Request $request): Response
    {
        // Handle DELETE /api/users/123
    }
}
```

## HTTP Routing Features

### HTTP Methods

Sockeon supports all standard HTTP methods:

```php
#[HttpRoute('GET', '/path')]       // Read operations
#[HttpRoute('POST', '/path')]      // Create operations
#[HttpRoute('PUT', '/path')]       // Update operations (full)
#[HttpRoute('PATCH', '/path')]     // Update operations (partial)
#[HttpRoute('DELETE', '/path')]    // Delete operations
#[HttpRoute('HEAD', '/path')]      // Metadata only
#[HttpRoute('OPTIONS', '/path')]   // CORS preflight
```

### Path Parameters

Extract dynamic segments from URLs using curly braces:

```php
#[HttpRoute('GET', '/users/{id}')]
public function getUser(Request $request): Response
{
    $userId = $request->getParam('id');
    // $userId contains the value from the URL
}

#[HttpRoute('GET', '/users/{userId}/posts/{postId}')]
public function getUserPost(Request $request): Response
{
    $userId = $request->getParam('userId');
    $postId = $request->getParam('postId');
    // Multiple parameters
}

#[HttpRoute('GET', '/categories/{category}/items/{id}')]
public function getCategoryItem(Request $request): Response
{
    $category = $request->getParam('category');
    $itemId = $request->getParam('id');
    // Named parameters for clarity
}
```

### Query Parameters

Access URL query parameters:

```php
#[HttpRoute('GET', '/search')]
public function search(Request $request): Response
{
    // URL: /search?q=hello&type=post&limit=10
    $query = $request->getQuery('q');           // 'hello'
    $type = $request->getQuery('type');         // 'post'
    $limit = $request->getQuery('limit', 20);   // 10 (with default)
    $sort = $request->getQuery('sort', 'date'); // 'date' (default used)
}
```

### Complex Route Patterns

```php
class RestController extends SocketController
{
    // Basic CRUD operations
    #[HttpRoute('GET', '/api/posts')]
    public function listPosts(Request $request): Response
    {
        $page = (int)$request->getQuery('page', 1);
        $limit = (int)$request->getQuery('limit', 10);
        // Pagination logic
    }

    #[HttpRoute('GET', '/api/posts/{id}')]
    public function getPost(Request $request): Response
    {
        $id = $request->getParam('id');
        // Get single post
    }

    #[HttpRoute('POST', '/api/posts')]
    public function createPost(Request $request): Response
    {
        $data = $request->all();
        // Create new post
    }

    #[HttpRoute('PUT', '/api/posts/{id}')]
    public function updatePost(Request $request): Response
    {
        $id = $request->getParam('id');
        $data = $request->all();
        // Update existing post
    }

    // Nested resources
    #[HttpRoute('GET', '/api/users/{userId}/posts')]
    public function getUserPosts(Request $request): Response
    {
        $userId = $request->getParam('userId');
        // Get posts for specific user
    }

    #[HttpRoute('POST', '/api/users/{userId}/posts')]
    public function createUserPost(Request $request): Response
    {
        $userId = $request->getParam('userId');
        $data = $request->all();
        // Create post for specific user
    }

    // Complex paths with multiple parameters
    #[HttpRoute('GET', '/api/organizations/{orgId}/projects/{projectId}/tasks')]
    public function getProjectTasks(Request $request): Response
    {
        $orgId = $request->getParam('orgId');
        $projectId = $request->getParam('projectId');
        // Get tasks for specific project in organization
    }
}
```

## WebSocket Event Routing

### Event Naming Conventions

Use dot notation for hierarchical event names:

```php
class EventController extends SocketController
{
    // User events
    #[SocketOn('user.login')]
    #[SocketOn('user.logout')]
    #[SocketOn('user.profile.update')]

    // Chat events
    #[SocketOn('chat.message.send')]
    #[SocketOn('chat.message.edit')]
    #[SocketOn('chat.message.delete')]
    #[SocketOn('chat.room.join')]
    #[SocketOn('chat.room.leave')]

    // Game events
    #[SocketOn('game.start')]
    #[SocketOn('game.move')]
    #[SocketOn('game.end')]
    #[SocketOn('game.player.ready')]

    // System events
    #[SocketOn('system.ping')]
    #[SocketOn('system.status')]
}
```

### Event Data Handling

WebSocket events receive data as arrays:

```php
#[SocketOn('chat.message')]
public function handleChatMessage(int $clientId, array $data): void
{
    // Extract data with defaults
    $message = $data['message'] ?? '';
    $room = $data['room'] ?? 'general';
    $type = $data['type'] ?? 'text';

    // Validate required fields
    if (empty($message)) {
        $this->emit($clientId, 'error', [
            'code' => 'INVALID_MESSAGE',
            'message' => 'Message cannot be empty'
        ]);
        return;
    }

    // Process the event
    $this->broadcastToRoomClients('chat.message', [
        'id' => uniqid(),
        'from' => $clientId,
        'message' => $message,
        'type' => $type,
        'timestamp' => time()
    ], $room);
}

#[SocketOn('game.move')]
public function handleGameMove(int $clientId, array $data): void
{
    // Structured data handling
    $gameData = [
        'gameId' => $data['gameId'] ?? null,
        'move' => [
            'from' => $data['move']['from'] ?? null,
            'to' => $data['move']['to'] ?? null,
            'piece' => $data['move']['piece'] ?? null
        ],
        'timestamp' => $data['timestamp'] ?? time()
    ];

    // Validate game move
    if (!$this->isValidMove($gameData)) {
        $this->emit($clientId, 'game.move.invalid', [
            'reason' => 'Invalid move'
        ]);
        return;
    }

    // Broadcast move to game room
    $this->broadcastToRoomClients('game.move', $gameData, $gameData['gameId']);
}
```

## Router Configuration

### Route Registration

Routes are automatically registered when you register controllers:

```php
$server = new Server($config);

// All routes in these controllers are automatically registered
$server->registerController(new ChatController());
$server->registerController(new ApiController());
$server->registerController(new GameController());

$server->run();
```

### Accessing Router Information

Get information about registered routes:

```php
$router = $server->getRouter();

// Get all HTTP routes
$httpRoutes = $router->getHttpRoutes();
foreach ($httpRoutes as $route => $handler) {
    echo "HTTP Route: {$route}\n";
}

// Get all WebSocket routes
$wsRoutes = $router->getWebSocketRoutes();
foreach ($wsRoutes as $event => $handler) {
    echo "WebSocket Event: {$event}\n";
}
```

## Route Middleware

Apply middleware to specific routes using the middleware parameter:

### HTTP Route Middleware

```php
use App\Middleware\AuthMiddleware;
use App\Middleware\AdminMiddleware;
use Sockeon\Sockeon\Core\Attributes\RateLimit;

class SecureApiController extends SocketController
{
    #[HttpRoute('GET', '/api/public')]
    public function publicEndpoint(Request $request): Response
    {
        // No middleware - public access
        return Response::json(['message' => 'Public data']);
    }

    #[HttpRoute('GET', '/api/protected', middlewares: [AuthMiddleware::class])]
    public function protectedEndpoint(Request $request): Response
    {
        // Requires authentication
        $user = $request->getAttribute('user');
        return Response::json(['message' => 'Protected data', 'user' => $user]);
    }

    #[HttpRoute('GET', '/api/admin', middlewares: [AuthMiddleware::class, AdminMiddleware::class])]
    public function adminEndpoint(Request $request): Response
    {
        // Requires authentication and admin role
        $user = $request->getAttribute('user');
        return Response::json(['message' => 'Admin data', 'user' => $user]);
    }

    #[HttpRoute('POST', '/api/upload')]
    #[RateLimit(maxCount: 5, timeWindow: 300)] // 5 uploads per 5 minutes
    public function uploadFile(Request $request): Response
    {
        // Rate limiting handled automatically by #[RateLimit] attribute
        return Response::json(['message' => 'File uploaded']);
    }
}
```

### WebSocket Event Middleware

```php
use App\Middleware\WebSocketAuthMiddleware;
use App\Middleware\ChatModerationMiddleware;

class ChatController extends SocketController
{
    #[SocketOn('chat.message', middlewares: [WebSocketAuthMiddleware::class, ChatModerationMiddleware::class])]
    public function handleMessage(int $clientId, array $data): void
    {
        // Requires authentication and moderation checks
    }

    #[SocketOn('admin.command', middlewares: [WebSocketAuthMiddleware::class, AdminMiddleware::class])]
    public function handleAdminCommand(int $clientId, array $data): void
    {
        // Admin-only commands
    }
}
```

### Excluding Global Middleware

Exclude specific global middleware from routes:

```php
// Health check endpoint - no rate limiting needed
#[HttpRoute('GET', '/api/health')]
public function healthCheck(Request $request): Response
{
    return Response::json(['status' => 'healthy']);
}

// Exclude global auth middleware for public WebSocket events
#[SocketOn('public.announcement', excludeGlobalMiddlewares: [WebSocketAuthMiddleware::class])]
public function handlePublicAnnouncement(int $clientId, array $data): void
{
    // Public event - no auth required
}
```

## Advanced Routing Patterns

### API Versioning

```php
class ApiV1Controller extends SocketController
{
    #[HttpRoute('GET', '/api/v1/users')]
    public function listUsersV1(Request $request): Response
    {
        // Version 1 implementation
    }

    #[HttpRoute('GET', '/api/v1/posts/{id}')]
    public function getPostV1(Request $request): Response
    {
        // Version 1 implementation
    }
}

class ApiV2Controller extends SocketController
{
    #[HttpRoute('GET', '/api/v2/users')]
    public function listUsersV2(Request $request): Response
    {
        // Version 2 implementation with new features
    }

    #[HttpRoute('GET', '/api/v2/posts/{id}')]
    public function getPostV2(Request $request): Response
    {
        // Version 2 implementation with new response format
    }
}
```

### Content Type Routing

Handle different content types:

```php
class MediaController extends SocketController
{
    #[HttpRoute('POST', '/api/media/upload')]
    public function uploadMedia(Request $request): Response
    {
        $contentType = $request->getHeader('Content-Type');
        
        if (str_starts_with($contentType, 'image/')) {
            return $this->handleImageUpload($request);
        } elseif (str_starts_with($contentType, 'video/')) {
            return $this->handleVideoUpload($request);
        } elseif ($contentType === 'application/json') {
            return $this->handleJsonUpload($request);
        }
        
        return Response::json(['error' => 'Unsupported content type'], 415);
    }
}
```

### Conditional Routing

Route based on conditions:

```php
class ConditionalController extends SocketController
{
    #[HttpRoute('GET', '/api/data')]
    public function getData(Request $request): Response
    {
        $format = $request->getQuery('format', 'json');
        
        switch ($format) {
            case 'json':
                return $this->getDataAsJson($request);
            case 'xml':
                return $this->getDataAsXml($request);
            case 'csv':
                return $this->getDataAsCsv($request);
            default:
                return Response::json(['error' => 'Unsupported format'], 400);
        }
    }

    #[SocketOn('data.request')]
    public function handleDataRequest(int $clientId, array $data): void
    {
        $type = $data['type'] ?? 'default';
        
        match ($type) {
            'realtime' => $this->handleRealtimeData($clientId, $data),
            'historical' => $this->handleHistoricalData($clientId, $data),
            'aggregated' => $this->handleAggregatedData($clientId, $data),
            default => $this->emit($clientId, 'error', ['message' => 'Unknown data type'])
        };
    }
}
```

## Route Organization

### Grouping Related Routes

Organize routes by feature in dedicated controllers:

```php
// User management
class UserController extends SocketController
{
    #[HttpRoute('GET', '/api/users')]
    #[HttpRoute('POST', '/api/users')]
    #[HttpRoute('GET', '/api/users/{id}')]
    #[HttpRoute('PUT', '/api/users/{id}')]
    #[HttpRoute('DELETE', '/api/users/{id}')]
    
    #[SocketOn('user.profile.update')]
    #[SocketOn('user.status.change')]
    // ... user-related methods
}

// Chat functionality
class ChatController extends SocketController
{
    #[HttpRoute('GET', '/api/chat/rooms')]
    #[HttpRoute('POST', '/api/chat/rooms')]
    #[HttpRoute('GET', '/api/chat/rooms/{id}/messages')]
    
    #[SocketOn('chat.message')]
    #[SocketOn('chat.join')]
    #[SocketOn('chat.leave')]
    // ... chat-related methods
}
```

### Route Listing and Documentation

Create a route listing endpoint for documentation:

```php
class DocsController extends SocketController
{
    #[HttpRoute('GET', '/api/routes')]
    public function listRoutes(Request $request): Response
    {
        $router = $this->getServer()->getRouter();
        
        $routes = [
            'http' => [],
            'websocket' => []
        ];
        
        foreach ($router->getHttpRoutes() as $route => $handler) {
            $routes['http'][] = [
                'route' => $route,
                'controller' => get_class($handler[0]),
                'method' => $handler[1]
            ];
        }
        
        foreach ($router->getWebSocketRoutes() as $event => $handler) {
            $routes['websocket'][] = [
                'event' => $event,
                'controller' => get_class($handler[0]),
                'method' => $handler[1]
            ];
        }
        
        return Response::json($routes);
    }
}
```

## Best Practices

1. **Use Descriptive Route Names**: Make URLs and event names self-documenting
2. **Follow REST Conventions**: Use appropriate HTTP methods for their intended purposes
3. **Group Related Functionality**: Organize routes in dedicated controllers
4. **Use Middleware Wisely**: Apply security and validation at the route level
5. **Validate Parameters**: Always validate path and query parameters
6. **Handle Errors Gracefully**: Return appropriate HTTP status codes and error messages
7. **Document Your Routes**: Use PHPDoc comments for complex routes
8. **Use Consistent Naming**: Follow consistent patterns for URLs and events

## Next Steps

- [Middleware](core/middleware.md) - Learn about request/response processing
- [HTTP Features](http/routing.md) - Advanced HTTP routing features
- [WebSocket Events](websocket/events.md) - Deep dive into WebSocket event handling
- [Rate Limiting](advanced/rate-limiting.md) - Protect your routes from abuse
