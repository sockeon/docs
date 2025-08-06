---
title: "Error Handling - Sockeon Documentation"
description: "Learn how to handle errors gracefully in Sockeon framework with try-catch blocks and custom exceptions"
og_image: "https://sockeon.com/assets/logo.png"
twitter_image: "https://sockeon.com/assets/logo.png"
---

# Error Handling

Sockeon provides comprehensive error handling for both WebSocket and HTTP operations. This guide covers how to handle errors gracefully in your applications.

## Overview

Error handling in Sockeon is built into the framework. You can:

- Use try-catch blocks for error handling
- Create custom exceptions
- Provide meaningful error responses
- Log errors for debugging

## Basic Error Handling

### WebSocket Error Handling

```php
class ChatController extends SocketController
{
    #[SocketOn('chat.message')]
    public function handleMessage(int $clientId, array $data): void
    {
        try {
            $message = $data['message'] ?? '';
            
            if (empty($message)) {
                $this->emit($clientId, 'error', [
                    'message' => 'Message cannot be empty'
                ]);
                return;
            }
            
            $this->broadcast('chat.message', [
                'user' => $clientId,
                'message' => $message
            ]);
            
        } catch (Exception $e) {
            // Log the error
            $this->getLogger()->error('Chat message error: ' . $e->getMessage());
            
            // Send error to client
            $this->emit($clientId, 'error', [
                'message' => 'Failed to process message'
            ]);
        }
    }
}
```

### HTTP Error Handling

```php
class ApiController extends SocketController
{
    #[HttpRoute('POST', '/api/users')]
    public function createUser(Request $request): Response
    {
        try {
            $data = $request->all();
            
            // Validate required fields
            if (empty($data['name']) || empty($data['email'])) {
                return Response::json([
                    'error' => 'Name and email are required'
                ], 400);
            }
            
            // Create user logic...
            $user = $this->createUser($data);
            
            return Response::json(['user' => $user], 201);
            
        } catch (Exception $e) {
            // Log the error
            $this->getLogger()->error('User creation error: ' . $e->getMessage());
            
            return Response::json([
                'error' => 'Failed to create user'
            ], 500);
        }
    }
}
```

## Custom Exceptions

Create custom exceptions for specific error types:

```php
use Sockeon\Sockeon\Exception\Client\WebSocketException;

class ChatException extends WebSocketException
{
    public function __construct(string $message, int $code = 0)
    {
        parent::__construct($message, $code);
    }
}

class ValidationException extends WebSocketException
{
    public function __construct(string $field, string $message)
    {
        parent::__construct("Validation failed for {$field}: {$message}");
    }
}
```

### Using Custom Exceptions

```php
class UserController extends SocketController
{
    #[SocketOn('user.update')]
    public function updateUser(int $clientId, array $data): void
    {
        try {
            $userId = $data['userId'] ?? null;
            
            if (!$userId) {
                throw new ValidationException('userId', 'User ID is required');
            }
            
            $user = $this->findUser($userId);
            
            if (!$user) {
                throw new ChatException('User not found');
            }
            
            // Update user logic...
            $this->emit($clientId, 'user.updated', ['success' => true]);
            
        } catch (ValidationException $e) {
            $this->emit($clientId, 'error', [
                'type' => 'validation',
                'message' => $e->getMessage()
            ]);
        } catch (ChatException $e) {
            $this->emit($clientId, 'error', [
                'type' => 'not_found',
                'message' => $e->getMessage()
            ]);
        } catch (Exception $e) {
            $this->getLogger()->error('User update error: ' . $e->getMessage());
            $this->emit($clientId, 'error', [
                'type' => 'server_error',
                'message' => 'Internal server error'
            ]);
        }
    }
}
```

## Error Response Patterns

### Simple Error Response

```php
$this->emit($clientId, 'error', [
    'message' => 'Operation failed'
]);
```

### Detailed Error Response

```php
$this->emit($clientId, 'error', [
    'type' => 'validation_error',
    'message' => 'Invalid input data',
    'details' => [
        'field' => 'email',
        'reason' => 'Invalid email format'
    ],
    'timestamp' => time()
]);
```

### Retry Information

```php
$this->emit($clientId, 'error', [
    'message' => 'Service temporarily unavailable',
    'retry_after' => 30, // seconds
    'suggestion' => 'Please try again later'
]);
```

### HTTP Error Responses

```php
// Bad Request
return Response::json(['error' => 'Invalid request data'], 400);

// Not Found
return Response::json(['error' => 'Resource not found'], 404);

// Internal Server Error
return Response::json(['error' => 'Internal server error'], 500);
```

## Best Practices

### Always Log Errors

```php
try {
    // Your code
} catch (Exception $e) {
    $this->getLogger()->error('Operation failed: ' . $e->getMessage(), [
        'clientId' => $clientId,
        'data' => $data
    ]);
    
    $this->emit($clientId, 'error', ['message' => 'Operation failed']);
}
```

### Provide Clear Error Messages

```php
// Good
$this->emit($clientId, 'error', ['message' => 'Email format is invalid']);

// Bad
$this->emit($clientId, 'error', ['message' => 'Error occurred']);
```

### Use Appropriate HTTP Status Codes

```php
// 400 for client errors
return Response::json(['error' => 'Invalid input'], 400);

// 401 for authentication errors
return Response::json(['error' => 'Authentication required'], 401);

// 404 for not found
return Response::json(['error' => 'User not found'], 404);

// 500 for server errors
return Response::json(['error' => 'Internal server error'], 500);
```

### Handle Specific Exceptions

```php
try {
    // Your code
} catch (ValidationException $e) {
    // Handle validation errors
} catch (DatabaseException $e) {
    // Handle database errors
} catch (Exception $e) {
    // Handle all other errors
}
```

## Summary

Error handling in Sockeon is:

- **Built-in**: Framework provides error handling infrastructure
- **Flexible**: Use try-catch blocks and custom exceptions
- **Informative**: Provide clear error messages to clients
- **Logged**: Errors are automatically logged for debugging

Always handle errors gracefully to provide a good user experience. 