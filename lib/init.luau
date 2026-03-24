--[=[
	@class Specium
	A lightweight and flexible testing framework for Roblox.

	Specium allows you to organize tests into suites and sub-suites,
	run them and get a detailed report of the results.
]=]
local Specium = {}

type SpeciumTest = {
	name: string,
	fn: () -> SpeciumResult,
	skipped: boolean,
	timeout: number?,
}
type SpeciumSuite = {
	name: string,
	tests: { SpeciumTest },
	subSuites: { SpeciumSuite },
	beforeAll: (() -> ())?,
	afterAll: (() -> ())?,
	beforeEach: (() -> ())?,
	afterEach: (() -> ())?,
}
type SpeciumTestResult = {
	name: string,
	success: boolean,
	skipped: boolean,
	message: string,
}
type SpeciumSuiteResult = {
	name: string,
	tests: { SpeciumTestResult },
	subSuites: { SpeciumSuiteResult },
}
--[=[
	@interface SpeciumResult
	@within Specium
	.success boolean -- Whether the test passed or failed
	.message string -- A message describing the result
]=]
export type SpeciumResult = {
	success: boolean,
	message: string,
}
--[=[
	@interface SpeciumRunResult
	@within Specium
	.total number -- Total number of tests run
	.passed number -- Number of tests that passed
	.failed number -- Number of tests that failed
	.suites {SpeciumSuiteResult} -- Results for each root suite
]=]
export type SpeciumRunResult = {
	total: number,
	passed: number,
	failed: number,
	skipped: number,
	suites: { SpeciumSuiteResult },
}
--[=[
	@interface SpeciumSuiteContext
	@within Specium
	.it   (name: string, fn: () -> SpeciumResult, timeout: number?) -> ()
	.skip (name: string, fn: () -> SpeciumResult, timeout: number?) -> ()
	.describe (name: string, fn: (SpeciumSuiteContext) -> ()) -> () -- Creates a nested sub-suite
	.beforeAll (() -> ())? -- Runs once before all tests in the suite
	.afterAll (() -> ())? -- Runs once after all tests in the suite
	.beforeEach (() -> ())? -- Runs before each test in the suite
	.afterEach (() -> ())? -- Runs after each test in the suite
]=]
export type SpeciumSuiteContext = {
	it: (name: string, fn: () -> SpeciumResult) -> (),
	skip: (name: string, fn: () -> SpeciumResult) -> (),
	describe: (name: string, fn: (SpeciumSuiteContext) -> ()) -> (),
	beforeAll: (() -> ()) -> (),
	afterAll: (() -> ()) -> (),
	beforeEach: (() -> ()) -> (),
	afterEach: (() -> ()) -> (),
}

--[=[
	@within Specium
	@param name string -- The name of the suite
	@param fn (SpeciumSuiteContext) -> () -- A function that registers tests and sub-suites
	@return SpeciumSuite -- The constructed suite, ready to be passed to `Specium.run`

	Creates a new test suite.

	Example:
	```lua
	local suite = Specium.suite("Math", function(t)
		t.it("adds numbers", function()
			Specium.expect(1 + 1).toBe(2)
			return Specium.success("ok")
		end)

		t.describe("subtraction", function(t)
			t.it("subtracts numbers", function()
				Specium.expect(5 - 3).toBe(2)
				return Specium.success("ok")
			end)
		end)
	end)
	```
]=]
function Specium.suite(name: string, fn: (SpeciumSuiteContext) -> ()): SpeciumSuite
	local suite: SpeciumSuite = {
		name = name,
		tests = {},
		subSuites = {},
	}

	local function createContext(currentSuite: SpeciumSuite): SpeciumSuiteContext
		local ctx = {}

		function ctx.it(name: string, fn: () -> SpeciumResult, timeout: number?)
			table.insert(currentSuite.tests, {
				name = name,
				fn = fn,
				skipped = false,
				timeout = timeout,
			})
		end

		function ctx.skip(name: string, fn: () -> SpeciumResult, timeout: number?)
			table.insert(currentSuite.tests, {
				name = name,
				fn = fn,
				skipped = true,
				timeout = timeout,
			})
		end

		function ctx.describe(name: string, fn: (SpeciumSuiteContext) -> ())
			local newSuite: SpeciumSuite = {
				name = name,
				tests = {},
				subSuites = {},
			}

			table.insert(currentSuite.subSuites, newSuite)

			fn(createContext(newSuite))
		end

		local function createSuiteSetter(key: string)
			ctx[key] = function(value: any)
				currentSuite[key] = value
			end
		end

		createSuiteSetter("beforeAll")
		createSuiteSetter("afterAll")
		createSuiteSetter("beforeEach")
		createSuiteSetter("afterEach")

		return ctx
	end

	fn(createContext(suite))

	return suite
end

--[=[
	@within Specium
	@param suite SpeciumSuite -- The suite to run
	@return string -- A formatted output string with a tree-view of results and a summary
	@return SpeciumRunResult -- A structured table with the full results

	Runs all tests in a suite (including sub-suites).

	Example:
	```lua
	local output, results = Specium.run(suite)
	print(output)
	-- > Math
	--   [Pass] adds numbers - ok
	--   > subtraction
	--     [Pass] subtracts numbers - ok
	--
	-- Result:
	-- 2/2 (100%) tests passed
	```
]=]
function Specium.run(suite: SpeciumSuite): (string, SpeciumRunResult)
	local total = 0
	local passed = 0
	local skipped = 0

	local output = "\n"

	local results: SpeciumRunResult = {
		total = 0,
		passed = 0,
		failed = 0,
		skipped = 0,
		suites = {},
	}

	local function runSuite(currentSuite: SpeciumSuite, depth: number): SpeciumSuiteResult
		depth += 1
		local indent = string.rep("  ", depth)

		local suiteResult: SpeciumSuiteResult = {
			name = currentSuite.name,
			tests = {},
			subSuites = {},
		}

		output ..= `{string.rep(" ", depth - 1)}> {currentSuite.name}\n`

		local function opcall(fn: (() -> ())?, hookName: string)
			if not fn then
				return
			end

			local ok, err = pcall(fn)

			if not ok then
				warn(`[Specium] {hookName} failed in "{currentSuite.name}": {err}`)
			end
		end

		opcall(currentSuite.beforeAll, "beforeAll")

		for _, test in currentSuite.tests do
			total += 1

			if test.skipped then
				skipped += 1
				output ..= `{indent}[Skip] {test.name}\n`
				table.insert(suiteResult.tests, {
					name = test.name,
					success = false,
					message = "skipped",
					skipped = true,
				})
				continue
			end

			opcall(currentSuite.beforeEach, "beforeEach")

			local ok: boolean, result: any

			if test.timeout then
				local done = false

				local thread = task.spawn(function()
					ok, result = pcall(test.fn)
					done = true
				end)

				local timeoutThread = task.delay(test.timeout, function()
					ok, result = false, `Timeout after {test.timeout}s`
					done = true
				end)

				repeat
					task.wait()
				until done

				task.cancel(thread)
				task.cancel(timeoutThread)
			else
				ok, result = pcall(test.fn)
			end

			opcall(currentSuite.afterEach, "afterEach")

			if not ok then
				result = Specium.error(tostring(result))
			end
			if not result then
				result = {
					message = ok and "Pass" or "Failure",
					success = ok,
				}
			end

			passed += result.success and 1 or 0
			output ..= `{indent}[{result.success and "Pass" or "Failure"}] {test.name} - {result.message}\n`

			table.insert(suiteResult.tests, {
				name = test.name,
				success = result.success,
				message = result.message,
				skipped = false,
			})
		end

		for _, sub in currentSuite.subSuites do
			local subResult = runSuite(sub, depth + 1)
			table.insert(suiteResult.subSuites, subResult)
		end

		opcall(currentSuite.afterAll, "afterAll")

		return suiteResult
	end

	local rootResult = runSuite(suite, 0)

	results.total = total
	results.passed = passed
	results.failed = total - passed - skipped
	results.skipped = skipped
	results.suites = { rootResult }

	output ..= "\n\nResult:\n"
	if total > 0 then
		local ran = total - skipped
		local summary
		if ran > 0 then
			summary = `{passed}/{ran} ({math.round(passed / ran * 1000) / 10}%) tests passed`
		else
			summary = "all tests skipped"
		end
		if skipped > 0 then
			summary ..= `, {skipped} skipped`
		end
		output ..= summary
	else
		output ..= "no tests found"
	end

	return output, results
end

--[=[
	@within Specium
	@param testsFolder {Instance} | Instance -- A single folder or a list of folders to scan for `.spec` ModuleScripts.
	@return string -- A concatenated output string of all suite results
	@return {SpeciumRunResult} -- A list of results, one per suite found

	Scans one or more folders for `.spec` ModuleScripts and runs each one as a suite.

	Each `.spec` module must return a `SpeciumSuite` created via `Specium.suite`.
	If a module fails to load, a warning is emitted and it is skipped.

	Example:
	```lua
	-- Single folder
	local output, results = Specium.runTests(ServerScriptService.Tests)
	print(output)

	-- Multiple folders
	local output, results = Specium.runTests({
		ServerScriptService.Tests,
		ReplicatedStorage.Shared.Tests,
	})
	print(output)
	```
]=]
function Specium.runTests(testsFolder: { Instance } | Instance): (string, { SpeciumRunResult })
	if typeof(testsFolder) == "Instance" then
		return Specium.runTests({ testsFolder })
	end

	local output = ""
	local results: { SpeciumRunResult } = {}

	for _, testFolder in testsFolder do
		for _, testsScript in testFolder:QueryDescendants("ModuleScript") do
			if not testsScript.Name:match("%.spec$") then
				continue
			end

			local ok, suite = pcall(require, testsScript)
			if not ok then
				warn(`[Specium] Failed to load {testsScript:GetFullName()}: {suite}`)
				continue
			end
			local o, r = Specium.run(suite)
			output ..= `{o}\n`
			table.insert(results, r)
		end
	end

	return output, results
end

--[=[
	@within Specium
	@param message string -- The failure message
	@return SpeciumResult -- A result with `success = false`

	Returns a failed `SpeciumResult` with the given message.

	Example:
	```lua
	t.it("always fails", function()
		return Specium.error("this test is not implemented yet")
	end)
	```
]=]
function Specium.error(message: string): SpeciumResult
	return { success = false, message = message }
end

--[=[
	@within Specium
	@param message string -- The success message
	@return SpeciumResult -- A result with `success = true`

	Returns a successful `SpeciumResult` with the given message.

	Example:
	```lua
	-- Returning Specium.success is optional — if omitted, the test is marked as passed automatically.
	t.it("works", function()
		Specium.expect(1 + 1).toBe(2)
		return Specium.success("all good")
	end)
	```
]=]
function Specium.success(message: string): SpeciumResult
	return { success = true, message = message }
end

--[=[
	@within Specium
	@param received any -- The value to assert against
	@return SpeciumMatchers -- A table of matcher functions

	Creates a matcher chain for the given value.

	Use `.never` to invert any matcher, and `.withMessage(msg)` to prepend
	a custom message to any failure.

	Available matchers:
	- `toBe(expected)` — strict equality (`==`)
	- `toEqual(expected)` — deep equality (tables compared recursively)
	- `toBeA(type, legacy?)` — checks `typeof` (or `type` if `legacy` is true)
	- `toBeTruthy()` — value is not `nil` and not `false`
	- `toBeNil()` — value is `nil`
	- `toBeNear(expected, epsilon?)` — numeric proximity (default epsilon: `1e-5`)
	- `toBeGreaterThan(expected)` — numeric `>`
	- `toBeLessThan(expected)` — numeric `<`
	- `toContain(item)` — table contains value (deep) or string contains substring
	- `toHaveLength(expected)` — checks `#value`
	- `toMatch(pattern)` — string matches a Lua pattern
	- `toThrow(expected?, ...args)` — function throws when called with `args`
	- `withMessage(msg)` — prepends a custom message to any failure
	- `never` — inverts the next matcher

	Example:
	```lua
	-- All examples below pass
	Specium.expect(2 + 2).toBe(4)
	Specium.expect("hello world").toContain("world")
	Specium.expect({1, 2, 3}).toHaveLength(3)
	Specium.expect(math.huge).never.toBeNil()
	Specium.expect(function() error("oops") end).toThrow()
	Specium.expect(42).withMessage("answer should be 42").toBe(42)
	Specium.expect(1 + 1).never.toBe(3)
	```
]=]
function Specium.expect(received: any)
	local function format(value: any, indent: number?): string
		indent = indent or 0
		assert(indent) -- ignore '?'
		local t = typeof(value)
		if t == "string" then
			return `"{value}"`
		elseif t == "number" or t == "boolean" or value == nil then
			return tostring(value)
		elseif t == "table" then
			local parts = {}
			local innerIndent = indent + 1
			local pad = string.rep("  ", innerIndent)
			local closePad = string.rep("  ", indent)
			for k, v in pairs(value) do
				table.insert(parts, `{pad}[{format(k)}] = {format(v, innerIndent)}`)
			end
			if #parts == 0 then
				return "{}"
			end
			return `\{\n{table.concat(parts, ",\n")}\n{closePad}\}`
		else
			return `<{t}> {tostring(value)}`
		end
	end

	local function deepEqual(a: any, b: any): boolean
		if a == b then
			return true
		end
		if typeof(a) ~= "table" or typeof(b) ~= "table" then
			return false
		end
		for k, v in pairs(a) do
			if not deepEqual(v, b[k]) then
				return false
			end
		end
		for k in pairs(b) do
			if a[k] == nil then
				return false
			end
		end
		return true
	end

	local function contains(collection: any, item: any): boolean
		local t = typeof(collection)
		if t == "string" then
			return string.find(collection, item, 1, true) ~= nil
		elseif t == "table" then
			for _, v in pairs(collection) do
				if deepEqual(v, item) then
					return true
				end
			end
		end
		return false
	end

	local function makeMatchers(invert: boolean)
		local matchers = {}
		local op = invert and " not " or " "
		local customMessage: string? = nil

		local function check(condition: boolean, message: string)
			if invert then
				condition = not condition
			end
			if not condition then
				local finalMessage = customMessage and `{customMessage}\n{message}` or message
				error(finalMessage, 2)
			end
		end

		function matchers.withMessage(msg: string)
			customMessage = msg
			return matchers
		end

		function matchers.toBeA(expected: string, legacy: boolean?)
			local getType = legacy and type or typeof
			local actual = getType(received)
			check(
				actual == expected,
				`Expected type: "{expected}"\nReceived type: "{actual}"\nValue: {format(received)}`
			)
		end

		function matchers.toBe(expected: any)
			check(received == expected, `Expected (===): {format(expected)}\nReceived:        {format(received)}`)
		end

		function matchers.toEqual(expected: any)
			check(
				deepEqual(received, expected),
				`Expected (deep): {format(expected)}\nReceived:        {format(received)}`
			)
		end

		function matchers.toBeTruthy()
			check(received ~= nil and received ~= false, `Expected value to{op}be truthy\nReceived: {format(received)}`)
		end

		function matchers.toBeNil()
			check(received == nil, `Expected value to{op}be nil\nReceived: {format(received)}`)
		end

		function matchers.toBeNear(expected: number, epsilon: number?)
			assert(typeof(received) == "number", "Expected received to be a number")
			epsilon = epsilon or 1e-5
			local diff = math.abs(received - expected)
			check(diff <= epsilon, `Expected: {expected} ± {epsilon}\nReceived: {received}\nDifference: {diff}`)
		end

		function matchers.toBeGreaterThan(expected: number)
			assert(typeof(received) == "number", "Expected received to be a number")
			check(received > expected, `Expected: > {expected}\nReceived: {received}`)
		end

		function matchers.toBeLessThan(expected: number)
			assert(typeof(received) == "number", "Expected received to be a number")
			check(received < expected, `Expected: < {expected}\nReceived: {received}`)
		end

		function matchers.toContain(item: any)
			local t = typeof(received)
			assert(t == "string" or t == "table", "Expected received to be a string or table")
			check(contains(received, item), `Expected{op}to contain: {format(item)}\nIn: {format(received)}`)
		end

		function matchers.toHaveLength(expected: number)
			local t = typeof(received)
			assert(t == "string" or t == "table", "Expected received to be a string or table")
			local actual = #received
			check(actual == expected, `Expected length: {expected}\nReceived length: {actual}`)
		end

		function matchers.toMatch(pattern: string)
			assert(typeof(received) == "string", "Expected received to be a string")
			check(
				string.match(received, pattern) ~= nil,
				`Expected string to{op}match pattern: "{pattern}"\nReceived: {format(received)}`
			)
		end

		function matchers.toThrow(expected: any?, ...)
			assert(typeof(received) == "function", "Expected received to be a function")
			local args = { ... }
			local ok, err = pcall(function()
				return received(table.unpack(args))
			end)

			check(not ok, `Expected function to{op}throw`)

			if expected ~= nil and not ok then
				assert(err == expected, `Expected error: {format(expected)}\nReceived error: {format(err)}`)
			end
		end

		if not invert then
			matchers.never = makeMatchers(true)
		end

		return matchers
	end

	return makeMatchers(false)
end

return Specium
