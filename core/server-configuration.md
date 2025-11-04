---
title: "Server Configuration - Sockeon Documentation"
description: "Learn how to configure Sockeon server with host, port, CORS, rate limiting, and authentication settings"
og_image: "https://sockeon.com/assets/logo.png"
twitter_image: "https://sockeon.com/assets/logo.png"
---

# Server Configuration

The `ServerConfig` class provides comprehensive configuration options for your Sockeon server. This guide covers all available settings and their use cases.

## Basic Configuration

### Using Constructor with Array

```php
use Sockeon\Sockeon\Config\ServerConfig;

$config = new ServerConfig([
    'host' => '0.0.0.0',
    'port' => 6001,
    'debug' => false
]);
```

### Using Setters

```php
use Sockeon\Sockeon\Config\ServerConfig;

$config = new ServerConfig();
$config->setHost('0.0.0.0');
$config->setPort(6001);
$config->setDebug(false);
```

## Configuration Properties

### Network Settings

#### host
- **Type**: `string`
- **Default**: `'0.0.0.0'`
- **Description**: The IP address the server will bind to
- **Getter**: `getHost()`
- **Setter**: `setHost(string $host)`

```php
$config->setHost('127.0.0.1');     // Localhost only
$config->setHost('0.0.0.0');       // All interfaces (default)
$config->setHost('192.168.1.100'); // Specific IP

// Get the configured host
$host = $config->getHost();
```

#### port
- **Type**: `int`
- **Default**: `6001`
- **Description**: The port number the server will listen on
- **Getter**: `getPort()`
- **Setter**: `setPort(int $port)`

```php
$config->setPort(8080);   // HTTP alternative port
$config->setPort(6001);   // Default
$config->setPort(443);    // HTTPS (requires appropriate setup)

// Get the configured port
$port = $config->getPort();
```

### Debug Settings

#### debug
- **Type**: `bool`
- **Default**: `false`
- **Description**: Enable or disable debug mode for detailed logging
- **Getter**: `isDebug()`
- **Setter**: `setDebug(bool $debug)`

```php
$config->setDebug(true);   // Enable debug logging
$config->setDebug(false);  // Production mode (default)

// Check if debug is enabled
if ($config->isDebug()) {
    // Debug mode is enabled
}
```

## CORS Configuration

Configure Cross-Origin Resource Sharing for HTTP requests using the `CorsConfig` class:

### Using Constructor with Array

```php
use Sockeon\Sockeon\Config\CorsConfig;

$corsConfig = new CorsConfig([
    'allowed_origins' => ['*'],  // Allow all origins
    'allowed_methods' => ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    'allowed_headers' => ['Content-Type', 'Authorization'],
    'allow_credentials' => false,
    'max_age' => 86400
]);

$config->setCorsConfig($corsConfig);
```

### Using Setters

```php
use Sockeon\Sockeon\Config\CorsConfig;

$corsConfig = new CorsConfig();
$corsConfig->setAllowedOrigins(['*']);
$corsConfig->setAllowedMethods(['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']);
$corsConfig->setAllowedHeaders(['Content-Type', 'Authorization']);
$corsConfig->setAllowCredentials(false);
$corsConfig->setMaxAge(86400);

$config->setCorsConfig($corsConfig);
```

### Via ServerConfig Constructor

```php
use Sockeon\Sockeon\Config\ServerConfig;

$config = new ServerConfig([
    'host' => '0.0.0.0',
    'port' => 6001,
    'cors' => [
        'allowed_origins' => ['*'],
        'allowed_methods' => ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
        'allowed_headers' => ['Content-Type', 'Authorization'],
        'allow_credentials' => false,
        'max_age' => 86400
    ]
]);
```

### CORS Configuration Methods

#### Getters
- `getAllowedOrigins()`: Get allowed origin URLs
- `getAllowedMethods()`: Get allowed HTTP methods
- `getAllowedHeaders()`: Get allowed headers
- `isCredentialsAllowed()`: Check if credentials are allowed
- `getMaxAge()`: Get max age for preflight cache
- `isOriginAllowed(string $origin)`: Check if a specific origin is allowed

#### Setters
- `setAllowedOrigins(array $origins)`: Set allowed origins
- `setAllowedMethods(array $methods)`: Set allowed HTTP methods
- `setAllowedHeaders(array $headers)`: Set allowed headers
- `setAllowCredentials(bool $allow)`: Enable/disable credentials
- `setMaxAge(int $seconds)`: Set max age for preflight cache

### CORS Options

- **allowed_origins**: Array of allowed origin URLs or `['*']` for all
- **allowed_methods**: HTTP methods to allow
- **allowed_headers**: Headers that can be used during the actual request
- **allow_credentials**: Whether to allow credentials (cookies, authorization headers)
- **max_age**: How long the browser should cache preflight responses (seconds)

### Examples

```php
use Sockeon\Sockeon\Config\CorsConfig;

// Development - Allow everything
$corsConfig = new CorsConfig([
    'allowed_origins' => ['*'],
    'allowed_methods' => ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH', 'HEAD'],
    'allowed_headers' => ['*']
]);
$config->setCorsConfig($corsConfig);

// Production - Restrict to specific domains
$corsConfig = new CorsConfig();
$corsConfig->setAllowedOrigins([
    'https://myapp.com',
    'https://www.myapp.com',
    'https://admin.myapp.com'
]);
$corsConfig->setAllowedMethods(['GET', 'POST', 'PUT', 'DELETE']);
$corsConfig->setAllowedHeaders(['Content-Type', 'Authorization', 'X-Requested-With']);
$corsConfig->setAllowCredentials(true);
$corsConfig->setMaxAge(3600);
$config->setCorsConfig($corsConfig);

// Check if origin is allowed
if ($corsConfig->isOriginAllowed('https://myapp.com')) {
    // Origin is allowed
}
```

## Authentication

### authKey
- **Type**: `string|null`
- **Default**: `null`
- **Description**: Optional authentication key for securing WebSocket connections
- **Getter**: `getAuthKey()`
- **Setter**: `setAuthKey(?string $key)`

```php
$config->setAuthKey('your-secret-key');

// Get the auth key
$key = $config->getAuthKey();
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
- **Getter**: `getLogger()`
- **Setter**: `setLogger(?LoggerInterface $logger)`

```php
use Sockeon\Sockeon\Logging\Logger;

$logger = new Logger();
$logger->setLogLevel('info');
$logger->setLogToFile(true);
$logger->setLogDirectory('/var/log/sockeon');

$config->setLogger($logger);

// Get the logger
$logger = $config->getLogger();
```

## Queue Configuration

### queueFile
- **Type**: `string|null`
- **Default**: `null`
- **Description**: Optional path to queue file for message persistence
- **Getter**: `getQueueFile()`
- **Setter**: `setQueueFile(?string $path)`

```php
$config->setQueueFile('/tmp/sockeon_queue.json');

// Get the queue file path
$queueFile = $config->getQueueFile();
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
- **Getter**: `getRateLimitConfig()`
- **Setter**: `setRateLimitConfig(?RateLimitConfig $config)`

### Using Constructor with Array

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

$config->setRateLimitConfig($rateLimitConfig);
```

### Using Setters

```php
use Sockeon\Sockeon\Config\RateLimitConfig;

$rateLimitConfig = new RateLimitConfig();
$rateLimitConfig->setEnabled(true);
$rateLimitConfig->setMaxHttpRequestsPerIp(100);
$rateLimitConfig->setHttpTimeWindow(60);
$rateLimitConfig->setMaxWebSocketMessagesPerClient(200);
$rateLimitConfig->setWebSocketTimeWindow(60);
$rateLimitConfig->setMaxConnectionsPerIp(50);
$rateLimitConfig->setConnectionTimeWindow(60);
$rateLimitConfig->setMaxGlobalConnections(10000);
$rateLimitConfig->setBurstAllowance(10);
$rateLimitConfig->setCleanupInterval(300);
$rateLimitConfig->setWhitelist(['127.0.0.1']);

$config->setRateLimitConfig($rateLimitConfig);
```

### RateLimitConfig Methods

#### Getters
- `isEnabled()`: Check if rate limiting is enabled
- `getMaxHttpRequestsPerIp()`: Get max HTTP requests per IP
- `getHttpTimeWindow()`: Get HTTP time window in seconds
- `getMaxWebSocketMessagesPerClient()`: Get max WebSocket messages per client
- `getWebSocketTimeWindow()`: Get WebSocket time window in seconds
- `getMaxConnectionsPerIp()`: Get max connections per IP
- `getConnectionTimeWindow()`: Get connection time window in seconds
- `getMaxGlobalConnections()`: Get max global connections
- `getBurstAllowance()`: Get burst allowance
- `getCleanupInterval()`: Get cleanup interval in seconds
- `getWhitelist()`: Get whitelisted IPs
- `isWhitelisted(string $ip)`: Check if an IP is whitelisted

#### Setters
- `setEnabled(bool $enabled)`: Enable or disable rate limiting
- `setMaxHttpRequestsPerIp(int $max)`: Set max HTTP requests per IP
- `setHttpTimeWindow(int $seconds)`: Set HTTP time window
- `setMaxWebSocketMessagesPerClient(int $max)`: Set max WebSocket messages per client
- `setWebSocketTimeWindow(int $seconds)`: Set WebSocket time window
- `setMaxConnectionsPerIp(int $max)`: Set max connections per IP
- `setConnectionTimeWindow(int $seconds)`: Set connection time window
- `setMaxGlobalConnections(int $max)`: Set max global connections
- `setBurstAllowance(int $allowance)`: Set burst allowance
- `setCleanupInterval(int $seconds)`: Set cleanup interval
- `setWhitelist(array $ips)`: Set whitelisted IPs
- `addToWhitelist(string $ip)`: Add an IP to whitelist
- `removeFromWhitelist(string $ip)`: Remove an IP from whitelist

### Via ServerConfig Constructor

```php
use Sockeon\Sockeon\Config\ServerConfig;

$config = new ServerConfig([
    'host' => '0.0.0.0',
    'port' => 6001,
    'rate_limit' => [
        'enabled' => true,
        'maxHttpRequestsPerIp' => 100,
        'httpTimeWindow' => 60,
        'maxWebSocketMessagesPerClient' => 200,
        'webSocketTimeWindow' => 60
    ]
]);
```

## Complete Configuration Example

Here's a comprehensive configuration for a production environment:

### Using Constructor with Array

```php
<?php

use Sockeon\Sockeon\Config\ServerConfig;
use Sockeon\Sockeon\Logging\Logger;

// Create logger
$logger = new Logger();
$logger->setLogLevel('warning'); // Only log warnings and errors in production
$logger->setLogToFile(true);
$logger->setLogDirectory('/var/log/sockeon');
$logger->setLogToConsole(false); // Disable console logging in production

// Create server config with all settings
$config = new ServerConfig([
    'host' => '0.0.0.0',
    'port' => 6001,
    'debug' => false,
    'auth_key' => $_ENV['SOCKEON_AUTH_KEY'] ?? null,
    'queue_file' => '/tmp/sockeon_queue.json',
    'cors' => [
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
    ],
    'rate_limit' => [
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
    ]
]);

// Set the custom logger
$config->setLogger($logger);

return $config;
```

### Using Setters

```php
<?php

use Sockeon\Sockeon\Config\ServerConfig;
use Sockeon\Sockeon\Config\CorsConfig;
use Sockeon\Sockeon\Config\RateLimitConfig;
use Sockeon\Sockeon\Logging\Logger;

// Create server config
$config = new ServerConfig();
$config->setHost('0.0.0.0');
$config->setPort(6001);
$config->setDebug(false);
$config->setAuthKey($_ENV['SOCKEON_AUTH_KEY'] ?? null);
$config->setQueueFile('/tmp/sockeon_queue.json');

// Create and set logger
$logger = new Logger();
$logger->setLogLevel('warning');
$logger->setLogToFile(true);
$logger->setLogDirectory('/var/log/sockeon');
$logger->setLogToConsole(false);
$config->setLogger($logger);

// Create and set CORS config
$corsConfig = new CorsConfig();
$corsConfig->setAllowedOrigins([
    'https://yourdomain.com',
    'https://www.yourdomain.com',
    'https://admin.yourdomain.com'
]);
$corsConfig->setAllowedMethods(['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']);
$corsConfig->setAllowedHeaders(['Content-Type', 'Authorization', 'X-Requested-With', 'X-API-Key']);
$corsConfig->setAllowCredentials(true);
$corsConfig->setMaxAge(3600);
$config->setCorsConfig($corsConfig);

// Create and set rate limit config
$rateLimitConfig = new RateLimitConfig();
$rateLimitConfig->setEnabled(true);
$rateLimitConfig->setMaxHttpRequestsPerIp(1000);
$rateLimitConfig->setHttpTimeWindow(3600);
$rateLimitConfig->setMaxWebSocketMessagesPerClient(500);
$rateLimitConfig->setWebSocketTimeWindow(60);
$rateLimitConfig->setMaxConnectionsPerIp(100);
$rateLimitConfig->setConnectionTimeWindow(3600);
$rateLimitConfig->setMaxGlobalConnections(50000);
$rateLimitConfig->setBurstAllowance(50);
$rateLimitConfig->setCleanupInterval(1800);
$rateLimitConfig->setWhitelist(['127.0.0.1', '10.0.0.0/8', '192.168.1.100']);
$config->setRateLimitConfig($rateLimitConfig);

return $config;
```

## Environment-Specific Configurations

### Development Configuration

```php
use Sockeon\Sockeon\Config\ServerConfig;
use Sockeon\Sockeon\Config\CorsConfig;

$config = new ServerConfig([
    'host' => '127.0.0.1',
    'port' => 6001,
    'debug' => true,
    'cors' => [
        'allowed_origins' => ['*'],
        'allowed_methods' => ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH', 'HEAD'],
        'allowed_headers' => ['*']
    ]
]);

// No rate limiting in development
$config->setRateLimitConfig(null);
```

### Testing Configuration

```php
use Sockeon\Sockeon\Config\ServerConfig;
use Sockeon\Sockeon\Logging\Logger;

$logger = new Logger();
$logger->setLogToConsole(false);
$logger->setLogToFile(false);

$config = new ServerConfig([
    'host' => '127.0.0.1',
    'port' => 0, // Use random available port
    'debug' => true
]);

$config->setLogger($logger);
```

### Production Configuration

```php
use Sockeon\Sockeon\Config\ServerConfig;
use Sockeon\Sockeon\Config\RateLimitConfig;

$config = new ServerConfig([
    'host' => '0.0.0.0',
    'port' => (int)($_ENV['SOCKEON_PORT'] ?? 6001),
    'debug' => false,
    'auth_key' => $_ENV['SOCKEON_AUTH_KEY'],
    'cors' => [
        'allowed_origins' => explode(',', $_ENV['ALLOWED_ORIGINS']),
        'allowed_methods' => ['GET', 'POST', 'PUT', 'DELETE'],
        'allowed_headers' => ['Content-Type', 'Authorization'],
        'allow_credentials' => true
    ],
    'rate_limit' => [
        'enabled' => true,
        'maxHttpRequestsPerIp' => 1000,
        'maxWebSocketMessagesPerClient' => 500
    ]
]);
```

## Configuration Validation

Sockeon automatically validates configuration during server startup. The configuration classes handle type validation automatically.

### Type Safety

All configuration methods use type hints to ensure valid data:

```php
// These will cause PHP type errors
$config->setPort('invalid');        // TypeError: must be int
$config->setDebug('invalid');       // TypeError: must be bool
$config->setHost(123);              // TypeError: must be string

// Correct usage
$config->setPort(6001);
$config->setDebug(true);
$config->setHost('0.0.0.0');
```

### Validation Examples

```php
use Sockeon\Sockeon\Config\ServerConfig;
use Sockeon\Sockeon\Config\CorsConfig;

// Valid configuration
$config = new ServerConfig([
    'port' => 6001,
    'host' => '0.0.0.0'
]);

// Constructor handles type conversion for numeric values
$config = new ServerConfig([
    'port' => '6001',  // Will be converted to int
    'debug' => 1       // Will be converted to bool
]);

// CORS configuration is validated
$corsConfig = new CorsConfig([
    'allowed_origins' => ['https://example.com'],  // Valid array
    'max_age' => 3600                               // Valid int
]);
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
    },
    "rate_limit": {
        "enabled": true,
        "maxHttpRequestsPerIp": 100,
        "httpTimeWindow": 60
    }
}
```

```php
use Sockeon\Sockeon\Config\ServerConfig;

$configData = json_decode(file_get_contents('config.json'), true);

// Option 1: Pass entire config to constructor
$config = new ServerConfig($configData);

// Option 2: Use setters
$config = new ServerConfig();
$config->setHost($configData['host']);
$config->setPort($configData['port']);
$config->setDebug($configData['debug']);

if (isset($configData['cors'])) {
    $corsConfig = new \Sockeon\Sockeon\Config\CorsConfig($configData['cors']);
    $config->setCorsConfig($corsConfig);
}
```

### Environment Variables

```php
use Sockeon\Sockeon\Config\ServerConfig;

$config = new ServerConfig([
    'host' => $_ENV['SOCKEON_HOST'] ?? '0.0.0.0',
    'port' => (int)($_ENV['SOCKEON_PORT'] ?? 6001),
    'debug' => filter_var($_ENV['SOCKEON_DEBUG'] ?? false, FILTER_VALIDATE_BOOLEAN),
    'auth_key' => $_ENV['SOCKEON_AUTH_KEY'] ?? null
]);

// Or using setters
$config = new ServerConfig();
$config->setHost($_ENV['SOCKEON_HOST'] ?? '0.0.0.0');
$config->setPort((int)($_ENV['SOCKEON_PORT'] ?? 6001));
$config->setDebug(filter_var($_ENV['SOCKEON_DEBUG'] ?? false, FILTER_VALIDATE_BOOLEAN));
$config->setAuthKey($_ENV['SOCKEON_AUTH_KEY'] ?? null);
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
use Sockeon\Sockeon\Config\ServerConfig;

$configData = parse_ini_file('sockeon.ini');

$config = new ServerConfig([
    'host' => $configData['host'],
    'port' => (int)$configData['port'],
    'debug' => filter_var($configData['debug'], FILTER_VALIDATE_BOOLEAN),
    'auth_key' => $configData['auth_key']
]);

// Or using setters
$config = new ServerConfig();
$config->setHost($configData['host']);
$config->setPort((int)$configData['port']);
$config->setDebug(filter_var($configData['debug'], FILTER_VALIDATE_BOOLEAN));
$config->setAuthKey($configData['auth_key']);
```

## Next Steps

- [Controllers](core/controllers.md) - Learn about creating and organizing controllers
- [Middleware](core/middleware.md) - Implement request/response processing
- [Rate Limiting](advanced/rate-limiting.md) - Deep dive into rate limiting
- [Logging](advanced/logging.md) - Advanced logging configuration
