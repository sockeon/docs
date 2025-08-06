---
title: "Logging - Sockeon Documentation"
description: "Learn how to use logging in Sockeon framework for debugging and monitoring applications"
og_image: "https://sockeon.com/assets/logo.png"
twitter_image: "https://sockeon.com/assets/logo.png"
---

# Logging

Sockeon provides a comprehensive logging system for debugging and monitoring your applications. This guide covers how to use logging effectively.

## Overview

Sockeon's logging system is built into the framework. You can:

- Log messages at different levels
- Configure logging for different environments
- Log HTTP requests and WebSocket events
- Handle errors with detailed logging

## Basic Logging

### Creating a Logger

```php
use Sockeon\Sockeon\Logging\Logger;
use Sockeon\Sockeon\Logging\LogLevel;

// Development logger
$logger = new Logger(
    LogLevel::DEBUG,        // Minimum log level
    true,                   // Log to console
    true,                   // Log to file
    'logs',                 // Log directory
    true                    // Separate log files
);

// Production logger
$logger = new Logger(
    LogLevel::ERROR,        // Only log errors and above
    false,                  // Don't log to console
    true,                   // Log to file
    'logs',
    true
);
```

### Using Logger in Controllers

```php
class ChatController extends SocketController
{
    #[SocketOn('chat.message')]
    public function handleMessage(int $clientId, array $data): void
    {
        // Log info message
        $this->getLogger()->info('Chat message received', [
            'clientId' => $clientId,
            'message' => $data['message'] ?? ''
        ]);
        
        $this->broadcast('chat.message', [
            'user' => $clientId,
            'message' => $data['message']
        ]);
    }
    
    #[OnConnect]
    public function onConnect(int $clientId): void
    {
        // Log debug message
        $this->getLogger()->debug('Client connected', [
            'clientId' => $clientId,
            'timestamp' => time()
        ]);
        
        $this->emit($clientId, 'welcome', ['message' => 'Welcome!']);
    }
    
    #[OnDisconnect]
    public function onDisconnect(int $clientId): void
    {
        // Log warning message
        $this->getLogger()->warning('Client disconnected', [
            'clientId' => $clientId,
            'timestamp' => time()
        ]);
    }
}
```

## Log Levels

Sockeon supports standard log levels:

```php
use Sockeon\Sockeon\Logging\LogLevel;

// Emergency - System is unusable
$logger->emergency('System is down');

// Alert - Action must be taken immediately
$logger->alert('Database connection failed');

// Critical - Critical conditions
$logger->critical('Application crash detected');

// Error - Error conditions
$logger->error('Failed to process request');

// Warning - Warning conditions
$logger->warning('High memory usage detected');

// Notice - Normal but significant events
$logger->notice('User logged in');

// Info - Informational messages
$logger->info('Request processed successfully');

// Debug - Debug-level messages
$logger->debug('Processing step 1 of 3');
```

### Log Level Hierarchy

```
EMERGENCY (highest priority)
    ↓
ALERT
    ↓
CRITICAL
    ↓
ERROR
    ↓
WARNING
    ↓
NOTICE
    ↓
INFO
    ↓
DEBUG (lowest priority)
```

## HTTP Request Logging

```php
class ApiController extends SocketController
{
    #[HttpRoute('POST', '/api/users')]
    public function createUser(Request $request): Response
    {
        $startTime = microtime(true);
        
        // Log request details
        $this->getLogger()->info('HTTP request received', [
            'method' => $request->getMethod(),
            'path' => $request->getPath(),
            'clientIp' => $request->getClientIp(),
            'userAgent' => $request->getHeader('User-Agent')
        ]);
        
        try {
            $data = $request->all();
            
            // Process request...
            $user = $this->createUser($data);
            
            $processingTime = (microtime(true) - $startTime) * 1000;
            
            // Log successful response
            $this->getLogger()->info('HTTP request completed', [
                'statusCode' => 201,
                'processingTime' => round($processingTime, 2) . 'ms'
            ]);
            
            return Response::json(['user' => $user], 201);
            
        } catch (Exception $e) {
            $processingTime = (microtime(true) - $startTime) * 1000;
            
            // Log error
            $this->getLogger()->error('HTTP request failed', [
                'error' => $e->getMessage(),
                'processingTime' => round($processingTime, 2) . 'ms'
            ]);
            
            return Response::json(['error' => 'Failed to create user'], 500);
        }
    }
}
```

## Error Logging

```php
class ErrorController extends SocketController
{
    #[SocketOn('risky.operation')]
    public function handleRiskyOperation(int $clientId, array $data): void
    {
        try {
            // Perform risky operation
            $result = $this->performRiskyOperation($data);
            
            $this->emit($clientId, 'success', ['result' => $result]);
            
        } catch (Exception $e) {
            // Log error with context
            $this->getLogger()->error('Risky operation failed', [
                'clientId' => $clientId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'data' => $data
            ]);
            
            $this->emit($clientId, 'error', [
                'message' => 'Operation failed'
            ]);
        }
    }
}
```

## Logger Configuration

### Logger Factory

```php
class LoggerFactory
{
    public static function createForEnvironment(string $environment): Logger
    {
        switch ($environment) {
            case 'development':
                return new Logger(
                    LogLevel::DEBUG,
                    true,   // Console logging
                    true,   // File logging
                    'logs',
                    true    // Separate files
                );
                
            case 'production':
                return new Logger(
                    LogLevel::ERROR,
                    false,  // No console logging
                    true,   // File logging
                    'logs',
                    true    // Separate files
                );
                
            case 'testing':
                return new Logger(
                    LogLevel::DEBUG,
                    false,  // No console logging
                    false,  // No file logging
                    'logs',
                    false
                );
                
            default:
                return new Logger(
                    LogLevel::INFO,
                    true,
                    true,
                    'logs',
                    true
                );
        }
    }
}

// Usage
$logger = LoggerFactory::createForEnvironment($_ENV['APP_ENV'] ?? 'development');
```

### Logger Methods

```php
$logger = new Logger(LogLevel::INFO);

// Change log level
$logger->setMinLogLevel(LogLevel::WARNING);

// Enable/disable console logging
$logger->setLogToConsole(false);

// Enable/disable file logging
$logger->setLogToFile(true);

// Set log directory
$logger->setLogDirectory('custom/logs');

// Enable/disable separate log files
$logger->setSeparateLogFiles(true);
```

## Best Practices

### Use Appropriate Log Levels

```php
// Use DEBUG for detailed information
$logger->debug('Processing step 1 of 3');

// Use INFO for general information
$logger->info('User logged in', ['userId' => 123]);

// Use WARNING for potential issues
$logger->warning('High memory usage', ['usage' => '85%']);

// Use ERROR for actual errors
$logger->error('Database connection failed', ['error' => $e->getMessage()]);
```

### Include Context

```php
// Good - includes relevant context
$logger->info('User action', [
    'userId' => $userId,
    'action' => 'profile_update',
    'timestamp' => time()
]);

// Bad - no context
$logger->info('User did something');
```

### Don't Log Sensitive Information

```php
// Good - log user ID but not password
$logger->info('User login attempt', [
    'userId' => $userId,
    'success' => $success
]);

// Bad - logs sensitive data
$logger->info('User login attempt', [
    'userId' => $userId,
    'password' => $password,  // Don't log passwords!
    'success' => $success
]);
```

### Use Structured Logging

```php
// Structured logging with consistent format
$logger->info('API request', [
    'method' => 'POST',
    'endpoint' => '/api/users',
    'statusCode' => 201,
    'processingTime' => '45ms',
    'clientIp' => '192.168.1.1'
]);
```

## Summary

Logging in Sockeon is:

- **Built-in**: Framework provides logging infrastructure
- **Configurable**: Different settings for different environments
- **Comprehensive**: Support for all log levels
- **Contextual**: Include relevant information in log messages

Use logging to monitor your application and debug issues effectively. 