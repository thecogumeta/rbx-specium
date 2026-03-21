interface SpeciumResult {
  success: boolean;
  message: string;
}

interface SpeciumRunResult {
  total: number;
  passed: number;
  failed: number;
  suites: SpeciumSuiteResult[];
}

interface SpeciumSuiteResult {
  name: string;
  tests: SpeciumTestResult[];
  subSuites: SpeciumSuiteResult[];
}

interface SpeciumTestResult {
  name: string;
  success: boolean;
  message: string;
}

interface SpeciumSuiteContext {
  it(name: string, fn: () => SpeciumResult | void): void;
  describe(name: string, fn: (ctx: SpeciumSuiteContext) => void): void;
}

interface SpeciumSuite {
  name: string;
}

interface SpeciumMatchersRaw {
  toBe(expected: unknown): void;
  toEqual(expected: unknown): void;
  toBeA(type: string, legacy?: boolean): void;
  toBeTruthy(): void;
  toBeNil(): void;
  toBeNear(expected: number, epsilon?: number): void;
  toBeGreaterThan(expected: number): void;
  toBeLessThan(expected: number): void;
  toContain(item: unknown): void;
  toHaveLength(expected: number): void;
  toMatch(pattern: string): void;
  toThrow(expected?: unknown, ...args: unknown[]): void;
  withMessage(msg: string): SpeciumMatchersRaw;
}

interface SpeciumMatchers extends SpeciumMatchersRaw {
  never: SpeciumMatchersRaw;
}

interface Specium {
  suite(name: string, fn: (ctx: SpeciumSuiteContext) => void): SpeciumSuite;
  run(suite: SpeciumSuite): [string, SpeciumRunResult];
  runTests(
    testsFolder: Instance | Instance[],
  ): [string, Array<SpeciumRunResult>];
  expect(received: unknown): SpeciumMatchers;
  success(message: string): SpeciumResult;
  error(message: string): SpeciumResult;
}

declare const Specium: Specium;
export = Specium;
