---
sidebar_position: 3
---

# Basic Usage

Specium works by organizing tests into suites. Each suite contains test cases registered with `t.it`, and optionally nested sub-suites with `t.describe`.

## Creating a Suite

```lua
local Specium = require(path.to.Specium)

local suite = Specium.suite("Math", function(t)
    t.it("adds numbers", function()
        Specium.expect(1 + 1).toBe(2)
    end)
end)
```

## Running a Suite

```lua
local output, results = Specium.run(suite)
print(output)
-- > Math
--   [Pass] adds numbers
--
-- Result:
-- 1/1 (100%) tests passed
```

## Nested Suites

Use `t.describe` to create sub-suites:

```lua
local suite = Specium.suite("Math", function(t)
    t.it("adds numbers", function()
        Specium.expect(1 + 1).toBe(2)
    end)

    t.describe("subtraction", function(t)
        t.it("subtracts numbers", function()
            Specium.expect(5 - 3).toBe(2)
        end)
    end)
end)
```

## Returning a Result

Returning a value from a test is optional. If nothing is returned, the test is marked as passed automatically.

You can use `Specium.success` and `Specium.error` to return explicit results with a message:

```lua
t.it("works", function()
    return Specium.success("all good")
end)

t.it("not implemented", function()
    return Specium.error("todo")
end)
```

## Auto-discovery

Place your test files anywhere inside a folder and name them with the `.spec` suffix (e.g. `MathUtils.spec`). Each module should return a `SpeciumSuite`:

```lua
-- MathUtils.spec.luau
return Specium.suite("MathUtils", function(t)
    t.it("works", function()
        Specium.expect(1 + 1).toBe(2)
    end)
end)
```

Then run them all at once:

```lua
local output, results = Specium.runTests(ServerScriptService.Tests)
print(output)
```
