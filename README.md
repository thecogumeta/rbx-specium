<div align="center">
	<h1>Specium</h1>
	<p>A simple and flexible <code>testing framework</code> for Roblox</p>
	<a href="https://thecogumeta.github.io/rbx-specium/"><strong>View docs</strong></a>
</div>

<!--moonwave-hide-before-this-line-->

## Why Specium?

Testing in Roblox usually means scattered `print` statements or heavy dependencies like TestEZ. **Specium** is a lightweight alternative that gives you structured test suites, readable assertions, and detailed output — with no external dependencies.

## Features

- **Suites & sub-suites**: Organize tests with `suite` and `describe`.
- **Expressive assertions**: `expect` with matchers like `toBe`, `toEqual`, `toThrow`, `toContain` and more.
- **Invertible matchers**: Use `.never` to flip any assertion.
- **Custom failure messages**: Chain `.withMessage(msg)` for clearer output.
- **Structured results**: Get a full `SpeciumRunResult` to inspect programmatically.
- **Auto-discovery**: Use `runTests` to scan folders for `.spec` modules automatically.
