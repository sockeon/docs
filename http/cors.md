---
title: "CORS Configuration - Sockeon Documentation"
description: "Learn how to configure CORS (Cross-Origin Resource Sharing) in Sockeon framework"
og_image: "https://sockeon.com/assets/logo.png"
twitter_image: "https://sockeon.com/assets/logo.png"
---

# CORS Configuration

Learn how to configure Cross-Origin Resource Sharing (CORS) in Sockeon.

## Overview

CORS is handled automatically by the framework based on the configuration in `ServerConfig`. No middleware or manual handling is required.

## Basic Configuration

```php
use Sockeon\Sockeon\Config\ServerConfig;
use Sockeon\Sockeon\Connection\Server;

// Create server configuration with CORS
$config = new ServerConfig();
$config->cors = [
    'allowed_origins' => ['https://example.com', 'https://app.example.com'],
    'allowed_methods' => ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    'allowed_headers' => ['Content-Type', 'Authorization', 'X-Requested-With'],
    'exposed_headers' => ['X-Total-Count', 'X-Page-Count'],
    'allow_credentials' => true,
    'max_age' => 86400 // 24 hours
];

// Create server with CORS configuration
$server = new Server($config);
$server->run();
```

## Configuration Options

### Allowed Origins

```php
// Allow all origins (not recommended for production)
$config->cors = [
    'allowed_origins' => ['*']
];

// Allow specific origins
$config->cors = [
    'allowed_origins' => [
        'https://example.com',
        'https://app.example.com'
    ]
];
```

### HTTP Methods

```php
$config->cors = [
    'allowed_methods' => ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']
];
```

### Headers

```php
$config->cors = [
    'allowed_headers' => [
        'Content-Type',
        'Authorization',
        'X-Requested-With'
    ],
    'exposed_headers' => [
        'X-Total-Count',
        'X-Page-Count'
    ]
];
```

### Credentials and Caching

```php
$config->cors = [
    'allow_credentials' => true,
    'max_age' => 86400 // 24 hours
];
``` 