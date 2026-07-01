---
title: "Event API - Sockeon Documentation"
description: "Reference for Sockeon's Event broadcaster and EventableContract for custom event classes"
og_image: "https://sockeon.github.io/logo.png"
twitter_image: "https://sockeon.github.io/logo.png"
---

# Event API Reference

Use `Sockeon\Sockeon\Core\Event` to broadcast from non-controller code (services, jobs, CLI scripts).

## Class: `Sockeon\Sockeon\Core\Event`

### broadcast()

```php
public static function broadcast(EventableContract $event): void
```

Broadcasts a custom event by writing a payload to Sockeon's queue file.

## Contract: `Sockeon\Sockeon\Contracts\WebSocket\EventableContract`

Your custom event class must implement:

```php
public function broadcastAs(): string;
public function broadcastWith(): array;
public function broadcastOn(): ?array;
public function broadcastNamespace(): ?string;
```

## Example Custom Event

```php
use Sockeon\Sockeon\Contracts\WebSocket\EventableContract;
use Sockeon\Sockeon\Core\Event;

final class InventoryChanged implements EventableContract
{
    public function __construct(
        private readonly string $sku,
        private readonly int $available
    ) {
    }

    public function broadcastAs(): string
    {
        return 'inventory.changed';
    }

    public function broadcastWith(): array
    {
        return [
            'sku' => $this->sku,
            'available' => $this->available,
            'time' => time(),
        ];
    }

    public function broadcastOn(): ?array
    {
        return ['warehouse', 'admin'];
    }

    public function broadcastNamespace(): ?string
    {
        return '/inventory';
    }
}

Event::broadcast(new InventoryChanged('SKU-123', 42));
```

## Behavior Details

- `broadcastOn()` returns room names to broadcast to.
- `broadcastNamespace()` defaults to `/` when null.
- If `broadcastOn()` is null/empty, no room payload is emitted.

## See Also

- [WebSocket Events](/v3.0/websocket/events.md)
- [Broadcasting](/v3.0/websocket/broadcasting.md)
