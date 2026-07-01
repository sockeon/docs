---
title: "Reverse Proxy and Load Balancing - Sockeon Documentation"
description: "Complete guide to configuring Sockeon behind reverse proxies and load balancers"
og_image: "https://sockeon.github.io/logo.png"
twitter_image: "https://sockeon.github.io/logo.png"
---

# Reverse Proxy and Load Balancing

Sockeon is designed to work seamlessly behind reverse proxies (nginx, Apache, HAProxy) and load balancers. This guide covers configuration, security considerations, and best practices.

## Overview

When your Sockeon server sits behind a reverse proxy, the server only sees the proxy's IP address and connection details, not the real client information. Sockeon's trust proxy feature allows you to safely extract the real client information from proxy headers.

## Why Use a Reverse Proxy?

- **SSL/TLS Termination** - Handle HTTPS at the proxy level
- **Load Balancing** - Distribute traffic across multiple server instances
- **Security** - Add additional security layers (firewall, DDoS protection)
- **Caching** - Cache static content at the proxy level
- **Compression** - Compress responses at the proxy level
- **Logging** - Centralized logging and monitoring

## Configuration

### Basic Setup

```php
use Sockeon\Sockeon\Config\ServerConfig;
use Sockeon\Sockeon\Connection\Server;

$config = new ServerConfig([
    'host' => '0.0.0.0',
    'port' => 6001,
    'trust_proxy' => [
        '127.0.0.1',        // Localhost
        '10.0.0.0/8',       // Private network
        '192.168.0.0/16',   // Private network
    ],
    'health_check_path' => '/health',
]);

$server = new Server($config);
$server->run();
```

### Trust Proxy Settings

#### Trust All Proxies (Development Only)

```php
// ⚠️ WARNING: Never use in production!
$config->setTrustProxy(true);
```

#### Trust Specific IPs (Recommended)

```php
$config->setTrustProxy([
    '127.0.0.1',        // Localhost
    '10.0.0.5',         // Specific nginx server
    '10.0.0.6',         // Another nginx server
]);
```

#### Trust Network Ranges (CIDR)

```php
$config->setTrustProxy([
    '10.0.0.0/8',       // All 10.x.x.x addresses
    '172.16.0.0/12',    // All 172.16-31.x.x addresses
    '192.168.0.0/16',   // All 192.168.x.x addresses
]);
```

### Health Check Endpoint

Enable a health check endpoint for load balancers:

```php
$config->setHealthCheckPath('/health');
```

The health check returns:

```json
{
  "status": "healthy",
  "timestamp": 1234567890,
  "server": {
    "clients": 5,
    "uptime": 12345,
    "uptime_human": "3h 25m 45s"
  }
}
```

## Proxy Headers

Sockeon automatically processes the following headers when trust proxy is enabled:

### X-Forwarded-For

Contains the original client IP address.

```
X-Forwarded-For: 1.2.3.4
X-Forwarded-For: 1.2.3.4, 10.0.0.1  # Multiple proxies
```

### X-Forwarded-Proto

Contains the original protocol (http or https).

```
X-Forwarded-Proto: https
```

### X-Forwarded-Host

Contains the original hostname.

```
X-Forwarded-Host: api.example.com
```

### X-Forwarded-Port

Contains the original port number.

```
X-Forwarded-Port: 443
```

### Forwarded (RFC 7239)

Sockeon also supports the standard `Forwarded` header:

```
Forwarded: for=1.2.3.4;proto=https;host=api.example.com
```

## Nginx Configuration

### Basic Configuration

```nginx
server {
    listen 80;
    server_name api.example.com;

    location / {
        proxy_pass http://127.0.0.1:6001;
        proxy_http_version 1.1;

        # WebSocket support
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # Forward proxy headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;

        # Timeouts for WebSocket
        proxy_connect_timeout 7d;
        proxy_send_timeout 7d;
        proxy_read_timeout 7d;
    }
}
```

### HTTPS Configuration

```nginx
server {
    listen 443 ssl http2;
    server_name api.example.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://127.0.0.1:6001;
        proxy_http_version 1.1;

        # WebSocket support
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # Forward proxy headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
    }
}
```

## Apache Configuration

```apache
<VirtualHost *:443>
    ServerName api.example.com
    
    SSLEngine on
    SSLCertificateFile /path/to/cert.pem
    SSLCertificateKeyFile /path/to/key.pem

    <Location />
        ProxyPass http://127.0.0.1:6001/
        ProxyPassReverse http://127.0.0.1:6001/
        
        # WebSocket support
        RewriteEngine on
        RewriteCond %{HTTP:Upgrade} websocket [NC]
        RewriteCond %{HTTP:Connection} upgrade [NC]
        RewriteRule ^/?(.*) "ws://127.0.0.1:6001/$1" [P,L]
        
        # Forward proxy headers
        RequestHeader set X-Forwarded-Proto "https" env=HTTPS
        RequestHeader set X-Forwarded-Host %{HTTP_HOST}e
        RequestHeader set X-Forwarded-Port %{SERVER_PORT}e
        RequestHeader set X-Forwarded-For %{REMOTE_ADDR}e
    </Location>
</VirtualHost>
```

## HAProxy Configuration

```haproxy
frontend websocket_frontend
    bind *:443 ssl crt /path/to/cert.pem
    mode http
    default_backend websocket_backend

backend websocket_backend
    mode http
    balance roundrobin
    option httpchk GET /health
    http-check expect status 200
    server ws1 127.0.0.1:6001 check
    server ws2 127.0.0.1:6002 check
    
    # Forward headers
    http-request set-header X-Forwarded-Proto https if { ssl_fc }
    http-request set-header X-Forwarded-Proto http if !{ ssl_fc }
    http-request set-header X-Forwarded-Host %[req.hdr(Host)]
    http-request set-header X-Forwarded-Port %[dst_port]
    http-request set-header X-Forwarded-For %[src]
```

## Security Considerations

### Never Trust All Proxies in Production

```php
// ❌ BAD - Security vulnerability
$config->setTrustProxy(true);

// ✅ GOOD - Specific trusted IPs
$config->setTrustProxy(['127.0.0.1', '10.0.0.0/8']);
```

### Why It's Dangerous

If you trust all proxies, an attacker who can reach your server directly can send fake headers:

```bash
# Attacker sends request directly to server
curl -H "X-Forwarded-For: 1.1.1.1" \
     -H "X-Forwarded-Proto: https" \
     http://your-server:6001/api/info

# Server thinks request came from 1.1.1.1 via HTTPS
# But it actually came directly from attacker's IP
```

### Best Practices

1. **Always use specific IPs or CIDR ranges** in production
2. **Use private network ranges** (10.x.x.x, 172.16-31.x.x, 192.168.x.x) for internal proxies
3. **Only trust proxies you control**
4. **Test your configuration** to ensure it works correctly
5. **Monitor for suspicious activity** in your logs

## Testing

### Test Request Details

Create an endpoint to verify proxy headers are working:

```php
#[HttpRoute('GET', '/api/request-details')]
public function getRequestDetails(Request $request): Response
{
    return Response::json([
        'ip_address' => $request->getIpAddress(),
        'scheme' => $request->getScheme(),
        'host' => $request->getHost(),
        'port' => $request->getPort(),
        'url' => $request->getUrl(),
        'headers' => $request->getHeaders(),
    ]);
}
```

### Test Health Check

```bash
curl http://api.example.com/health
```

Expected response:

```json
{
  "status": "healthy",
  "timestamp": 1234567890,
  "server": {
    "clients": 5,
    "uptime": 12345,
    "uptime_human": "3h 25m 15s"
  }
}
```

## Troubleshooting

### Problem: IP Address Shows Proxy IP

**Solution**: Ensure proxy IP is in trusted list:

```php
$config->setTrustProxy(['10.0.0.5']); // Your proxy IP
```

### Problem: Scheme Always Shows "http"

**Solution**: Ensure proxy sends X-Forwarded-Proto header:

```nginx
proxy_set_header X-Forwarded-Proto $scheme;
```

### Problem: Wrong URL in getUrl()

**Solution**: Ensure all proxy headers are set in nginx:

```nginx
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header X-Forwarded-Host $host;
proxy_set_header X-Forwarded-Port $server_port;
```

## Load Balancing

### Multiple Server Instances

Run multiple Sockeon server instances on different ports:

```bash
# Server 1
php server.php --port=6001

# Server 2
php server.php --port=6002

# Server 3
php server.php --port=6003
```

### Sticky Sessions

For WebSocket connections, use sticky sessions in your load balancer to ensure clients stay connected to the same server instance.

**Nginx sticky sessions:**

```nginx
upstream sockeon_backend {
    ip_hash;  # Sticky sessions based on client IP
    server 127.0.0.1:6001;
    server 127.0.0.1:6002;
    server 127.0.0.1:6003;
}

server {
    location / {
        proxy_pass http://sockeon_backend;
        # ... proxy headers ...
    }
}
```

## See Also

- [Server Configuration](/v3.0/core/server-configuration.md) - Complete server configuration guide
- [Request API](/v3.0/api/request.md) - Request methods for proxy headers
- [Server API](/v3.0/api/server.md) - Server uptime and health check methods

