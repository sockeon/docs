---
title: "Data Sanitization - Sockeon Documentation"
description: "Learn about Sockeon's standalone sanitization utilities for cleaning and normalizing data"
og_image: "https://sockeon.com/assets/logo.png"
twitter_image: "https://sockeon.com/assets/logo.png"
---

# Data Sanitization

Sockeon provides comprehensive sanitization utilities through the `Sanitizer` class, offering standalone data cleaning and normalization functions for various data types.

## Overview

The `Sanitizer` class provides:

- **Standalone sanitization** - Independent of validation
- **Type-specific cleaning** - Specialized functions for different data types
- **Security-focused** - XSS protection and input normalization
- **Flexible options** - Configurable sanitization behavior
- **Comprehensive coverage** - Support for strings, numbers, arrays, and more

## Basic Usage

```php
use Sockeon\Sockeon\Validation\Sanitizer;

// Basic sanitization
$cleanString = Sanitizer::string($userInput, true, true);
$cleanEmail = Sanitizer::email($userInput);
$cleanInteger = Sanitizer::integer($userInput, 0);
$cleanBoolean = Sanitizer::boolean($userInput);
$cleanArray = Sanitizer::array($userInput);
```

## String Sanitization

### Basic String Cleaning

```php
// Basic string sanitization
$clean = Sanitizer::string('  Hello World  '); // "Hello World"
$clean = Sanitizer::string('<script>alert("xss")</script>Hello'); // "Hello"

// With options
$clean = Sanitizer::string($input, $trim = true, $stripTags = true);
```

### Email Sanitization

```php
// Email normalization
$email = Sanitizer::email('  USER@EXAMPLE.COM  '); // "user@example.com"
$email = Sanitizer::email('user@example.com'); // "user@example.com"
$email = Sanitizer::email(''); // ""
```

### URL Sanitization

```php
// URL normalization
$url = Sanitizer::url('example.com'); // "http://example.com"
$url = Sanitizer::url('https://example.com'); // "https://example.com"
$url = Sanitizer::url(''); // ""
```

### HTML Sanitization

```php
// HTML content sanitization
$html = '<p>Hello <script>alert("xss")</script> <strong>World</strong></p>';

// Remove all HTML tags
$clean = Sanitizer::html($html); // "Hello World"

// Allow specific tags
$clean = Sanitizer::html($html, ['p', 'strong']); // "<p>Hello <strong>World</strong></p>"
```

### Filename Sanitization

```php
// Safe filename creation
$filename = Sanitizer::filename('../../dangerous/path/file.txt'); // "file.txt"
$filename = Sanitizer::filename('My File (2024).pdf'); // "MyFile2024.pdf"
$filename = Sanitizer::filename(''); // ""
```

### Phone Number Sanitization

```php
// Phone number cleaning
$phone = Sanitizer::phone('+1 (555) 123-4567'); // "+1 (555) 123-4567"
$phone = Sanitizer::phone('555.123.4567'); // "555 123 4567"
$phone = Sanitizer::phone('5551234567'); // "5551234567"
```

### Credit Card Sanitization

```php
// Credit card number cleaning
$card = Sanitizer::creditCard('1234-5678-9012-3456'); // "1234567890123456"
$card = Sanitizer::creditCard('1234 5678 9012 3456'); // "1234567890123456"
$card = Sanitizer::creditCard(''); // ""
```

### Password Sanitization

```php
// Basic password sanitization
$password = Sanitizer::password('  MyPassword123  '); // "MyPassword123"
$password = Sanitizer::password('<script>alert("xss")</script>pass'); // "pass"
```

## Numeric Sanitization

### Integer Sanitization

```php
// Integer conversion with fallback
$int = Sanitizer::integer('25'); // 25
$int = Sanitizer::integer('25.5'); // 25
$int = Sanitizer::integer('invalid', 0); // 0
$int = Sanitizer::integer('', 18); // 18
```

### Float Sanitization

```php
// Float conversion with fallback
$float = Sanitizer::float('25.5'); // 25.5
$float = Sanitizer::float('25'); // 25.0
$float = Sanitizer::float('invalid', 0.0); // 0.0
$float = Sanitizer::float('', 10.5); // 10.5
```

## Boolean Sanitization

```php
// Boolean conversion
$bool = Sanitizer::boolean('true'); // true
$bool = Sanitizer::boolean('1'); // true
$bool = Sanitizer::boolean('yes'); // true
$bool = Sanitizer::boolean('on'); // true
$bool = Sanitizer::boolean('false'); // false
$bool = Sanitizer::boolean('0'); // false
$bool = Sanitizer::boolean('no'); // false
$bool = Sanitizer::boolean('off'); // false
```

## Array Sanitization

```php
// Array conversion
$array = Sanitizer::array(['item1', 'item2']); // ['item1', 'item2']
$array = Sanitizer::array('["item1", "item2"]'); // ['item1', 'item2'] (JSON)
$array = Sanitizer::array('not an array'); // []
$array = Sanitizer::array(null); // []
```

## JSON Sanitization

```php
// JSON parsing and sanitization
$json = Sanitizer::json('{"name": "John", "age": 30}'); // ['name' => 'John', 'age' => 30]
$json = Sanitizer::json('invalid json'); // 'invalid json' (unchanged)
$json = Sanitizer::json(null); // null
```

## Date and Time Sanitization

### Date Sanitization

```php
// Date formatting
$date = Sanitizer::date('2024-01-15'); // "2024-01-15"
$date = Sanitizer::date('01/15/2024', 'Y-m-d'); // "2024-01-15"
$date = Sanitizer::date('invalid date'); // ""
$date = Sanitizer::date('', 'Y-m-d'); // ""
```

### Time Sanitization

```php
// Time formatting
$time = Sanitizer::time('14:30:00'); // "14:30:00"
$time = Sanitizer::time('2:30 PM', 'H:i:s'); // "14:30:00"
$time = Sanitizer::time('invalid time'); // ""
```

### DateTime Sanitization

```php
// DateTime formatting
$datetime = Sanitizer::datetime('2024-01-15 14:30:00'); // "2024-01-15 14:30:00"
$datetime = Sanitizer::datetime('01/15/2024 2:30 PM', 'Y-m-d H:i:s'); // "2024-01-15 14:30:00"
$datetime = Sanitizer::datetime('invalid datetime'); // ""
```

## Specialized Sanitization

### IP Address Sanitization

```php
// IP address validation
$ip = Sanitizer::ipAddress('192.168.1.1'); // "192.168.1.1"
$ip = Sanitizer::ipAddress('invalid ip'); // ""
$ip = Sanitizer::ipAddress(''); // ""
```

### Color Sanitization

```php
// Color value validation
$color = Sanitizer::color('#FF0000'); // "#FF0000"
$color = Sanitizer::color('rgb(255, 0, 0)'); // "rgb(255, 0, 0)"
$color = Sanitizer::color('rgba(255, 0, 0, 0.5)'); // "rgba(255, 0, 0, 0.5)"
$color = Sanitizer::color('invalid color'); // ""
```

### CSS Class Sanitization

```php
// CSS class name cleaning
$class = Sanitizer::cssClass('my-class-name'); // "my-class-name"
$class = Sanitizer::cssClass('my class name'); // "myclassname"
$class = Sanitizer::cssClass('my-class@name'); // "my-classname"
$class = Sanitizer::cssClass(''); // ""
```

### ID Sanitization

```php
// HTML ID attribute cleaning
$id = Sanitizer::id('my-element-id'); // "my-element-id"
$id = Sanitizer::id('123element'); // "id_123element" (prefixed if starts with number)
$id = Sanitizer::id('my element id'); // "myelementid"
$id = Sanitizer::id(''); // ""
```

## Advanced Usage

### Custom Sanitization Chains

```php
// Chain multiple sanitization steps
$userInput = '  <script>alert("xss")</script>John Doe  ';

// Step 1: Basic string sanitization
$clean = Sanitizer::string($userInput, true, true); // "John Doe"

// Step 2: Additional HTML encoding if needed
$safe = htmlspecialchars($clean, ENT_QUOTES, 'UTF-8'); // "John Doe"
```

### Batch Sanitization

```php
// Sanitize multiple fields at once
$data = [
    'name' => '  John Doe  ',
    'email' => '  USER@EXAMPLE.COM  ',
    'age' => '25',
    'website' => 'example.com',
    'phone' => '+1 (555) 123-4567'
];

$sanitized = [
    'name' => Sanitizer::string($data['name']),
    'email' => Sanitizer::email($data['email']),
    'age' => Sanitizer::integer($data['age']),
    'website' => Sanitizer::url($data['website']),
    'phone' => Sanitizer::phone($data['phone'])
];

// Result:
// [
//     'name' => 'John Doe',
//     'email' => 'user@example.com',
//     'age' => 25,
//     'website' => 'http://example.com',
//     'phone' => '+1 (555) 123-4567'
// ]
```

### Conditional Sanitization

```php
// Sanitize based on conditions
function sanitizeUserData(array $data): array
{
    $sanitized = [];
    
    // Always sanitize name
    $sanitized['name'] = Sanitizer::string($data['name'] ?? '');
    
    // Sanitize email only if provided
    if (!empty($data['email'])) {
        $sanitized['email'] = Sanitizer::email($data['email']);
    }
    
    // Sanitize age with fallback
    $sanitized['age'] = Sanitizer::integer($data['age'] ?? '', 18);
    
    // Sanitize website only if valid
    if (!empty($data['website'])) {
        $website = Sanitizer::url($data['website']);
        if (!empty($website)) {
            $sanitized['website'] = $website;
        }
    }
    
    return $sanitized;
}
```

## Security Considerations

### XSS Protection

```php
// Always sanitize user input to prevent XSS
$userInput = '<script>alert("xss")</script>Hello World';

// Remove HTML tags
$safe = Sanitizer::string($userInput, true, true); // "Hello World"

// Or allow specific tags
$safe = Sanitizer::html($userInput, ['p', 'strong']); // "Hello World"
```

### SQL Injection Prevention

```php
// Sanitize data before database operations
$userId = Sanitizer::integer($_GET['id'] ?? '', 0);
$username = Sanitizer::string($_POST['username'] ?? '', true, true);

// Use prepared statements with sanitized data
$stmt = $pdo->prepare("SELECT * FROM users WHERE id = ? AND username = ?");
$stmt->execute([$userId, $username]);
```

### File Upload Security

```php
// Sanitize filenames
$originalName = $_FILES['file']['name'];
$safeName = Sanitizer::filename($originalName);

// Validate file type and size
if ($_FILES['file']['size'] > 5000000) { // 5MB limit
    throw new Exception('File too large');
}

// Move to safe location
move_uploaded_file($_FILES['file']['tmp_name'], "/uploads/{$safeName}");
```

## Best Practices

### 1. Always Sanitize User Input

```php
// Good: Sanitize all user input
$name = Sanitizer::string($_POST['name'] ?? '');
$email = Sanitizer::email($_POST['email'] ?? '');
$age = Sanitizer::integer($_POST['age'] ?? '', 0);

// Bad: Using raw input
$name = $_POST['name'] ?? '';
$email = $_POST['email'] ?? '';
$age = $_POST['age'] ?? 0;
```

### 2. Use Appropriate Sanitization Methods

```php
// Use type-specific sanitization
$email = Sanitizer::email($input);        // For emails
$phone = Sanitizer::phone($input);        // For phone numbers
$url = Sanitizer::url($input);            // For URLs
$filename = Sanitizer::filename($input);  // For filenames
```

### 3. Provide Fallback Values

```php
// Always provide sensible defaults
$age = Sanitizer::integer($input, 18);        // Default age
$isActive = Sanitizer::boolean($input, false); // Default status
$tags = Sanitizer::array($input);             // Default empty array
```

### 4. Chain with Validation

```php
// Sanitize before validation
$cleanInput = [
    'name' => Sanitizer::string($rawInput['name'] ?? ''),
    'email' => Sanitizer::email($rawInput['email'] ?? ''),
    'age' => Sanitizer::integer($rawInput['age'] ?? '', 0)
];

// Then validate
$validator->validate($cleanInput, [
    'name' => 'required|string|min:2',
    'email' => 'required|email',
    'age' => 'integer|min:18'
]);
```

### 5. Handle Empty Values

```php
// Check for empty values after sanitization
$name = Sanitizer::string($input);
if (empty($name)) {
    throw new Exception('Name is required');
}

// Or provide defaults
$name = Sanitizer::string($input) ?: 'Anonymous';
```

## Performance Considerations

### 1. Reuse Sanitized Data

```php
// Sanitize once and reuse
$sanitizedData = [
    'name' => Sanitizer::string($input['name']),
    'email' => Sanitizer::email($input['email'])
];

// Use sanitized data multiple times
$user = User::create($sanitizedData);
$log->info('User created', $sanitizedData);
```

### 2. Batch Processing

```php
// Sanitize multiple items efficiently
$names = ['  John  ', '  Jane  ', '  Bob  '];
$cleanNames = array_map(fn($name) => Sanitizer::string($name), $names);
// Result: ['John', 'Jane', 'Bob']
```

This comprehensive sanitization system ensures your data is clean, secure, and properly formatted for safe processing in your Sockeon applications.