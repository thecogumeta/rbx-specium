---
sidebar_position: 4
---

# Using expect

`Specium.expect` is the assertion API. It takes any value and returns a chain of matchers.

## Basic Assertions

```lua
Specium.expect(1 + 1).toBe(2)
Specium.expect("hello world").toContain("world")
Specium.expect({1, 2, 3}).toHaveLength(3)
```

## Inverting with .never

Any matcher can be inverted with `.never`:

```lua
Specium.expect(1 + 1).never.toBe(3)
Specium.expect(nil).never.toBeTruthy()
```

## Custom Failure Messages

Use `.withMessage` to prepend a custom message to any failure:

```lua
Specium.expect(result).withMessage("result should be 42").toBe(42)
```

## Available Matchers

| Matcher                        | Description                                              |
| ------------------------------ | -------------------------------------------------------- |
| `toBe(expected)`               | Strict equality (`==`)                                   |
| `toEqual(expected)`            | Deep equality (tables compared recursively)              |
| `toBeA(type, legacy?)`         | Checks `typeof` (or `type` if `legacy` is true)          |
| `toBeTruthy()`                 | Value is not `nil` and not `false`                       |
| `toBeNil()`                    | Value is `nil`                                           |
| `toBeNear(expected, epsilon?)` | Numeric proximity (default epsilon: `1e-5`)              |
| `toBeGreaterThan(expected)`    | Numeric `>`                                              |
| `toBeLessThan(expected)`       | Numeric `<`                                              |
| `toContain(item)`              | Table contains value (deep) or string contains substring |
| `toHaveLength(expected)`       | Checks `#value`                                          |
| `toMatch(pattern)`             | String matches a Lua pattern                             |
| `toThrow(expected?, ...args)`  | Function throws when called with `args`                  |
