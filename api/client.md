---
title: "Client API - Sockeon Documentation"
description: "Complete API reference for Sockeon Client class with methods for connecting to WebSocket servers"
og_image: "https://sockeon.com/assets/logo.png"
twitter_image: "https://sockeon.com/assets/logo.png"
---

# Client API Reference

The Client provides a PHP interface for connecting to WebSocket servers, including Sockeon servers. It supports event-driven communication and can be used for testing or building client applications.

## Class: `Sockeon\Sockeon\Connection\Client`

### Constructor

```php
public function __construct(string $host, int $port, string $path = '/', int $timeout = 10)
```

Creates a new client instance.

**Parameters:**
- `$host` (`string`): The WebSocket server host
- `$port` (`int`): The WebSocket server port
- `$path` (`string`): The WebSocket endpoint path (default: '/')
- `$timeout` (`int`): Connection timeout in seconds (default: 10)

**Example:**
```php
use Sockeon\Sockeon\Connection\Client;

// Connect to local server
$client = new Client('localhost', 8080);

// Connect with custom path and timeout
$client = new Client('api.example.com', 443, '/ws', 30);
```

---

## Connection Management

### connect()

```php
public function connect(array $headers = []): bool
```

Establishes a connection to the WebSocket server.

**Parameters:**
- `$headers` (`array<string, string>`): Optional HTTP headers for the WebSocket handshake

**Returns:** `bool` - True if connection successful, false otherwise

**Example:**
```php
$client = new Client('localhost', 8080);

if ($client->connect(['Authorization' => 'Bearer token123'])) {
    echo "Connected successfully!\n";
} else {
    echo "Connection failed!\n";
}
```

### disconnect()

```php
public function disconnect(): void
```

Closes the WebSocket connection.

**Example:**
```php
$client = new Client('localhost', 8080);
$client->connect();

// Do some work...

$client->disconnect();
echo "Disconnected\n";
```

### isConnected()

```php
public function isConnected(): bool
```

Checks if the client is currently connected.

**Returns:** `bool` - True if connected, false otherwise

**Example:**
```php
$client = new Client('localhost', 8080);

if (!$client->isConnected()) {
    $client->connect();
}

if ($client->isConnected()) {
    // Send messages...
}
```

---

## Message Sending

### send()

```php
public function send(string $data): bool
```

Sends raw data to the server.

**Parameters:**
- `$data` (`string`): The data to send

**Returns:** `bool` - True if sent successfully, false otherwise

**Example:**
```php
$client = new Client('localhost', 8080);
$client->connect();

// Send raw text
$client->send('Hello Server!');

// Send JSON data
$client->send(json_encode([
    'event' => 'chat.message',
    'data' => ['message' => 'Hello World!']
]));
```

### emit()

```php
public function emit(string $event, array $data = []): bool
```

Sends a structured event to the server (Sockeon format).

**Parameters:**
- `$event` (`string`): The event name
- `$data` (`array<string, mixed>`): The event data

**Returns:** `bool` - True if sent successfully, false otherwise

**Example:**
```php
$client = new Client('localhost', 8080);
$client->connect();

// Send a chat message
$client->emit('chat.message', [
    'message' => 'Hello everyone!',
    'room' => 'general'
]);

// Send user login
$client->emit('user.login', [
    'username' => 'john_doe',
    'token' => 'abc123'
]);

// Send data without payload
$client->emit('ping');
```

---

## Message Receiving

### receive()

```php
public function receive(): ?string
```

Receives a message from the server (blocking).

**Returns:** `string|null` - The received message or null if connection closed

**Example:**
```php
$client = new Client('localhost', 8080);
$client->connect();

$client->emit('get.data');

// Wait for response
$response = $client->receive();
if ($response) {
    echo "Received: $response\n";
}
```

### receiveEvent()

```php
public function receiveEvent(): ?array
```

Receives and parses a Sockeon event from the server.

**Returns:** `array|null` - Parsed event array or null if no event

**Example:**
```php
$client = new Client('localhost', 8080);
$client->connect();

$client->emit('chat.join', ['room' => 'general']);

// Wait for event response
$event = $client->receiveEvent();
if ($event) {
    echo "Event: {$event['event']}\n";
    echo "Data: " . json_encode($event['data']) . "\n";
    /*
    Output:
    Event: room.joined
    Data: {"room":"general","message":"Welcome to general"}
    */
}
```

### receiveNonBlocking()

```php
public function receiveNonBlocking(): ?string
```

Receives a message without blocking.

**Returns:** `string|null` - The received message or null if no message available

**Example:**
```php
$client = new Client('localhost', 8080);
$client->connect();

while ($client->isConnected()) {
    // Check for messages without blocking
    $message = $client->receiveNonBlocking();
    
    if ($message) {
        echo "Received: $message\n";
    }
    
    // Do other work
    usleep(100000); // 100ms delay
}
```

---

## Event Handling

### onMessage()

```php
public function onMessage(callable $callback): void
```

Sets a callback for incoming messages.

**Parameters:**
- `$callback` (`callable`): Function to call when message received

**Example:**
```php
$client = new Client('localhost', 8080);

$client->onMessage(function($message) {
    echo "Message received: $message\n";
});

$client->connect();
```

### onEvent()

```php
public function onEvent(string $eventName, callable $callback): void
```

Sets a callback for specific events.

**Parameters:**
- `$eventName` (`string`): The event name to listen for
- `$callback` (`callable`): Function to call when event received

**Example:**
```php
$client = new Client('localhost', 8080);

// Listen for chat messages
$client->onEvent('chat.message', function($data) {
    echo "Chat: {$data['message']}\n";
});

// Listen for user events
$client->onEvent('user.joined', function($data) {
    echo "User {$data['username']} joined\n";
});

$client->connect();
```

### onConnect()

```php
public function onConnect(callable $callback): void
```

Sets a callback for successful connection.

**Parameters:**
- `$callback` (`callable`): Function to call when connected

**Example:**
```php
$client = new Client('localhost', 8080);

$client->onConnect(function() {
    echo "Connected to server!\n";
    // Auto-join a room
    $this->emit('room.join', ['room' => 'lobby']);
});

$client->connect();
```

### onDisconnect()

```php
public function onDisconnect(callable $callback): void
```

Sets a callback for disconnection.

**Parameters:**
- `$callback` (`callable`): Function to call when disconnected

**Example:**
```php
$client = new Client('localhost', 8080);

$client->onDisconnect(function() {
    echo "Disconnected from server\n";
    // Attempt reconnection
    sleep(5);
    $this->connect();
});

$client->connect();
```

---

## Advanced Features

### listen()

```php
public function listen(): void
```

Starts the event loop to continuously listen for messages.

**Note:** This method blocks and runs indefinitely until disconnected.

**Example:**
```php
$client = new Client('localhost', 8080);

$client->onMessage(function($message) {
    echo "Received: $message\n";
});

$client->onEvent('chat.message', function($data) {
    echo "Chat from {$data['from']}: {$data['message']}\n";
});

$client->connect();
$client->listen(); // Blocks here, listening for events
```

### setTimeout()

```php
public function setTimeout(int $seconds): void
```

Sets the timeout for socket operations.

**Parameters:**
- `$seconds` (`int`): Timeout in seconds

**Example:**
```php
$client = new Client('localhost', 8080);
$client->setTimeout(30); // 30 second timeout

$client->connect();
```

### setReconnect()

```php
public function setReconnect(bool $enabled, int $delay = 5): void
```

Enables/disables automatic reconnection.

**Parameters:**
- `$enabled` (`bool`): Whether to enable auto-reconnect
- `$delay` (`int`): Delay between reconnection attempts in seconds

**Example:**
```php
$client = new Client('localhost', 8080);
$client->setReconnect(true, 10); // Reconnect after 10 seconds

$client->connect();
```

---

## Complete Client Examples

### Simple Chat Client

```php
<?php

require_once 'vendor/autoload.php';

use Sockeon\Sockeon\Connection\Client;

$client = new Client('localhost', 8080);

// Set up event handlers
$client->onConnect(function() {
    echo "Connected! You can start typing messages.\n";
});

$client->onEvent('chat.message', function($data) {
    $from = $data['from'] ?? 'Unknown';
    $message = $data['message'] ?? '';
    echo "[$from]: $message\n";
});

$client->onEvent('user.joined', function($data) {
    echo ">> {$data['clientId']} joined the chat\n";
});

$client->onEvent('user.left', function($data) {
    echo ">> {$data['clientId']} left the chat\n";
});

$client->onDisconnect(function() {
    echo "Disconnected from server\n";
    exit(1);
});

// Connect to server
if (!$client->connect()) {
    echo "Failed to connect to server\n";
    exit(1);
}

// Send initial join message
$client->emit('chat.join', ['username' => 'PHPClient']);

// Read input from stdin and send messages
while (true) {
    // Check for incoming messages (non-blocking)
    $event = $client->receiveEvent();
    if ($event) {
        // Events are handled by callbacks set above
    }
    
    // Check for user input
    $read = [STDIN];
    $write = null;
    $except = null;
    
    if (stream_select($read, $write, $except, 0, 100000)) {
        $input = trim(fgets(STDIN));
        
        if ($input === '/quit') {
            break;
        }
        
        if (!empty($input)) {
            $client->emit('chat.message', ['message' => $input]);
        }
    }
}

$client->disconnect();
```

### API Testing Client

```php
<?php

class SockeonTestClient
{
    private Client $client;
    private array $responses = [];
    
    public function __construct(string $host, int $port)
    {
        $this->client = new Client($host, $port);
        
        // Collect all responses
        $this->client->onEvent('*', function($event, $data) {
            $this->responses[] = [
                'event' => $event,
                'data' => $data,
                'timestamp' => microtime(true)
            ];
        });
    }
    
    public function connect(): bool
    {
        return $this->client->connect();
    }
    
    public function testEvent(string $event, array $data = [], int $timeoutMs = 5000): array
    {
        // Clear previous responses
        $this->responses = [];
        
        // Send test event
        $this->client->emit($event, $data);
        
        // Wait for response
        $startTime = microtime(true);
        while ((microtime(true) - $startTime) * 1000 < $timeoutMs) {
            $response = $this->client->receiveEvent();
            if ($response) {
                return $response;
            }
            usleep(10000); // 10ms
        }
        
        throw new Exception("Timeout waiting for response to '$event'");
    }
    
    public function testSequence(array $tests): array
    {
        $results = [];
        
        foreach ($tests as $test) {
            $event = $test['event'];
            $data = $test['data'] ?? [];
            $expectedEvent = $test['expect'] ?? null;
            
            try {
                echo "Testing: $event\n";
                $response = $this->testEvent($event, $data);
                
                if ($expectedEvent && $response['event'] !== $expectedEvent) {
                    throw new Exception("Expected '{$expectedEvent}', got '{$response['event']}'");
                }
                
                $results[$event] = [
                    'success' => true,
                    'response' => $response
                ];
                
                echo "✓ Passed\n";
                
            } catch (Exception $e) {
                $results[$event] = [
                    'success' => false,
                    'error' => $e->getMessage()
                ];
                
                echo "✗ Failed: {$e->getMessage()}\n";
            }
        }
        
        return $results;
    }
    
    public function disconnect(): void
    {
        $this->client->disconnect();
    }
}

// Usage
$tester = new SockeonTestClient('localhost', 8080);

if (!$tester->connect()) {
    echo "Failed to connect\n";
    exit(1);
}

$tests = [
    [
        'event' => 'ping',
        'expect' => 'pong'
    ],
    [
        'event' => 'chat.join',
        'data' => ['room' => 'test'],
        'expect' => 'room.joined'
    ],
    [
        'event' => 'chat.message',
        'data' => ['message' => 'Hello test'],
        'expect' => 'chat.message'
    ],
    [
        'event' => 'invalid.event',
        'expect' => 'error'
    ]
];

$results = $tester->testSequence($tests);

echo "\nTest Results:\n";
foreach ($results as $event => $result) {
    $status = $result['success'] ? '✓' : '✗';
    echo "$status $event\n";
}

$tester->disconnect();
```

### Background Service Client

```php
<?php

class BackgroundServiceClient
{
    private Client $client;
    private bool $running = true;
    private array $eventQueue = [];
    
    public function __construct(string $host, int $port)
    {
        $this->client = new Client($host, $port);
        $this->client->setReconnect(true, 5);
        
        // Handle server events
        $this->client->onEvent('task.assigned', [$this, 'handleTaskAssigned']);
        $this->client->onEvent('task.cancel', [$this, 'handleTaskCancel']);
        
        $this->client->onConnect(function() {
            echo "[" . date('Y-m-d H:i:s') . "] Connected to server\n";
            $this->registerWorker();
        });
        
        $this->client->onDisconnect(function() {
            echo "[" . date('Y-m-d H:i:s') . "] Disconnected from server\n";
        });
    }
    
    public function start(): void
    {
        if (!$this->client->connect()) {
            throw new Exception("Failed to connect to server");
        }
        
        echo "Background service started\n";
        
        // Main event loop
        while ($this->running) {
            // Process incoming events
            $event = $this->client->receiveEvent();
            if ($event) {
                $this->eventQueue[] = $event;
            }
            
            // Process queued events
            $this->processEventQueue();
            
            // Send heartbeat every 30 seconds
            if (time() % 30 === 0) {
                $this->sendHeartbeat();
            }
            
            usleep(100000); // 100ms delay
        }
        
        $this->client->disconnect();
    }
    
    public function stop(): void
    {
        $this->running = false;
    }
    
    private function registerWorker(): void
    {
        $this->client->emit('worker.register', [
            'type' => 'background_service',
            'capabilities' => ['data_processing', 'file_conversion'],
            'max_concurrent_tasks' => 5
        ]);
    }
    
    private function sendHeartbeat(): void
    {
        $this->client->emit('worker.heartbeat', [
            'timestamp' => time(),
            'status' => 'running',
            'queue_length' => count($this->eventQueue)
        ]);
    }
    
    public function handleTaskAssigned(array $data): void
    {
        $taskId = $data['task_id'];
        $taskType = $data['type'];
        
        echo "[" . date('Y-m-d H:i:s') . "] Received task: $taskId ($taskType)\n";
        
        // Process task in background
        $this->processTask($taskId, $taskType, $data['payload'] ?? []);
    }
    
    public function handleTaskCancel(array $data): void
    {
        $taskId = $data['task_id'];
        echo "[" . date('Y-m-d H:i:s') . "] Task cancelled: $taskId\n";
        
        // Cancel task processing
        $this->cancelTask($taskId);
    }
    
    private function processTask(string $taskId, string $type, array $payload): void
    {
        // Send acknowledgment
        $this->client->emit('task.started', ['task_id' => $taskId]);
        
        try {
            // Simulate task processing
            switch ($type) {
                case 'data_processing':
                    $result = $this->processData($payload);
                    break;
                    
                case 'file_conversion':
                    $result = $this->convertFile($payload);
                    break;
                    
                default:
                    throw new Exception("Unknown task type: $type");
            }
            
            // Send completion
            $this->client->emit('task.completed', [
                'task_id' => $taskId,
                'result' => $result
            ]);
            
            echo "[" . date('Y-m-d H:i:s') . "] Task completed: $taskId\n";
            
        } catch (Exception $e) {
            // Send error
            $this->client->emit('task.failed', [
                'task_id' => $taskId,
                'error' => $e->getMessage()
            ]);
            
            echo "[" . date('Y-m-d H:i:s') . "] Task failed: $taskId - {$e->getMessage()}\n";
        }
    }
    
    private function processData(array $payload): array
    {
        // Simulate data processing
        sleep(2);
        return ['processed' => true, 'count' => count($payload)];
    }
    
    private function convertFile(array $payload): array
    {
        // Simulate file conversion
        sleep(5);
        return ['converted' => true, 'format' => $payload['target_format'] ?? 'pdf'];
    }
    
    private function cancelTask(string $taskId): void
    {
        // Implementation for task cancellation
        echo "Cancelling task: $taskId\n";
    }
    
    private function processEventQueue(): void
    {
        // Process events from queue
        while (!empty($this->eventQueue)) {
            $event = array_shift($this->eventQueue);
            // Handle queued events if needed
        }
    }
}

// Usage
$service = new BackgroundServiceClient('localhost', 8080);

// Handle shutdown signals
pcntl_signal(SIGTERM, function() use ($service) {
    $service->stop();
});

pcntl_signal(SIGINT, function() use ($service) {
    $service->stop();
});

try {
    $service->start();
} catch (Exception $e) {
    echo "Service error: {$e->getMessage()}\n";
    exit(1);
}
```

---

## Error Handling

### Connection Errors

```php
$client = new Client('localhost', 8080);

try {
    if (!$client->connect()) {
        throw new Exception("Connection failed");
    }
} catch (Exception $e) {
    echo "Error: {$e->getMessage()}\n";
}
```

### Timeout Handling

```php
$client = new Client('localhost', 8080);
$client->setTimeout(10); // 10 second timeout

$client->connect();

try {
    $response = $client->receive();
    if ($response === null) {
        echo "No response received\n";
    }
} catch (Exception $e) {
    echo "Timeout or error: {$e->getMessage()}\n";
}
```

---

## Best Practices

1. **Always Check Connection**: Verify connection before sending messages
2. **Handle Reconnection**: Implement auto-reconnect for robustness  
3. **Use Event Callbacks**: Prefer event handlers over polling
4. **Set Timeouts**: Configure appropriate timeouts for your use case
5. **Error Handling**: Always handle connection and message errors
6. **Clean Disconnection**: Properly disconnect when done
7. **Resource Management**: Don't keep connections open unnecessarily

---

## See Also

- [Server API](api/server.md) - Server configuration and methods
- [WebSocket Events](websocket/events.md) - Event handling patterns
- [Server Configuration](core/server-configuration.md) - Server setup and configuration
