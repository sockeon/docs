---
title: "Rate Limiting - Sockeon Documentation"
description: "Learn how to implement rate limiting in Sockeon framework using attributes and global configuration"
og_image: "https://sockeon.com/assets/logo.png"
twitter_image: "https://sockeon.com/assets/logo.png"
---

# Rate Limiting

Sockeon provides automatic rate limiting to protect your server from abuse. Rate limiting is handled through the `#[RateLimit]` attribute and global configuration.

## Overview

Rate limiting in Sockeon is automatic and doesn't require manual implementation. You can:

- Use `#[RateLimit]` attributes on individual routes and events
- Configure global rate limiting via `RateLimitConfig`
- Set different limits for HTTP requests and WebSocket messages

## Basic Usage

### WebSocket Events

```php
use Sockeon\Sockeon\Core\Attributes\RateLimit;

class ChatController extends SocketController
{
    #[SocketOn('chat.message')]
    #[RateLimit(maxCount: 10, timeWindow: 60)] // 10 messages per minute
    public function handleMessage(int $clientId, array $data): void
    {
        $this->broadcast('chat.message', [
            'user' => $clientId,
            'message' => $data['message']
        ]);
    }

    #[SocketOn('user.typing')]
    #[RateLimit(maxCount: 30, timeWindow: 60)] // 30 typing events per minute
    public function handleTyping(int $clientId, array $data): void
    {
        $this->broadcast('user.typing', [
            'user' => $clientId,
            'isTyping' => $data['isTyping']
        ]);
    }
}
```

### HTTP Routes

```php
class ApiController extends SocketController
{
    #[HttpRoute('POST', '/api/login')]
    #[RateLimit(maxCount: 5, timeWindow: 300)] // 5 login attempts per 5 minutes
    public function login(Request $request): Response
    {
        $data = $request->all();
        // Login logic...
        return Response::json(['success' => true]);
    }

    #[HttpRoute('POST', '/api/upload')]
    #[RateLimit(maxCount: 3, timeWindow: 3600)] // 3 uploads per hour
    public function uploadFile(Request $request): Response
    {
        // Upload logic...
        return Response::json(['success' => true]);
    }
}
```

## Global Configuration

Configure rate limiting globally using `RateLimitConfig`:

```php
use Sockeon\Sockeon\Config\RateLimitConfig;

$config = new ServerConfig();
$config->host = '0.0.0.0';
$config->port = 6001;

// Configure global rate limiting
$rateLimitConfig = new RateLimitConfig([
    'enabled' => true,
    'maxHttpRequestsPerIp' => 100,      // 100 HTTP requests per IP per time window
    'maxWebSocketMessagesPerClient' => 200, // 200 WebSocket messages per client per time window
    'httpTimeWindow' => 60,              // 1 minute for HTTP
    'websocketTimeWindow' => 60          // 1 minute for WebSocket
]);

$config->rateLimitConfig = $rateLimitConfig;
```

## Common Use Cases

### Login Rate Limiting

```php
#[HttpRoute('POST', '/api/login')]
#[RateLimit(maxCount: 3, timeWindow: 900)] // 3 attempts per 15 minutes
public function login(Request $request): Response
{
    $data = $request->all();
    
    if ($this->validateCredentials($data)) {
        return Response::json(['success' => true]);
    }
    
    return Response::json(['error' => 'Invalid credentials'], 401);
}
```

### Chat Message Rate Limiting

```php
#[SocketOn('chat.message')]
#[RateLimit(maxCount: 20, timeWindow: 60)] // 20 messages per minute
public function handleChatMessage(int $clientId, array $data): void
{
    $message = trim($data['message'] ?? '');
    
    if (empty($message)) {
        $this->emit($clientId, 'error', ['message' => 'Message cannot be empty']);
        return;
    }
    
    $this->broadcast('chat.message', [
        'user' => $clientId,
        'message' => $message,
        'timestamp' => time()
    ]);
}
```

## Rate Limit Parameters

The `#[RateLimit]` attribute accepts these parameters:

- `maxCount` (int): Maximum number of requests/events allowed
- `timeWindow` (int): Time window in seconds
- `burstAllowance` (int): Additional burst allowance (optional)
- `bypassGlobal` (bool): Bypass global rate limiting (optional)
- `whitelist` (array): List of IPs/clients to whitelist (optional)

## Common Time Windows

- **30 seconds**: For very frequent events
- **60 seconds (1 minute)**: For chat messages, API calls
- **300 seconds (5 minutes)**: For login attempts
- **3600 seconds (1 hour)**: For file uploads, heavy operations

## Common Rate Limits

- **Chat messages**: 10-20 per minute
- **API requests**: 100-1000 per minute
- **Login attempts**: 3-5 per 15 minutes
- **File uploads**: 1-3 per hour
- **Admin operations**: 10-50 per minute

## Best Practices

### Start Conservative

```php
// Start with strict limits, then adjust based on usage
#[RateLimit(maxCount: 5, timeWindow: 60)] // Very conservative
public function sensitiveOperation(Request $request): Response
{
    // Implementation
}
```

### Use Appropriate Time Windows

```php
// Short window for frequent events
#[RateLimit(maxCount: 30, timeWindow: 30)] // 30 events per 30 seconds

// Longer window for sensitive operations
#[RateLimit(maxCount: 3, timeWindow: 900)] // 3 attempts per 15 minutes
```

### Monitor and Adjust

Track rate limit hits and adjust limits based on legitimate usage patterns.

### Provide Clear Feedback

When rate limits are hit, provide clear error messages:

```php
// The framework automatically handles rate limit responses
// You can customize the response in your error handling
```

## Summary

Rate limiting in Sockeon is:

- **Automatic**: Use `#[RateLimit]` attributes on routes and events
- **Configurable**: Set global limits via `RateLimitConfig`
- **Flexible**: Different limits for different operations
- **Built-in**: No manual implementation required

The framework handles all the complexity, so you can focus on your application logic. 