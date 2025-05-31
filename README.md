# WebSocket and HTTP Server in PHP

Welcome to the official Sockeon documentation. Sockeon is a high-performance dual-protocol server library for PHP that handles both WebSocket and HTTP connections on a single port. Create real-time applications with WebSockets while simultaneously serving HTTP requests, RESTful APIs, and web content - all with one unified codebase.

## Key Features

- **Dual-Protocol Server**: Combined WebSocket and HTTP server on a single port
- **HTTP & WebSocket Routing**: Attribute-based routing for both protocols
- **RESTful API Support**: Build REST APIs alongside WebSocket functionality
- **Advanced Request Handling**: Content negotiation and path parameters
- **Security Layer**: CORS support and authentication middleware for both protocols
- **Zero Dependencies**: Built on PHP's native socket extensions

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
use Sockeon\Sockeon\Http\Request;
use Sockeon\Sockeon\Http\Response;

class DualController extends SocketController
{
    // WebSocket event handler
    #[SocketOn('message')]
    public function handleMessage(int $clientId, array $data)
    {
        // Broadcast the message to all clients
        $this->broadcast('message', [
            'from' => $clientId,
            'text' => $data['text'] ?? ''
        ]);
    }
    
    // HTTP REST API endpoint
    #[HttpRoute('GET', '/api/users/{id}')]
    public function getUser(Request $request): Response
    {
        $userId = $request->getParam('id');
        return Response::json([
            'id' => $userId,
            'name' => 'User ' . $userId
        ]);
    }
}

// Create and run the dual-protocol server
$server = new Server("0.0.0.0", 8000);
$server->registerController(new DualController());
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
- [Live Demo](https://sockeon.com/demo)
- [Community Forum](https://community.sockeon.com)
