---
title: "HTTP Routing - Sockeon Documentation"
description: "Learn how to create HTTP routes and handle different HTTP methods in Sockeon framework"
og_image: "https://sockeon.com/assets/logo.png"
twitter_image: "https://sockeon.com/assets/logo.png"
---

# HTTP Routing

Learn how to implement HTTP routing in Sockeon using attribute-based routing.

## Basic HTTP Routing

### Route Attributes

Sockeon uses PHP 8 attributes for clean, declarative HTTP routing:

```php
class ApiController extends SocketController
{
    #[HttpRoute('GET', '/api/health')]
    public function healthCheck(Request $request): Response
    {
        return Response::json([
            'status' => 'healthy',
            'timestamp' => time()
        ]);
    }
    
    #[HttpRoute('POST', '/api/users')]
    public function createUser(Request $request): Response
    {
        $data = $request->all();
        
        // Validate required fields
        if (empty($data['name']) || empty($data['email'])) {
            return Response::json(['error' => 'Name and email are required'], 400);
        }
        
        // Create user logic here
        $user = ['id' => 1, 'name' => $data['name'], 'email' => $data['email']];
        
        return Response::json($user, 201);
    }
    
    #[HttpRoute('GET', '/api/users/{id}')]
    public function getUser(Request $request): Response
    {
        $userId = $request->getParam('id');
        
        // Get user logic here
        $user = ['id' => $userId, 'name' => 'John Doe', 'email' => 'john@example.com'];
        
        return Response::json($user);
    }
    
    #[HttpRoute('PUT', '/api/users/{id}')]
    #[HttpRoute('PATCH', '/api/users/{id}')]
    public function updateUser(Request $request): Response
    {
        $userId = $request->getParam('id');
        $data = $request->all();
        
        // Update user logic here
        $user = ['id' => $userId, 'name' => $data['name'], 'email' => $data['email']];
        
        return Response::json($user);
    }
    
    #[HttpRoute('DELETE', '/api/users/{id}')]
    public function deleteUser(Request $request): Response
    {
        $userId = $request->getParam('id');
        
        // Delete user logic here
        
        return Response::json(['message' => 'User deleted'], 200);
    }
}
```

## HTTP Methods

Support for all standard HTTP methods:

```php
class ResourceController extends SocketController
{
    #[HttpRoute('GET', '/api/users')]
    public function listUsers(Request $request): Response
    {
        $page = (int)$request->getQuery('page', 1);
        $limit = (int)$request->getQuery('limit', 20);
        
        return Response::json([
            'users' => [],
            'pagination' => [
                'page' => $page,
                'limit' => $limit,
                'total' => 0
            ]
        ]);
    }
    
    #[HttpRoute('POST', '/api/users')]
    public function createUser(Request $request): Response
    {
        $userData = $request->all();
        
        // Validate required fields
        if (empty($userData['name']) || empty($userData['email'])) {
            return Response::json(['error' => 'Name and email are required'], 400);
        }
        
        return Response::json(['user' => $userData], 201);
    }
    
    #[HttpRoute('PUT', '/api/users/{id}')]
    public function updateUser(Request $request): Response
    {
        $userId = $request->getParam('id');
        $userData = $request->all();
        
        return Response::json(['user' => array_merge(['id' => $userId], $userData)]);
    }
    
    #[HttpRoute('DELETE', '/api/users/{id}')]
    public function deleteUser(Request $request): Response
    {
        $userId = $request->getParam('id');
        
        return Response::json(['message' => 'User deleted']);
    }
}
```

## Route Parameters

```php
class ParameterController extends SocketController
{
    #[HttpRoute('GET', '/api/users/{id}')]
    public function getUser(Request $request): Response
    {
        $userId = $request->getParam('id');
        return Response::json(['id' => $userId]);
    }
    
    #[HttpRoute('GET', '/api/users/{id}/posts/{postId}')]
    public function getUserPost(Request $request): Response
    {
        $userId = $request->getParam('id');
        $postId = $request->getParam('postId');
        
        return Response::json([
            'user_id' => $userId,
            'post_id' => $postId
        ]);
    }
}
```

## Query Parameters

```php
class QueryController extends SocketController
{
    #[HttpRoute('GET', '/api/search')]
    public function search(Request $request): Response
    {
        $query = $request->getQuery('q', '');
        $page = (int)$request->getQuery('page', 1);
        $limit = (int)$request->getQuery('limit', 10);
        
        return Response::json([
            'query' => $query,
            'page' => $page,
            'limit' => $limit,
            'results' => []
        ]);
    }
}
```
