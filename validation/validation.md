---
title: "Data Validation - Sockeon Documentation"
description: "Learn about Sockeon's unified validation system for HTTP and WebSocket data"
og_image: "https://sockeon.com/assets/logo.png"
twitter_image: "https://sockeon.com/assets/logo.png"
---

# Data Validation

Sockeon provides a **unified validation system** that's shared between HTTP and WebSocket contexts, ensuring consistent data validation and sanitization across your entire application.

## Overview

The validation system is centralized in `src/Validation/` and provides:

- **Single Validator Class** - Same validation engine for HTTP and WebSocket
- **Automatic Sanitization** - Data is cleaned during validation
- **Extensive Rule Set** - Comprehensive validation rules
- **Custom Error Messages** - Flexible error handling
- **Flat Validation Rules** - Simple, explicit validation approach

## Usage Patterns

### 1. HTTP Request Validation

```php
use Sockeon\Sockeon\Http\Request;

class UserController
{
    public function store(Request $request)
    {
        $validatedData = $request->validated([
            'name' => 'required|string|max:100',
            'email' => 'required|email',
            'age' => 'integer|min:18'
        ]);
        
        // Data is automatically sanitized
        $name = $validatedData['name'];    // Trimmed string
        $email = $validatedData['email'];  // Lowercase email
        $age = $validatedData['age'];      // Integer
        
        // Process validated data...
    }
}
```

### 2. WebSocket Event Validation

```php
use Sockeon\Sockeon\Validation\Validator;

class ChatController extends SocketController
{
    private Validator $validator;
    
    public function __construct()
    {
        $this->validator = new Validator();
    }
    
    #[SocketOn('message')]
    public function onMessage(int $clientId, array $data): void
    {
        try {
            // Same Validator class as HTTP
            $this->validator->validate($data, [
                'content' => 'required|string|max:1000',
                'room_id' => 'required|integer'
            ]);
            
            // Get sanitized data
            $validatedData = $this->validator->getSanitized();
            
            // Process validated data...
            
        } catch (ValidationException $e) {
            // Handle validation errors
        }
    }
}
```

### 3. Direct Validator Usage

```php
use Sockeon\Sockeon\Validation\Validator;

class DataProcessor
{
    private Validator $validator;
    
    public function __construct()
    {
        $this->validator = new Validator();
    }
    
    public function processData(array $data): array
    {
        // Validate any data source
        $this->validator->validate($data, [
            'id' => 'required|integer|min:1',
            'status' => 'required|in:active,inactive,pending',
            'metadata' => 'array|max:10'
        ]);
        
        return $this->validator->getSanitized();
    }
}
```

## Validation Rules

### Basic Rules

| Rule | Description | Example |
|------|-------------|---------|
| `required` | Field must be present and not empty | `'name' => 'required'` |
| `string` | Value must be a string | `'username' => 'string'` |
| `integer` | Value must be an integer | `'user_id' => 'integer'` |
| `float` | Value must be a float | `'score' => 'float'` |
| `boolean` | Value must be a boolean | `'active' => 'boolean'` |
| `array` | Value must be an array | `'tags' => 'array'` |
| `email` | Value must be a valid email | `'email' => 'email'` |
| `url` | Value must be a valid URL | `'avatar' => 'url'` |
| `json` | Value must be valid JSON | `'config' => 'json'` |

### String Rules

| Rule | Description | Example |
|------|-------------|---------|
| `min:length` | Minimum string length | `'content' => 'string|min:1'` |
| `max:length` | Maximum string length | `'username' => 'string|max:50'` |
| `alpha` | Only alphabetic characters | `'name' => 'alpha'` |
| `alpha_num` | Alphanumeric characters | `'username' => 'alpha_num'` |
| `numeric` | Numeric string | `'code' => 'numeric'` |
| `regex:pattern` | Custom regex pattern | `'phone' => 'regex:/^\+?[1-9]\d{1,14}$/'` |

### Numeric Rules

| Rule | Description | Example |
|------|-------------|---------|
| `min:value` | Minimum numeric value | `'user_id' => 'integer|min:1'` |
| `max:value` | Maximum numeric value | `'score' => 'integer|max:100'` |
| `between:min,max` | Value between range | `'rating' => 'integer|between:1,5'` |

### Array Rules

| Rule | Description | Example |
|------|-------------|---------|
| `min:count` | Minimum array items | `'tags' => 'array|min:1'` |
| `max:count` | Maximum array items | `'items' => 'array|max:100'` |

### List Rules

| Rule | Description | Example |
|------|-------------|---------|
| `in:value1,value2` | Value must be in list | `'status' => 'in:active,inactive'` |
| `not_in:value1,value2` | Value must not be in list | `'role' => 'not_in:admin,super_admin'` |

## Automatic Sanitization

Data is automatically sanitized during validation:

```php
$validatedData = $request->validated([
    'name' => 'required|string',      // Trimmed
    'email' => 'required|email',      // Lowercase
    'age' => 'integer',               // Cast to int
    'tags' => 'array',                // Cast to array
    'is_active' => 'boolean'          // Cast to bool
]);

// Results:
// $validatedData['name'] = "John Doe" (trimmed)
// $validatedData['email'] = "john@example.com" (lowercase)
// $validatedData['age'] = 25 (integer)
// $validatedData['tags'] = ["tag1", "tag2"] (array)
// $validatedData['is_active'] = true (boolean)
```

## Complex Data Handling

### Flat Validation Rules

For complex nested data, use flat validation rules and reconstruct:

```php
// Validate flat structure
$validatedData = $request->validated([
    'user_name' => 'required|string|max:100',
    'user_email' => 'required|email',
    'user_preferences_theme' => 'in:light,dark',
    'user_preferences_notifications' => 'boolean',
    'user_address_street' => 'string|max:200',
    'user_address_city' => 'string|max:100',
    'user_address_country' => 'in:US,CA,UK,DE,FR'
]);

// Reconstruct nested data
$user = [
    'name' => $validatedData['user_name'],
    'email' => $validatedData['user_email'],
    'preferences' => [
        'theme' => $validatedData['user_preferences_theme'] ?? 'light',
        'notifications' => $validatedData['user_preferences_notifications'] ?? false
    ],
    'address' => [
        'street' => $validatedData['user_address_street'] ?? '',
        'city' => $validatedData['user_address_city'] ?? '',
        'country' => $validatedData['user_address_country'] ?? 'US'
    ]
];
```

## Error Handling

### Validation Exceptions

```php
use Sockeon\Sockeon\Exception\Validation\ValidationException;

try {
    $validatedData = $request->validated($rules);
    // Process data...
} catch (ValidationException $e) {
    $errors = $e->getErrors();
    $message = $e->getMessage();
    
    return response()->json([
        'message' => 'Validation failed',
        'errors' => $errors
    ], 422);
}
```

### Custom Error Messages

```php
$validatedData = $request->validated([
    'name' => 'required|string|max:100',
    'email' => 'required|email',
    'age' => 'integer|min:18'
], [
    'name.required' => 'Please provide your full name.',
    'email.required' => 'Email address is required.',
    'email.email' => 'Please provide a valid email address.',
    'age.min' => 'You must be at least 18 years old.'
]);
```

### WebSocket Error Handling

```php
#[SocketOn('message')]
public function onMessage(int $clientId, array $data): void
{
    try {
        $this->validator->validate($data, [
            'content' => 'required|string|max:1000',
            'room_id' => 'required|integer'
        ]);
        
        $validatedData = $this->validator->getSanitized();
        // Process validated data...
        
    } catch (ValidationException $e) {
        // Send error to client
        $this->server->sendToClient($clientId, json_encode([
            'event' => 'error',
            'data' => [
                'message' => 'Invalid message format',
                'errors' => $e->getErrors()
            ]
        ]));
    }
}
```

## Best Practices

### 1. Use the Unified System

```php
// Same validation approach everywhere
$request->validated($rules);           // HTTP
$this->validator->validate($data, $rules); // WebSocket
```

### 2. Handle Errors Consistently

```php
try {
    $validatedData = $request->validated($rules);
    // Process data...
} catch (ValidationException $e) {
    // Consistent error handling
    return response()->json([
        'message' => 'Validation failed',
        'errors' => $e->getErrors()
    ], 422);
}
```

### 3. Use Flat Validation Rules for Complex Data

```php
// Use flat rules and reconstruct nested data
$validatedData = $request->validated([
    'user_name' => 'required|string|max:100',
    'user_email' => 'required|email',
    'user_preferences_theme' => 'in:light,dark',
    'user_preferences_notifications' => 'boolean'
]);

// Reconstruct nested data
$user = [
    'name' => $validatedData['user_name'],
    'email' => $validatedData['user_email'],
    'preferences' => [
        'theme' => $validatedData['user_preferences_theme'] ?? 'light',
        'notifications' => $validatedData['user_preferences_notifications'] ?? false
    ]
];
```

### 4. Leverage Automatic Sanitization

```php
// Data is automatically sanitized during validation
$validatedData = $request->validated([
    'name' => 'required|string',      // Trimmed
    'email' => 'required|email',      // Lowercase
    'age' => 'integer',               // Cast to int
    'tags' => 'array'                 // Cast to array
]);
```

### 5. Use Appropriate Validation Rules

```php
// Good: Specific validation rules
'user_id' => 'required|integer|min:1'

// Avoid: Complex regex when simple rules work
'user_id' => 'required|regex:/^\d+$/'
```

## Performance Considerations

### 1. Reuse Validator Instances

```php
class Controller
{
    private Validator $validator;
    
    public function __construct()
    {
        $this->validator = new Validator();
    }
    
    // Reuse the same validator instance
}
```

### 2. Use Efficient Validation Rules

```php
// Good: Specific validation rules
'user_id' => 'required|integer|min:1'

// Avoid: Complex regex when simple rules work
'user_id' => 'required|regex:/^\d+$/'
```

## Benefits of Unified Validation

1. **Consistency** - Same validation logic across HTTP and WebSocket
2. **Maintainability** - Single codebase for validation rules
3. **Reusability** - Validation rules can be shared
4. **Testing** - Unified testing approach
5. **Performance** - Optimized validation engine
6. **Security** - Consistent sanitization across contexts

This unified validation system ensures your Sockeon applications have consistent, secure, and maintainable data validation across all contexts.