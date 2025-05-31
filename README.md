# WebSocket and Socket Programming in PHP

Welcome to the official Sockeon documentation. Sockeon is a high-performance WebSocket library for PHP that enables real-time bidirectional communication for modern web applications. Perfect for building chat systems, live dashboards, and multiplayer games, Sockeon offers an intuitive API to handle both WebSocket and HTTP connections efficiently.

## Key Features

- **Unified Communication**: Combined WebSocket and HTTP server on a single port
- **Simple Event Handling**: Attribute-based routing for WebSocket events
- **Real-time Messaging**: Efficient bidirectional communication system
- **Advanced Room Management**: Support for channels and private communication
- **Built-in Security**: CORS support and authentication middleware
- **Zero Dependencies**: Built with PHP's native socket extensions

## Installation

```bash
composer require sockeon/sockeon
```

## Quick Start Example

```php
use Sockeon\Sockeon\Core\Server;
use Sockeon\Sockeon\Core\Contracts\SocketController;
use Sockeon\Sockeon\WebSocket\Attributes\SocketOn;
use Sockeon\Sockeon\Http\Attributes\HttpRoute;

class ChatController extends SocketController
{
    // Handle incoming WebSocket messages
    #[SocketOn('message')]
    public function handleMessage(int $clientId, array $data)
    {
        // Broadcast the message to all connected clients
        $this->broadcast('message', [
            'from' => $clientId,
            'text' => $data['text'] ?? ''
        ]);
    }
}

// Create and run the server
$server = new Server("0.0.0.0", 8000);
$server->registerController(new ChatController());
$server->run();
```

## Documentation

Our comprehensive documentation will guide you through building real-time applications with WebSockets:

- [**Getting Started**](/docs/getting-started): Installation and basic setup
- [**WebSocket Architecture**](/docs/core-concepts): Core concepts and implementation details
- [**Code Examples**](/docs/examples): Working examples for common use cases
- [**API Reference**](/docs/api-reference): Complete class and method documentation

## Installation

```bash
composer require sockeon/sockeon
```

## System Requirements

- PHP >= 8.0
- ext-sockets PHP extension

## Resources

- [GitHub Repository](https://github.com/sockeon/sockeon)
