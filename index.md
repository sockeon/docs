# Sockeon

Welcome to the official Sockeon documentation. Sockeon is a high-performance, framework-agnostic PHP WebSocket and HTTP server library designed for modern applications requiring real-time communication capabilities. It offers attribute-based routing and powerful namespace and room management features.

## Features

- WebSocket and HTTP combined server
- Attribute-based routing for both WebSocket events and HTTP endpoints
- Advanced HTTP request and response handling
- Path parameters and query parameter support
- RESTful API support with content negotiation
- Namespaces and rooms support for WebSocket communication
- Middleware support for authentication and request processing
- Zero dependencies - built with PHP core functionality only
- Easy-to-use event-based architecture

## Installation

```bash
composer require sockeon/sockeon
```

## Quick Start

```php
use Sockeon\Sockeon\Core\Server;
use Sockeon\Sockeon\Core\Contracts\SocketController;
use Sockeon\Sockeon\WebSocket\Attributes\SocketOn;
use Sockeon\Sockeon\Http\Attributes\HttpRoute;
use Sockeon\Sockeon\Http\Request;
use Sockeon\Sockeon\Http\Response;

class MyController extends SocketController
{
    // WebSocket event handler
    #[SocketOn('message')]
    public function handleMessage(int $clientId, array $data)
    {
        $this->broadcast('message', [
            'from' => $clientId,
            'text' => $data['text'] ?? ''
        ]);
    }
    
    // HTTP route with path parameter
    #[HttpRoute('GET', '/users/{id}')]
    public function getUser(Request $request): Response
    {
        $userId = $request->getParam('id');
        return Response::json([
            'id' => $userId,
            'name' => 'Example User'
        ]);
    }
}

// Initialize server
$server = new Server("0.0.0.0", 8000);

// Register your controller
$server->registerController(new MyController());

// Start the server
$server->run();
```

See the example files for complete demonstrations:
- `examples/example.php` - Basic WebSocket and HTTP example
- `examples/namespace_example.php` - WebSocket namespaces and rooms
- `examples/advanced_http_example.php` - Advanced HTTP features

## Documentation

1. [Getting Started](/docs/getting-started)
   - Installation
   - Server Configuration
   - Basic Implementation
   - First Application

2. [Core Concepts](/docs/core-concepts)
   - Server Architecture
   - WebSocket Communication
   - HTTP Routing
   - Namespaces & Rooms
   - Middleware Pipeline

3. [API Reference](/docs/api-reference)
   - Server Class
   - WebSocket Handler
   - HTTP Handler
   - Controllers
   - Attributes Reference

4. [Examples](/docs/examples)
   - Real-time Chat Application
   - Room Management System
   - RESTful API Implementation
   - Hybrid Applications

5. [Advanced Topics](/docs/advanced-topics)
   - Custom Middleware Development
   - Error Handling Strategies
   - Performance Optimization
   - Security Best Practices

## Requirements

- PHP >= 8.0

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Links

- [GitHub Repository](https://github.com/sockeon/sockeon)
- [Issue Tracker](https://github.com/sockeon/sockeon/issues)
- [Examples](examples)
