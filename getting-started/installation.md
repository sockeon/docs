---
title: "Installation - Sockeon Documentation"
description: "Learn how to install Sockeon PHP WebSocket and HTTP server framework with Composer"
og_image: "https://sockeon.github.io/logo.png"
twitter_image: "https://sockeon.github.io/logo.png"
---

# Installation

## Requirements

Before installing Sockeon, ensure your system meets the following requirements:

- **PHP >= 8.3**
- **ext-openssl** - Required for secure WebSocket connections
- **ext-sockets** - Required for socket operations

### Optional Extensions

For high-concurrency and multi-node deployments:

- **ext-openswoole** (or ext-swoole) — enables `engine=swoole` for tens of thousands of concurrent WebSocket connections per node. See [Engines](/v3.0/core/engines.md).
- **ext-redis** — enables Redis-backed pub/sub and room registry for multi-node clusters. See [Scaling and Clustering](/v3.0/advanced/scaling.md).

Composer lists both as **suggested** dependencies — they are not installed by default:

```bash
# High-concurrency single node
pecl install openswoole

# Multi-node cluster
pecl install openswoole redis
```

Upgrading from Sockeon 2.x? See the [Migration Guide](/v3.0/getting-started/migration-v3.md).

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
$config = new ServerConfig([
    'host' => '127.0.0.1',
    'port' => 6001,
    'debug' => true
]);

// Create the server instance
$server = new Server($config);

$host = $config->getHost();
$port = $config->getPort();

echo "Sockeon server created successfully!\n";
echo "Server configured for {$host}:{$port}\n";
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

- [Quick Start Guide](/v3.0/getting-started/quick-start.md) - Build your first Sockeon application
- [Basic Concepts](/v3.0/getting-started/basic-concepts.md) - Learn the core concepts
- [Engines](/v3.0/core/engines.md) - Choose stream_select or swoole
- [Migrating to 3.x](/v3.0/getting-started/migration-v3.md) - Upgrade from Sockeon 2.x
- [Server Configuration](/v3.0/core/server-configuration.md) - Detailed configuration options
