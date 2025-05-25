# API Reference

This document provides detailed technical reference for the Sockeon package - a PHP WebSocket and HTTP server library.

## Core Classes

### Server

`Sockeon\Sockeon\Core\Server`

The main class that handles the socket server implementation, client connections, and dispatches requests to appropriate handlers.

#### Properties

- `$socket`: Socket resource for the server
- `$clients`: Array of active client connections
- `$clientTypes`: Array mapping client IDs to connection types ('ws' for WebSocket, 'http' for HTTP)
- `$clientData`: Custom data associated with clients
- `$router`: Router instance
- `$wsHandler`: WebSocketHandler instance
- `$httpHandler`: HttpHandler instance
- `$namespaceManager`: NamespaceManager instance
- `$middleware`: Middleware instance
- `$isDebug`: Boolean flag for debug mode

#### Methods

- `__construct(string $host = "0.0.0.0", int $port = 6001, bool $debug = false)`: Initializes the server on the specified host and port
- `registerController(SocketController $controller): void`: Registers a controller with the server
- `getRouter(): Router`: Returns the router instance
- `getNamespaceManager(): NamespaceManager`: Returns the namespace manager instance
- `getHttpHandler(): HttpHandler`: Returns the HTTP handler instance
- `getMiddleware(): Middleware`: Returns the middleware instance
- `addWebSocketMiddleware(Closure $middleware): self`: Adds a WebSocket middleware function
- `addHttpMiddleware(Closure $middleware): self`: Adds an HTTP middleware function
- `run(): void`: Starts the server and listens for connections
- `disconnectClient(int $clientId): void`: Disconnects a client from the server
- `setClientData(int $clientId, string $key, mixed $value): void`: Sets data for a specific client
- `getClientData(int $clientId, ?string $key = null): mixed`: Gets data for a specific client
- `send(int $clientId, string $event, array $data): void`: Sends a message to a specific client
- `broadcast(string $event, array $data, ?string $namespace = null, ?string $room = null): void`: Broadcasts a message to multiple clients
- `joinRoom(int $clientId, string $room, string $namespace = '/'): void`: Adds a client to a room
- `leaveRoom(int $clientId, string $room, string $namespace = '/'): void`: Removes a client from a room
- `log(string $message): void`: Logs a message if debug mode is enabled

### Router

`Sockeon\Sockeon\Core\Router`

Manages routing of WebSocket events and HTTP requests to controller methods.

#### Properties

- `$wsRoutes`: Array of WebSocket routes
- `$httpRoutes`: Array of HTTP routes
- `$server`: Server instance

#### Methods

- `setServer(Server $server): void`: Sets the server instance
- `register(SocketController $controller): void`: Registers a controller's routes using reflection
- `dispatch(int $clientId, string $event, array $data): mixed`: Dispatches a WebSocket event to its handler
- `dispatchHttp(Request $request): mixed`: Dispatches an HTTP request to its handler
- `matchHttpRoute(string $method, string $path): ?array`: Matches an HTTP method and path to a route
- `extractPathParameters(string $routePath, string $requestPath): array`: Extracts path parameters from a route

### Middleware

`Sockeon\Sockeon\Core\Middleware`

Manages middleware chains for WebSocket and HTTP pipelines.

#### Properties

- `$wsStack`: Stack of WebSocket middleware functions
- `$httpStack`: Stack of HTTP middleware functions

#### Methods

- `addWebSocketMiddleware(Closure $middleware): void`: Adds a WebSocket middleware function
- `addHttpMiddleware(Closure $middleware): void`: Adds an HTTP middleware function
- `runWebSocketStack(int $clientId, string $event, array $data, Closure $target): mixed`: Executes the WebSocket middleware stack
- `runHttpStack(Request $request, Closure $target): mixed`: Executes the HTTP middleware stack

### NamespaceManager

`Sockeon\Sockeon\Core\NamespaceManager`

Manages namespaces and rooms for WebSocket connections.

#### Properties

- `$namespaces`: Array of namespaces and clients within them
- `$rooms`: Array of room definitions
- `$clientNamespaces`: Map of which clients belong to which namespaces
- `$clientRooms`: Map of which clients belong to which rooms

#### Methods

- `joinNamespace(int $clientId, string $namespace = '/'): void`: Adds a client to a namespace
- `leaveNamespace(int $clientId): void`: Removes a client from its namespace
- `joinRoom(int $clientId, string $room, string $namespace = '/'): void`: Adds a client to a room within a namespace
- `leaveRoom(int $clientId, string $room, string $namespace = '/'): void`: Removes a client from a room
- `leaveAllRooms(int $clientId): void`: Removes a client from all rooms
- `getClientsInRoom(string $room, string $namespace = '/'): array`: Gets all clients in a specific room
- `getClientsInNamespace(string $namespace = '/'): array`: Gets all clients in a specific namespace
- `getRoomsForClient(int $clientId): array`: Gets all rooms that a client belongs to

## WebSocket Components

### WebSocketHandler

`Sockeon\Sockeon\WebSocket\WebSocketHandler`

Handles WebSocket protocol implementation, connections and message framing.

#### Properties

- `$server`: Reference to the server instance
- `$handshakes`: Array tracking completed handshakes by client ID

#### Methods

- `__construct(Server $server)`: Constructor that takes a Server instance
- `handle(int $clientId, resource $client, string $data): bool`: Handle an incoming WebSocket message
- `performHandshake(int $clientId, resource $client, string $data): bool`: Perform WebSocket handshake with client
- `decodeWebSocketFrame(string $data): array`: Decode WebSocket frames from raw data
- `prepareMessage(string $event, array $data): string`: Prepare a WebSocket message for sending
- `sendPong(resource $client): void`: Sends a pong frame in response to a ping
- `generateAcceptKey(string $key): string`: Generate the accept key for WebSocket handshake

### SocketOn Attribute

`Sockeon\Sockeon\WebSocket\Attributes\SocketOn`

Attribute for marking methods as WebSocket event handlers.

#### Properties

- `$event`: The event name this handler responds to

#### Methods

- `__construct(string $event)`: Constructor that sets the event name

## HTTP Components

### HttpHandler

`Sockeon\Sockeon\Http\HttpHandler`

Handles HTTP protocol implementation, request parsing and responses.

#### Properties

- `$server`: Reference to the server instance
- `$routes`: Registered HTTP routes

#### Methods

- `__construct(Server $server)`: Constructor that takes a Server instance
- `handle(int $clientId, resource $client, string $data): void`: Handle an incoming HTTP request
- `parseHttpRequest(string $data): array`: Parse raw HTTP request into structured format
- `processRequest(Request $request): string`: Process an HTTP request and generate a response

### Request

`Sockeon\Sockeon\Http\Request`

Handles HTTP request data encapsulation and provides convenient methods to access request parameters, headers, and body.

#### Properties

- `$method`: HTTP method (GET, POST, PUT, etc.)
- `$path`: Request path
- `$protocol`: HTTP protocol version
- `$headers`: Request headers
- `$query`: Query parameters
- `$params`: Path parameters
- `$body`: Request body
- `$rawData`: Raw request data
- `$normalizedHeaders`: Normalized headers cache (lowercase keys)

#### Methods

- `__construct(array $requestData)`: Constructor that takes parsed HTTP request data
- `getMethod(): string`: Get HTTP method
- `getPath(): string`: Get request path
- `getProtocol(): string`: Get HTTP protocol
- `getHeaders(): array`: Get all headers
- `getHeader(string $name): ?string`: Get a specific header value
- `hasHeader(string $name): bool`: Check if a header exists
- `getQuery(): array`: Get all query parameters
- `getQueryParam(string $name, mixed $default = null): mixed`: Get a specific query parameter
- `hasQueryParam(string $name): bool`: Check if a query parameter exists
- `getParams(): array`: Get all path parameters
- `getParam(string $name, mixed $default = null): mixed`: Get a specific path parameter
- `hasParam(string $name): bool`: Check if a path parameter exists
- `getBody(): mixed`: Get the request body
- `getData(string $key = null, mixed $default = null): mixed`: Get data from body or query parameters
- `isJson(): bool`: Check if this is a JSON request
- `isAjax(): bool`: Check if the request is an XHR/AJAX request
- `isMethod(string $method): bool`: Check if this is a specific HTTP method
- `getUrl(bool $includeQuery = false): string`: Get the request URL

### Response

`Sockeon\Sockeon\Http\Response`

Handles HTTP response generation with status codes, headers, and body.

#### Properties

- `$statusCode`: HTTP status code
- `$headers`: Response headers
- `$body`: Response body
- `$contentType`: Content type
- `$statusTexts`: HTTP status texts

#### Methods

- `__construct(mixed $body = null, int $statusCode = 200, array $headers = [])`: Constructor
- `setBody(mixed $body): self`: Set response body
- `getBody(): mixed`: Get response body
- `setStatusCode(int $code): self`: Set HTTP status code
- `getStatusCode(): int`: Get HTTP status code
- `setHeader(string $name, string $value): self`: Set a response header
- `getHeaders(): array`: Get all response headers
- `setContentType(string $contentType): self`: Set the content type
- `getContentType(): string`: Get the content type
- `toString(): string`: Convert the response to a string for output
- `getBodyString(): string`: Get the body as a string
- `getStatusText(int $code): string`: Get the text for an HTTP status code
- `static json(mixed $data, int $code = 200, array $headers = []): self`: Create a JSON response
- `static html(string $html, int $code = 200, array $headers = []): self`: Create an HTML response
- `static text(string $text, int $code = 200, array $headers = []): self`: Create a text response
- `static redirect(string $url, int $code = 302, array $headers = []): self`: Create a redirect response
- `static notFound(mixed $data = 'Not Found', array $headers = []): self`: Create a 404 Not Found response
- `static serverError(mixed $data = 'Internal Server Error', array $headers = []): self`: Create a 500 Server Error response
- `static unauthorized(mixed $data = 'Unauthorized', array $headers = []): self`: Create a 401 Unauthorized response
- `static forbidden(mixed $data = 'Forbidden', array $headers = []): self`: Create a 403 Forbidden response
- `static badRequest(mixed $data = 'Bad Request', array $headers = []): self`: Create a 400 Bad Request response

### HttpRoute Attribute

`Sockeon\Sockeon\Http\Attributes\HttpRoute`

Attribute for marking methods as HTTP route handlers.

#### Properties

- `$method`: The HTTP method (GET, POST, PUT, DELETE, etc.)
- `$path`: The URL path to handle, can include path parameters like {id}

#### Methods

- `__construct(string $method, string $path)`: Constructor

## Base Classes

### SocketController

`Sockeon\Sockeon\Core\Contracts\SocketController`

Base class for all socket controllers providing access to core server functionalities.

#### Properties

- `$server`: Instance of the server

#### Methods

- `setServer(Server $server): void`: Sets the server instance for this controller
- `emit(int $clientId, string $event, array $data): void`: Emits an event to a specific client
- `broadcast(string $event, array $data, ?string $namespace = null, ?string $room = null): void`: Broadcasts an event to multiple clients
- `joinRoom(int $clientId, string $room, string $namespace = '/'): void`: Adds a client to a room
- `leaveRoom(int $clientId, string $room, string $namespace = '/'): void`: Removes a client from a room
- `disconnectClient(int $clientId): void`: Disconnects a client from the server