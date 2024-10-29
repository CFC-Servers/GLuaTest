GLuaTest is a testing framework for Garry's Mod Lua (GLua) projects, designed to make writing automated tests intuitive and efficient.

---

**Test Structure:**

- Each test file returns a **Test Group**, which is a table containing:
  - `groupName` (optional): Name of the test group.
  - `cases` (required): Table of **Test Cases**.
  - `beforeAll` (optional): Function executed once before all test cases.
  - `beforeEach` (optional): Function executed before each test case.
  - `afterEach` (optional): Function executed after each test case.
  - `afterAll` (optional): Function executed once after all test cases.

**Test Case Structure:**

- Each Test Case is a table with:
  - `name` (required): Description of the test.
  - `func` (required): Function containing the test logic.
  - `async` (optional, default `false`): Set to `true` for asynchronous tests.
  - `timeout` (optional, default `60`): Time in seconds before an async test times out. (Keep this as low as possible)
  - `cleanup` (optional): Function executed after the test case, even if it fails.
  - `when` (optional): Boolean or function; test runs only if `true`.
  - `skip` (optional): Boolean or function; test is skipped if `true`.

---

**Expectations:**

Use the `expect` function to make assertions.

- **Equality:**
  - `expect( actual ).to.equal( expected )`
  - `expect( actual ).to.aboutEqual( expected, tolerance? )`
- **Comparisons:**
  - `expect( actual ).to.beLessThan( value )`
  - `expect( actual ).to.beGreaterThan( value )`
  - `expect( actual ).to.beBetween( min, max )`
- **Type Checks:**
  - `expect( actual ).to.beA( "type" )` or `expect( actual ).to.beAn( "type" )`
- **Existence:**
  - `expect( actual ).to.exist()`
  - `expect( actual ).to.beNil()`
- **Validity:**
  - `expect( entity ).to.beValid()`
  - `expect( entity ).to.beInvalid()`
- **Boolean Values:**
  - `expect( actual ).to.beTrue()`
  - `expect( actual ).to.beFalse()`
- **Errors:**
  - `expect( function ).to.err()`
  - `expect( function ).to.errWith( "error message" )`
  - `expect( function ).to.succeed()`
- **Function Calls (with stubs, or functions):**
  - `expect( funcStub ).was.called()`
  - `expect( funcStub ).wasNot.called()`

When passing functions to `expect`, you may add parameters that get passed into the subject function:
```
expect( func, param1, param2 ).to.succeed() -- Calls func(param1, param2)
```

---

**Negation:**

- Use `.notTo` or `.toNot` to negate expectations:
  - `expect( actual ).notTo.equal( value )`
  - `expect( entity ).toNot.beValid()`

---

**Stubs:**

- Replace functions to control behavior during tests.
- **Creating a Stub:**
  - `local myStub = stub( tbl, "functionName" ) -- Stubs tbl.functionName`
- **Specifying Return Values:**
  - `.returns( value )`: Always returns `value`.
  - `.with( func )`: Uses a custom function.
  - `.returnsSequence( { values }, default )`: Returns values in sequence.
- **Checking Calls:**
  - `expect( myStub ).was.called()`
  - `expect( myStub ).wasNot.called()`
- **Restoring Original Function (this is done automatically when the test finishes):**
  - `myStub:Restore()`

---

**Asynchronous Tests:**

- Set `async = true` in the test case.
- Use `done()` to signal completion.
- Use `fail()` or `fail( "custom message" )` to manually fail.
- Example:

  ```lua
  {
      name = "Async Test Example",
      async = true,
      timeout = 1.25, -- Keep the timeout as low as possible
      func = function()
          timer.Simple( 1, function()
              expect( true ).to.beTrue()
              done()
          end )
      end
  }
  ```

---

**State Management:**

- Use `state` table to share data between `beforeEach`, `func`, `cleanup`, and `afterEach`.
- Store data in the `state` when you need to reliably clean it up/undo it after the test.
- Example:

  ```lua
  beforeEach = function( state )
      local ent = ents.Create( "prop_physics" )
      ent:Spawn()

      state.ent = ent
  end,
  afterEach = function( state )
      if IsValid( state.ent ) then
          SafeRemoveEntity( state.ent )
      end
  end

  cases = {
      {
          name = "State Example",
          func = function( state )
              state.originalValue = _G.SomeGlobal
              _G.SomeGlobal = 42

              local ent = state.ent
              expect( ent:GetClass() ).to.equal( "prop_physics" )

              local extraEnt = ents.Create( "prop_physics" )
              extraEnt:Spawn()
              state.extraEnt = extraEnt
              expect( extraEnt:GetClass() ).to.equal( "prop_physics" )

              -- Don't clean up `SomeGlobal` or `extraEnt` here because if any `expect` fails (or something errors), nothing after it will run
              -- Do it in the `cleanup` function instead
          end,
          cleanup = function( state )
              _G.SomeGlobal = state.originalValue

              if IsValid( state.extraEnt ) then
                  SafeRemoveEntity( state.extraEnt )
              end
          end
      }
  }
  ```

---

**Example Test Group:**

```lua
return {
    groupName = "Example Tests",

    beforeEach = function( state )
        state.player = Player( 1 ) -- Convenience, does not need cleanup

        -- file.Write( "test.txt", "Hello, world!" ) This is only needed for a single test, it should be in that test instead
    end,

    afterEach = function( state )
        -- file.Delete( "test.txt" ) if you did file.Write in beforeEach, you should do file.Delete here
    end,

    cases = {
        {
            name = "Check Player Validity",
            func = function(state)
                expect(state.player).to.beValid()
            end
        },
        {
            name = "Function Should Succeed",
            func = function()
                local result = SomeFunction()
                expect(result).to.succeed()
            end
        },
        {
            name = "Checker returns true when file exists",
            func = function()
                file.Write( "test.txt", "Hello, world!" )

                local exists = file.Exists( "test.txt", "DATA" )
                expect( exists ).to.beTrue()
            end,
            cleanup = function()
                file.Delete( "test.txt" ) -- Clean it up here instead of in the test func
            end
        {
            name = "Stub Example",
            func = function()
                -- You do not need to restore the stub manually in cases like this (it's done automatically)
                local myStub = stub( SomeModule, "FunctionName" ).returns( true )
                expect( SomeModule.FunctionName() ).to.beTrue()
                expect( myStub ).was.called()
            end
        },
        {
            name = "Stub restoration example",
            func = function()
                local printStub = stub( _G, "print" ).returns( true )
                expect( SomeModule.FunctionThatCallsPrint() ).to.beTrue()
                expect( printStub ).was.called()

                -- But now I need it to actually print again, so I have to manually Restore the stub
                printStub:Restore()

                expect( SomeModule.AnotherFunctionThatCallsPrint() ).to.beTrue()
            end
        },
        {
            name = "Conditional Test",
            when = system.IsLinux(),
            func = function()
                expect(system.IsLinux()).to.beTrue()
            end
        },
        {
            name = "Skipped Test",
            skip = true,
            func = function()
                -- This test will be skipped
            end
        }
    }
}
```

---

**Best Practices:**

- **Isolation:** Use stubs to isolate the unit under test.
- **Cleanup:** Ensure any changes made during tests are reverted.
- **Avoid Side Effects:** Tests should not affect global state or other tests.
- **Clarity:** Use descriptive names and clear assertions.
- **State Sharing:** Use `state` to pass data between setup, test, and teardown functions.

---

**Caveats:**

- **No External Functions:** Do not use functions not provided by GLuaTest.
- **Automatic Stub Restoration:** Stubs are automatically restored after each test; manual restoration is rarely needed.
- **Async Tests Must Signal Completion:** Always call `done()` or `fail()` in async tests.

---

By following this guide, you can write effective GLuaTest test suites for GLua code, utilizing the framework's full feature set correctly.
