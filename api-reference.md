---
title: "API Reference - Sockeon Documentation v1.0"
description: "Complete technical reference for Sockeon's dual-protocol PHP library. Detailed documentation of all classes, methods, and configuration options for WebSocket and HTTP implementations."
og_image: "https://sockeon.com/assets/logo.png"
twitter_image: "https://sockeon.com/assets/logo.png"
---

# WebSocket & HTTP API Reference

This document provides detailed technical reference for Sockeon's dual-protocol capabilities, covering both WebSocket and HTTP implementations. Use this comprehensive guide to understand all available classes, methods, and configuration options for building applications that leverage both real-time WebSocket communication and HTTP request handling.

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
- `$logger`: LoggerInterface instance for application logging

#### Methods

- `__construct(string $host = "0.0.0.0", int $port = 6001, bool $debug = false, array $corsConfig = [], ?LoggerInterface $logger = null)`: Initializes the server on the specified host and port with optional CORS configuration and custom logger
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
- `getLogger(): LoggerInterface`: Returns the logger instance for advanced logging

### Router

`Sockeon\Sockeon\Core\Router`

Manages routing of WebSocket events and HTTP requests to controller methods.

#### Properties

- `$wsRoutes`: Array of WebSocket routes
- `$httpRoutes`: Array of HTTP routes
- `$specialEventHandlers`: Array of special event handlers (connect/disconnect)
- `$server`: Server instance

#### Methods

- `setServer(Server $server): void`: Sets the server instance
- `register(SocketController $controller): void`: Registers a controller's routes using reflection
- `dispatch(int $clientId, string $event, array $data): mixed`: Dispatches a WebSocket event to its handler
- `dispatchSpecialEvent(int $clientId, string $eventType): void`: Dispatches special events (connect/disconnect) to all registered handlers
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
- `$allowedOrigins`: Array of allowed origins for WebSocket connections

#### Methods

- `__construct(Server $server, array $allowedOrigins = ['*'])`: Constructor that takes a Server instance and optional allowed origins
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

### OnConnect Attribute

`Sockeon\Sockeon\WebSocket\Attributes\OnConnect`

Attribute for marking methods as WebSocket connection event handlers. Methods marked with this attribute are automatically called when a client establishes a WebSocket connection.

#### Properties

None.

#### Methods

- `__construct()`: Constructor for the OnConnect attribute

### OnDisconnect Attribute

`Sockeon\Sockeon\WebSocket\Attributes\OnDisconnect`

Attribute for marking methods as WebSocket disconnection event handlers. Methods marked with this attribute are automatically called when a client disconnects from the WebSocket.

#### Properties

None.

#### Methods

- `__construct()`: Constructor for the OnDisconnect attribute

## HTTP Components

### CorsConfig

`Sockeon\Sockeon\Http\CorsConfig`

Handles Cross-Origin Resource Sharing (CORS) configurations for the server.

#### Properties

- `$allowedOrigins`: Array of allowed origins, defaults to ['*'] (allow all)
- `$allowedMethods`: Array of allowed HTTP methods, defaults to ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH', 'HEAD']
- `$allowedHeaders`: Array of allowed headers, defaults to ['Content-Type', 'X-Requested-With', 'Authorization']
- `$allowCredentials`: Whether to allow credentials (cookies, authorization headers), defaults to false
- `$maxAge`: Max age for preflight requests in seconds, defaults to 86400 (1 day)

#### Methods

- `__construct(array $config = [])`: Creates a new CORS configuration instance with optional config parameters
- `getAllowedOrigins(): array`: Returns the array of allowed origins
- `getAllowedMethods(): array`: Returns the array of allowed methods
- `getAllowedHeaders(): array`: Returns the array of allowed headers
- `getAllowCredentials(): bool`: Returns whether credentials are allowed
- `getMaxAge(): int`: Returns the max age for preflight requests
- `isOriginAllowed(string $origin): bool`: Checks if the given origin is allowed

### HttpHandler

`Sockeon\Sockeon\Http\HttpHandler`

Handles HTTP protocol implementation, request parsing and responses.

#### Properties

- `$server`: Reference to the server instance
- `$routes`: Registered HTTP routes
- `$corsConfig`: CORS configuration for HTTP responses

#### Methods

- `__construct(Server $server, array $corsConfig = [])`: Constructor that takes a Server instance and optional CORS configuration
- `handle(int $clientId, resource $client, string $data): void`: Handle an incoming HTTP request
- `parseHttpRequest(string $data): array`: Parse raw HTTP request into structured format
- `processRequest(Request $request): string`: Process an HTTP request and generate a response
- `addCorsHeaders(Response $response, Request $request): Response`: Add CORS headers to a response based on configuration
- `handlePreflightRequest(Request $request): Response`: Handle CORS preflight requests

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

## Logging Components

### LoggerInterface

`Sockeon\Sockeon\Logging\LoggerInterface`

Interface that defines standard logging methods according to PSR-3 logging standards.

#### Methods

- `emergency(string $message, array $context = []): void`: Log a message with emergency level (system is unusable)
- `alert(string $message, array $context = []): void`: Log a message with alert level (action must be taken immediately)
- `critical(string $message, array $context = []): void`: Log a message with critical level (critical conditions)
- `error(string $message, array $context = []): void`: Log a message with error level (error conditions)
- `warning(string $message, array $context = []): void`: Log a message with warning level (warning conditions)
- `notice(string $message, array $context = []): void`: Log a message with notice level (normal but significant events)
- `info(string $message, array $context = []): void`: Log a message with info level (informational messages)
- `debug(string $message, array $context = []): void`: Log a message with debug level (detailed debug information)
- `log(string $level, string $message, array $context = []): void`: Log a message with an arbitrary level
- `exception(Throwable $exception, array $context = []): void`: Log an exception with error level

### Logger

`Sockeon\Sockeon\Logging\Logger`

Default implementation of LoggerInterface. Supports console and file logging with ANSI color formatting.

#### Properties

- `$logDirectory`: Directory path where log files will be stored
- `$minLogLevel`: Current minimum log level
- `$logToConsole`: Whether to output logs to the console
- `$logToFile`: Whether to log to a file
- `$separateLogFiles`: Whether to create separate log files for each level
- `$colors`: ANSI color codes for console output

#### Methods

- `__construct(string $minLogLevel = LogLevel::DEBUG, bool $logToConsole = true, bool $logToFile = true, ?string $logDirectory = null, bool $separateLogFiles = false)`: Create a new logger instance
- `emergency(string $message, array $context = []): void`: Log with emergency level
- `alert(string $message, array $context = []): void`: Log with alert level
- `critical(string $message, array $context = []): void`: Log with critical level
- `error(string $message, array $context = []): void`: Log with error level
- `warning(string $message, array $context = []): void`: Log with warning level
- `notice(string $message, array $context = []): void`: Log with notice level
- `info(string $message, array $context = []): void`: Log with info level
- `debug(string $message, array $context = []): void`: Log with debug level
- `log(string $level, string $message, array $context = []): void`: Log with an arbitrary level
- `exception(Throwable $exception, array $context = []): void`: Log an exception with error level
- `formatMessage(string $level, string $message, array $context = []): string`: Format a log message
- `shouldLog(string $level): bool`: Check if a message at the given level should be logged

### LogLevel

`Sockeon\Sockeon\Logging\LogLevel`

Class with constants for standard logging levels according to PSR-3.

#### Constants

- `EMERGENCY`: System is unusable
- `ALERT`: Action must be taken immediately
- `CRITICAL`: Critical conditions
- `ERROR`: Error conditions
- `WARNING`: Warning conditions
- `NOTICE`: Normal but significant events
- `INFO`: Informational messages
- `DEBUG`: Detailed debug information

#### Methods

- `getLevels(): array`: Get all available log levels
- `isValidLevel(string $level): bool`: Check if a level name is valid
- `toInt(string $level): int`: Convert a level name to its numeric priority
- `toString(int $level): string`: Convert a numeric level to its string name