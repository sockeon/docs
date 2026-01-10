# System Room Controller

The SystemRoomController is a built-in controller that automatically handles room management for WebSocket connections.

## Overview

By default, Sockeon registers a system controller that processes `join_room` and `leave_room` events from clients, making room management seamless out-of-the-box.

## Features

- ✅ Automatic room join/leave handling
- ✅ Namespace support
- ✅ Input validation (room names, namespaces)
- ✅ Confirmation events (`room_joined`, `room_left`)
- ✅ Error handling with detailed error events
- ✅ Can be disabled or overridden

## Events Handled

### `join_room`

Client sends this event to join a room.

**Expected data:**
```json
{
  "room": "room-name",
  "namespace": "/namespace" // optional, defaults to "/"
}
```

**Success response:**
```json
{
  "event": "room_joined",
  "data": {
    "room": "room-name",
    "namespace": "/namespace",
    "timestamp": 1234567890
  }
}
```

**Error response:**
```json
{
  "event": "error",
  "data": {
    "message": "Invalid room name",
    "event": "join_room"
  }
}
```

### `leave_room`

Client sends this event to leave a room.

**Expected data:**
```json
{
  "room": "room-name",
  "namespace": "/namespace" // optional, defaults to "/"
}
```

**Success response:**
```json
{
  "event": "room_left",
  "data": {
    "room": "room-name",
    "namespace": "/namespace",
    "timestamp": 1234567890
  }
}
```

## Configuration

### Enable/Disable System Controllers

By default, system controllers are enabled. You can disable them:

```php
use Sockeon\Sockeon\Config\ServerConfig;
use Sockeon\Sockeon\Connection\Server;

$config = new ServerConfig([
    'host' => '0.0.0.0',
    'port' => 6001,
    'register_system_controllers' => false, // Disable system controllers
]);

$server = new Server($config);
```

## Custom Room Logic

### Option 1: Disable and Implement Your Own

```php
$config = new ServerConfig([
    'register_system_controllers' => false,
]);

$server = new Server($config);

// Register your custom controller
$server->registerController(new MyCustomRoomController());
```

**MyCustomRoomController.php:**
```php
use Sockeon\Sockeon\Controllers\SocketController;
use Sockeon\Sockeon\WebSocket\Attributes\SocketOn;

class MyCustomRoomController extends SocketController
{
    #[SocketOn('join_room')]
    public function handleJoinRoom(string $clientId, array $data): bool
    {
        // Add your custom logic here
        // - Authentication checks
        // - Room capacity limits
        // - Permission validation
        // - Logging
        
        $room = $data['room'] ?? null;
        $namespace = $data['namespace'] ?? '/';
        
        // Check if user has permission to join
        if (!$this->hasPermission($clientId, $room)) {
            $this->emit($clientId, 'error', [
                'message' => 'You do not have permission to join this room',
            ]);
            return false;
        }
        
        // Join the room
        $this->joinRoom($clientId, $room, $namespace);
        
        // Send custom confirmation
        $this->emit($clientId, 'room_joined', [
            'room' => $room,
            'namespace' => $namespace,
            'members' => $this->getClientsInRoom($room, $namespace),
        ]);
        
        return true;
    }
    
    private function hasPermission(string $clientId, string $room): bool
    {
        // Your permission logic
        return true;
    }
}
```

### Option 2: Extend SystemRoomController

```php
use Sockeon\Sockeon\Controllers\SystemRoomController;

class EnhancedRoomController extends SystemRoomController
{
    #[SocketOn('join_room')]
    public function onJoinRoom(string $clientId, array $data): bool
    {
        // Add pre-processing logic
        $this->logRoomJoin($clientId, $data);
        
        // Call parent implementation
        $result = parent::onJoinRoom($clientId, $data);
        
        // Add post-processing logic
        if ($result) {
            $this->notifyRoomMembers($clientId, $data['room']);
        }
        
        return $result;
    }
    
    #[SocketOn('leave_room')]
    public function onLeaveRoom(string $clientId, array $data): bool
    {
        $result = parent::onLeaveRoom($clientId, $data);
        
        if ($result) {
            $this->notifyRoomMembers($clientId, $data['room']);
        }
        
        return $result;
    }
    
    private function logRoomJoin(string $clientId, array $data): void
    {
        $this->getLogger()->info("Client $clientId joining room: {$data['room']}");
    }
    
    private function notifyRoomMembers(string $clientId, string $room): void
    {
        $this->broadcast('room.member_update', [
            'clientId' => $clientId,
            'room' => $room,
            'action' => 'joined',
        ], '/', $room);
    }
}
```

Then register your custom controller:

```php
$config = new ServerConfig([
    'register_system_controllers' => false, // Disable default
]);

$server = new Server($config);
$server->registerController(new EnhancedRoomController());
```

## Client Usage

Works seamlessly with `@sockeon/client`:

```javascript
import { Sockeon } from '@sockeon/client';

const socket = new Sockeon({
  url: 'ws://localhost:6001',
});

socket.on('connect', () => {
  // Join a room
  socket.joinRoom('game-room-42');
});

// Listen for confirmation
socket.on('room_joined', (data) => {
  console.log('Joined room:', data.room);
});

// Listen for errors
socket.on('error', (error) => {
  console.error('Error:', error.message);
});

// Leave room
socket.leaveRoom('game-room-42');
```

## Validation

The system controller validates:

1. **Room name**: Must be a non-empty string
2. **Namespace**: Must be a non-empty string (defaults to `/`)

Invalid requests receive an error event.

## Error Handling

All errors are caught and:
- Logged via the server logger
- Sent to the client as an `error` event

This ensures the connection remains stable even if room operations fail.

## Thread Safety

The SystemRoomController is thread-safe when used with Sockeon's single-threaded event loop.

## Best Practices

1. **Always listen for confirmation events** (`room_joined`, `room_left`) in your client
2. **Handle error events** to provide user feedback
3. **Use namespaces** to isolate different parts of your application
4. **Override with custom logic** when you need authentication or permissions
5. **Log important room operations** for debugging and analytics
