---
sidebar_position: 2
---

# Installation

## Method 1. Manual Installation

Download the [latest release](https://github.com/thecogumeta/specium/releases/) and place it in your project (e.g., `ReplicatedStorage`).

## Method 2. Install with Wally

### 1. Add dependency

Add the package to your `wally.toml`:

```toml
[dependencies]
Specium = "thecogumeta/specium@1.0.0"
```

### 2. Install

```bash
wally install
```

### 3. Add Packages to your project

Make sure your `default.project.json` includes Wally packages:

```json
{
  "name": "YourProject",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "Packages": {
        "$path": "Packages"
      }
    }
  }
}
```

## Using with roblox-ts

Install the package:

```bash
npm install @rbxts/specium
```

Then import in your code:

```ts
import Specium from "@rbxts/specium";

const suite = Specium.suite("Math", (t) => {
  t.it("adds numbers", () => {
    Specium.expect(1 + 1).toBe(2);
  });
});

const [output] = Specium.run(suite);
print(output);
```
