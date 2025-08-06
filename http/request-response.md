---
title: "HTTP Request and Response - Sockeon Documentation"
description: "Learn how to handle HTTP requests and create responses in Sockeon framework"
og_image: "https://sockeon.com/assets/logo.png"
twitter_image: "https://sockeon.com/assets/logo.png"
---

# Request and Response Handling

Learn how to handle HTTP requests and responses in Sockeon.

## Request Handling

### Basic Request Data

```php
class RequestController extends SocketController
{
    #[HttpRoute('GET', '/api/request-info')]
    public function requestInfo(Request $request): Response
    {
        return Response::json([
            'method' => $request->getMethod(),
            'path' => $request->getPath(),
            'ip_address' => $request->getIpAddress(),
            'user_agent' => $request->getHeader('User-Agent')
        ]);
    }
    
    #[HttpRoute('GET', '/api/query')]
    public function queryParameters(Request $request): Response
    {
        $page = $request->getQuery('page', 1);
        $limit = $request->getQuery('limit', 10);
        $search = $request->getQuery('search', '');
        
        return Response::json([
            'page' => (int)$page,
            'limit' => (int)$limit,
            'search' => $search
        ]);
    }
}
```

### POST Data

```php
class PostDataController extends SocketController
{
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
}
```

## Response Handling

### JSON Responses

```php
class ResponseController extends SocketController
{
    #[HttpRoute('GET', '/api/data')]
    public function getData(Request $request): Response
    {
        return Response::json([
            'success' => true,
            'data' => ['id' => 1, 'name' => 'Example']
        ]);
    }
    
    #[HttpRoute('POST', '/api/create')]
    public function createData(Request $request): Response
    {
        return Response::json(['message' => 'Created'], 201);
    }
    
    #[HttpRoute('GET', '/api/error')]
    public function errorExample(Request $request): Response
    {
        return Response::json(['error' => 'Not found'], 404);
    }
}
```

### Response Status Codes

```php
class StatusController extends SocketController
{
    #[HttpRoute('GET', '/api/success')]
    public function success(Request $request): Response
    {
        return Response::ok(['data' => 'Success']);
    }
    
    #[HttpRoute('POST', '/api/create')]
    public function created(Request $request): Response
    {
        return Response::created(['id' => 1]);
    }
    
    #[HttpRoute('GET', '/api/not-found')]
    public function notFound(Request $request): Response
    {
        return Response::notFound('Resource not found');
    }
    
    #[HttpRoute('POST', '/api/bad-request')]
    public function badRequest(Request $request): Response
    {
        return Response::badRequest('Invalid data');
    }
}
```
