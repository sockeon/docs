---
title: "Request API - Sockeon Documentation"
description: "Complete API reference for Sockeon Request class with methods for accessing HTTP request data"
og_image: "https://sockeon.com/logo.png"
twitter_image: "https://sockeon.com/logo.png"
---

# Request API Reference

The Request class represents an HTTP request in Sockeon, providing access to headers, query parameters, POST data, and request body.

## Class: `Sockeon\Sockeon\Http\Request`

### Constructor

```php
public function __construct(array $requestData)
```

Creates a new Request instance.

**Parameters:**
- `$requestData` (`array<string, mixed>`): The parsed HTTP request data containing method, path, headers, query, params, and body

**Example:**
```php
$requestData = [
    'method' => 'POST',
    'path' => '/api/users',
    'headers' => ['Content-Type' => 'application/json'],
    'query' => ['page' => '1'],
    'params' => ['id' => '123'],
    'body' => '{"name":"John","email":"john@example.com"}'
];

$request = new Request($requestData);
```

---

## Basic Request Information

### getMethod()

```php
public function getMethod(): string
```

Returns the HTTP method.

**Returns:** `string` - The HTTP method (GET, POST, PUT, DELETE, etc.)

**Example:**
```php
#[HttpRoute('POST', '/api/users')]
public function createUser(Request $request): Response
{
    $method = $request->getMethod(); // 'POST'
    
    if ($method !== 'POST') {
        return Response::json(['error' => 'Method not allowed'], 405);
    }
    
    // Process POST request...
}
```

### getPath()

```php
public function getPath(): string
```

Returns the request path (without query string).

**Returns:** `string` - The request path

**Example:**
```php
#[HttpRoute('GET', '/api/users/{id}')]
public function getUser(Request $request): Response
{
    $path = $request->getPath(); // '/api/users/123'
    $id = $request->getParam('id'); // '123'
    
    return Response::json(['path' => $path, 'userId' => $id]);
}
```

### getUrl()

```php
public function getUrl(bool $includeQuery = true): string
```

Returns the full request URL. Automatically uses proxy headers (X-Forwarded-Proto, X-Forwarded-Host, X-Forwarded-Port) when trust proxy is enabled.

**Parameters:**
- `$includeQuery` (`bool`): Whether to include query string (default: true)

**Returns:** `string` - The full request URL with correct protocol, host, and port

**Example:**
```php
#[HttpRoute('GET', '/api/search')]
public function search(Request $request): Response
{
    $url = $request->getUrl(); // 'https://api.example.com/api/search?q=test&limit=10'
    $urlWithoutQuery = $request->getUrl(false); // 'https://api.example.com/api/search'
    
    return Response::json(['url' => $url, 'urlWithoutQuery' => $urlWithoutQuery]);
}
```

### getScheme()

```php
public function getScheme(): string
```

Returns the request scheme (http or https). Respects X-Forwarded-Proto header when proxy is trusted.

**Returns:** `string` - The request scheme ('http' or 'https')

**Example:**
```php
#[HttpRoute('GET', '/api/info')]
public function getInfo(Request $request): Response
{
    $scheme = $request->getScheme(); // 'https' when behind reverse proxy with HTTPS
    
    return Response::json([
        'scheme' => $scheme,
        'isSecure' => $scheme === 'https'
    ]);
}
```

### getHost()

```php
public function getHost(): string
```

Returns the request hostname. Respects X-Forwarded-Host header when proxy is trusted.

**Returns:** `string` - The request hostname

**Example:**
```php
#[HttpRoute('GET', '/api/info')]
public function getInfo(Request $request): Response
{
    $host = $request->getHost(); // 'api.example.com' when behind reverse proxy
    
    return Response::json(['host' => $host]);
}
```

### getPort()

```php
public function getPort(): int
```

Returns the request port number. Respects X-Forwarded-Port header when proxy is trusted.

**Returns:** `int` - The request port number

**Example:**
```php
#[HttpRoute('GET', '/api/info')]
public function getInfo(Request $request): Response
{
    $port = $request->getPort(); // 443 when behind reverse proxy with HTTPS
    
    return Response::json(['port' => $port]);
}
```

### getIpAddress()

```php
public function getIpAddress(bool $fallbackToDefault = false): ?string
```

Returns the client IP address. Respects trust proxy settings and checks X-Forwarded-For header when proxy is trusted.

**Parameters:**
- `$fallbackToDefault` (`bool`): Whether to return '127.0.0.1' if no IP is found (default: false)

**Returns:** `string|null` - The client IP address or null/default

**Example:**
```php
#[HttpRoute('GET', '/api/request-details')]
public function getRequestDetails(Request $request): Response
{
    $ip = $request->getIpAddress(); // Real client IP when behind reverse proxy
    
    return Response::json([
        'ip_address' => $ip,
        'is_local' => in_array($ip, ['127.0.0.1', '::1'])
    ]);
}
```

**Note**: The method checks multiple headers in order:
1. `CF-Connecting-IP` (Cloudflare)
2. `X-Forwarded-For` (Standard proxy header)
3. `X-Real-IP` (Nginx)
4. `REMOTE_ADDR` (Direct connection)

---

## Headers

### getHeaders()

```php
public function getHeaders(): array
```

Returns all HTTP headers.

**Returns:** `array<string, string>` - Associative array of headers

**Example:**
```php
#[HttpRoute('POST', '/api/upload')]
public function uploadFile(Request $request): Response
{
    $headers = $request->getHeaders();
    
    if (!isset($headers['Content-Type'])) {
        return Response::json(['error' => 'Content-Type required'], 400);
    }
    
    return Response::json(['contentType' => $headers['Content-Type']]);
}
```

### getHeader()

```php
public function getHeader(string $name): ?string
```

Returns a specific header value.

**Parameters:**
- `$name` (`string`): The header name (case-insensitive)

**Returns:** `string|null` - The header value or null if not found

**Example:**
```php
#[HttpRoute('POST', '/api/webhook')]
public function handleWebhook(Request $request): Response
{
    $signature = $request->getHeader('X-Signature');
    $userAgent = $request->getHeader('User-Agent');
    $contentType = $request->getHeader('content-type'); // Case-insensitive
    
    if (!$signature) {
        return Response::json(['error' => 'Signature required'], 401);
    }
    
    // Verify signature...
    return Response::json(['success' => true]);
}
```

### has()

```php
public function has(string $key): bool
```

Checks if a value exists in the request body.

**Parameters:**
- `$key` (`string`): The field name

**Returns:** `bool` - True if field exists

**Example:**
```php
#[HttpRoute('POST', '/api/users')]
public function createUser(Request $request): Response
{
    if (!$request->has('name') || !$request->has('email')) {
        return Response::json(['error' => 'Name and email required'], 400);
    }
    
    $name = $request->input('name');
    $email = $request->input('email');
    
    return Response::json(['user' => ['name' => $name, 'email' => $email]]);
}
```

---

## Query Parameters

### getQueryParams()

```php
public function getQueryParams(): array
```

Returns all query string parameters.

**Returns:** `array<string, mixed>` - Associative array of query parameters

**Example:**
```php
#[HttpRoute('GET', '/api/users')]
public function listUsers(Request $request): Response
{
    $queryParams = $request->getQueryParams();
    /*
    For URL: /api/users?page=2&limit=10&sort=name
    Returns: ['page' => '2', 'limit' => '10', 'sort' => 'name']
    */
    
    $page = (int)($queryParams['page'] ?? 1);
    $limit = (int)($queryParams['limit'] ?? 20);
    $sort = $queryParams['sort'] ?? 'id';
    
    return Response::json([
        'page' => $page,
        'limit' => $limit,
        'sort' => $sort
    ]);
}
```

### getQuery()

```php
public function getQuery(string $key, mixed $default = null): mixed
```

Returns a specific query parameter value.

**Parameters:**
- `$key` (`string`): The parameter name
- `$default` (`mixed`): Default value if parameter doesn't exist

**Returns:** `mixed` - The parameter value or default

**Example:**
```php
#[HttpRoute('GET', '/api/search')]
public function search(Request $request): Response
{
    $query = $request->getQuery('q', '');
    $page = (int)$request->getQuery('page', 1);
    $limit = (int)$request->getQuery('limit', 20);
    $category = $request->getQuery('category'); // null if not provided
    
    if (empty($query)) {
        return Response::json(['error' => 'Search query required'], 400);
    }
    
    return Response::json([
        'query' => $query,
        'page' => $page,
        'limit' => $limit,
        'category' => $category
    ]);
}
```

---

## Request Body Data

### all()

```php
public function all(): array
```

Returns the request body as an array. For JSON requests, this automatically decodes the JSON body.

**Returns:** `array<string, mixed>` - The request body data as an array

**Example:**
```php
#[HttpRoute('POST', '/api/contact')]
public function submitContact(Request $request): Response
{
    $data = $request->all();
    /*
    For JSON body: {"name":"John","email":"john@example.com","message":"Hello"}
    Returns: ['name' => 'John', 'email' => 'john@example.com', 'message' => 'Hello']
    */
    
    $required = ['name', 'email', 'message'];
    foreach ($required as $field) {
        if (empty($data[$field])) {
            return Response::json(['error' => "Field '{$field}' is required"], 400);
        }
    }
    
    return Response::json(['success' => true]);
}
```

### input()

```php
public function input(string $key, mixed $default = null): mixed
```

Returns a specific value from the request body.

**Parameters:**
- `$key` (`string`): The field name
- `$default` (`mixed`): Default value if field doesn't exist

**Returns:** `mixed` - The field value or default

**Example:**
```php
#[HttpRoute('POST', '/api/users')]
public function createUser(Request $request): Response
{
    $name = $request->input('name');
    $email = $request->input('email');
    $age = (int)$request->input('age', 0);
    $newsletter = $request->input('newsletter', false);
    
    if (!$name || !$email) {
        return Response::json(['error' => 'Name and email required'], 400);
    }
    
    return Response::json([
        'user' => [
            'name' => $name,
            'email' => $email,
            'age' => $age,
            'newsletter' => $newsletter
        ]
    ]);
}
```



---

## Raw Body

### getBody()

```php
public function getBody(): string
```

Returns the raw request body.

**Returns:** `string` - The raw body content

**Example:**
```php
#[HttpRoute('POST', '/api/webhook')]
public function webhook(Request $request): Response
{
    $rawBody = $request->getBody();
    $signature = $request->getHeader('X-Hub-Signature-256');
    
    // Verify webhook signature
    $expectedSignature = 'sha256=' . hash_hmac('sha256', $rawBody, $secret);
    
    if (!hash_equals($expectedSignature, $signature)) {
        return Response::json(['error' => 'Invalid signature'], 401);
    }
    
    // Process webhook...
    return Response::json(['success' => true]);
}

#[HttpRoute('PUT', '/api/files/{filename}')]
public function uploadRawFile(Request $request): Response
{
    $filename = $request->getParam('filename');
    $content = $request->getBody();
    
    file_put_contents("/uploads/{$filename}", $content);
    
    return Response::json([
        'filename' => $filename,
        'size' => strlen($content)
    ]);
}
```

---

## Route Parameters

### getPathParams()

```php
public function getPathParams(): array
```

Returns all route parameters extracted from the URL path.

**Returns:** `array<string, string>` - Associative array of route parameters

**Example:**
```php
#[HttpRoute('GET', '/api/users/{userId}/posts/{postId}')]
public function getUserPost(Request $request): Response
{
    $params = $request->getPathParams();
    /*
    For URL: /api/users/123/posts/456
    Returns: ['userId' => '123', 'postId' => '456']
    */
    
    return Response::json([
        'user' => $params['userId'],
        'post' => $params['postId']
    ]);
}
```

### getParam()

```php
public function getParam(string $name, string $default = null): ?string
```

Returns a specific route parameter value.

**Parameters:**
- `$name` (`string`): The parameter name
- `$default` (`string|null`): Default value if parameter doesn't exist

**Returns:** `string|null` - The parameter value or default

**Example:**
```php
#[HttpRoute('GET', '/api/users/{id}')]
public function getUser(Request $request): Response
{
    $userId = $request->getParam('id');
    
    if (!$userId) {
        return Response::json(['error' => 'User ID required'], 400);
    }
    
    if (!is_numeric($userId)) {
        return Response::json(['error' => 'Invalid user ID'], 400);
    }
    
    return Response::json(['user' => ['id' => (int)$userId]]);
}

#[HttpRoute('GET', '/api/files/{path}')]
#[HttpRoute('GET', '/api/files/{path}/{filename}')]
public function processData(Request $request): Response
{
    $path = $request->getParam('path');
    $filename = $request->getParam('filename', 'index.html');
    
    $fullPath = "/files/{$path}/{$filename}";
    
    return Response::json(['path' => $fullPath]);
}
```



---

## Content Type Detection

### isJson()

```php
public function isJson(): bool
```

Checks if the request content type is JSON.

**Returns:** `bool` - True if content type is application/json

**Example:**
```php
#[HttpRoute('POST', '/api/data')]
public function submitData(Request $request): Response
{
    $data = $request->all();
    return Response::json(['received' => $data]);
}
```

### isFormData()

```php
public function isFormData(): bool
```

Checks if the request has form data content type.

**Returns:** `bool` - True if content type is application/x-www-form-urlencoded

**Example:**
```php
#[HttpRoute('POST', '/api/submit')]
public function submitForm(Request $request): Response
{
    if ($request->isFormData()) {
        // Handle form data
        $data = $request->all();
        return Response::json(['form_data' => $data]);
    } else {
        // Handle JSON
        $data = $request->isJson() ? $request->all() : [];
        return Response::json(['json_data' => $data]);
    }
}
```

---

## Complete Request Handling Examples

### REST API Endpoint

```php
class UserController extends SocketController
{
    #[HttpRoute('GET', '/api/users')]
    public function listUsers(Request $request): Response
    {
        // Query parameters
        $page = (int)$request->getQuery('page', 1);
        $limit = min((int)$request->getQuery('limit', 20), 100);
        $search = $request->getQuery('search', '');
        $sort = $request->getQuery('sort', 'id');
        $order = $request->getQuery('order', 'asc');
        
        // Validation
        if ($page < 1) $page = 1;
        if (!in_array($order, ['asc', 'desc'])) $order = 'asc';
        
        // Simulate database query
        $users = [
            ['id' => 1, 'name' => 'John', 'email' => 'john@example.com'],
            ['id' => 2, 'name' => 'Jane', 'email' => 'jane@example.com'],
        ];
        
        return Response::json([
            'users' => $users,
            'pagination' => [
                'page' => $page,
                'limit' => $limit,
                'total' => count($users)
            ],
            'filters' => [
                'search' => $search,
                'sort' => $sort,
                'order' => $order
            ]
        ]);
    }

    #[HttpRoute('POST', '/api/users')]
    public function createUser(Request $request): Response
    {
        $data = $request->all();
        
        // Validation
        $required = ['name', 'email'];
        foreach ($required as $field) {
            if (empty($data[$field])) {
                return Response::json([
                    'error' => "Field '{$field}' is required"
                ], 400);
            }
        }
        
        if (!filter_var($data['email'], FILTER_VALIDATE_EMAIL)) {
            return Response::json(['error' => 'Invalid email'], 400);
        }
        
        // Create user
        $user = [
            'id' => rand(1000, 9999),
            'name' => $data['name'],
            'email' => $data['email'],
            'created_at' => date('Y-m-d H:i:s')
        ];
        
        return Response::json(['user' => $user], 201);
    }

    #[HttpRoute('PUT', '/api/users/{id}')]
    public function updateUser(Request $request): Response
    {
        $userId = $request->getParam('id');
        
        if (!is_numeric($userId)) {
            return Response::json(['error' => 'Invalid user ID'], 400);
        }
        
        $data = $request->all();
        
        // Update user logic...
        return Response::json([
            'user' => [
                'id' => (int)$userId,
                'updated_fields' => array_keys($data)
            ]
        ]);
    }
}
```

### Data Processing API

```php
class DataController extends SocketController
{
    #[HttpRoute('POST', '/api/process')]
    public function processData(Request $request): Response
    {
        $data = $request->all();
        
        if (empty($data)) {
            return Response::json(['error' => 'No data provided'], 400);
        }
        
        // Process the data
        $processed = [];
        foreach ($data as $key => $value) {
            $processed[$key] = is_string($value) ? strtoupper($value) : $value;
        }
        
        return Response::json([
            'original' => $data,
            'processed' => $processed,
            'count' => count($data)
        ], 201);
    }
}
```

---

## Best Practices

1. **Always Validate Input**: Check all request data before processing
2. **Use Type Casting**: Convert string parameters to appropriate types
3. **Set Reasonable Defaults**: Provide sensible default values
4. **Handle Both JSON and Form Data**: Support multiple content types
5. **Use Dot Notation**: For complex JSON structures in `input()`
6. **Sanitize Output**: Clean data before sending responses
7. **Check Content Type**: Use `isJson()` and `isFormData()` to handle different request types

---

## Reverse Proxy Support

When your Sockeon server is behind a reverse proxy or load balancer, the Request class automatically handles proxy headers to provide accurate client information.

### Configuration

Enable trust proxy in your server configuration:

```php
use Sockeon\Sockeon\Config\ServerConfig;

$config = new ServerConfig([
    'trust_proxy' => [
        '127.0.0.1',      // Localhost
        '10.0.0.0/8',     // Private network
        '192.168.0.0/16', // Private network
    ],
]);
```

### Proxy Headers

The following headers are automatically processed when trust proxy is enabled:

- **X-Forwarded-For**: Real client IP address
- **X-Forwarded-Proto**: Original protocol (http/https)
- **X-Forwarded-Host**: Original hostname
- **X-Forwarded-Port**: Original port number
- **Forwarded**: RFC 7239 standard header (also supported)

### Example: Getting Real Client Information

```php
#[HttpRoute('GET', '/api/request-details')]
public function getRequestDetails(Request $request): Response
{
    return Response::json([
        'ip_address' => $request->getIpAddress(),      // Real client IP
        'scheme' => $request->getScheme(),              // Original protocol
        'host' => $request->getHost(),                  // Original hostname
        'port' => $request->getPort(),                  // Original port
        'url' => $request->getUrl(),                    // Full URL with correct info
    ]);
}
```

For detailed information about reverse proxy configuration, see the [Reverse Proxy and Load Balancing Guide](/v2.0/advanced/reverse-proxy.md).

## See Also

- [Response API](/v2.0/api/response.md) - Creating HTTP responses
- [Controller API](/v2.0/api/controller.md) - Controller base class methods
- [Routing Guide](/v2.0/core/routing.md) - HTTP routing patterns
- [HTTP Guide](/v2.0/http/request-response.md) - Request/response handling
- [Server Configuration](/v2.0/core/server-configuration.md) - Trust proxy configuration
