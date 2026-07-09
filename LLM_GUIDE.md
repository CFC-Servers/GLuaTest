# Writing GLuaTest Tests

GLuaTest is a testing framework for Garry's Mod Lua (GLua). This document is the complete reference for writing GLuaTest tests. It is authoritative: every field, function, and expectation that exists in GLuaTest is listed here. If a method is not in this document, it does not exist — do not use matchers or helpers from other frameworks (Jest, Busted, luassert, etc.). The only additions come from the project itself: shared helpers it defines under `lua/gluatest/extensions/`.

Your job when writing tests: read the code under test first, then produce test files that follow this reference exactly.

## Test files and discovery

- Test files live at `lua/tests/<project>/` (any name for `<project>`, e.g. your addon's name). Subdirectories are scanned recursively; every `.lua` file found is loaded as one test group.
- Files placed directly in `lua/tests/` (not inside a project folder) are **not** loaded.
- Each test file must `return` a single test group table. A file whose returned table has no `cases` field is ignored with a warning. File-local helpers and constants above the `return` are fine.
- Tests run **serverside**.

Minimal runnable skeleton:

```lua
return {
    groupName = "MyAddon: CalculateFallDamage",

    cases = {
        {
            name = "Returns 0 for short falls",
            func = function()
                local damage = MyAddon.CalculateFallDamage( 10 )
                expect( damage ).to.equal( 0 )
            end
        }
    }
}
```

## Test group fields

This is the complete list of group fields:

| Field | Type | Required | Purpose |
|---|---|---|---|
| `cases` | table | yes | Array of test case tables |
| `groupName` | string | no | Display name (defaults to the file path) |
| `beforeAll` | `function( state )` | no | Runs once before the group; receives the group state |
| `beforeEach` | `function( state )` | no | Runs before each case; receives that case's state |
| `afterEach` | `function( state )` | no | Runs after each case, even if it failed |
| `afterAll` | `function( state )` | no | Runs once after the group; receives the group state |

## Test case fields

This is the complete list of case fields:

| Field | Type | Default | Purpose |
|---|---|---|---|
| `name` | string | required | Human-readable description of the behavior |
| `func` | `function( state )` | required | The test body |
| `async` | boolean | `false` | Test finishes via `done()` / `fail()` instead of by returning |
| `timeout` | number | `5` | Seconds before an async case fails with "Timeout" |
| `coroutine` | boolean | `false` | Run the case inside a coroutine (it may yield) |
| `cleanup` | `function( state )` | — | Runs after the case, **even if it failed or errored** |
| `when` | boolean, function, or list of either | — | Case runs only if every condition is/returns `true` |
| `skip` | boolean or function | — | Case is skipped if `true`/returns `true`; takes precedence over `when` |

Notes:
- `when = false` (or a function returning anything but `true`) skips the case. A list form is supported: `when = { system.IsLinux(), function() return game.IsDedicated() end }`.
- A synchronous case that runs without ever calling `expect` is reported as **empty**, not passed. Async cases aren't flagged automatically, but the same rule applies: every case must assert something.

## Expectations

Assertions start with `expect( subject )` and chain through one of five links:

- `.to` — positive assertion
- `.notTo` / `.toNot` — negated assertion
- `.was` / `.wasNot` — full aliases of `.to` / `.notTo`; by convention used for stub call checks (`expect( myStub ).was.called()`)

This is the **complete** list of current expectation methods (two deprecated aliases are noted below). Anything else (`toBe`, `toEqual`, `toContain`, `contain`, `beCloseTo`, `toThrow`, `assert.are.equal`, ...) does not exist in GLuaTest.

| Method | Passes when |
|---|---|
| `equal( value )` | `subject == value` (no deep comparison) |
| `deepEqual( tbl )` | Tables are recursively equal (both must be tables) |
| `aboutEqual( num, tolerance? )` | Difference ≤ tolerance (default `0.00001`); subject must be a number |
| `beLessThan( num )` | `subject < num` |
| `beGreaterThan( num )` | `subject > num` |
| `beBetween( lower, upper )` | `lower <= subject <= upper` (inclusive) |
| `beTrue()` / `beFalse()` | Subject is exactly `true` / exactly `false` |
| `beValid()` / `beInvalid()` | `IsValid( subject )` passes / fails |
| `beNil()` | Subject is `nil` |
| `exist()` | Subject is not `nil` |
| `beNaN()` | Subject is NaN; subject must be a number |
| `beA( typeName )` / `beAn( typeName )` | `type( subject ) == typeName` (aliases) |
| `succeed()` | Subject function runs without erroring |
| `err()` | Subject function errors |
| `errWith( message )` | Subject function errors with exactly `message` |
| `called( n? )` | Subject stub was called at least once (or at least `n` times) |

Semantics that matter:

- **Function subjects**: for `succeed`, `err`, and `errWith`, pass the function *uncalled*, with its arguments as extra `expect` arguments:

  ```lua
  expect( MyAddon.Heal, ply, 50 ).to.succeed()          -- calls MyAddon.Heal( ply, 50 )
  expect( MyAddon.Heal, nil ).to.errWith( "Expected a player, got nil" )
  ```

- `errWith` compares the exact error text after stripping the leading `path/to/file.lua:123:` prefix, so match the bare message. Engine errors need their full text, e.g. `"bad argument #1 to 'Heal' (Player expected, got nil)"`.
- `expect( myStub ).was.called( 2 )` passes when the stub was called **at least** 2 times, not exactly 2.
- The negated form `wasNot.called()` takes no count — it asserts zero calls.
- Use `aboutEqual` or `beBetween` for float results; `equal` on floats is flaky.
- In a synchronous case, a failed `expect` raises an error — **nothing after the failed line runs**. Put all teardown in `cleanup`, never at the bottom of `func`. (Async cases behave differently; see below.)
- Deprecated, do not write in new tests: `.eq` (use `equal`) and `.haveBeenCalled` (use `.was.called`).

## Stubs

`stub( tbl, "key" )` replaces `tbl.key` with a callable stub and returns it. This is the complete stub API:

```lua
local s = stub( MyAddon, "GetRank" )          -- calls return nil until a behavior is set
stub( MyAddon, "GetRank" ).returns( "admin" ) -- always returns these values (varargs allowed)
stub( MyAddon, "GetRank" ).with( function( ply ) return ply.rank end ) -- delegate to a function
stub( MyAddon, "GetRank" ).returnsSequence( { "user", "admin" }, "guest" ) -- nth call returns sequence[n]; the default is optional (nil when exhausted without one)
local spy = stub()                             -- bare spy; replaces nothing, useful as a callback

s.callCount                                    -- number of times the stub was called
s.callHistory                                  -- array of argument lists, one per call
s:Restore()                                    -- put the original function back early
```

- Each stub takes **one** behavior: `.returns`, `.with`, or `.returnsSequence` — setting a second errors ("Stub already set").
- The key does not need to exist beforehand — stubbing a method the table never had works, and `Restore` sets it back to `nil`.
- Inspect calls with `expect( s ).was.called()` / `expect( s ).wasNot.called()`. For an exact count, assert the field: `expect( s.callCount ).to.equal( 1 )`.
- Stubs restore the original function **automatically after each case**, including stubs created in `beforeEach`. Call `s:Restore()` early only if the same test needs the real function back.

## Async cases

Set `async = true` when the behavior under test finishes later (timers, hooks, net callbacks). Two extra functions exist inside async cases only:

- `done()` — marks the case finished.
- `fail( reason? )` — immediately fails and finishes the case.

Every path through an async case **must** end in exactly one `done()` or `fail()` call — otherwise the case hangs and fails with "Timeout" after `timeout` seconds.

```lua
{
    name = "Regenerates health on the next think",
    async = true,
    timeout = 0.5, -- keep timeouts as low as reliably possible
    func = function( state )
        -- state.ply is created in the group's beforeEach (not shown)
        hook.Add( "Think", "MyAddon_RegenTest", function()
            hook.Remove( "Think", "MyAddon_RegenTest" ) -- stop re-firing before done() lands

            local health = state.ply:Health()
            expect( health ).to.beGreaterThan( 100 )

            done()
        end )
    end
}
```

Use `fail()` as a tripwire for code paths that must not run:

```lua
{
    name = "Does not notify muted players",
    async = true,
    timeout = 0.5,
    func = function()
        local mutedPly = { muted = true, IsValid = function() return true end }

        MyAddon.Notify( mutedPly, function()
            fail( "The notify callback ran for a muted player" )
        end )

        timer.Simple( 0.2, function()
            local sentCount = MyAddon.GetSentCount()
            expect( sentCount ).to.equal( 0 )

            done()
        end )
    end
}
```

- Inside an async case, a failed `expect` is **recorded as the case's failure but does not abort execution** — the code after it keeps running. Still call `done()` after your expectations so the case ends immediately instead of waiting out the timeout.
- A plain runtime error inside a timer/hook callback (not an `expect` failure) is not attributed to the case — it surfaces as a "Timeout". Keep callback bodies down to expectations plus `done()`.
- Choose the smallest `timeout` that is reliable (0.1–1 for most timer/hook tests). The default is 5 seconds; a hung test holds up the whole run for that long.

## Coroutine cases

Set `coroutine = true` to run `func` inside a coroutine so it can `coroutine.yield()` mid-test. Combine it with `async = true` + `done()` so the `timeout` catches a coroutine that is never resumed. Capture the running coroutine and have outside code resume it:

```lua
{
    name = "Finishes loading after one tick",
    async = true,
    coroutine = true,
    timeout = 0.5,
    func = function()
        local co = coroutine.running()
        timer.Simple( 0, function() coroutine.resume( co ) end )
        coroutine.yield() -- suspends here until the timer resumes us

        local loaded = MyAddon.IsLoaded()
        expect( loaded ).to.beTrue()

        done()
    end
}
```

GLuaTest ships no wait helpers — helpers like `WaitForTicks` only exist if the project defines them as extensions (see below).

## What the framework cleans up for you — and what it doesn't

After every case, GLuaTest automatically:

- Removes any hooks added with `hook.Add` during the case
- Removes any timers created with `timer.Create` / `timer.Simple` during the case
- Restores all stubs

Everything else leaks unless you undo it. Entities you spawn, files you write, globals or convars you change, net receivers you register — revert them in `cleanup` (per-case) or `afterEach` (whole group). Because a failed `expect` aborts a synchronous `func`, stash anything needing teardown on `state` the moment you create it, and do the teardown in `cleanup`:

```lua
{
    name = "Applies damage to the target prop",
    func = function( state )
        local prop = ents.Create( "prop_physics" )
        prop:Spawn()
        state.prop = prop -- stash BEFORE asserting, so cleanup can always find it

        MyAddon.Explode( prop:GetPos(), 10 )

        local health = prop:Health()
        expect( health ).to.beLessThan( 100 )
    end,

    cleanup = function( state )
        if IsValid( state.prop ) then
            SafeRemoveEntity( state.prop )
        end
    end
}
```

## State

Every case gets a fresh `state` table shared by `beforeEach`, `func`, `cleanup`, and `afterEach` for that case. Reads fall through to the group state (which `beforeAll`/`afterAll` receive), so values set in `beforeAll` are visible in every case, while writes inside a case stay isolated to that case.

Use `state` for fixtures and for anything `cleanup` must undo. Do not pass data between cases — each case must work standing alone.

## Designing good tests

- **Test observable behavior**, one behavior per case: the return value, the entity change, the error raised. Don't test internals a caller can't see.
- **Name cases as present-tense factual sentences** about behavior: `"Returns nil when the player is disconnected"`, `"Errors when given a negative amount"` — not `"test heal 1"`.
- **Cover three kinds of cases** for each function: expected inputs, edge inputs (`nil`, `0`, negative, empty string/table, huge values), and failure paths asserted with `errWith` and the exact message.
- **Split work into intentional steps**: call the function under test, assign the result to a named local, then assert the local. Don't bury the call inside `expect( ... )`:

  ```lua
  local price = PointShop.CalculatePrice( 100, "member" )
  expect( price ).to.equal( 90 )
  ```

- **No loops or metaprogramming in cases**: write each input's case or assertion out explicitly, even when repetitive — explicit tests read clearly and fail clearly.
- **Isolate the unit with stubs**: stub out expensive or unrelated dependencies (network, database, chat output) so the test exercises only the function under test.
- **Prefer fake entity tables over real entities**: when the code under test only calls methods on an entity, hand it a plain table faking exactly those methods — no spawning, no cleanup, no engine flakiness. If the code calls `IsValid( target )`, include an `IsValid` method on the fake. Create a real entity only when engine behavior matters (spawning, physics, damage, networking):

  ```lua
  local fakePly = {
      Nick = function() return "Fake Player" end,
      IsPlayer = function() return true end,
      IsValid = function() return true end
  }

  local message = MyAddon.FormatJoinMessage( fakePly )
  expect( message ).to.equal( "Fake Player joined!" )
  ```

- **Use bots when a real player is unavoidable**: `player.CreateNextBot( name )` gives a real player entity serverside. Never rely on connected humans. Kick bots in `cleanup`.
- **Guard every entity teardown**: `if IsValid( state.ent ) then SafeRemoveEntity( state.ent ) end`.
- **Gate environment-dependent cases with `when`** (map, OS, player count) instead of letting them fail.
- **Prefer sync tests**: only use `async` when the code path is genuinely asynchronous.
- **Check for project extensions**: projects can define shared helpers in `lua/gluatest/extensions/`. Reuse the project's existing helpers and conventions; never invent a helper that isn't in this document or in that folder.
- **Code style**: 4-space indent, double quotes, spaces inside parentheses — `expect( x ).to.equal( y )`, `func = function( state )`. Empty parentheses stay empty: `done()`, `beTrue()`.
- **Vertical spacing**: a blank line between every case in `cases`; inside a case, a blank line after each multi-line function value that has another key after it (e.g. after `func = ... end,` when `cleanup` follows); a blank line before the final `done()` in async callbacks.

## Workflow

1. Read the code under test. List its public functions and, for each, the behaviors a caller relies on.
2. Locate or create the test file: `lua/tests/<project>/<module>.lua`, one focused group per file.
3. Write one case per behavior: expected, edge, and error cases.
4. Make each case self-contained: fixtures in `beforeEach`/`state`, teardown of entities/files/globals in `cleanup`.
5. Use `async` + `done()` + a tight `timeout` only where the code is actually asynchronous.
6. Before finishing, verify every field and expectation you wrote appears in the tables above, and that every case calls `expect`.
7. If Docker is available, prove the suite passes by running it (see "Running your tests" below). Reading tests is not running them: a real run catches load errors, typo'd expectation names, async cases that never call `done()`, and behavior you guessed wrong.

## Running your tests

GLuaTest ships a local runner that boots a real GMod server in Docker and runs the suite — the same runner CI uses. Clone the GLuaTest repo if you don't have it, then run from the project you're testing:

```sh
cd /path/to/your/project
/path/to/GLuaTest/docker/run_local.sh --quiet
```

- Always pass `--quiet`: the live server stream is thousands of lines. You still get progress notes and the verdict. Use `--project /path/to/project` to run from elsewhere.
- **Exit code is the verdict:** `0` = every test passed. `124` = the server hit the time limit before finishing — retry with `--timeout 5`. Anything else = a test failed or the server crashed.
- Every run writes the complete server log to `gluatest-run.log` in the directory you invoked from. Do not read it whole (it contains the full server boot); search it: `FAIL` marks failed cases and `Test failures:` heads the failure detail section with stack traces.
- On Apple Silicon hosts add `--branch x86-64` — the default branch's 32-bit server crashes under emulation.
- The first run downloads a multi-gigabyte server image and is slow; later runs reuse it. If your project needs other addons, list them in `gluatest_requirements.txt` (`Owner/Repo` per line) in the project root — the runner picks it up automatically.

## Worked examples

A complete file — pure-function group with edge and error cases:

```lua
return {
    groupName = "PointShop: CalculatePrice",

    cases = {
        {
            name = "Applies the member discount",
            func = function()
                local price = PointShop.CalculatePrice( 100, "member" )
                expect( price ).to.equal( 90 )
            end
        },

        {
            name = "Applies fractional discounts within rounding tolerance",
            func = function()
                local price = PointShop.CalculatePrice( 99.99, "member" )
                expect( price ).to.aboutEqual( 89.99, 0.01 )
            end
        },

        {
            name = "Charges guests full price",
            func = function()
                local price = PointShop.CalculatePrice( 100, "guest" )
                expect( price ).to.equal( 100 )
            end
        },

        {
            name = "Returns 0 for a free item regardless of rank",
            func = function()
                local price = PointShop.CalculatePrice( 0, "admin" )
                expect( price ).to.equal( 0 )
            end
        },

        {
            name = "Errors when given a negative base price",
            func = function()
                expect( PointShop.CalculatePrice, -5, "member" ).to.errWith( "price must be >= 0" )
            end
        }
    }
}
```

Entity fixture via `beforeEach`, extra resources cleaned per-case:

```lua
return {
    groupName = "FortWars: Ownership",

    beforeEach = function( state )
        local prop = ents.Create( "prop_physics" )
        prop:SetModel( "models/props_c17/oildrum001.mdl" )
        prop:Spawn()
        state.prop = prop
    end,

    afterEach = function( state )
        if IsValid( state.prop ) then
            SafeRemoveEntity( state.prop )
        end
    end,

    cases = {
        {
            name = "Marks the spawner as the owner",
            func = function( state )
                local bot = player.CreateNextBot( "fortwars_test_bot" )
                state.bot = bot

                FortWars.SetOwner( state.prop, bot )

                local owner = FortWars.GetOwner( state.prop )
                expect( owner ).to.equal( bot )
            end,

            cleanup = function( state )
                if IsValid( state.bot ) then
                    state.bot:Kick( "Test finished" )
                end
            end
        },

        {
            name = "Returns nil for unowned props",
            func = function( state )
                local owner = FortWars.GetOwner( state.prop )
                expect( owner ).to.beNil()
            end
        }
    }
}
```

Stub-isolated logic with a fake player and a globals-restoring `cleanup`:

```lua
return {
    groupName = "DailyRewards: Grant",

    beforeEach = function( state )
        -- Grant only reads identity methods, so a fake player table is enough
        state.fakePly = {
            SteamID = function() return "STEAM_0:1:11111" end,
            IsPlayer = function() return true end,
            IsValid = function() return true end
        }
    end,

    cases = {
        {
            name = "Saves through the storage layer exactly once",
            func = function( state )
                local save = stub( DailyRewards.Storage, "Save" ).returns( true )

                DailyRewards.Grant( state.fakePly, 500 )

                expect( save.callCount ).to.equal( 1 )
            end
        },

        {
            name = "Skips players who already claimed today",
            func = function( state )
                stub( DailyRewards.Storage, "HasClaimed" ).returns( true )
                local save = stub( DailyRewards.Storage, "Save" )

                state.originalCooldown = DailyRewards.Cooldown
                DailyRewards.Cooldown = 0 -- globals aren't auto-restored; stash the original

                DailyRewards.Grant( state.fakePly, 500 )

                expect( save ).wasNot.called()
            end,

            cleanup = function( state )
                DailyRewards.Cooldown = state.originalCooldown
            end
        }
    }
}
```

Async timer behavior with a `when`-gated case:

```lua
return {
    groupName = "JailBreak: RoundTimer",

    cases = {
        {
            name = "Fires the round-end callback after the duration",
            async = true,
            timeout = 0.5,
            func = function()
                local onEnd = stub()

                JailBreak.StartRound( 0.1, onEnd )

                timer.Simple( 0.2, function()
                    expect( onEnd ).was.called()

                    done()
                end )
            end
        },

        {
            name = "Counts every connected player into the round",
            when = function() return #player.GetHumans() == 0 end, -- needs a bot-only server
            func = function( state )
                local bot = player.CreateNextBot( "jb_test_bot" )
                state.bot = bot

                JailBreak.StartRound( 10 )

                local playerCount = JailBreak.GetRoundPlayerCount()
                expect( playerCount ).to.equal( 1 )
            end,

            cleanup = function( state )
                JailBreak.EndRound()

                if IsValid( state.bot ) then
                    state.bot:Kick( "Test finished" )
                end
            end
        }
    }
}
```

## Common mistakes

**Teardown at the bottom of `func`** — a failed `expect` aborts `func`, so teardown there never runs and state leaks into other tests:

```lua
-- WRONG
func = function()
    OldValue = MyAddon.MaxHealth
    MyAddon.MaxHealth = 50
    expect( MyAddon.GetMaxHealth() ).to.equal( 50 )
    MyAddon.MaxHealth = OldValue -- skipped if the expect fails
end

-- RIGHT: cleanup always runs, even on failure
func = function( state )
    state.oldValue = MyAddon.MaxHealth
    MyAddon.MaxHealth = 50

    local maxHealth = MyAddon.GetMaxHealth()
    expect( maxHealth ).to.equal( 50 )
end,

cleanup = function( state )
    MyAddon.MaxHealth = state.oldValue
end
```

**Async case that never calls `done()`** — the case hangs until the timeout and then fails, even though its expectations passed:

```lua
-- WRONG
async = true,
func = function()
    timer.Simple( 0.1, function()
        expect( MyAddon.IsReady() ).to.beTrue()
        -- missing done()
    end )
end

-- RIGHT: done() after the expectations, timeout kept tight
async = true,
timeout = 0.5,
func = function()
    timer.Simple( 0.1, function()
        local ready = MyAddon.IsReady()
        expect( ready ).to.beTrue()

        done()
    end )
end
```

**Matchers borrowed from other frameworks** — they don't exist here and error immediately:

```lua
-- WRONG
expect( result ).to.toBe( 5 )
expect( list ).to.contain( "admin" )

-- RIGHT: use the GLuaTest expectation table
expect( result ).to.equal( 5 )

local hasAdmin = table.HasValue( list, "admin" )
expect( hasAdmin ).to.beTrue()

expect( list ).to.deepEqual( { "admin" } )
```

## Critical reminders

- Use only the fields, expectations, and stub methods listed in this document, plus helpers the project itself defines under `lua/gluatest/extensions/` — nothing else exists.
- Teardown goes in `cleanup` (or `afterEach`), never at the end of `func`; stash handles on `state` as soon as you create them.
- Async cases must set `async = true`, end every path with `done()` or `fail()`, and use the lowest reliable `timeout` (default is 5s).
- Hooks, timers, and stubs are cleaned up automatically after each case (still `hook.Remove` a repeating hook once it has served its purpose); entities, files, globals, and convars are yours to revert.
- Every case must call `expect` at least once, and files must live at `lua/tests/<project>/`.
- Write tests explicitly and intentionally: assign results to locals before asserting, no loops over inputs, blank lines between cases and after multi-line function values.
- Match the code style: spaces inside parentheses, double quotes, 4-space indent.
