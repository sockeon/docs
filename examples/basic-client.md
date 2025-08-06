---
title: "Basic WebSocket Client Example - Sockeon Documentation"
description: "Complete example of a basic WebSocket client using Sockeon framework to connect to servers"
og_image: "https://sockeon.com/assets/logo.png"
twitter_image: "https://sockeon.com/assets/logo.png"
---

# Basic WebSocket Client Example

A simple PHP WebSocket client that connects to the chat server.

## Client Code

```php
<?php

require_once __DIR__ . '/../vendor/autoload.php';

use Sockeon\Sockeon\Connection\Client;

// Create client
$client = new Client('localhost', 8080);

// Set up event handlers
$client->on('welcome', function($data) {
    echo "Welcome: {$data['message']}\n";
    echo "Your client ID: {$data['clientId']}\n";
});

$client->on('chat.message', function($data) {
    echo "[{$data['from']}]: {$data['message']}\n";
});

$client->on('user.connected', function($data) {
    echo "{$data['message']}\n";
});

$client->on('user.disconnected', function($data) {
    echo "{$data['message']}\n";
});

$client->on('user.typing', function($data) {
    if ($data['typing']) {
        echo "User {$data['clientId']} is typing...\n";
    }
});

$client->on('error', function($data) {
    echo "Error: {$data['message']}\n";
});

// Connect to server
try {
    $client->connect();
    echo "Connected to WebSocket server\n";
    
    // Send a message
    $client->emit('chat.message', [
        'message' => 'Hello from PHP client!'
    ]);
    
    // Keep connection alive and listen for messages
    $client->run();
    
} catch (Exception $e) {
    echo "Failed to connect: " . $e->getMessage() . "\n";
}
```

## How to Run

1. Make sure the WebSocket server is running first
2. Save the code as `client.php`
3. Run the client:
   ```bash
   php client.php
   ```

## Features

- **Event Handling**: Listens for various server events
- **Message Sending**: Sends chat messages to the server
- **Connection Management**: Handles connection and disconnection
- **Error Handling**: Catches and displays connection errors

## Server Events Handled

- `welcome` - Welcome message from server
- `chat.message` - Chat messages from other users
- `user.connected` - When a new user joins
- `user.disconnected` - When a user leaves
- `user.typing` - Typing indicators
- `error` - Error messages from server

## Usage

The client will:
1. Connect to the WebSocket server
2. Send an initial "Hello" message
3. Listen for incoming messages
4. Display all chat activity in the console 