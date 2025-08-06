---
title: "Examples - Sockeon Documentation"
description: "Complete examples and tutorials for Sockeon framework including WebSocket and HTTP servers"
og_image: "https://sockeon.com/assets/logo.png"
twitter_image: "https://sockeon.com/assets/logo.png"
---

# Sockeon Examples

Simple and concise examples demonstrating Sockeon framework usage.

## Examples Overview

### 1. [Basic WebSocket Server](basic-server.md)
A simple WebSocket server that handles chat functionality with connection events and message broadcasting.

**Features:**
- Connection/disconnection handling
- Chat message broadcasting
- Typing indicators
- Error validation

### 2. [Basic WebSocket Client](basic-client.md)
A PHP WebSocket client that connects to the chat server and handles various events.

**Features:**
- Event handling for server messages
- Message sending
- Connection management
- Error handling

### 3. [HTTP Server](http-server.md)
A REST API server with full CRUD operations for user management.

**Features:**
- RESTful API endpoints
- CORS configuration
- Query parameters
- Path parameters
- JSON responses

### 4. [Hybrid Server](hybrid-server.md)
A server that handles both WebSocket and HTTP requests simultaneously.

**Features:**
- WebSocket real-time communication
- HTTP API for data management
- Cross-protocol messaging
- Client management

## Quick Start

1. **Choose an example** that fits your needs
2. **Copy the code** from the markdown file
3. **Save as PHP file** (e.g., `server.php`)
4. **Run the server**:
   ```bash
   php server.php
   ```

## Example Use Cases

### Chat Application
- Use **Basic WebSocket Server** for the backend
- Use **Basic WebSocket Client** for PHP clients
- Use browser WebSocket clients for frontend

### REST API
- Use **HTTP Server** for API endpoints
- Test with curl or HTTP clients
- Integrate with frontend applications

### Real-time Dashboard
- Use **Hybrid Server** for combined functionality
- HTTP for data retrieval
- WebSocket for live updates

## Testing Examples

### WebSocket Testing
```bash
# Start the WebSocket server
php basic-server.php

# In another terminal, test with wscat
wscat -c ws://localhost:8080
```

### HTTP API Testing
```bash
# Start the HTTP server
php http-server.php

# Test endpoints
curl http://localhost:8080/api/health
curl http://localhost:8080/api/users
```

### Hybrid Testing
```bash
# Start the hybrid server
php hybrid-server.php

# Test HTTP endpoints
curl http://localhost:8080/api/status

# Test WebSocket (in browser console)
const ws = new WebSocket('ws://localhost:8080');
ws.send(JSON.stringify({event:'chat.message',data:{message:'Hello'}}));
```

## Common Patterns

### WebSocket Events
```php
#[SocketOn('event.name')]
public function handleEvent(int $clientId, array $data): void
{
    // Handle event
    $this->broadcast('response.event', $data);
}
```

### HTTP Routes
```php
#[HttpRoute('GET', '/api/endpoint')]
public function handleRequest(Request $request): Response
{
    return Response::json(['data' => 'value']);
}
```

### Connection Events
```php
#[OnConnect]
public function onConnect(int $clientId): void
{
    $this->emit($clientId, 'welcome', ['message' => 'Hello']);
}

#[OnDisconnect]
public function onDisconnect(int $clientId): void
{
    // Clean up
}
```

## Next Steps

After running the examples:

1. **Modify the code** to fit your specific needs
2. **Add database integration** for persistent data
3. **Implement authentication** for secure connections
4. **Add error handling** for production use
5. **Configure logging** for monitoring

## Documentation

For detailed documentation, see:
- [Getting Started](../docs/getting-started/)
- [Core Concepts](../docs/core/)
- [WebSocket Guide](../docs/websocket/)
- [HTTP Guide](../docs/http/)
- [API Reference](../docs/api/) 