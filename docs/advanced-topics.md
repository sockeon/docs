# Advanced Topics

This document explores sophisticated implementation patterns, performance optimization strategies, and security considerations for enterprise applications built with the Sockeon library.

## Custom Middleware Development

Middleware components provide a powerful mechanism for intercepting, processing, and potentially modifying requests before they reach your application controllers. This section demonstrates how to implement custom middleware for various advanced use cases.

### Authentication Middleware Implementation

```php
class AuthMiddleware
{
    private $tokens = [];

    public function process($request, callable $next)
    {
        // For WebSocket
        if (isset($request['clientId'])) {
            $token = $this->extractToken($request['data']);
            if (!$this->verifyToken($token)) {
                return false;
            }
            $this->tokens[$request['clientId']] = $token;
        }
        // For HTTP
        else {
            $token = $this->extractHttpToken($request);
            if (!$this->verifyToken($token)) {
                return [
                    'status' => 401,
                    'body' => ['error' => 'Unauthorized']
                ];
            }
        }

        return $next();
    }

    private function verifyToken($token)
    {
        // Implement your token verification logic
        return true;
    }
}

// Usage
$server->addWebSocketMiddleware(new AuthMiddleware());
```

### Rate Limiting Middleware

```php
class RateLimitMiddleware
{
    private $limits = [];
    private $windowSize = 60; // 1 minute
    private $maxRequests = 100;

    public function __invoke($request, callable $next)
    {
        $clientId = $request['clientId'] ?? $request['ip'];
        
        if (!isset($this->limits[$clientId])) {
            $this->limits[$clientId] = [
                'count' => 0,
                'windowStart' => time()
            ];
        }

        // Reset window if expired
        if (time() - $this->limits[$clientId]['windowStart'] > $this->windowSize) {
            $this->limits[$clientId] = [
                'count' => 0,
                'windowStart' => time()
            ];
        }

        // Check rate limit
        if (++$this->limits[$clientId]['count'] > $this->maxRequests) {
            return [
                'status' => 429,
                'body' => ['error' => 'Too Many Requests']
            ];
        }

        return $next();
    }
}
```

## Error Handling

### Custom Error Handler

```php
class ErrorHandler
{
    public function handle(\Throwable $error, Server $server, int $clientId = null)
    {
        $errorData = [
            'message' => $error->getMessage(),
            'code' => $error->getCode()
        ];

        if ($clientId) {
            $server->emit($clientId, 'error', $errorData);
        }

        if ($server->isDebug()) {
            $errorData['trace'] = $error->getTraceAsString();
        }

        error_log(json_encode($errorData));
    }
}

// Usage
try {
    $server->run();
} catch (\Throwable $e) {
    $errorHandler = new ErrorHandler();
    $errorHandler->handle($e, $server);
}
```

## Custom Protocol Extensions

### Adding Custom Frame Types

```php
class CustomWebSocketHandler extends WebSocketHandler
{
    protected const CUSTOM_OPCODE = 10;

    public function handleCustomFrame($payload)
    {
        // Custom frame handling logic
    }

    protected function decodeWebSocketFrame($data)
    {
        $frames = parent::decodeWebSocketFrame($data);
        
        foreach ($frames as &$frame) {
            if ($frame['opcode'] === self::CUSTOM_OPCODE) {
                $frame['payload'] = $this->handleCustomFrame($frame['payload']);
            }
        }
        
        return $frames;
    }
}
```

## Performance Optimization

### Connection Pooling

```php
class ConnectionPool
{
    private $pool = [];
    private $maxSize = 1000;

    public function acquire(): ?int
    {
        // Find first available slot
        for ($i = 0; $i < $this->maxSize; $i++) {
            if (!isset($this->pool[$i])) {
                $this->pool[$i] = true;
                return $i;
            }
        }
        return null;
    }

    public function release(int $id): void
    {
        unset($this->pool[$id]);
    }
}
```

### Memory Management

```php
class MemoryManager
{
    private $limit;
    private $warning;

    public function __construct($limitMB = 128, $warningThreshold = 0.8)
    {
        $this->limit = $limitMB * 1024 * 1024;
        $this->warning = $this->limit * $warningThreshold;
    }

    public function check(): void
    {
        $used = memory_get_usage(true);
        
        if ($used >= $this->limit) {
            throw new \RuntimeException('Memory limit exceeded');
        }
        
        if ($used >= $this->warning) {
            trigger_error('Memory usage warning', E_USER_WARNING);
        }
    }
}
```

## Testing

### WebSocket Client Mock

```php
class MockWebSocketClient
{
    private $events = [];

    public function emit(string $event, array $data)
    {
        if (isset($this->events[$event])) {
            call_user_func($this->events[$event], $data);
        }
    }

    public function on(string $event, callable $callback)
    {
        $this->events[$event] = $callback;
    }
}

// Usage in tests
public function testMessageBroadcast()
{
    $client = new MockWebSocketClient();
    $received = false;
    
    $client->on('message.receive', function($data) use (&$received) {
        $received = true;
        $this->assertEquals('Hello', $data['message']);
    });
    
    $client->emit('message.send', ['message' => 'Hello']);
    $this->assertTrue($received);
}
```

For more information about the core functionality, refer to:
- [Core Concepts](./core-concepts.md)
- [API Reference](./api-reference.md)
