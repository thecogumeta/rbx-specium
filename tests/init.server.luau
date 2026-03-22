local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Specium = require(ReplicatedStorage.Specium)

local speciumSuite = Specium.suite("Specium", function(ctx)
	local function basicCtxValidation(ctx: Specium.SpeciumSuiteContext)
		ctx.it("should success without a return", function() end)

		ctx.it("should success", function()
			return Specium.success("passed successfully")
		end)

		ctx.it("should fail", function()
			local suite = Specium.suite("fail", function(ctx)
				ctx.it("fail", function()
					return Specium.error("no")
				end)
			end)

			local _, result = Specium.run(suite)

			Specium.expect(result.failed).withMessage("failed count").toBe(1)
		end)
	end

	basicCtxValidation(ctx)
	ctx.describe("Sub suite tests", basicCtxValidation)

	ctx.it("should count total/passed/failed correctly", function()
		local suite = Specium.suite("count", function(ctx)
			ctx.it("pass", function()
				return Specium.success("ok")
			end)

			ctx.it("fail", function()
				return Specium.error("no")
			end)
		end)

		local _, result = Specium.run(suite)

		Specium.expect(result.total).withMessage("total").toBe(2)
		Specium.expect(result.passed).withMessage("passed").toBe(1)
		Specium.expect(result.failed).withMessage("failed").toBe(1)
	end)

	ctx.it("should handle thrown errors", function()
		local suite = Specium.suite("error handling", function(ctx)
			ctx.it("boom", function()
				error("boom")
			end)
		end)

		local _, result = Specium.run(suite)

		Specium.expect(result.failed).withMessage("failed count").toBe(1)
	end)

	ctx.it("should treat nil return as success", function()
		local suite = Specium.suite("nil", function(ctx)
			ctx.it("nil test", function() end)
		end)

		local _, result = Specium.run(suite)

		Specium.expect(result.passed).withMessage("passed count").toBe(1)
	end)

	ctx.it("should run nested suites", function()
		local suite = Specium.suite("root", function(ctx)
			ctx.describe("child", function(ctx)
				ctx.it("test", function()
					return Specium.success("ok")
				end)
			end)
		end)

		local _, result = Specium.run(suite)

		Specium.expect(result.total).withMessage("total").toBe(1)
		Specium.expect(result.passed).withMessage("passed").toBe(1)
	end)

	ctx.it("should return correct structure", function()
		local suite = Specium.suite("root", function(ctx)
			ctx.it("test", function()
				return Specium.success("ok")
			end)
		end)

		local _, result = Specium.run(suite)
		local root = result.suites[1]

		Specium.expect(root).never.toBeNil()
		Specium.expect(root.name).withMessage("suite name").toBe("root")
		Specium.expect(#root.tests).withMessage("test count").toBe(1)
	end)

	ctx.it("should include summary in output", function()
		local suite = Specium.suite("root", function(ctx)
			ctx.it("test", function()
				return Specium.success("ok")
			end)
		end)

		local output = Specium.run(suite)

		Specium.expect(output).toContain("1/1")
		Specium.expect(output).toContain("tests passed")
	end)

	ctx.it("should handle empty suite", function()
		local suite = Specium.suite("empty", function() end)

		local _, result = Specium.run(suite)

		Specium.expect(result.total).withMessage("total").toBe(0)
	end)

	ctx.it("should handle multiple nested tests", function()
		local suite = Specium.suite("root", function(ctx)
			ctx.it("a", function()
				return Specium.success("ok")
			end)

			ctx.describe("child", function(ctx)
				ctx.it("b", function()
					return Specium.success("ok")
				end)

				ctx.it("c", function()
					return Specium.error("fail")
				end)
			end)
		end)

		local _, result = Specium.run(suite)

		Specium.expect(result.total).withMessage("total").toBe(3)
		Specium.expect(result.passed).withMessage("passed").toBe(2)
		Specium.expect(result.failed).withMessage("failed").toBe(1)
	end)

	ctx.describe("skip", function(ctx)
		ctx.it("should count skipped tests", function()
			local suite = Specium.suite("skip", function(ctx)
				ctx.it("pass", function()
					return Specium.success("ok")
				end)

				ctx.skip("skipped", function()
					return Specium.error("should not run")
				end)
			end)

			local _, result = Specium.run(suite)

			Specium.expect(result.total).withMessage("total").toBe(2)
			Specium.expect(result.passed).withMessage("passed").toBe(1)
			Specium.expect(result.skipped).withMessage("skipped").toBe(1)
			Specium.expect(result.failed).withMessage("failed").toBe(0)
		end)

		ctx.it("should not run skipped test fn", function()
			local ran = false

			local suite = Specium.suite("skip", function(ctx)
				ctx.skip("skipped", function()
					ran = true
				end)
			end)

			Specium.run(suite)

			Specium.expect(ran).withMessage("should not have run").toBe(false)
		end)

		ctx.it("should show skipped in output", function()
			local suite = Specium.suite("skip", function(ctx)
				ctx.skip("my skipped test", function() end)
			end)

			local output = Specium.run(suite)

			Specium.expect(output).toContain("Skip")
			Specium.expect(output).toContain("my skipped test")
		end)

		ctx.it("should handle all tests skipped", function()
			local suite = Specium.suite("all skipped", function(ctx)
				ctx.skip("a", function() end)
				ctx.skip("b", function() end)
			end)

			local output, result = Specium.run(suite)

			Specium.expect(result.skipped).withMessage("skipped").toBe(2)
			Specium.expect(result.failed).withMessage("failed").toBe(0)
			Specium.expect(output).toContain("all tests skipped")
		end)
	end)

	ctx.describe("hooks", function(ctx)
		ctx.it("beforeEach should run before each test", function()
			local count = 0

			local suite = Specium.suite("hooks", function(ctx)
				ctx.beforeEach(function()
					count += 1
				end)

				ctx.it("a", function() end)
				ctx.it("b", function() end)
				ctx.it("c", function() end)
			end)

			Specium.run(suite)

			Specium.expect(count).withMessage("beforeEach count").toBe(3)
		end)

		ctx.it("afterEach should run after each test", function()
			local count = 0

			local suite = Specium.suite("hooks", function(ctx)
				ctx.afterEach(function()
					count += 1
				end)

				ctx.it("a", function() end)
				ctx.it("b", function() end)
			end)

			Specium.run(suite)

			Specium.expect(count).withMessage("afterEach count").toBe(2)
		end)

		ctx.it("beforeAll should run once before all tests", function()
			local count = 0

			local suite = Specium.suite("hooks", function(ctx)
				ctx.beforeAll(function()
					count += 1
				end)

				ctx.it("a", function() end)
				ctx.it("b", function() end)
				ctx.it("c", function() end)
			end)

			Specium.run(suite)

			Specium.expect(count).withMessage("beforeAll count").toBe(1)
		end)

		ctx.it("afterAll should run once after all tests", function()
			local count = 0

			local suite = Specium.suite("hooks", function(ctx)
				ctx.afterAll(function()
					count += 1
				end)

				ctx.it("a", function() end)
				ctx.it("b", function() end)
			end)

			Specium.run(suite)

			Specium.expect(count).withMessage("afterAll count").toBe(1)
		end)

		ctx.it("beforeEach should not run for skipped tests", function()
			local count = 0

			local suite = Specium.suite("hooks", function(ctx)
				ctx.beforeEach(function()
					count += 1
				end)

				ctx.it("a", function() end)
				ctx.skip("b", function() end)
			end)

			Specium.run(suite)

			Specium.expect(count).withMessage("beforeEach count").toBe(1)
		end)
	end)

	ctx.describe("expect matchers", function(ctx)
		ctx.it("toBe", function()
			Specium.expect(1 + 1).toBe(2)
		end)

		ctx.it("toBe with .never", function()
			Specium.expect(1 + 1).never.toBe(3)
		end)

		ctx.it("toEqual deep", function()
			Specium.expect({ a = 1 }).toEqual({ a = 1 })
		end)

		ctx.it("toEqual nested", function()
			Specium.expect({ a = { b = 2 } }).toEqual({ a = { b = 2 } })
		end)

		ctx.it("toContain string", function()
			Specium.expect("hello world").toContain("world")
		end)

		ctx.it("toContain table", function()
			Specium.expect({ 1, 2, 3 }).toContain(2)
		end)

		ctx.it("toHaveLength", function()
			Specium.expect({ 1, 2, 3 }).toHaveLength(3)
		end)

		ctx.it("toBeA", function()
			Specium.expect("str").toBeA("string")
			Specium.expect(1).toBeA("number")
			Specium.expect({}).toBeA("table")
		end)

		ctx.it("toBeTruthy", function()
			Specium.expect(1).toBeTruthy()
			Specium.expect(false).never.toBeTruthy()
			Specium.expect(nil).never.toBeTruthy()
		end)

		ctx.it("toBeNil", function()
			Specium.expect(nil).toBeNil()
			Specium.expect(1).never.toBeNil()
		end)

		ctx.it("toBeNear", function()
			Specium.expect(0.1 + 0.2).toBeNear(0.3)
		end)

		ctx.it("toBeNear with custom epsilon", function()
			Specium.expect(1.5).toBeNear(1.6, 0.2)
			Specium.expect(1.5).never.toBeNear(1.6, 0.05)
		end)

		ctx.it("toBeGreaterThan", function()
			Specium.expect(5).toBeGreaterThan(3)
		end)

		ctx.it("toBeLessThan", function()
			Specium.expect(3).toBeLessThan(5)
		end)

		ctx.it("toMatch", function()
			Specium.expect("hello123").toMatch("%d+")
		end)

		ctx.it("toMatch with .never", function()
			Specium.expect("hello").never.toMatch("%d+")
		end)

		ctx.it("toThrow", function()
			Specium.expect(function()
				error("oops")
			end).toThrow()
		end)

		ctx.it("toThrow with expected message", function()
			Specium.expect(function()
				error("oops", 0)
			end).toThrow("oops")
		end)

		ctx.it("toThrow with .never", function()
			Specium.expect(function() end).never.toThrow()
		end)

		ctx.it("withMessage on failure", function()
			local suite = Specium.suite("msg", function(ctx)
				ctx.it("fail", function()
					Specium.expect(1).withMessage("custom msg").toBe(2)
				end)
			end)

			local _, result = Specium.run(suite)

			Specium.expect(result.failed).withMessage("failed count").toBe(1)
		end)
	end)
end)

local output, result = Specium.run(speciumSuite)

warn("=SPECIUM OUTPUT=")
print(output)
warn("=SPECIUM RESULT=")
print(result)
