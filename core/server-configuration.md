---
title: "Server Configuration - Sockeon Documentation"
description: "Learn how to configure Sockeon server with host, port, CORS, rate limiting, and authentication settings"
og_image: "https://sockeon.github.io/logo.png"
twitter_image: "https://sockeon.github.io/logo.png"
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

### Message Size and System Controllers

#### maxMessageSize
- **Type**: `int`
- **Default**: `65536` (64KB)
- **Description**: Maximum allowed WebSocket message payload size in bytes
- **Getter**: `getMaxMessageSize()`
- **Setter**: `setMaxMessageSize(int $maxMessageSize)`

```php
// 256KB max incoming WebSocket message
$config->setMaxMessageSize(262144);
```

#### register_system_controllers
- **Type**: `bool`
- **Default**: `true`
- **Description**: Whether Sockeon auto-registers built-in system controllers
- **Getter**: `shouldRegisterSystemControllers()`
- **Setter**: `setRegisterSystemControllers(bool $register)`

```php
// Disable built-in system endpoints/controllers
$config->setRegisterSystemControllers(false);
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
$logger->setMinLogLevel('info');
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

## Reverse Proxy and Load Balancing

Sockeon supports reverse proxy and load balancer configurations through trust proxy settings and health check endpoints.

### trustProxy

- **Type**: `bool|array<int, string>`
- **Default**: `false`
- **Description**: Configure which proxies to trust for X-Forwarded-* headers
- **Getter**: `getTrustProxy()`
- **Setter**: `setTrustProxy(bool|array $trustProxy)`

#### Trust All Proxies (Development Only)

```php
// ⚠️ WARNING: Only use for local development!
$config->setTrustProxy(true);
```

#### Trust Specific IPs (Recommended for Production)

```php
$config->setTrustProxy([
    '127.0.0.1',        // Localhost
    '::1',              // IPv6 localhost
    '10.0.0.0/8',       // Private network (10.0.0.0 - 10.255.255.255)
    '172.16.0.0/12',    // Private network (172.16.0.0 - 172.31.255.255)
    '192.168.0.0/16',   // Private network (192.168.0.0 - 192.168.255.255)
]);
```

#### Trust Specific Proxy IPs

```php
$config->setTrustProxy([
    '10.0.0.5',  // Nginx server 1
    '10.0.0.6',  // Nginx server 2
    '172.16.1.10' // Load balancer
]);
```

**Security Note**: Never use `trust_proxy => true` in production. Always specify trusted proxy IPs to prevent header spoofing attacks.

### proxyHeaders

- **Type**: `array<string, string>|null`
- **Default**: `null`
- **Description**: Custom proxy header names for non-standard configurations
- **Getter**: `getProxyHeaders()`
- **Setter**: `setProxyHeaders(?array $headers)`

```php
$config->setProxyHeaders([
    'proto' => 'X-Forwarded-Proto',  // Protocol header
    'host' => 'X-Forwarded-Host',    // Host header
    'port' => 'X-Forwarded-Port',    // Port header
]);
```

### healthCheckPath

- **Type**: `string|null`
- **Default**: `null`
- **Description**: Enable health check endpoint at the specified path
- **Getter**: `getHealthCheckPath()`
- **Setter**: `setHealthCheckPath(?string $path)`

```php
$config->setHealthCheckPath('/health');
```

When enabled, the health check endpoint returns:

```json
{
  "status": "healthy",
  "timestamp": 1234567890,
  "server": {
    "clients": 5,
    "uptime": 12345,
    "uptime_human": "3h 25m 45s"
  }
}
```

### Via ServerConfig Constructor

```php
use Sockeon\Sockeon\Config\ServerConfig;

$config = new ServerConfig([
    'host' => '0.0.0.0',
    'port' => 6001,
    'trust_proxy' => [
        '127.0.0.1',
        '10.0.0.0/8',
        '192.168.0.0/16',
    ],
    'proxy_headers' => [
        'proto' => 'X-Forwarded-Proto',
        'host' => 'X-Forwarded-Host',
        'port' => 'X-Forwarded-Port',
    ],
    'health_check_path' => '/health',
]);
```

### Complete Reverse Proxy Configuration Example

```php
use Sockeon\Sockeon\Config\ServerConfig;

$config = new ServerConfig([
    'host' => '0.0.0.0',
    'port' => 6001,
    'trust_proxy' => [
        '127.0.0.1',
        '10.0.0.0/8',
        '172.16.0.0/12',
        '192.168.0.0/16',
    ],
    'health_check_path' => '/health',
]);
```

### Nginx Configuration

```nginx
location / {
    proxy_pass http://127.0.0.1:6001;
    proxy_http_version 1.1;
    
    # WebSocket support
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    
    # Forward proxy headers
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-Port $server_port;
}
```

For more details, see the [Reverse Proxy and Load Balancing Guide](/v3.0/advanced/reverse-proxy.md).

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

## Engine Configuration

Sockeon 3.x decouples transport from routing. The engine owns the event loop and socket I/O; controllers and middleware stay the same.

### engine
- **Type**: `string`
- **Default**: `'stream_select'`
- **Values**: `'stream_select'` | `'swoole'`
- **Getter**: `getEngine()`
- **Setter**: `setEngine(string $engine)`

```php
$config = new ServerConfig([
    'engine' => 'stream_select',  // default — no extra extensions
]);

// High concurrency
$config = new ServerConfig([
    'engine' => 'swoole',
]);
```

| Engine | Extension | Typical capacity |
|--------|-----------|-----------------|
| `stream_select` | None (core PHP) | Hundreds to ~2k connections |
| `swoole` | `ext-openswoole` or `ext-swoole` | 10k–500k connections per node |

See [Engines](/v3.0/core/engines.md) for selection guidance.

## Survivability Configuration

Hard connection limits enforced at accept time. Configure under the `survivability` key:

```php
$config = new ServerConfig([
    'survivability' => [
        'max_connections' => 10_000,
        'write_buffer_limit' => 65536,
        'heartbeat_idle_time' => 600,
        'heartbeat_check_interval' => 60,
    ],
]);
```

### Survivability options

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `max_connections` | `int` | `10000` | Hard cap on total connections |
| `write_buffer_limit` | `int` | `65536` | Slow-client threshold (SurvivabilityConfig API) |
| `heartbeat_idle_time` | `int` | `600` | Max idle seconds before disconnect (Swoole) |
| `heartbeat_check_interval` | `int` | `60` | Idle scan interval (Swoole) |

```php
use Sockeon\Sockeon\Config\SurvivabilityConfig;

$survivability = new SurvivabilityConfig(['max_connections' => 50_000]);
$config->setSurvivabilityConfig($survivability);

$config->getSurvivabilityConfig()->getMaxConnections();
```

Align `max_connections` with `rate_limit.maxGlobalConnections` in production. See [Survivability](/v3.0/core/survivability.md).

## Swoole Engine Configuration

Swoole-specific options under the `swoole` key (only used when `engine=swoole`):

```php
$config = new ServerConfig([
    'engine' => 'swoole',
    'swoole' => [
        'worker_num' => 8,
        'task_worker_num' => 0,
        'max_connection' => 100_000,
        'client_table_size' => null,
        'coroutine_dispatch' => true,
    ],
]);
```

### Swoole options

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `worker_num` | `int\|null` | CPU count | Worker process count |
| `task_worker_num` | `int` | `0` | Background task workers |
| `max_connection` | `int` | `100000` | Swoole connection ceiling (effective: `min` with `survivability.max_connections`) |
| `client_table_size` | `int` | auto | `min(131072, max(2048, max_connection + 2048))` |
| `socket_buffer_size` | `int` | auto | 32/64/128 KB tier from `max_connection` |
| `buffer_output_size` | `int` | auto | Defaults to `socket_buffer_size` |
| `memory_limit` | `string\|null` | auto | PHP `memory_limit` at Swoole startup (`2G` / `1G` / scaled) |
| `coroutine_dispatch` | `bool` | `true` | Run handlers in coroutines |

With stock config (`survivability.max_connections=10000`, `swoole.max_connection=100000`), Sockeon accepts at most **10,000** connections. Buffer and memory auto-tuning use the `swoole.max_connection` value, not the effective cap.

```php
use Sockeon\Sockeon\Config\SwooleEngineConfig;

$swoole = new SwooleEngineConfig([
    'worker_num' => 4,
    'max_connection' => 50_000,
    'memory_limit' => '2G',
]);
$config->setSwooleEngineConfig($swoole);

$config->getSwooleEngineConfig()->getWorkerNum();
$config->getSwooleEngineConfig()->getMaxConnection();
$config->getSwooleEngineConfig()->getSocketBufferSize();
$config->getSwooleEngineConfig()->getMemoryLimit();
```

See [Swoole Engine](/v3.0/advanced/swoole-engine.md) for tuning and capacity planning.

## Scale Configuration

Multi-node clustering via Redis pub/sub and shared room registry. Configure under the `scale` key:

```php
$config = new ServerConfig([
    'engine' => 'swoole',
    'scale' => [
        'node_id' => 'node-west-2a',
        'publisher' => 'redis',
        'registry' => 'redis',
        'presence_ttl' => 300,
        'redis' => [
            'host' => '127.0.0.1',
            'port' => 6379,
            'password' => null,
            'database' => 0,
            'channel' => 'sockeon:broadcast',
            'prefix' => 'sockeon:',
        ],
    ],
]);
```

### Scale options

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `node_id` | `string` | `'node-1'` | Unique identifier per server instance |
| `publisher` | `string` | `'local'` | `'local'` or `'redis'` cross-node broadcast |
| `registry` | `string` | `'local'` | `'local'` or `'redis'` shared room membership |
| `presence_ttl` | `int` | `300` | Node presence key TTL in Redis (seconds) |
| `redis` | `array` | see below | Redis connection settings |

### Redis sub-options

| Key | Default | Description |
|-----|---------|-------------|
| `host` | `127.0.0.1` | Redis hostname |
| `port` | `6379` | Redis port |
| `password` | `null` | Optional password |
| `database` | `0` | Redis database index |
| `channel` | `sockeon:broadcast` | Pub/sub channel |
| `prefix` | `sockeon:` | Registry key prefix |

```php
use Sockeon\Sockeon\Config\ScaleConfig;

$scale = new ScaleConfig([
    'node_id' => getenv('SOCKEON_NODE_ID') ?: 'node-1',
    'publisher' => 'redis',
    'registry' => 'redis',
]);
$config->setScaleConfig($scale);

$config->getScaleConfig()->getNodeId();
$config->getScaleConfig()->isRedisPublisher();
```

Requires `ext-redis` when using Redis publisher or registry. See [Scaling and Clustering](/v3.0/advanced/scaling.md).

## Complete Configuration Example

Here's a comprehensive configuration for a production environment:

### Using Constructor with Array

```php
<?php

use Sockeon\Sockeon\Config\ServerConfig;
use Sockeon\Sockeon\Logging\Logger;

// Create logger
$logger = new Logger();
$logger->setMinLogLevel('warning'); // Only log warnings and errors in production
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
    'trust_proxy' => [
        '127.0.0.1',
        '10.0.0.0/8',
        '172.16.0.0/12',
        '192.168.0.0/16',
    ],
    'health_check_path' => '/health',
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
$config->setTrustProxy([
    '127.0.0.1',
    '10.0.0.0/8',
    '172.16.0.0/12',
    '192.168.0.0/16',
]);
$config->setHealthCheckPath('/health');

// Create and set logger
$logger = new Logger();
$logger->setMinLogLevel('warning');
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

// Configure reverse proxy support
$config->setTrustProxy([
    '127.0.0.1',
    '10.0.0.0/8',
    '172.16.0.0/12',
    '192.168.0.0/16',
]);
$config->setHealthCheckPath('/health');

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
    'trust_proxy' => ['127.0.0.1', '::1'], // Trust localhost for development
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
    'trust_proxy' => explode(',', $_ENV['TRUSTED_PROXY_IPS'] ?? '127.0.0.1,10.0.0.0/8'),
    'health_check_path' => $_ENV['HEALTH_CHECK_PATH'] ?? '/health',
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
    "trust_proxy": [
        "127.0.0.1",
        "10.0.0.0/8",
        "192.168.0.0/16"
    ],
    "health_check_path": "/health",
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
    'auth_key' => $_ENV['SOCKEON_AUTH_KEY'] ?? null,
    'trust_proxy' => isset($_ENV['TRUSTED_PROXY_IPS']) ? explode(',', $_ENV['TRUSTED_PROXY_IPS']) : ['127.0.0.1'],
    'health_check_path' => $_ENV['HEALTH_CHECK_PATH'] ?? null
]);

// Or using setters
$config = new ServerConfig();
$config->setHost($_ENV['SOCKEON_HOST'] ?? '0.0.0.0');
$config->setPort((int)($_ENV['SOCKEON_PORT'] ?? 6001));
$config->setDebug(filter_var($_ENV['SOCKEON_DEBUG'] ?? false, FILTER_VALIDATE_BOOLEAN));
$config->setAuthKey($_ENV['SOCKEON_AUTH_KEY'] ?? null);
if (isset($_ENV['TRUSTED_PROXY_IPS'])) {
    $config->setTrustProxy(explode(',', $_ENV['TRUSTED_PROXY_IPS']));
}
if (isset($_ENV['HEALTH_CHECK_PATH'])) {
    $config->setHealthCheckPath($_ENV['HEALTH_CHECK_PATH']);
}
```

### INI Configuration

```ini
; sockeon.ini
host = 0.0.0.0
port = 6001
debug = false
auth_key = your-secret-key
health_check_path = /health
; Note: trust_proxy cannot be set in INI format, use setters or array config
```

```php
use Sockeon\Sockeon\Config\ServerConfig;

$configData = parse_ini_file('sockeon.ini');

$config = new ServerConfig([
    'host' => $configData['host'],
    'port' => (int)$configData['port'],
    'debug' => filter_var($configData['debug'], FILTER_VALIDATE_BOOLEAN),
    'auth_key' => $configData['auth_key'] ?? null,
    'health_check_path' => $configData['health_check_path'] ?? null
]);

// Trust proxy must be set separately if needed
if (isset($configData['trusted_proxy_ips'])) {
    $config->setTrustProxy(explode(',', $configData['trusted_proxy_ips']));
}

// Or using setters
$config = new ServerConfig();
$config->setHost($configData['host']);
$config->setPort((int)$configData['port']);
$config->setDebug(filter_var($configData['debug'], FILTER_VALIDATE_BOOLEAN));
$config->setAuthKey($configData['auth_key'] ?? null);
if (isset($configData['health_check_path'])) {
    $config->setHealthCheckPath($configData['health_check_path']);
}
if (isset($configData['trusted_proxy_ips'])) {
    $config->setTrustProxy(explode(',', $configData['trusted_proxy_ips']));
}
```

## Configuration Summary

### All Available Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `host` | `string` | `'0.0.0.0'` | Server bind address |
| `port` | `int` | `6001` | Server port |
| `debug` | `bool` | `false` | Debug mode |
| `max_message_size` | `int` | `65536` | Max WS message size in bytes |
| `cors` | `CorsConfig` | Auto-created | CORS configuration |
| `logger` | `LoggerInterface\|null` | `null` | Custom logger |
| `queue_file` | `string\|null` | `null` | Queue file path |
| `auth_key` | `string\|null` | `null` | WebSocket auth key |
| `rate_limit` | `RateLimitConfig\|null` | `null` | Rate limiting config |
| `trust_proxy` | `bool\|array<int, string>` | `false` | Trust proxy settings |
| `proxy_headers` | `array<string, string>\|null` | `null` | Custom proxy headers |
| `health_check_path` | `string\|null` | `null` | Health check endpoint |
| `register_system_controllers` | `bool` | `true` | Auto-register built-in system controllers |
| `engine` | `string` | `'stream_select'` | Runtime engine (`stream_select` or `swoole`) |
| `survivability` | `SurvivabilityConfig` | defaults | Hard connection caps and heartbeats |
| `swoole` | `SwooleEngineConfig` | defaults | Swoole worker and connection settings |
| `scale` | `ScaleConfig` | defaults | Multi-node publisher, registry, and Redis |

### All Available Methods

#### Getters
- `getHost()`: Get server host
- `getPort()`: Get server port
- `isDebug()`: Check if debug is enabled
- `getMaxMessageSize()`: Get max message size
- `getCorsConfig()`: Get CORS configuration
- `getLogger()`: Get logger instance
- `getQueueFile()`: Get queue file path
- `getAuthKey()`: Get authentication key
- `getRateLimitConfig()`: Get rate limit configuration
- `getTrustProxy()`: Get trust proxy settings
- `getProxyHeaders()`: Get custom proxy headers
- `getHealthCheckPath()`: Get health check path
- `shouldRegisterSystemControllers()`: Check system controller auto-registration
- `getEngine()`: Get runtime engine name
- `getSurvivabilityConfig()`: Get survivability configuration
- `getSwooleEngineConfig()`: Get Swoole engine configuration
- `getScaleConfig()`: Get scale/cluster configuration

#### Setters
- `setHost(string $host)`: Set server host
- `setPort(int $port)`: Set server port
- `setDebug(bool $debug)`: Enable/disable debug mode
- `setMaxMessageSize(int $maxMessageSize)`: Set max message size
- `setCorsConfig(CorsConfig $config)`: Set CORS configuration
- `setLogger(?LoggerInterface $logger)`: Set custom logger
- `setQueueFile(?string $path)`: Set queue file path
- `setAuthKey(?string $key)`: Set authentication key
- `setRateLimitConfig(?RateLimitConfig $config)`: Set rate limit configuration
- `setTrustProxy(bool\|array $trustProxy)`: Set trust proxy settings
- `setProxyHeaders(?array $headers)`: Set custom proxy headers
- `setHealthCheckPath(?string $path)`: Set health check path
- `setRegisterSystemControllers(bool $register)`: Enable/disable system controller auto-registration
- `setEngine(string $engine)`: Set runtime engine
- `setSurvivabilityConfig(SurvivabilityConfig $config)`: Set survivability configuration
- `setSwooleEngineConfig(SwooleEngineConfig $config)`: Set Swoole engine configuration
- `setScaleConfig(ScaleConfig $config)`: Set scale/cluster configuration

## Next Steps

- [Engines](/v3.0/core/engines.md) - Choose stream_select vs swoole
- [Survivability](/v3.0/core/survivability.md) - Connection caps and heartbeats
- [Swoole Engine](/v3.0/advanced/swoole-engine.md) - High-concurrency tuning
- [Scaling and Clustering](/v3.0/advanced/scaling.md) - Multi-node Redis deployment
- [Controllers](/v3.0/core/controllers.md) - Learn about creating and organizing controllers
- [Middleware](/v3.0/core/middleware.md) - Implement request/response processing
- [Rate Limiting](/v3.0/advanced/rate-limiting.md) - Deep dive into rate limiting
- [Logging](/v3.0/advanced/logging.md) - Advanced logging configuration
- [Reverse Proxy and Load Balancing](/v3.0/advanced/reverse-proxy.md) - Complete reverse proxy guide
