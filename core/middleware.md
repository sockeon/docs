---
title: "Middleware - Sockeon Documentation"
description: "Learn how to create and use middleware in Sockeon framework for request/response processing"
og_image: "https://sockeon.com/assets/logo.png"
twitter_image: "https://sockeon.com/assets/logo.png"
---

# Middleware

Middleware provides a clean way to filter, modify, or validate HTTP requests and WebSocket events before they reach your controller methods. Sockeon supports both HTTP middleware and WebSocket middleware with global and route-specific application.

## Understanding Middleware

Middleware acts as a pipeline between incoming requests/events and your controllers:

```
Request/Event → Middleware 1 → Middleware 2 → Controller → Response
```

Each middleware can:
- Modify the request/event data
- Perform authentication or authorization
- Log requests
- Rate limit clients
- Short-circuit the pipeline and return early
- Pass control to the next middleware

## HTTP Middleware

HTTP middleware processes HTTP requests before they reach your controller methods.

### Creating HTTP Middleware

Implement the `HttpMiddleware` interface:

```php
<?php

use Sockeon\Sockeon\Contracts\Http\HttpMiddleware;
use Sockeon\Sockeon\Connection\Server;
use Sockeon\Sockeon\Http\Request;
use Sockeon\Sockeon\Http\Response;

class AuthMiddleware implements HttpMiddleware
{
    public function handle(Request $request, callable $next, Server $server): mixed
    {
        // Check for authorization header
        $authHeader = $request->getHeader('Authorization');
        
        if (!$authHeader) {
            return Response::json(['error' => 'Authorization required'], 401);
        }

        // Validate token
        $token = str_replace('Bearer ', '', $authHeader);
        if (!$this->isValidToken($token)) {
            return Response::json(['error' => 'Invalid token'], 401);
        }

        // Add user info to request attributes
        $user = $this->getUserFromToken($token);
        $request->setAttribute('user', $user);

        // Continue to next middleware or controller
        return $next($request);
    }

    private function isValidToken(string $token): bool
    {
        // Implement your token validation logic
        return !empty($token) && strlen($token) > 10;
    }

    private function getUserFromToken(string $token): array
    {
        // Implement your user retrieval logic
        return ['id' => 1, 'name' => 'John Doe'];
    }
}

// In your controller, access user data like this:
// $user = $request->getAttribute('user');
```

### HTTP Middleware Examples

#### CORS Handling

**Note**: CORS is handled automatically by Sockeon through the `CorsConfig` class. You don't need to create custom CORS middleware.

Configure CORS in your server configuration:

```php
$config = new ServerConfig();
$config->cors = [
    'allowed_origins' => ['https://myapp.com', 'https://admin.myapp.com'],
    'allowed_methods' => ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    'allowed_headers' => ['Content-Type', 'Authorization', 'X-Requested-With'],
    'allow_credentials' => true,
    'max_age' => 86400
];
```

#### Request Validation Middleware

```php
class ValidationMiddleware implements HttpMiddleware
{
    public function handle(Request $request, callable $next, Server $server): mixed
    {
        // Validate required headers
        $contentType = $request->getHeader('Content-Type');
        if ($request->getMethod() === 'POST' && !$contentType) {
            return Response::json(['error' => 'Content-Type header required'], 400);
        }

        // Validate JSON requests
        if ($request->isJson() && $request->getMethod() === 'POST') {
            $data = $request->all();
            if (empty($data)) {
                return Response::json(['error' => 'JSON body required'], 400);
            }
        }

        // Validate API key for protected routes
        $apiKey = $request->getHeader('X-API-Key');
        if ($this->isProtectedRoute($request->getPath()) && !$this->isValidApiKey($apiKey)) {
            return Response::json(['error' => 'Invalid API key'], 401);
        }

        return $next($request);
    }

    private function isProtectedRoute(string $path): bool
    {
        return str_starts_with($path, '/api/admin/');
    }

    private function isValidApiKey(?string $apiKey): bool
    {
        return $apiKey && $apiKey === 'your-secret-api-key';
    }
}
```

#### Request Logging Middleware

```php
class RequestLoggingMiddleware implements HttpMiddleware
{
    private LoggerInterface $logger;

    public function __construct(LoggerInterface $logger)
    {
        $this->logger = $logger;
    }

    public function handle(Request $request, callable $next, Server $server): mixed
    {
        $startTime = microtime(true);
        
        // Log incoming request
        $this->logger->info('HTTP Request', [
            'method' => $request->getMethod(),
            'path' => $request->getPath(),
            'ip' => $request->getHeader('X-Forwarded-For') ?: 'unknown',
            'user_agent' => $request->getHeader('User-Agent')
        ]);

        // Process request
        $response = $next($request);
        
        // Log response
        $duration = microtime(true) - $startTime;
        $statusCode = $response instanceof Response ? $response->getStatusCode() : 200;
        
        $this->logger->info('HTTP Response', [
            'method' => $request->getMethod(),
            'path' => $request->getPath(),
            'status' => $statusCode,
            'duration_ms' => round($duration * 1000, 2)
        ]);

        return $response;
    }
}
```

#### JSON Validation Middleware

```php
class JsonValidationMiddleware implements HttpMiddleware
{
    public function handle(Request $request, callable $next, Server $server): mixed
    {
        // Only validate POST and PUT requests
        if (!in_array($request->getMethod(), ['POST', 'PUT', 'PATCH'])) {
            return $next($request);
        }

        $contentType = $request->getHeader('Content-Type');
        
        // Check if content type is JSON
        if (!str_contains($contentType, 'application/json')) {
            return Response::json(['error' => 'Content-Type must be application/json'], 400);
        }

        // Validate JSON body
        $body = $request->getBody();
        if (!empty($body)) {
            $decoded = json_decode($body, true);
            if (json_last_error() !== JSON_ERROR_NONE) {
                return Response::json([
                    'error' => 'Invalid JSON',
                    'details' => json_last_error_msg()
                ], 400);
            }
        }

        return $next($request);
    }
}
```

## WebSocket Middleware

WebSocket middleware processes WebSocket events before they reach your event handlers.

### Creating WebSocket Middleware

Implement the `WebsocketMiddleware` interface:

```php
<?php

use Sockeon\Sockeon\Contracts\WebSocket\WebsocketMiddleware;
use Sockeon\Sockeon\Connection\Server;

class WebSocketAuthMiddleware implements WebsocketMiddleware
{
    public function handle(int $clientId, string $event, array $data, callable $next, Server $server): mixed
    {
        // Check if client is authenticated
        if (!$this->isClientAuthenticated($clientId, $server)) {
            // Send error to client
            $server->send($clientId, 'error', [
                'code' => 'AUTHENTICATION_REQUIRED',
                'message' => 'You must authenticate before sending events'
            ]);
            return; // Stop processing
        }

        // Continue to next middleware or handler
        return $next($clientId, $event, $data);
    }

    private function isClientAuthenticated(int $clientId, Server $server): bool
    {
        // Check authentication status (you'd implement this)
        $clientData = $server->getClientData($clientId);
        return isset($clientData['authenticated']) && $clientData['authenticated'] === true;
    }
}
```

### WebSocket Middleware Examples

#### Rate Limiting

**Note**: Rate limiting is handled automatically by Sockeon through the built-in rate limiting system. You don't need to create custom rate limiting middleware.

**For HTTP requests**, use the `#[RateLimit]` attribute:

```php
#[HttpRoute('POST', '/api/upload')]
#[RateLimit(maxCount: 5, timeWindow: 300)] // 5 uploads per 5 minutes
public function uploadFile(Request $request): Response
{
    // Your upload logic
}
```

**For WebSocket events**, use the `#[RateLimit]` attribute:

```php
#[SocketOn('chat.message')]
#[RateLimit(maxCount: 10, timeWindow: 60)] // 10 messages per minute
public function handleChatMessage(array $data): void
{
    // Your chat logic
}
```

**Global rate limiting** can be configured via `RateLimitConfig`:

```php
use Sockeon\Sockeon\Config\RateLimitConfig;

$rateLimitConfig = new RateLimitConfig([
    'enabled' => true,
    'max_requests_per_minute' => 100,
    'time_window' => 60,
    'strategy' => 'ip' // or 'client_id'
]);

$config->rateLimitConfig = $rateLimitConfig;
```

#### Message Validation Middleware

```php
class MessageValidationMiddleware implements WebsocketMiddleware
{
    private array $eventSchemas;

    public function __construct()
    {
        $this->eventSchemas = [
            'chat.message' => [
                'required' => ['message'],
                'optional' => ['room', 'type'],
                'rules' => [
                    'message' => 'string|max:1000',
                    'room' => 'string|max:50',
                    'type' => 'in:text,image,file'
                ]
            ],
            'user.profile.update' => [
                'required' => ['name'],
                'optional' => ['avatar', 'bio'],
                'rules' => [
                    'name' => 'string|min:2|max:50',
                    'avatar' => 'url',
                    'bio' => 'string|max:500'
                ]
            ]
        ];
    }

    public function handle(int $clientId, string $event, array $data, callable $next, Server $server): mixed
    {
        // Check if we have validation rules for this event
        if (!isset($this->eventSchemas[$event])) {
            return $next($clientId, $event, $data);
        }

        $schema = $this->eventSchemas[$event];
        
        // Validate required fields
        foreach ($schema['required'] as $field) {
            if (!isset($data[$field])) {
                $server->send($clientId, 'validation.error', [
                    'event' => $event,
                    'field' => $field,
                    'message' => "Field '{$field}' is required"
                ]);
                return;
            }
        }

        // Validate field rules
        foreach ($schema['rules'] as $field => $rules) {
            if (isset($data[$field]) && !$this->validateField($data[$field], $rules)) {
                $server->send($clientId, 'validation.error', [
                    'event' => $event,
                    'field' => $field,
                    'message' => "Field '{$field}' validation failed"
                ]);
                return;
            }
        }

        return $next($clientId, $event, $data);
    }

    private function validateField($value, string $rules): bool
    {
        $ruleList = explode('|', $rules);
        
        foreach ($ruleList as $rule) {
            if (str_contains($rule, ':')) {
                [$ruleName, $ruleValue] = explode(':', $rule, 2);
            } else {
                $ruleName = $rule;
                $ruleValue = null;
            }

            switch ($ruleName) {
                case 'string':
                    if (!is_string($value)) return false;
                    break;
                case 'max':
                    if (strlen($value) > (int)$ruleValue) return false;
                    break;
                case 'min':
                    if (strlen($value) < (int)$ruleValue) return false;
                    break;
                case 'url':
                    if (!filter_var($value, FILTER_VALIDATE_URL)) return false;
                    break;
                case 'in':
                    $allowedValues = explode(',', $ruleValue);
                    if (!in_array($value, $allowedValues)) return false;
                    break;
            }
        }

        return true;
    }
}
```

#### Profanity Filter Middleware

```php
class ProfanityFilterMiddleware implements WebsocketMiddleware
{
    private array $bannedWords;

    public function __construct(array $bannedWords = [])
    {
        $this->bannedWords = array_map('strtolower', $bannedWords ?: [
            'spam', 'inappropriate', 'banned' // Add your words here
        ]);
    }

    public function handle(int $clientId, string $event, array $data, callable $next, Server $server): mixed
    {
        // Only filter text-based events
        if (!in_array($event, ['chat.message', 'comment.post', 'review.create'])) {
            return $next($clientId, $event, $data);
        }

        // Check message content
        $message = $data['message'] ?? $data['content'] ?? $data['text'] ?? '';
        
        if ($this->containsProfanity($message)) {
            $server->send($clientId, 'message.blocked', [
                'reason' => 'Inappropriate content detected',
                'original_event' => $event
            ]);
            return; // Block the message
        }

        return $next($clientId, $event, $data);
    }

    private function containsProfanity(string $text): bool
    {
        $text = strtolower($text);
        
        foreach ($this->bannedWords as $word) {
            if (str_contains($text, $word)) {
                return true;
            }
        }

        return false;
    }
}
```

## Handshake Middleware

Special middleware for WebSocket connection handshakes:

```php
use Sockeon\Sockeon\Contracts\WebSocket\HandshakeMiddleware;
use Sockeon\Sockeon\WebSocket\HandshakeRequest;

class WebSocketAuthHandshakeMiddleware implements HandshakeMiddleware
{
    public function handle(int $clientId, HandshakeRequest $request, callable $next, Server $server): bool
    {
        // Check for authentication token in headers
        $authHeader = $request->getHeader('Authorization');
        
        if (!$authHeader) {
            return false; // Reject connection
        }

        $token = str_replace('Bearer ', '', $authHeader);
        
        if (!$this->isValidToken($token)) {
            return false; // Reject connection
        }

        // Store auth info for later use
        $server->setClientData($clientId, 'authenticated', true);
        $server->setClientData($clientId, 'token', $token);

        return $next($clientId, $request);
    }

    private function isValidToken(string $token): bool
    {
        // Implement your token validation
        return !empty($token);
    }
}
```

## Applying Middleware

### Global Middleware

Apply middleware to all routes/events:

```php
$server = new Server($config);

// Global HTTP middleware (applies to all HTTP routes)
$server->addHttpMiddleware(CorsMiddleware::class);
$server->addHttpMiddleware(RequestLoggingMiddleware::class);
$server->addHttpMiddleware(AuthMiddleware::class);

// Global WebSocket middleware (applies to all WebSocket events)
$server->addWebSocketMiddleware(WebSocketAuthMiddleware::class);
$server->addWebSocketMiddleware(MessageValidationMiddleware::class);
// Note: Rate limiting is handled automatically via #[RateLimit] attribute

// Global handshake middleware
$server->addHandshakeMiddleware(WebSocketAuthHandshakeMiddleware::class);

$server->registerController(new ChatController());
$server->run();
```

### Route-Specific Middleware

Apply middleware to specific routes or events:

```php
class ApiController extends SocketController
{
    // No middleware - public endpoint
    #[HttpRoute('GET', '/api/public')]
    public function publicData(Request $request): Response
    {
        return Response::json(['message' => 'Public data']);
    }

    // Specific middleware for this route
    #[HttpRoute('GET', '/api/admin', middlewares: [AdminMiddleware::class])]
    public function adminData(Request $request): Response
    {
        return Response::json(['message' => 'Admin data']);
    }

    // Multiple middleware
    #[HttpRoute('POST', '/api/sensitive', middlewares: [AuthMiddleware::class, AuditMiddleware::class])]
    public function sensitiveOperation(Request $request): Response
    {
        return Response::json(['message' => 'Operation completed']);
    }

    // WebSocket event with middleware
    #[SocketOn('admin.command', middlewares: [WebSocketAuthMiddleware::class, AdminMiddleware::class])]
    public function adminCommand(int $clientId, array $data): void
    {
        // Admin command handling
    }
}
```

### Excluding Global Middleware

Exclude specific global middleware from certain routes:

```php
class HealthController extends SocketController
{
    // Health check endpoint - no auth needed
    #[HttpRoute('GET', '/health')]
    public function healthCheck(Request $request): Response
    {
        return Response::json(['status' => 'healthy']);
    }

    // Public WebSocket event (exclude auth)
    #[SocketOn('system.ping', excludeGlobalMiddlewares: [WebSocketAuthMiddleware::class])]
    public function ping(int $clientId, array $data): void
    {
        $this->emit($clientId, 'system.pong', ['timestamp' => time()]);
    }
}
```

## Middleware Best Practices

### 1. Keep Middleware Focused

Each middleware should have a single responsibility:

```php
// Good - focused on authentication
class AuthMiddleware implements HttpMiddleware { ... }

// Good - focused on validation
class ValidationMiddleware implements HttpMiddleware { ... }

// Bad - too many responsibilities
class EverythingMiddleware implements HttpMiddleware { ... }
```

### 2. Order Matters

Apply middleware in logical order:

```php
// Correct order
$server->addHttpMiddleware(CorsMiddleware::class);        // Handle CORS first
$server->addHttpMiddleware(AuthMiddleware::class);       // Auth before validation
$server->addHttpMiddleware(ValidationMiddleware::class); // Validate last
// Note: Rate limiting is handled automatically via #[RateLimit] attribute
```

### 3. Early Returns

Return early when possible to short-circuit the pipeline:

```php
public function handle(Request $request, callable $next, Server $server): mixed
{
    // Check condition early
    if (!$this->shouldProcess($request)) {
        return Response::json(['error' => 'Skipped'], 400);
    }

    return $next($request);
}
```

### 4. Error Handling

Handle errors gracefully in middleware:

```php
public function handle(Request $request, callable $next, Server $server): mixed
{
    try {
        return $next($request);
    } catch (Exception $e) {
        // Log error
        error_log($e->getMessage());
        
        // Return appropriate error response
        return Response::json(['error' => 'Internal server error'], 500);
    }
}
```

### 5. Configuration

Make middleware configurable:

```php
// Note: Rate limiting is handled automatically by the framework
// Use #[RateLimit] attributes on routes or configure globally via RateLimitConfig
```

## Built-in Middleware

Sockeon includes some built-in middleware:

### Rate Limiting

Rate limiting is handled automatically by Sockeon through the `#[RateLimit]` attribute and global configuration via `RateLimitConfig`. You don't need to manually add rate limiting middleware.

**For HTTP routes:**
```php
#[HttpRoute('POST', '/api/upload')]
#[RateLimit(maxCount: 5, timeWindow: 300)] // 5 uploads per 5 minutes
public function uploadFile(Request $request): Response
{
    // Rate limiting handled automatically
}
```

**For WebSocket events:**
```php
#[SocketOn('chat.message')]
#[RateLimit(maxCount: 10, timeWindow: 60)] // 10 messages per minute
public function handleChatMessage(int $clientId, array $data): void
{
    // Rate limiting handled automatically
}
```

**Global configuration:**
```php
use Sockeon\Sockeon\Config\RateLimitConfig;

$rateLimitConfig = new RateLimitConfig([
    'enabled' => true,
    'max_http_requests_per_ip' => 100,
    'max_websocket_messages_per_client' => 200,
    'time_window' => 60
]);

$config->rateLimitConfig = $rateLimitConfig;
```

## Testing Middleware

Test your middleware independently:

```php
class AuthMiddlewareTest extends TestCase
{
    public function testAuthenticationRequired()
    {
        $middleware = new AuthMiddleware();
        $request = new Request(['headers' => []]);
        
        $response = $middleware->handle($request, fn() => null, $this->mockServer);
        
        $this->assertEquals(401, $response->getStatusCode());
    }

    public function testValidToken()
    {
        $middleware = new AuthMiddleware();
        $request = new Request(['headers' => ['Authorization' => 'Bearer valid-token']]);
        
        $nextCalled = false;
        $next = function($req) use (&$nextCalled) {
            $nextCalled = true;
            return Response::json(['success' => true]);
        };
        
        $response = $middleware->handle($request, $next, $this->mockServer);
        
        $this->assertTrue($nextCalled);
        $this->assertEquals(200, $response->getStatusCode());
    }
}
```

## Next Steps

- [Namespaces and Rooms](core/namespaces-rooms.md) - Organize client connections
- [Rate Limiting](advanced/rate-limiting.md) - Built-in rate limiting features
- [Examples](../examples/) - See middleware in action
