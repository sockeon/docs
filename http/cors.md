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

### Using Constructor with Array

```php
use Sockeon\Sockeon\Config\ServerConfig;
use Sockeon\Sockeon\Config\CorsConfig;
use Sockeon\Sockeon\Connection\Server;

// Create CORS configuration
$corsConfig = new CorsConfig([
    'allowed_origins' => ['https://example.com', 'https://app.example.com'],
    'allowed_methods' => ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    'allowed_headers' => ['Content-Type', 'Authorization', 'X-Requested-With'],
    'allow_credentials' => true,
    'max_age' => 86400 // 24 hours
]);

// Create server configuration with CORS
$config = new ServerConfig();
$config->setCorsConfig($corsConfig);

// Create server with CORS configuration
$server = new Server($config);
$server->run();
```

### Using Setters

```php
use Sockeon\Sockeon\Config\CorsConfig;

$corsConfig = new CorsConfig();
$corsConfig->setAllowedOrigins(['https://example.com', 'https://app.example.com']);
$corsConfig->setAllowedMethods(['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']);
$corsConfig->setAllowedHeaders(['Content-Type', 'Authorization', 'X-Requested-With']);
$corsConfig->setAllowCredentials(true);
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
        'allowed_origins' => ['https://example.com', 'https://app.example.com'],
        'allowed_methods' => ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
        'allowed_headers' => ['Content-Type', 'Authorization', 'X-Requested-With'],
        'allow_credentials' => true,
        'max_age' => 86400
    ]
]);
```

## Configuration Options

### Allowed Origins

```php
use Sockeon\Sockeon\Config\CorsConfig;

// Allow all origins (not recommended for production)
$corsConfig = new CorsConfig([
    'allowed_origins' => ['*']
]);

// Allow specific origins
$corsConfig = new CorsConfig([
    'allowed_origins' => [
        'https://example.com',
        'https://app.example.com'
    ]
]);

// Or using setters
$corsConfig = new CorsConfig();
$corsConfig->setAllowedOrigins(['https://example.com', 'https://app.example.com']);

// Check if an origin is allowed
if ($corsConfig->isOriginAllowed('https://example.com')) {
    // Origin is allowed
}
```

### HTTP Methods

```php
$corsConfig = new CorsConfig([
    'allowed_methods' => ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']
]);

// Or using setter
$corsConfig->setAllowedMethods(['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']);

// Get allowed methods
$methods = $corsConfig->getAllowedMethods();
```

### Headers

```php
$corsConfig = new CorsConfig([
    'allowed_headers' => [
        'Content-Type',
        'Authorization',
        'X-Requested-With'
    ]
]);

// Or using setter
$corsConfig->setAllowedHeaders([
    'Content-Type',
    'Authorization',
    'X-Requested-With'
]);

// Get allowed headers
$headers = $corsConfig->getAllowedHeaders();
```

### Credentials and Caching

```php
$corsConfig = new CorsConfig([
    'allow_credentials' => true,
    'max_age' => 86400 // 24 hours
]);

// Or using setters
$corsConfig->setAllowCredentials(true);
$corsConfig->setMaxAge(86400);

// Check if credentials are allowed
if ($corsConfig->isCredentialsAllowed()) {
    // Credentials are allowed
}

// Get max age
$maxAge = $corsConfig->getMaxAge();
``` 