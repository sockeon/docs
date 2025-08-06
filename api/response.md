---
title: "Response API - Sockeon Documentation"
description: "Complete API reference for Sockeon Response class with methods for creating HTTP responses"
og_image: "https://sockeon.com/assets/logo.png"
twitter_image: "https://sockeon.com/assets/logo.png"
---

# Response API Reference

The Response class represents an HTTP response in Sockeon, providing methods to create various types of responses with headers, status codes, and different content types.

## Class: `Sockeon\Sockeon\Http\Response`

### Constructor

```php
public function __construct(mixed $body = null, int $statusCode = 200, array $headers = [])
```

Creates a new Response instance.

**Parameters:**
- `$body` (`mixed`): The response body content (can be string, array, object, or null)
- `$statusCode` (`int`): HTTP status code (default: 200)
- `$headers` (`array<string, string>`): HTTP headers

**Example:**
```php
$response = new Response('Hello World', 200, [
    'Content-Type' => 'text/plain',
    'Cache-Control' => 'no-cache'
]);

// For JSON responses
$response = new Response(['message' => 'Success'], 200, [
    'Content-Type' => 'application/json'
]);
```

---

## Static Factory Methods

### json()

```php
public static function json(mixed $data, int $statusCode = 200, array $headers = []): Response
```

Creates a JSON response.

**Parameters:**
- `$data` (`mixed`): Data to encode as JSON
- `$statusCode` (`int`): HTTP status code (default: 200)
- `$headers` (`array<string, string>`): Additional headers

**Returns:** `Response` - JSON response with appropriate Content-Type header

**Example:**
```php
#[HttpRoute('GET', '/api/users')]
public function listUsers(Request $request): Response
{
    $users = [
        ['id' => 1, 'name' => 'John', 'email' => 'john@example.com'],
        ['id' => 2, 'name' => 'Jane', 'email' => 'jane@example.com']
    ];
    
    return Response::json([
        'users' => $users,
        'count' => count($users)
    ]);
}

#[HttpRoute('POST', '/api/users')]
public function createUser(Request $request): Response
{
    $data = $request->all();
    
    // Validation
    if (empty($data['name'])) {
        return Response::json(['error' => 'Name is required'], 400);
    }
    
    // Create user
    $user = [
        'id' => rand(1000, 9999),
        'name' => $data['name'],
        'email' => $data['email'],
        'created_at' => date('c')
    ];
    
    return Response::json(['user' => $user], 201, [
        'Location' => '/api/users/' . $user['id']
    ]);
}
```

### ok()

```php
public static function ok(mixed $data = null, array $headers = []): Response
```

Creates a 200 OK response.

**Parameters:**
- `$data` (`mixed`): Response data (optional)
- `$headers` (`array<string, string>`): Additional headers

**Returns:** `Response` - 200 OK response

**Example:**
```php
#[HttpRoute('GET', '/api/health')]
public function healthCheck(Request $request): Response
{
    $status = [
        'status' => 'healthy',
        'timestamp' => date('c'),
        'version' => '1.0.0'
    ];
    
    return Response::ok($status);
}
```

### file()

```php
public static function file(string $filePath, string $mimeType = null, array $headers = []): Response
```

Creates a file download response.

**Parameters:**
- `$filePath` (`string`): Path to the file
- `$mimeType` (`string|null`): MIME type (auto-detected if null)
- `$headers` (`array<string, string>`): Additional headers

**Returns:** `Response` - File response with appropriate headers

**Example:**
```php
#[HttpRoute('GET', '/api/download/{filename}')]
public function downloadFile(Request $request): Response
{
    $filename = $request->getParam('filename');
    $filePath = "/uploads/{$filename}";
    
    if (!file_exists($filePath)) {
        return Response::json(['error' => 'File not found'], 404);
    }
    
    return Response::file($filePath, null, [
        'Content-Disposition' => 'attachment; filename="' . $filename . '"'
    ]);
}

#[HttpRoute('GET', '/api/images/{id}')]
public function getImage(Request $request): Response
{
    $imageId = $request->getParam('id');
    $imagePath = "/images/{$imageId}.jpg";
    
    if (!file_exists($imagePath)) {
        return Response::json(['error' => 'Image not found'], 404);
    }
    
    return Response::file($imagePath, 'image/jpeg', [
        'Cache-Control' => 'public, max-age=3600',
        'ETag' => md5_file($imagePath)
    ]);
}
```

### redirect()

```php
public static function redirect(string $url, int $statusCode = 302, array $headers = []): Response
```

Creates a redirect response.

**Parameters:**
- `$url` (`string`): URL to redirect to
- `$statusCode` (`int`): HTTP status code (default: 302)
- `$headers` (`array<string, string>`): Additional headers

**Returns:** `Response` - Redirect response with Location header

**Example:**
```php
#[HttpRoute('POST', '/api/login')]
public function login(Request $request): Response
{
    $data = $request->all();
    $username = $data['username'] ?? '';
    $password = $data['password'] ?? '';
    
    if ($this->authenticate($username, $password)) {
        // Permanent redirect to dashboard
        return Response::redirect('/dashboard', 301);
    }
    
    return Response::json(['error' => 'Invalid credentials'], 401);
}

#[HttpRoute('GET', '/old-api/{path}')]
public function redirectOldApi(Request $request): Response
{
    $path = $request->getParam('path');
    
    // Temporary redirect to new API
    return Response::redirect("/api/v2/{$path}", 302, [
        'X-Deprecated' => 'true'
    ]);
}

#[HttpRoute('GET', '/admin')]
public function adminAccess(Request $request): Response
{
    // Check if user is admin
    if (!$this->isAdmin($request)) {
        return Response::redirect('/login?redirect=/admin');
    }
    
            return Response::ok('<h1>Admin Panel</h1>')->setContentType('text/html');
}
```

---

## Content Methods

### getBody()

```php
public function getBody(): string
```

Returns the response body content.

**Returns:** `string` - The response body

**Example:**
```php
#[HttpRoute('GET', '/api/preview')]
public function previewContent(Request $request): Response
{
            $response = Response::ok('<h1>Preview</h1>')->setContentType('text/html');
    $body = $response->getBody(); // '<h1>Preview</h1>'
    
    // Log the response body
    error_log("Response body: " . $body);
    
    return $response;
}
```

### setBody()

```php
public function setBody(string $body): Response
```

Sets the response body content.

**Parameters:**
- `$body` (`string`): The new body content

**Returns:** `Response` - The response instance for method chaining

**Example:**
```php
#[HttpRoute('GET', '/api/dynamic')]
public function dynamicContent(Request $request): Response
{
    $response = new Response();
    
    $format = $request->getQuery('format', 'json');
    
    if ($format === 'xml') {
        $response->setBody('<?xml version="1.0"?><data><message>Hello</message></data>')
                ->setHeader('Content-Type', 'application/xml');
    } else {
        $response->setBody('{"message": "Hello"}')
                ->setHeader('Content-Type', 'application/json');
    }
    
    return $response;
}
```

---

## Status Code Methods

### getStatusCode()

```php
public function getStatusCode(): int
```

Returns the HTTP status code.

**Returns:** `int` - The status code

**Example:**
```php
#[HttpRoute('GET', '/api/status-check')]
public function statusCheck(Request $request): Response
{
    $response = Response::json(['status' => 'ok']);
    $statusCode = $response->getStatusCode(); // 200
    
    return $response;
}
```

### setStatusCode()

```php
public function setStatusCode(int $statusCode): Response
```

Sets the HTTP status code.

**Parameters:**
- `$statusCode` (`int`): The status code

**Returns:** `Response` - The response instance for method chaining

**Example:**
```php
#[HttpRoute('POST', '/api/resources')]
public function createResource(Request $request): Response
{
    $data = $request->all();
    
    try {
        $resource = $this->createNewResource($data);
        
        return Response::json(['resource' => $resource])
                      ->setStatusCode(201); // Created
                      
    } catch (ValidationException $e) {
        return Response::json(['error' => $e->getMessage()])
                      ->setStatusCode(422); // Unprocessable Entity
                      
    } catch (Exception $e) {
        return Response::json(['error' => 'Internal server error'])
                      ->setStatusCode(500);
    }
}
```

---

## Header Methods

### getHeaders()

```php
public function getHeaders(): array
```

Returns all response headers.

**Returns:** `array<string, string>` - Associative array of headers

**Example:**
```php
#[HttpRoute('GET', '/api/debug')]
public function debugResponse(Request $request): Response
{
    $response = Response::json(['debug' => true], 200, [
        'X-Debug' => 'enabled',
        'X-Request-ID' => uniqid()
    ]);
    
    $headers = $response->getHeaders();
    /*
    Returns:
    [
        'Content-Type' => 'application/json',
        'X-Debug' => 'enabled',
        'X-Request-ID' => '...'
    ]
    */
    
    return $response;
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
#[HttpRoute('GET', '/api/cache-info')]
public function cacheInfo(Request $request): Response
{
    $response = Response::json(['data' => 'cached'], 200, [
        'Cache-Control' => 'public, max-age=3600',
        'ETag' => '"abc123"'
    ]);
    
    $cacheControl = $response->getHeader('Cache-Control'); // 'public, max-age=3600'
    $etag = $response->getHeader('etag'); // '"abc123"' (case-insensitive)
    
    return $response;
}
```

### setHeader()

```php
public function setHeader(string $name, string $value): Response
```

Sets a response header.

**Parameters:**
- `$name` (`string`): The header name
- `$value` (`string`): The header value

**Returns:** `Response` - The response instance for method chaining

**Example:**
```php
#[HttpRoute('GET', '/api/cors-endpoint')]
public function corsEndpoint(Request $request): Response
{
    return Response::json(['message' => 'CORS enabled'])
                  ->setHeader('Access-Control-Allow-Origin', '*')
                  ->setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE')
                  ->setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
}

#[HttpRoute('GET', '/api/secure')]
public function secureEndpoint(Request $request): Response
{
    return Response::json(['data' => 'secure'])
                  ->setHeader('X-Frame-Options', 'DENY')
                  ->setHeader('X-Content-Type-Options', 'nosniff')
                  ->setHeader('X-XSS-Protection', '1; mode=block');
}
```

### setHeaders()

```php
public function setHeaders(array $headers): Response
```

Sets multiple response headers.

**Parameters:**
- `$headers` (`array<string, string>`): Associative array of headers

**Returns:** `Response` - The response instance for method chaining

**Example:**
```php
#[HttpRoute('GET', '/api/cached-data')]
public function cachedData(Request $request): Response
{
    $cacheHeaders = [
        'Cache-Control' => 'public, max-age=3600',
        'ETag' => '"' . md5('data') . '"',
        'Last-Modified' => gmdate('D, d M Y H:i:s T', time() - 3600),
        'Expires' => gmdate('D, d M Y H:i:s T', time() + 3600)
    ];
    
    return Response::json(['data' => 'cached content'])
                  ->setHeaders($cacheHeaders);
}

#[HttpRoute('POST', '/api/upload')]
public function uploadEndpoint(Request $request): Response
{
    $securityHeaders = [
        'X-Content-Type-Options' => 'nosniff',
        'X-Frame-Options' => 'DENY',
        'Content-Security-Policy' => "default-src 'self'",
        'Strict-Transport-Security' => 'max-age=31536000; includeSubDomains'
    ];
    
    return Response::json(['uploaded' => true], 201)
                  ->setHeaders($securityHeaders);
}
```

### removeHeader()

```php
public function removeHeader(string $name): Response
```

Removes a response header.

**Parameters:**
- `$name` (`string`): The header name to remove

**Returns:** `Response` - The response instance for method chaining

**Example:**
```php
#[HttpRoute('GET', '/api/conditional')]
public function conditionalHeaders(Request $request): Response
{
    $response = Response::json(['data' => 'example'], 200, [
        'Cache-Control' => 'no-cache',
        'X-Debug' => 'enabled'
    ]);
    
    // Remove debug header in production
    if (!$this->isDebugMode()) {
        $response->removeHeader('X-Debug');
    }
    
    return $response;
}
```

---

## Convenience Methods

### withCors()

```php
public function withCors(string $origin = '*', array $methods = ['GET', 'POST'], array $headers = []): Response
```

Adds CORS headers to the response.

**Parameters:**
- `$origin` (`string`): Allowed origin (default: '*')
- `$methods` (`array<string>`): Allowed methods
- `$headers` (`array<string>`): Allowed headers

**Returns:** `Response` - The response instance for method chaining

**Example:**
```php
#[HttpRoute('GET', '/api/public')]
public function publicApi(Request $request): Response
{
    return Response::json(['public' => 'data'])
                  ->withCors('*', ['GET', 'POST'], ['Content-Type', 'Authorization']);
}

#[HttpRoute('OPTIONS', '/api/users')]
public function preflight(Request $request): Response
{
            return Response::noContent()
                  ->setStatusCode(204)
                  ->withCors('https://example.com', ['GET', 'POST', 'PUT', 'DELETE']);
}
```

### withCache()

```php
public function withCache(int $maxAge, bool $public = true): Response
```

Adds cache control headers.

**Parameters:**
- `$maxAge` (`int`): Cache max age in seconds
- `$public` (`bool`): Whether cache is public (default: true)

**Returns:** `Response` - The response instance for method chaining

**Example:**
```php
#[HttpRoute('GET', '/api/static-data')]
public function staticData(Request $request): Response
{
    return Response::json(['data' => 'static'])
                  ->withCache(3600); // Cache for 1 hour
}

#[HttpRoute('GET', '/api/user-profile')]
public function userProfile(Request $request): Response
{
    return Response::json(['profile' => 'user data'])
                  ->withCache(300, false); // Private cache for 5 minutes
}
```

### withoutCache()

```php
public function withoutCache(): Response
```

Adds no-cache headers.

**Returns:** `Response` - The response instance for method chaining

**Example:**
```php
#[HttpRoute('GET', '/api/real-time-data')]
public function realTimeData(Request $request): Response
{
    return Response::json(['timestamp' => time()])
                  ->withoutCache();
}

#[HttpRoute('POST', '/api/sensitive')]
public function sensitiveOperation(Request $request): Response
{
    return Response::json(['result' => 'processed'])
                  ->withoutCache();
}
```

---

## Complete Response Examples

### REST API with Full Error Handling

```php
class UserApiController extends SocketController
{
    #[HttpRoute('GET', '/api/users/{id}')]
    public function getUser(Request $request): Response
    {
        $userId = $request->getParam('id');
        
        if (!is_numeric($userId)) {
            return Response::json([
                'error' => 'Invalid user ID',
                'code' => 'INVALID_ID'
            ], 400);
        }
        
        $user = $this->findUser((int)$userId);
        
        if (!$user) {
            return Response::json([
                'error' => 'User not found',
                'code' => 'USER_NOT_FOUND'
            ], 404);
        }
        
        return Response::json([
            'user' => $user,
            'meta' => [
                'requested_at' => date('c'),
                'version' => '1.0'
            ]
        ])->withCache(300); // Cache for 5 minutes
    }

    #[HttpRoute('POST', '/api/users')]
    public function createUser(Request $request): Response
    {
        $data = $request->isJson() ? 
                $request->getJsonBody() : 
                $request->getPostData();
        
        // Validation
        $validation = $this->validateUserData($data);
        if (!$validation['valid']) {
            return Response::json([
                'error' => 'Validation failed',
                'code' => 'VALIDATION_ERROR',
                'details' => $validation['errors']
            ], 422);
        }
        
        try {
            $user = $this->createNewUser($data);
            
            return Response::json([
                'user' => $user,
                'message' => 'User created successfully'
            ], 201, [
                'Location' => '/api/users/' . $user['id']
            ])->withoutCache();
            
        } catch (DuplicateEmailException $e) {
            return Response::json([
                'error' => 'Email already exists',
                'code' => 'DUPLICATE_EMAIL'
            ], 409);
            
        } catch (Exception $e) {
            error_log("User creation failed: " . $e->getMessage());
            
            return Response::json([
                'error' => 'Internal server error',
                'code' => 'INTERNAL_ERROR'
            ], 500);
        }
    }

    #[HttpRoute('PUT', '/api/users/{id}')]
    public function updateUser(Request $request): Response
    {
        $userId = (int)$request->getParam('id');
        $data = $request->isJson() ? 
                $request->getJsonBody() : 
                $request->getPostData();
        
        $user = $this->findUser($userId);
        if (!$user) {
            return Response::json(['error' => 'User not found'], 404);
        }
        
        // Partial validation (only validate provided fields)
        $validation = $this->validateUserData($data, true);
        if (!$validation['valid']) {
            return Response::json([
                'error' => 'Validation failed',
                'details' => $validation['errors']
            ], 422);
        }
        
        $updatedUser = $this->updateExistingUser($userId, $data);
        
        return Response::json([
            'user' => $updatedUser,
            'message' => 'User updated successfully'
        ])->withoutCache();
    }

    #[HttpRoute('DELETE', '/api/users/{id}')]
    public function deleteUser(Request $request): Response
    {
        $userId = (int)$request->getParam('id');
        
        if (!$this->userExists($userId)) {
            return Response::json(['error' => 'User not found'], 404);
        }
        
        $this->deleteExistingUser($userId);
        
        return Response::noContent(); // No Content
    }
}
```

### File Upload with Multiple Response Types

```php
class FileController extends SocketController
{
    #[HttpRoute('POST', '/api/upload')]
    public function uploadFile(Request $request): Response
    {
        if (!$request->isMultipart()) {
            return Response::json([
                'error' => 'Multipart form data required'
            ], 400);
        }
        
        $file = $request->getFile('file');
        if (!$file || $file['error'] !== UPLOAD_ERR_OK) {
            return Response::json([
                'error' => 'File upload failed'
            ], 400);
        }
        
        // Validate file
        $validation = $this->validateFile($file);
        if (!$validation['valid']) {
            return Response::json([
                'error' => 'File validation failed',
                'details' => $validation['errors']
            ], 422);
        }
        
        try {
            $savedFile = $this->saveFile($file);
            
            // Return different response based on Accept header
            $acceptHeader = $request->getHeader('Accept');
            
            if (str_contains($acceptHeader, 'text/plain')) {
                return Response::ok("File uploaded: {$savedFile['filename']}")
                              ->setHeader('X-File-ID', $savedFile['id']);
            }
            
            if (str_contains($acceptHeader, 'text/html')) {
                $html = "<h1>Upload Successful</h1>";
                $html .= "<p>File: {$savedFile['filename']}</p>";
                $html .= "<p>Size: {$savedFile['size']} bytes</p>";
                
                return Response::ok($html)->setContentType('text/html');
            }
            
            // Default to JSON
            return Response::json([
                'file' => $savedFile,
                'message' => 'File uploaded successfully'
            ], 201, [
                'Location' => '/api/files/' . $savedFile['id']
            ]);
            
        } catch (Exception $e) {
            return Response::json([
                'error' => 'Upload processing failed'
            ], 500);
        }
    }

    #[HttpRoute('GET', '/api/files/{id}')]
    public function downloadFile(Request $request): Response
    {
        $fileId = $request->getParam('id');
        $file = $this->findFile($fileId);
        
        if (!$file) {
            return Response::json(['error' => 'File not found'], 404);
        }
        
        if (!file_exists($file['path'])) {
            return Response::json(['error' => 'File data missing'], 410); // Gone
        }
        
        // Check if client wants inline or download
        $disposition = $request->getQuery('download') === '1' ? 
                      'attachment' : 'inline';
        
        return Response::file($file['path'], $file['mime_type'], [
            'Content-Disposition' => $disposition . '; filename="' . $file['original_name'] . '"',
            'Content-Length' => $file['size'],
            'Last-Modified' => gmdate('D, d M Y H:i:s T', $file['modified_time'])
        ])->withCache(86400); // Cache for 24 hours
    }

    #[HttpRoute('GET', '/api/files/{id}/info')]
    public function getFileInfo(Request $request): Response
    {
        $fileId = $request->getParam('id');
        $file = $this->findFile($fileId);
        
        if (!$file) {
            return Response::json(['error' => 'File not found'], 404);
        }
        
        return Response::json([
            'file' => [
                'id' => $file['id'],
                'filename' => $file['original_name'],
                'size' => $file['size'],
                'type' => $file['mime_type'],
                'uploaded_at' => $file['created_at'],
                'download_url' => '/api/files/' . $file['id']
            ]
        ])->withCache(3600);
    }
}
```

### Content Negotiation

```php
class ContentController extends SocketController
{
    #[HttpRoute('GET', '/api/data')]
    public function getData(Request $request): Response
    {
        $data = ['message' => 'Hello World', 'timestamp' => time()];
        
        $acceptHeader = $request->getHeader('Accept') ?? '';
        
        // XML response
        if (str_contains($acceptHeader, 'application/xml') || 
            str_contains($acceptHeader, 'text/xml')) {
            
            $xml = '<?xml version="1.0" encoding="UTF-8"?>';
            $xml .= '<response>';
            $xml .= '<message>' . htmlspecialchars($data['message']) . '</message>';
            $xml .= '<timestamp>' . $data['timestamp'] . '</timestamp>';
            $xml .= '</response>';
            
            return Response::ok($xml)
                          ->setHeader('Content-Type', 'application/xml');
        }
        
        // CSV response
        if (str_contains($acceptHeader, 'text/csv')) {
            $csv = "field,value\n";
            $csv .= "message,\"" . str_replace('"', '""', $data['message']) . "\"\n";
            $csv .= "timestamp," . $data['timestamp'] . "\n";
            
            return Response::ok($csv)
                          ->setHeader('Content-Type', 'text/csv')
                          ->setHeader('Content-Disposition', 'attachment; filename="data.csv"');
        }
        
        // Plain text response
        if (str_contains($acceptHeader, 'text/plain')) {
            $text = "Message: {$data['message']}\n";
            $text .= "Timestamp: {$data['timestamp']}\n";
            
            return Response::ok($text);
        }
        
        // Default to JSON
        return Response::json($data);
    }
}
```

---

## HTTP Status Code Reference

### Success (2xx)
- `200` OK - Request successful
- `201` Created - Resource created
- `202` Accepted - Request accepted for processing
- `204` No Content - Successful with no response body

### Client Error (4xx)
- `400` Bad Request - Invalid request
- `401` Unauthorized - Authentication required
- `403` Forbidden - Access denied
- `404` Not Found - Resource not found
- `409` Conflict - Resource conflict
- `422` Unprocessable Entity - Validation failed

### Server Error (5xx)
- `500` Internal Server Error - Server error
- `502` Bad Gateway - Gateway error
- `503` Service Unavailable - Service temporarily unavailable

---

## Best Practices

1. **Use Appropriate Status Codes**: Choose the most specific status code
2. **Include Error Details**: Provide helpful error messages and codes
3. **Set Proper Headers**: Use Content-Type, Cache-Control, etc.
4. **Method Chaining**: Chain methods for cleaner code
5. **Content Negotiation**: Support multiple response formats
6. **Security Headers**: Add security-related headers
7. **Consistent Format**: Use consistent response structure across your API

---

## See Also

- [Request API](api/request.md) - HTTP request handling
- [Controller API](api/controller.md) - Controller base class methods
- [HTTP Guide](http/request-response.md) - Request/response patterns
- [CORS Guide](http/cors.md) - Cross-origin resource sharing
