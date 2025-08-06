---
title: "WebSocket Client - Sockeon Documentation"
description: "Learn how to create WebSocket clients to connect to Sockeon servers using PHP"
og_image: "https://sockeon.com/assets/logo.png"
twitter_image: "https://sockeon.com/assets/logo.png"
---

# WebSocket Client

Learn how to use Sockeon's built-in PHP WebSocket client to connect to WebSocket servers.

## Basic Client Usage

```php
use Sockeon\Sockeon\Connection\Client;

// Create and connect to WebSocket server
$client = new Client('localhost', 8080);

// Connect to server
$client->connect();

// Send a message
$client->emit('hello', ['message' => 'Hello from PHP client!']);

// Listen for messages
$client->on('message', function($data) {
    echo "Received: " . json_encode($data) . "\n";
});

// Keep connection alive
$client->run();

// Close connection
$client->disconnect();
```

## Client Configuration

### Connection Options

```php
use Sockeon\Sockeon\Connection\Client;

// Create client with host and port
$client = new Client('localhost', 8080);

// Connect with optional headers
$client->connect([
    'Authorization' => 'Bearer your-token',
    'User-Agent' => 'Sockeon-Client/1.0'
]);
```

### Authentication

```php
// Connect with authentication key
$client = new Client('localhost', 8080, '/?key=your-secret-key');
$client->connect();
```

## Sending Messages

### Basic Message Sending

```php
$client = new Client('localhost', 8080);
$client->connect();

// Send simple message
$client->emit('ping');

// Send message with data
$client->emit('user_message', [
    'user' => 'john_doe',
    'message' => 'Hello everyone!',
    'timestamp' => time()
]);
```

## Receiving Messages

### Event Handlers

```php
$client = new Client('localhost', 8080);
$client->connect();

// Handle different event types
$client->on('welcome', function($data) {
    echo "Welcome message: " . $data['message'] . "\n";
});

$client->on('chat.message', function($data) {
    echo "Chat message from {$data['from']}: {$data['message']}\n";
});

$client->on('user.connected', function($data) {
    echo "User {$data['clientId']} connected\n";
});

$client->on('error', function($data) {
    echo "Error: " . $data['message'] . "\n";
});

// Start listening
$client->run();
```

## Connection Management

### Connection States

```php
$client = new Client('localhost', 8080);

// Check connection status
if ($client->isConnected()) {
    echo "Connected to server\n";
} else {
    echo "Not connected\n";
}

// Connect if not connected
if (!$client->isConnected()) {
    $client->connect();
}
```

### Error Handling

```php
$client = new Client('localhost', 8080);

try {
    $client->connect();
    echo "Connected successfully\n";
} catch (Exception $e) {
    echo "Connection failed: " . $e->getMessage() . "\n";
}

// Handle connection errors
$client->on('error', function($data) {
    echo "Connection error: " . $data['message'] . "\n";
});
```

## Complete Example

```php
<?php

require_once 'vendor/autoload.php';

use Sockeon\Sockeon\Connection\Client;

// Create client
$client = new Client('localhost', 8080);

// Set up event handlers
$client->on('welcome', function($data) {
    echo "Welcome: {$data['message']}\n";
});

$client->on('chat.message', function($data) {
    echo "Chat: {$data['message']}\n";
});

$client->on('error', function($data) {
    echo "Error: {$data['message']}\n";
});

// Connect to server
try {
    $client->connect();
    echo "Connected to server\n";
    
    // Send a message
    $client->emit('chat.message', [
        'message' => 'Hello from PHP client!'
    ]);
    
    // Keep connection alive
    $client->run();
    
} catch (Exception $e) {
    echo "Failed to connect: " . $e->getMessage() . "\n";
}
```
