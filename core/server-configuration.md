---
title: "Server Configuration - Sockeon Documentation"
description: "Learn how to configure Sockeon server with host, port, CORS, rate limiting, and authentication settings"
og_image: "https://sockeon.com/assets/logo.png"
twitter_image: "https://sockeon.com/assets/logo.png"
---

# Server Configuration

The `ServerConfig` class provides comprehensive configuration options for your Sockeon server. This guide covers all available settings and their use cases.

## Basic Configuration

```php
use Sockeon\Sockeon\Config\ServerConfig;

$config = new ServerConfig();
$config->host = '0.0.0.0';
$config->port = 6001;
$config->debug = false;
```

## Configuration Properties

### Network Settings

#### host
- **Type**: `string`
- **Default**: `'0.0.0.0'`
- **Description**: The IP address the server will bind to

```php
$config->host = '127.0.0.1';  // Localhost only
$config->host = '0.0.0.0';    // All interfaces (default)
$config->host = '192.168.1.100'; // Specific IP
```

#### port
- **Type**: `int`
- **Default**: `6001`
- **Description**: The port number the server will listen on

```php
$config->port = 8080;   // HTTP alternative port
$config->port = 6001;   // Default
$config->port = 443;    // HTTPS (requires appropriate setup)
```

### Debug Settings

#### debug
- **Type**: `bool`
- **Default**: `false`
- **Description**: Enable or disable debug mode for detailed logging

```php
$config->debug = true;   // Enable debug logging
$config->debug = false;  // Production mode (default)
```

## CORS Configuration

Configure Cross-Origin Resource Sharing for HTTP requests:

```php
$config->cors = [
    'allowed_origins' => ['*'],  // Allow all origins
    'allowed_methods' => ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    'allowed_headers' => ['Content-Type', 'Authorization'],
    'allow_credentials' => false,
    'max_age' => 86400
];
```

### CORS Options

- **allowed_origins**: Array of allowed origin URLs or `['*']` for all
- **allowed_methods**: HTTP methods to allow
- **allowed_headers**: Headers that can be used during the actual request
- **allow_credentials**: Whether to allow credentials (cookies, authorization headers)
- **max_age**: How long the browser should cache preflight responses (seconds)

### Examples

```php
// Development - Allow everything
$config->cors = [
    'allowed_origins' => ['*'],
    'allowed_methods' => ['*'],
    'allowed_headers' => ['*']
];

// Production - Restrict to specific domains
$config->cors = [
    'allowed_origins' => [
        'https://myapp.com',
        'https://www.myapp.com',
        'https://admin.myapp.com'
    ],
    'allowed_methods' => ['GET', 'POST', 'PUT', 'DELETE'],
    'allowed_headers' => ['Content-Type', 'Authorization', 'X-Requested-With'],
    'allow_credentials' => true,
    'max_age' => 3600
];

// API only - No CORS
$config->cors = [];
```

## Authentication

### authKey
- **Type**: `string|null`
- **Default**: `null`
- **Description**: Optional authentication key for securing WebSocket connections

```php
$config->authKey = 'your-secret-key';
```

When set, WebSocket clients must include this key as a query parameter:

```javascript
// JavaScript client
const ws = new WebSocket('ws://localhost:6001?key=your-secret-key');
```

```php
// PHP client
$client = new Client('localhost', 6001, '/?key=your-secret-key');
$client->connect();
```

## Logging Configuration

### logger
- **Type**: `LoggerInterface|null`
- **Default**: `null`
- **Description**: Custom logger instance (uses default logger if not provided)

```php
use Sockeon\Sockeon\Logging\Logger;

$logger = new Logger();
$logger->setLogLevel('info');
$logger->setLogToFile(true);
$logger->setLogDirectory('/var/log/sockeon');

$config->logger = $logger;
```

## Queue Configuration

### queueFile
- **Type**: `string|null`
- **Default**: `null`
- **Description**: Optional path to queue file for message persistence

```php
$config->queueFile = '/tmp/sockeon_queue.json';
```

When set, Sockeon will persist messages to this file, allowing for:
- Message recovery after server restart
- Offline message delivery
- Message history

## Rate Limiting Configuration

### rateLimitConfig
- **Type**: `RateLimitConfig|null`
- **Default**: `null`
- **Description**: Rate limiting configuration

```php
use Sockeon\Sockeon\Config\RateLimitConfig;

$rateLimitConfig = new RateLimitConfig([
    'enabled' => true,
    'maxHttpRequestsPerIp' => 100,        // Max HTTP requests per IP per time window
    'httpTimeWindow' => 60,               // Time window in seconds
    'maxWebSocketMessagesPerClient' => 200, // Max WS messages per client per time window
    'webSocketTimeWindow' => 60,          // Time window in seconds
    'maxConnectionsPerIp' => 50,          // Max connections per IP
    'connectionTimeWindow' => 60,         // Time window for connection limiting
    'maxGlobalConnections' => 10000,      // Max total connections
    'burstAllowance' => 10,               // Additional requests for bursts
    'cleanupInterval' => 300,             // Cleanup old entries every 5 minutes
    'whitelist' => ['127.0.0.1']          // IPs to bypass rate limiting
]);

$config->rateLimitConfig = $rateLimitConfig;
```

## Complete Configuration Example

Here's a comprehensive configuration for a production environment:

```php
<?php

use Sockeon\Sockeon\Config\ServerConfig;
use Sockeon\Sockeon\Config\RateLimitConfig;
use Sockeon\Sockeon\Logging\Logger;

// Create logger
$logger = new Logger();
$logger->setLogLevel('warning'); // Only log warnings and errors in production
$logger->setLogToFile(true);
$logger->setLogDirectory('/var/log/sockeon');
$logger->setLogToConsole(false); // Disable console logging in production

// Create rate limiting config
$rateLimitConfig = new RateLimitConfig([
    'enabled' => true,
    'maxHttpRequestsPerIp' => 1000,
    'httpTimeWindow' => 3600,        // 1 hour
    'maxWebSocketMessagesPerClient' => 500,
    'webSocketTimeWindow' => 60,     // 1 minute
    'maxConnectionsPerIp' => 100,
    'connectionTimeWindow' => 3600,  // 1 hour
    'maxGlobalConnections' => 50000,
    'burstAllowance' => 50,
    'cleanupInterval' => 1800,       // 30 minutes
    'whitelist' => [
        '127.0.0.1',           // Localhost
        '10.0.0.0/8',          // Internal network
        '192.168.1.100'        // Admin IP
    ]
]);

// Create server config
$config = new ServerConfig();
$config->host = '0.0.0.0';
$config->port = 6001;
$config->debug = false;
$config->authKey = $_ENV['SOCKEON_AUTH_KEY'] ?? null;
$config->queueFile = '/tmp/sockeon_queue.json';
$config->logger = $logger;
$config->rateLimitConfig = $rateLimitConfig;

// Production CORS settings
$config->cors = [
    'allowed_origins' => [
        'https://yourdomain.com',
        'https://www.yourdomain.com',
        'https://admin.yourdomain.com'
    ],
    'allowed_methods' => ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    'allowed_headers' => [
        'Content-Type',
        'Authorization',
        'X-Requested-With',
        'X-API-Key'
    ],
    'allow_credentials' => true,
    'max_age' => 3600
];

return $config;
```

## Environment-Specific Configurations

### Development Configuration

```php
$config = new ServerConfig();
$config->host = '127.0.0.1';
$config->port = 6001;
$config->debug = true;

// Permissive CORS for development
$config->cors = [
    'allowed_origins' => ['*'],
    'allowed_methods' => ['*'],
    'allowed_headers' => ['*']
];

// No rate limiting in development
$config->rateLimitConfig = null;
```

### Testing Configuration

```php
$config = new ServerConfig();
$config->host = '127.0.0.1';
$config->port = 0; // Use random available port
$config->debug = true;

// Disable logging in tests
$logger = new Logger();
$logger->setLogToConsole(false);
$logger->setLogToFile(false);
$config->logger = $logger;
```

### Production Configuration

```php
$config = new ServerConfig();
$config->host = '0.0.0.0';
$config->port = (int)($_ENV['SOCKEON_PORT'] ?? 6001);
$config->debug = false;
$config->authKey = $_ENV['SOCKEON_AUTH_KEY'];

// Strict CORS
$config->cors = [
    'allowed_origins' => explode(',', $_ENV['ALLOWED_ORIGINS']),
    'allowed_methods' => ['GET', 'POST', 'PUT', 'DELETE'],
    'allowed_headers' => ['Content-Type', 'Authorization'],
    'allow_credentials' => true
];

// Enable rate limiting
$config->rateLimitConfig = new RateLimitConfig([
    'enabled' => true,
    'maxHttpRequestsPerIp' => 1000,
    'maxWebSocketMessagesPerClient' => 500
]);
```

## Configuration Validation

Sockeon automatically validates configuration during server startup. Common validation errors:

### Invalid Host
```php
$config->host = 'invalid-host'; // Will throw exception
```

### Invalid Port
```php
$config->port = -1;     // Will throw exception
$config->port = 65536;  // Will throw exception
```

### Invalid CORS Configuration
```php
$config->cors = [
    'allowed_origins' => 'invalid' // Should be array
];
```

## Loading Configuration from Files

### JSON Configuration

```json
{
    "host": "0.0.0.0",
    "port": 6001,
    "debug": false,
    "cors": {
        "allowed_origins": ["https://example.com"],
        "allowed_methods": ["GET", "POST"],
        "allowed_headers": ["Content-Type"]
    }
}
```

```php
$configData = json_decode(file_get_contents('config.json'), true);

$config = new ServerConfig();
$config->host = $configData['host'];
$config->port = $configData['port'];
$config->debug = $configData['debug'];
$config->cors = $configData['cors'];
```

### Environment Variables

```php
$config = new ServerConfig();
$config->host = $_ENV['SOCKEON_HOST'] ?? '0.0.0.0';
$config->port = (int)($_ENV['SOCKEON_PORT'] ?? 6001);
$config->debug = filter_var($_ENV['SOCKEON_DEBUG'] ?? false, FILTER_VALIDATE_BOOLEAN);
$config->authKey = $_ENV['SOCKEON_AUTH_KEY'] ?? null;
```

### INI Configuration

```ini
; sockeon.ini
host = 0.0.0.0
port = 6001
debug = false
auth_key = your-secret-key
```

```php
$configData = parse_ini_file('sockeon.ini');

$config = new ServerConfig();
$config->host = $configData['host'];
$config->port = (int)$configData['port'];
$config->debug = filter_var($configData['debug'], FILTER_VALIDATE_BOOLEAN);
$config->authKey = $configData['auth_key'];
```

## Next Steps

- [Controllers](core/controllers.md) - Learn about creating and organizing controllers
- [Middleware](core/middleware.md) - Implement request/response processing
- [Rate Limiting](advanced/rate-limiting.md) - Deep dive into rate limiting
- [Logging](advanced/logging.md) - Advanced logging configuration
