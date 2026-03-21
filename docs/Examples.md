---
sidebar_position: 5
---

# Examples

## Basic Suite

```lua
local Specium = require(path.to.Specium)

local suite = Specium.suite("String utils", function(t)
    t.it("contains substring", function()
        Specium.expect("hello world").toContain("world")
    end)

    t.it("matches pattern", function()
        Specium.expect("abc123").toMatch("%d+")
    end)
end)

local output, results = Specium.run(suite)
print(output)
```

## Testing a Module

```lua
local Specium = require(path.to.Specium)
local MathUtils = require(path.to.MathUtils)

local suite = Specium.suite("MathUtils", function(t)
    t.it("adds correctly", function()
        Specium.expect(MathUtils.add(2, 3)).toBe(5)
    end)

    t.it("clamps values", function()
        Specium.expect(MathUtils.clamp(10, 0, 5)).toBe(5)
        Specium.expect(MathUtils.clamp(-1, 0, 5)).toBe(0)
    end)
end)

local output = Specium.run(suite)
print(output)
```

## Auto-discovery with Multiple Folders

```lua
local Specium = require(path.to.Specium)

local output, results = Specium.runTests({
    ServerScriptService.Tests,
    ReplicatedStorage.Shared.Tests,
})

print(output)
print("Total:", results[1].total)
print("Passed:", results[1].passed)
print("Failed:", results[1].failed)
```

## Inspecting Results Programmatically

```lua
local suite = Specium.suite("Checks", function(t)
    t.it("passes", function()
        return Specium.success("ok")
    end)

    t.it("fails", function()
        return Specium.error("not implemented")
    end)
end)

local _, results = Specium.run(suite)

if results.failed > 0 then
    warn(`{results.failed} test(s) failed!`)
end
```
