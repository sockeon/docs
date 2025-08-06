---
title: "Installation - Sockeon Documentation"
description: "Learn how to install Sockeon PHP WebSocket and HTTP server framework with Composer"
og_image: "https://sockeon.com/assets/logo.png"
twitter_image: "https://sockeon.com/assets/logo.png"
---

# Installation

## Requirements

Before installing Sockeon, ensure your system meets the following requirements:

- **PHP >= 8.0**
- **ext-openssl** - Required for secure WebSocket connections
- **ext-sockets** - Required for socket operations

## Installation via Composer

The recommended way to install Sockeon is through Composer:

```bash
composer require sockeon/sockeon
```

## Manual Installation

If you prefer to install manually, you can download the source code and include the autoloader:

```php
<?php
require_once 'path/to/sockeon/vendor/autoload.php';
```

## Verifying Installation

Create a simple test file to verify the installation:

```php
<?php
require_once 'vendor/autoload.php';

use Sockeon\Sockeon\Config\ServerConfig;
use Sockeon\Sockeon\Connection\Server;

// Create a basic server configuration
$config = new ServerConfig();
$config->host = '127.0.0.1';
$config->port = 6001;
$config->debug = true;

// Create the server instance
$server = new Server($config);

echo "Sockeon server created successfully!\n";
echo "Server configured for {$config->host}:{$config->port}\n";
```

Run the test:

```bash
php test.php
```

If you see the success message, Sockeon is properly installed!

## Development Dependencies

For development and testing, you may want to install additional dependencies:

```bash
composer install --dev
```

This will install:
- **pestphp/pest** - Testing framework
- **phpstan/phpstan** - Static analysis tool

## System Configuration

### PHP Configuration

Ensure the following PHP extensions are enabled in your `php.ini`:

```ini
extension=openssl
extension=sockets
```

### Memory Limits

For production use, consider increasing PHP memory limits:

```ini
memory_limit = 512M
```

### Socket Limits

On Linux systems, you may need to increase socket limits for high-concurrency applications:

```bash
# Temporary increase
ulimit -n 65536

# Permanent increase (add to /etc/security/limits.conf)
* soft nofile 65536
* hard nofile 65536
```

## Next Steps

- [Quick Start Guide](getting-started/quick-start.md) - Build your first Sockeon application
- [Basic Concepts](getting-started/basic-concepts.md) - Learn the core concepts
- [Server Configuration](core/server-configuration.md) - Detailed configuration options
