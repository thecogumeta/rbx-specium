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

## Skipping Tests

Use `t.skip` to mark a test as skipped. The test will appear in the output but its function will never run.

```lua
local suite = Specium.suite("Math", function(t)
    t.it("adds numbers", function()
        Specium.expect(1 + 1).toBe(2)
    end)

    t.skip("not implemented yet", function()
        Specium.expect(1 + 1).toBe(3)
    end)
end)
```

```
-- > Math
--   [Pass] adds numbers
--   [Skip] not implemented yet
--
-- Result:
-- 1/1 (100%) tests passed, 1 skipped
```

## Lifecycle Hooks

Use hooks to run setup and cleanup logic around your tests.

```lua
local suite = Specium.suite("Database", function(t)
    local db

    t.beforeAll(function()
        db = Database.connect()
    end)

    t.afterAll(function()
        db:disconnect()
    end)

    t.beforeEach(function()
        db:reset()
    end)

    t.it("inserts a record", function()
        db:insert({ id = 1 })
        Specium.expect(db:count()).toBe(1)
    end)

    t.it("deletes a record", function()
        db:insert({ id = 1 })
        db:delete(1)
        Specium.expect(db:count()).toBe(0)
    end)
end)
```

- `beforeAll` — runs once before all tests in the suite
- `afterAll` — runs once after all tests in the suite
- `beforeEach` — runs before each test
- `afterEach` — runs after each test

Hooks are scoped to their suite and do not affect parent or sibling suites.

## Timeouts

Pass a timeout (in seconds) as the third argument to `t.it` or `t.skip`. If the test takes longer than the limit, it fails automatically with a timeout message.

```lua
local suite = Specium.suite("Network", function(t)
    t.it("fetches data", function()
        local result = HttpService:GetAsync("https://example.com")
        Specium.expect(result).never.toBeNil()
    end, 5)
end)
```

```
-- > Network
--   [Failure] fetches data - Timeout after 5s
--
-- Result:
-- 0/1 (0%) tests passed
```

Tests without a timeout run indefinitely.
