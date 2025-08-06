---
title: "HTTP API Server Example - Sockeon Documentation"
description: "Complete example of an HTTP API server using Sockeon framework with REST endpoints"
og_image: "https://sockeon.com/assets/logo.png"
twitter_image: "https://sockeon.com/assets/logo.png"
---

# HTTP Server Example

A simple HTTP API server with REST endpoints.

## Server Code

```php
<?php

require_once __DIR__ . '/../vendor/autoload.php';

use Sockeon\Sockeon\Config\ServerConfig;
use Sockeon\Sockeon\Connection\Server;
use Sockeon\Sockeon\Controllers\SocketController;
use Sockeon\Sockeon\Http\Attributes\HttpRoute;
use Sockeon\Sockeon\Http\Request;
use Sockeon\Sockeon\Http\Response;

// HTTP API Controller
class ApiController extends SocketController
{
    #[HttpRoute('GET', '/api/health')]
    public function healthCheck(Request $request): Response
    {
        return Response::json([
            'status' => 'healthy',
            'timestamp' => time(),
            'server' => 'Sockeon'
        ]);
    }

    #[HttpRoute('GET', '/api/users')]
    public function getUsers(Request $request): Response
    {
        $page = (int)$request->getQuery('page', 1);
        $limit = (int)$request->getQuery('limit', 10);
        
        // Simulate user data
        $users = [
            ['id' => 1, 'name' => 'John Doe', 'email' => 'john@example.com'],
            ['id' => 2, 'name' => 'Jane Smith', 'email' => 'jane@example.com'],
            ['id' => 3, 'name' => 'Bob Johnson', 'email' => 'bob@example.com']
        ];
        
        return Response::json([
            'users' => $users,
            'pagination' => [
                'page' => $page,
                'limit' => $limit,
                'total' => count($users)
            ]
        ]);
    }

    #[HttpRoute('POST', '/api/users')]
    public function createUser(Request $request): Response
    {
        $data = $request->all();
        
        // Validate required fields
        if (empty($data['name']) || empty($data['email'])) {
            return Response::json([
                'error' => 'Name and email are required'
            ], 400);
        }
        
        // Simulate user creation
        $user = [
            'id' => rand(1000, 9999),
            'name' => $data['name'],
            'email' => $data['email'],
            'created_at' => date('c')
        ];
        
        return Response::json($user, 201);
    }

    #[HttpRoute('GET', '/api/users/{id}')]
    public function getUser(Request $request): Response
    {
        $userId = $request->getParam('id');
        
        // Simulate user lookup
        $user = [
            'id' => $userId,
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'created_at' => '2024-01-01T00:00:00Z'
        ];
        
        return Response::json($user);
    }

    #[HttpRoute('PUT', '/api/users/{id}')]
    public function updateUser(Request $request): Response
    {
        $userId = $request->getParam('id');
        $data = $request->all();
        
        // Simulate user update
        $user = [
            'id' => $userId,
            'name' => $data['name'] ?? 'John Doe',
            'email' => $data['email'] ?? 'john@example.com',
            'updated_at' => date('c')
        ];
        
        return Response::json($user);
    }

    #[HttpRoute('DELETE', '/api/users/{id}')]
    public function deleteUser(Request $request): Response
    {
        $userId = $request->getParam('id');
        
        return Response::json([
            'message' => "User {$userId} deleted successfully"
        ]);
    }
}

// Create server configuration
$config = new ServerConfig();
$config->host = '0.0.0.0';
$config->port = 8080;
$config->debug = true;

// Configure CORS
$config->cors = [
    'allowed_origins' => ['*'],
    'allowed_methods' => ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    'allowed_headers' => ['Content-Type', 'Authorization'],
    'allow_credentials' => true
];

// Create server
$server = new Server($config);

// Register controller
$server->registerController(new ApiController());

echo "Starting HTTP server on http://localhost:8080\n";
echo "Available endpoints:\n";
echo "  GET  /api/health\n";
echo "  GET  /api/users\n";
echo "  POST /api/users\n";
echo "  GET  /api/users/{id}\n";
echo "  PUT  /api/users/{id}\n";
echo "  DELETE /api/users/{id}\n";
echo "Press Ctrl+C to stop\n";

// Start server
$server->run();
```

## How to Run

1. Save the code as `http-server.php`
2. Run the server:
   ```bash
   php http-server.php
   ```
3. Test the endpoints with curl or a web browser

## API Endpoints

### Health Check
```bash
curl http://localhost:8080/api/health
```

### Get Users
```bash
curl http://localhost:8080/api/users
curl http://localhost:8080/api/users?page=1&limit=5
```

### Create User
```bash
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com"}'
```

### Get User
```bash
curl http://localhost:8080/api/users/1
```

### Update User
```bash
curl -X PUT http://localhost:8080/api/users/1 \
  -H "Content-Type: application/json" \
  -d '{"name":"John Updated","email":"john.updated@example.com"}'
```

### Delete User
```bash
curl -X DELETE http://localhost:8080/api/users/1
```

## Features

- **REST API**: Full CRUD operations for users
- **CORS Support**: Configured for cross-origin requests
- **Query Parameters**: Support for pagination
- **Path Parameters**: Dynamic route parameters
- **JSON Responses**: All responses in JSON format
- **Error Handling**: Proper HTTP status codes 