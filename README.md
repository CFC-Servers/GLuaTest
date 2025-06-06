# GLuaTest
<p align="left">
    <a href="https://discord.gg/5JUqZjzmYJ" alt="Discord Invite"><img src="https://img.shields.io/discord/981394195812085770?style=flat-square&logo=discord&logoColor=white&label=Support" /></a>
    <a href="https://github.com/CFC-Servers/GLuaTests/actions/workflows/self_tests.yml" alt="GLuaTest Status"><img src="https://img.shields.io/github/actions/workflow/status/CFC-Servers/GLuaTest/self_tests.yml?branch=main&logo=lua&logoColor=white&style=flat-square&label=Self%20Tests" /></a>
    <a href="https://github.com/CFC-Servers/GLuaTests/actions/workflows/self_tests.yml" alt="GLuaTest Status"><img src="https://img.shields.io/github/v/tag/CFC-Servers/GLuaTest?sort=semver&style=flat-square&logo=github&logoColor=white&label=Version" /></a>
</p>

🎉 <strong>The missing test framework for GMod</strong> 🎉

**GLuaTest is a testing framework built for Garry's Mod.**
**Its job is to make writing automated tests for Garry's Mod projects easy and tolerable.**

**It offers an approachable and flexible syntax that makes writing tests intuitive.**

GLuaTest takes a lot of inspiration from both Ruby's [RSpec](https://rspec.info/) and JavaScript's [Jest](https://jestjs.io/)

**Glossary**
 - [Additional reading](#some-additional-reading)
 - [Usage](#usage)
 - [Writing Tests](#writing-tests-%EF%B8%8F)
 - [Troubleshooting](#troubleshooting-)
 - [Developers](#developers-)

![GLuaLint](https://github.com/CFC-Servers/GLuaTest/actions/workflows/glualint.yml/badge.svg)

---
_(Are you an impatient software developer? Check out the [quickstart](https://github.com/CFC-Servers/GLuaTest/blob/main/QUICKSTART.md) guide to go fast)_

_(Is the idea of testing your code new to you? That's great! Check out the [guided testing walkthrough](https://github.com/CFC-Servers/GLuaTest/wiki/I-set-up-GLuaTest...-now-what) to see some great examples of how to test real code)_

<br>

# Features

## **Simple test setup and quirky (yet intuitive!) test syntax**
```lua
-- lua/tests/project_name/main.lua

return {
    groupName = "MyProject",
    cases = {
        {
            name = "Should create project tables",
            func = function()
                expect( MyProject ).to.exist()
            end
        }
    }
}
```

## **Beautiful test output**
<img src="https://user-images.githubusercontent.com/7936439/170405271-abbd745a-f9ca-48c5-8228-5160c8349a2c.png" width="725" height="300">


## **Handsome, informative error reporting**
![image](https://user-images.githubusercontent.com/7936439/171299517-72dde73c-3b29-492b-b2a9-0fe821c05f83.png)



<br>

#### **Some additional reading:**
<details>
 <summary><strong>Foreword about automated testing in GMod</strong></summary>
<br>
Automated testing is a crucial part of any software workflow.
Your automated tests define a contract that give you and your would-be users confidence that the project will behave properly.


Without tests, you may find yourself spending large amounts of time debugging obscure issues.
Automated tests require more work up front, but will save you time and frustration in the future as your project grows.

---

Traditionally, Garry's Mod developers have included, at most, a few crucial tests with their codebase - usually only ran manually when the maintainer remembers.
Modern testing infrastructure allow you to run your tests on a Pull Request, before the code has made it into the main branch.


Such a tool has never existed for Garry's Mod. Until now!
</details>

<details>
 <summary><strong>Technical info</strong></summary>
<br>
GLuaTest was made to run on GitHub Actions, but it's flexible enough to fit anywhere you'd like.

You can use the GLuaTest Docker image to spin up a test server, run your tests, and see the output - all without having to install a server of your own.

This makes it easy to test your code in a real Garry's Mod environment without worrying about other addons or config values.
</details>

<br>

# Usage

GLuaTest can be used in a number of ways. Whether you want to run your tests when you open a PR, or if you just want to have it run on your development server - we've got you covered.

<br>

## Automated testing on Pull Requests

<details>
<summary><strong>Run your tests in a Pull Request</strong></summary>
<br>

To set up automated test runs, we'll use GitHub Workflows.

It's actually really simple to set up the workflow. Add the following file to your project:
```yml
name: GLuaTest Runner

on:
  pull_request:

jobs:
  run-tests:
    uses: CFC-Servers/GLuaTest/.github/workflows/run_tests.yml@main
```

And that's it! The next time you make a PR, it'll spin up a new test server, run your project's test, and report any failures in your PR.

There are a couple of config options you can use though.

---

### Requirements
<details>
 <summary><strong>If your project depends on an external project, GLuaTest can automatically grab them for you</strong></summary>
<br>

Let's say you needed:
 - ULX
 - ULib
 - The Lua branch CFC's Logging Library ( https://github.com/CFC-Servers/gm_logger )


Make a new file somewhere in your project (i.e. `lua/tests/my_project/requirements.txt`) with the following:
```
TeamUlysses/ulx
TeamUlysses/ulib
CFC-Servers/gm_logger@lua
```

Each line should be in the format of: **`<Github owner name>/<Project name>`**.

You can use a specific branch of the project by adding **`@<branch-name>`** to the end of the line.

(**If your requirement is hosted in a private GitHub repo**, you'll need to do some annoying legwork to get everything connected. [More info here.](https://github.com/CFC-Servers/GLuaTest/wiki/Working-with-private-dependencies))


Great, now we update our workflow to use our requirements file
```yml
name: GLuaTest Runner

on:
  pull_request:

jobs:
  run-tests:
    uses: CFC-Servers/GLuaTest/.github/workflows/run_tests.yml@main
    with:
      requirements: lua/tests/my_project/requirements.txt
```

All done! Commit those changes and GLuaTest will automatically clone your requirements.

</summary>
</details>

---

### Server Configs
<details>
 <summary><strong>Sometimes your project requires specific convars / server settings</strong></summary>
<br>

Similar to how you define requirements, we'll make a new `.cfg` file.


This file will be dumped straight into the end of server's `server.cfg` file. You can override existing configs, too.


So, create the file:
```
# Example file name/location: lua/tests/my_project/server.cfg
my_convar 1
name "My favorite server"
```

Update the workflow:
```yml
name: GLuaTest Runner

on:
  pull_request:

jobs:
  run-tests:
    uses: CFC-Servers/GLuaTest/.github/workflows/run_tests.yml@main
    with:
      server-cfg: lua/tests/my_project/server.cfg
```

And that's it!

</summary>
</details>

<br>

### Gamemodes and Maps
<details>
 <summary><strong>You can customize which gamemode and map the server starts with</strong></summary>
<br>

Simply specify the desired gamemode and/or map in your workflow's `with` section.

```yml
name: GLuaTest Runner

on:
  pull_request:

jobs:
  run-tests:
    uses: CFC-Servers/GLuaTest/.github/workflows/run_tests.yml@main
    with:
      gamemode: darkrp
      map: rp_downtown_tits_v2
```

</summary>
</details>

<br>

### Workshop Collection
<details>
 <summary><strong>To make dependency management easier, you can tell the test server to use a specific workshop collection.</strong></summary>
<br>


Add the collection ID in your workflow's `with` section.

```yml
name: GLuaTest Runner

on:
  pull_request:

jobs:
  run-tests:
    uses: CFC-Servers/GLuaTest/.github/workflows/run_tests.yml@main
    with:
      collection: 1629732176
```

</summary>
</details>

<br>

### GMod Branch
<details>
 <summary><strong>You can run your tests on any of the GMod branches</strong></summary>
<br>


Just set the `branch` input in your workflow:

```yml
name: GLuaTest Runner

on:
  pull_request:

jobs:
  run-tests:
    uses: CFC-Servers/GLuaTest/.github/workflows/run_tests.yml@main
    with:
      branch: x86-64
```

Acceptable options are:
- `live` (Main GMod version - this is the default)
- `x86-64`
- `prerelease`
- `dev`

</summary>
</details>

### Extra Startup Arguments
<details>
 <summary><strong>You can give GLuaTest custom startup args to fine-tune your test setup</strong></summary>
<br>


You can use the `extra-startup-args` input to pass any arguments you want to the srcds instance. For example:

```yml
name: GLuaTest Runner

on:
  pull_request:

jobs:
  run-tests:
    uses: CFC-Servers/GLuaTest/.github/workflows/run_tests.yml@main
    with:
      extra-startup-args: "-tickrate 16 -usegh"
```

**Note:** These args are passed in before the base params, so you can override any of the base srcds arguments.

</summary>
</details>

<br>

### All options
<details>
 <summary><strong>Here are all of the options you can pass to the workflow</strong></summary>
<br>

| **Name**                 | **Description**                                                                                                            | **Example**                                                                                     |
|----------------------|------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------|
| `server-cfg`         | A path (relative to project directory) with extra server config options                                                | `data_static/my_addon.cfg`                                                                              |
| `requirements`       | A path (relative to project directory) with a list of all requirements to test this project                            | `data_static/my_addon.txt`                                                                              |
| `gamemode`           | The name of the gamemode for the test server to run                                                                    | `darkrp`                                                                                                |
| `map`                | The direct name of the map you want the server to startup with                                                         | `gm_bigcity_improved_lite`                                                                              |
| `collection`         | The workshop ID of the collection for the test server to use                                                           | `1629732176`                                                                                            |
| `extra-startup-args` | Additional startup arguments to add to the srcds startup                                                               | `-tickrate 16 -usegh`                                                                                   |
| `ssh-private-key`    | The Private SSH key to use when cloning the dependencies                                                               | `-----BEGIN OPENSSH PRIVATE KEY-----\n...`                                                              |
| `github-token`       | A GitHub Personal Access Token, used when cloning dependencies                                                         |                                                                                                         |
| `timeout`            | How many minutes to let the job run before killing the server                                                          | `10`                                                                                                    |
| `branch`             | Which GMod branch to run your tests on                                                                                 | `live`|`prerelease`|`dev`|`x86-64`                                                                      |
| `gluatest-ref`       | Which tag/branch of GLuaTest to run                                                                                    | `main`|`feature/new-feature-branch`                                                                     |
| `custom-overrides`   | An absolute path with custom files to copy to the server directly. Structure should match the contents of `garrysmod/` | `$GITHUB_WORKSPACE/my_overrides`                                                                        |
| `download-artifact`  | A URL path to a .tar.gz file that will be unpacked in the root directory                                               | `https://github.com/RaphaelIT7/gmod-holylib/releases/download/Release0.7/gmsv_holylib_linux_packed.zip` |
| `additional-setup`   | If specificed, executes the given string as a script after all setup is complete, allowing additional setup            | `echo "Hello, this is a test!"`                                                                         |

</summary>
</details>


### Speed 🏃
Running tests in a GitHub Runner is surprisingly fast.

Even with hundreds of tests, you can expect the entire check to take **under 30 seconds!**

In fact, the test suite itself will often complete in only a couple of seconds. Most of the time is spent downloading the image and setting up the runner.

_(Failing async tests will slow down the time significantly because it has to wait for the timeouts)_



### Cost 💸
You should incur no costs by using GitHub Actions.

Nothing better than free 😎

</details>



## Running locally
<details>
<summary><strong>Running your tests locally</strong></summary>
<br>

It's actually extremely simple to run GLuaTest locally.

Just put GLuaTest into your `addons/` directory and restart!


All of your tests will run when the server starts up and you can view the output in the server console/logs.
</details>


## Running locally without a server
<details>
<summary><strong>Running your tests locally without a server</strong></summary>
<br>

Sounds weird, right? Well it's really not all that different from running GLuaTest on GitHub.

In fact, many of the steps are the same.


### Requirements / Server Configs
If your project depends on other projects, you can have GLuaTest automatically acquire them for you.

Take a quick skim through the [GitHub Action setup instructions](#automated-testing-on-pull-requests) for the relevant sections on how to set this up.


### Environment setup
When running GLuaTest without a server, you need to tell it where to find your project and custom files.

You can do that with simple environment variables, i.e.:
```sh
export REQUIREMENTS=/absolute/path/to/requirements.txt
export CUSTOM_SERVER_CONFIG=/absolute/path/to/server.cfg
export PROJECT_DIR=/home/me/Code/my_project
export GAMEMODE="sandbox"
export COLLECTION_ID="12345"
export SSH_PRIVATE_KEY="the-entire-private-key"
export GITHUB_TOKEN="a-personal-access-token"
```

 - You can skip the `REQUIREMENTS` and `CUSTOM_SERVER_CONFIG` if you don't need them, but you must set the `PROJECT_DIR` variable.

 - The `GAMEMODE` variable defaults to `"sandbox"`, so you can omit it if that's appropriate for your tests.

 - The `COLLECTION_ID` variable allows you to pass a workshop collection ID for the server to grab before starting.

 - The `SSH_PRIVATE_KEY` variable is used when one or more of your Requirements are hosted on a Private Repository.

 - The `GITHUB_TOKEN` variable, like the `SSH_PRIVATE_KEY` is also used to grant access to private repositories. Personal Access Tokens are a simpler (but ultimately worse) alternative to a full SSH keypair.


_(Read more about privately-hosted project requirements: https://github.com/CFC-Servers/GLuaTest/wiki/Private-Requirements )_


### Running in Docker
Now you'll need docker-compose. I'll leave it to you to figure out how to install it: https://docs.docker.com/compose/install/

Once that's done, you just need to run the `docker-compose` file in the `docker/` directory.


On Linux/OSX, this looks like:
```
docker-compose up
```


And.. that's it! It'll pull the latest Runner, start the server, and run your tests.
You can even follow the test output live.

</details>


<br>

# Writing Tests ✍️

## Your first test file
In your GLua project, create a new directory: `lua/tests/<your project name>/`.

This is where you'll keep the tests for your project.
You can put all of your tests in one file, or split the files up based on module/responsibility.


For example, if your addon had two entities you'd like to test, you could make `lua/tests/your_project/entity_1.lua` and `lua/tests/your_project/entity_2.lua`.
We suggest you group your tests, but it'll work either way.

The test file itself is fairly simple. It has a few keys you can use, but the only requirement is the `cases` key; a table of Test Cases.


For example:
```lua
-- lua/tests/my_clock/get_time.lua

return {
    cases = {
        {
            name = "It should return the correct time",
            func = function()
                local myClock = Clock.New()
                local realTime = os.time()

                expect( myClock:GetTime() ).to.equal( realTime )
            end
        }
    }
}
```


<br>


### The Test Group
The Test Group (that is, the table you return from your Test File) can have the following keys:
| Key              |    Type    | Description                                                                         | Required |
|------------------|:----------:|-------------------------------------------------------------------------------------|:--------:|
| **`cases`**      |   `table`  | A table of [Test Cases](#the-test-case)                                             |     ✔️    |
| **`groupName`**  |  `string`  | The name of the module/function this Test Group is testing                          |     ❌    |
| **`beforeAll`**  | `function` | A function to run once before running your Test Group                               |     ❌    |
| **`beforeEach`** | `function` | A function to run before each Test Case in your Test Group. Takes a `state` table   |     ❌    |
| **`afterAll`**   | `function` | A function to run after all Test Cases in your Test Group                           |     ❌    |
| **`afterEach`**  | `function` | A function to run after each Test Case in your Test Group. Takes a `state` table    |     ❌    |


<br>


### The Test Case
Each Test Case is a table with the following keys:

| Key              | Type              | Description                                                                    | Required | Default |
|------------------|:-----------------:|--------------------------------------------------------------------------------|:--------:|:-------:|
| **`name`**       | `string`          | Name of the Test Case (for reference later)                                    |  ✔️       |         |
| **`func`**       | `function`        | The actual test function. Takes a `state` table                                |  ✔️       |         |
| **`async`**      | `bool`            | If your test relies on timers, hooks, or callbacks, it must run asynchronously |  ❌      | `false` |
| **`coroutine`**  | `bool`            | This allows your test to use coroutines to control its execution               |  ❌      | `false` |
| **`timeout`**    | `int`             | How long to wait for your async test before marking it as having timed out     |  ❌      | 5       |
| **`cleanup`**    | `function`        | The function to run after running your test. Takes a `state` table             |  ❌      |         |
| **`when`**       | `bool / function` | Only run this test case "when" this field is _(or evaluates to)_ `true`          |  ❌      |         |
| **`skip`**       | `bool / function` | Skip this test case if this field is _(or evaluates to)_ `true`                  |  ❌      |         |

<br>

### The `expect` function
The heart of a test is the _expectation_. You did a thing, and now you expect a result.

In each test function, you have access to the `expect` function.

Let's say you expect `"a"` to equal `"b"`. In regular Lua you might do:
```lua
assert( "a" == "b" )
```

Similarly, in GLuaTest, you'd do:
```lua
expect( "a" ).to.equal( "b" )
```

<br>

There are a number of different expectations you can use.

#### Expectations
| Expectation          | Description                                               | Example                                                         |
|----------------------|-----------------------------------------------------------|-----------------------------------------------------------------|
| **`equal`**/**`eq`** | Basic `==` equality check                                     | `expect( a ).to.equal( b )`                                     |
| **`aboutEqual`**     | Basic `==` equality check, with a tolerance                   | `expect( 0.999 ).to.aboutEqual( 1 )`                            |
| **`deepEqual`**      | Expects that two tables are deeply equal                      | `expect( {{ Entity(1) }} ).to.deepEqual( {{ Entity(1) }} )`     |
| **`beLessThan`**     | Basic `<` comparison                                          | `expect( 5 ).to.beLessThan( 6 )`                                |
| **`beGreaterThan`**  | Basic `>` comparison                                          | `expect( 10 ).to.beGreaterThan( 1 )`                            |
| **`beBetween`**      | Expects the subject to be less than min, and greater than max | `expect( 5 ).to.beBetween( 3, 7 )`                              |
| **`beTrue`**         | Expects the subject to literally be `true`                    | `expect( Entity( 1 ):IsPlayer() ).to.beTrue()`                  |
| **`beFalse`**        | Expects the subject to literally be `false`                   | `expect( istable( "test" ) ).to.beFalse()`                      |
| **`beValid`**        | Expects `IsValid( value )` to return `true`                   | `expect( ply ).to.beValid()`                                    |
| **`beInvalid`**      | Expects `IsValid( value )` to return `false`                  | `expect( nil ).to.beInvalid()`                                  |
| **`beNil`**          | Expects the subject to literally be `nil`                     | `expect( player.GetAll()[2] ).to.beNil()`                       |
| **`beNaN`**          | Expects the subject to be NaN                                 | `expect( 0 / 0 ).to.beNaN()`                                    |
| **`exist`**          | Expects the subject to not be `nil`                           | `expect( MyProject ).to.exist()`                                |
| **`beA`**/**`beAn`** | Expects the subject to have the given `type`                  | `expect( "test" ).to.beA( "string" )`                           |
| **`succeed`**        | Expects the subject function to run without error             | `expect( func, param ).to.succeed()`                            |
| **`err`**            | Expects the subject function to throw an error                | `expect( error ).to.err()`                                      |
| **`errWith`**        | Expects the subject function to throw the given error         | `expect( badFunc, param ).to.errWith( "error message" )`        |
| **`called`**         | Expects the subject Stub have been called                     | `expect( myStub ).was.called()`                                 |

<br>

#### Expectation Negation
You can invert an Expectation by using `.toNot` or `.notTo` in place of your `.to`

i.e.:
```lua
expect( ply ).toNot.beInvalid()
expect( "test" ).notTo.beA( "table" )
```

#### Was
You may replace `.to` with `.was` in any expectation.
`.wasNot` is also valid.

Primarily this is syntax sugar for the `called` expectation. Technically these two calls are equivalent:
```lua
expect( func ).to.called()
expect( func ).was.called()
```

#### `when` and `skip`
These fields can be used to control your test invocation.

For example, to run your test case only on the `x86-64` branch:
```lua
{
    name = "Is valid on x86-64",
    when = BRANCH == "x86-64",
    func = function()
        -- x86-64 specific stuff here
    end
}
```

Skipping is also handy if you want to disable a test but keep the code:
```lua
{
    name = "Broken test (but I'll definitely fix it some day 100%),
    skip = true,
    func = function() error() end
}
```

**Note:** `skip` takes precedence over `when`

<br>

#### The `coroutine` option
<details>
 <summary><strong>Sometimes you need your test to wait indefinitely for unpredictable circumstances that don't have callbacks</strong></summary>

 In these situations, you can use the `coroutine` option to run your test in a coroutine.

 For example, if you're testing with Nextbots, you'll find it frustrating to wait for them to disconnect before your next test runs.

```lua
-- lua/gluatest/extensions/my_nextbot_extensions.lua

--- Halts the coroutine until the server is empty
WaitForEmptyServer = function()
    local co = coroutine.running()
    local identifier = getWaitIdentifier()

    hook.Add( "Think", identifier, function()
        local count = player.GetCount()
        if count > 0 then return end

        hook.Remove( "Think", identifier )
        coroutine.resume( co )
    end )

    return coroutine.yield()
end
```

```lua
-- lua/tests/my_nextbot/my_nextbot.lua

return {
    groupName = "My Nextbot tests",

    -- Automatically kick all bots after each test
    afterEach = function()
        for _, bot in ipairs( player.GetBots() ) do
            game.KickID( bot:UserID() )
        end
    end,

    cases = {
        {
            name = "Should be able to spawn a nextbot",
            async = true,
            timeout = 2,
            coroutine = true,
            func = function()
                WaitForEmptyServer() -- We need to be sure the server is empty before we do our tests, otherwise it could fail due to timing

                local myBot = player.CreateNextBot( "Silly little guy" )
                expect( player.GetCount() ).to.equal( 1 )
                expect( player.GetAll()[1] ).to.equal( myBot )

                done()
            end
        }
    }
}
```

</details>

<br>

### The `stub` function
<details>
 <summary><strong>Isolating your tests is important. Stubs are a powerful way of controlling which parts of your code your tests invoke.</strong></summary>

Let's say your addon looks like this:
```lua
MyProject = {}

function MyProject.UserExistsInDatabase( user )
    local userObject = lookupUserInDatabase( user )
    return userObject.exists
end

function MyProject.CheckUser( user )
    if not MyProject.UserExistsInDatabase( user ) then return end
    if not user.name then return end
    if #user.name == 0 then return end

    return true
end
```

You want to test the functionality of `CheckUser`.

There are three checks in `CheckUser`:
 - The user exists in the database
 - The user's name exists
 - The user's name is not empty

You could add a fake user to the database and use the function normally, but you're not testing the _database_, you're testing `CheckUser`.

Instead, we could _pretend_ that `UserExistsInDatabase` returns `true` for our tests. We can do this using a Stub.

```lua
-- lua/tests/my_project/checkuser.lua

return {
    groupName = "CheckUser",
    beforeEach = function( state )
        state.validUser = { name = "Valid User" }
    end,

    cases = {
        {
            name = "Should return true with a valid User",
            func = function( state )
                stub( MyProject, "UserExistsInDatabase" ).returns( true )

                expect( MyProject.CheckUser, state.validUser ).to.beTrue()
            end
        },
        {
            name = "Should check if user exists in database",
            func = function()
                local dbCheck = stub( MyProject, "UserExistsInDatabase" ).returns( true )

                MyProject.CheckUser( state.validUser )

                expect( dbCheck ).to.haveBeenCalled()
            end
        }
    }
}
```

Now our `CheckUser` test _only_ tests the functionality in `CheckUser`, and doesn't depend on any other function's correctness.

A Stub will replace the given function on the given table with a callable Stub object. The Stub keeps track of how many times it was called, and what parameters it was called with.

#### Stub Restoration
If you need to restore the original functionality of the stubbed function, you can use `stub:Restore()`.

Un-restored stubs are automatically restored after each Test Case, but you can manually call `:Restore()` any time you need.

#### **Empty Stubs**
You can create an empty Stub that doesn't automatically replace anything by calling `stub()` with no arguments.

You can use the Stub like normal. This is particularly useful for functions that take callbacks, i.e.:
```lua
{
    name = "RunCallback should run the given callback",
    func = function()
        local myStub = stub()

        MyProject.RunCallback( myStub )

        expect( myStub ).to.haveBeenCalled()
    end
}
```

Restoring empty stubs is a no-op, but won't break anything.

#### **Stub return values**
You can tell your stubs what to return when they're called.

**`.with( function )`**

If you want to replace a function with another function, you can use the `.with` modifier.

When your stub is called, it will pass all of the parameters it received to the function you gave to `.with`, and will return whatever your given function returns.

**`.returns( ... )`**

If you just want to return a certain value every time your Stub is called, you can use the `.returns` modifier.

When your Stub is called, it will simply return everything you passed into `.returns`.

**`.returnsSequence( table sequence, any default )`**

If you need to specify a sequence of values that your stub will return as it's called, `.returnsSequence` is the right choice.

Every time your stub is called, it will return the next value in the sequence table.
One cool trick is to include gaps in your sequence table. So, for example, if you wanted to return `""` for every call except the 6th one, you could do:
```lua
stub( net, "ReadString" ).returnsSequence( { [6] = "hello" }, "" )
```

This would make `net.ReadString` return `""` for the first 5 calls, `"hello"` for the 6th, and `""` for every call after.

**Note**: Because lua discards all indices with `nil` values, using the `default` parameter will override any intentional `nil`s in your sequence table.

</details>


<br>

### Async tests and the `done`/`fail` functions
<details>
 <summary><strong>If your test relies on timers, hooks, callbacks, etc., then you need to run your test Asynchronously.</strong></summary>

The test is otherwise completely normal, but it's your job to tell GLuaTest when the test is done by calling `done()` or `fail()` anywhere in your test.


#### `done()` and timeout functionality
If your test fails for some reason before it can call `done()`, it'll be marked as having failed after timing out.

If you know the maximum amount of time your test will take, you can include the `timeout` key on the test with the number of seconds to wait until failing the test.

If you don't include a `timeout` on your Test Case, you'll have to wait for the default 60-second timer before the test can complete. So if speed is important to you, consider setting a conservative `timeout` value for your async tests.


For example, say we were trying to test this code:
```lua
-- lua/my_project/main.lua

MyProject = { didRun = false }

function MyProject:StartRun()
    timer.Simple( 2, function()
        MyProject.didRun = true
    end )
end
```

We want to make sure that when `MyProject:StartRun()` is called, that it changes `MyProject.didRun` two seconds later.

Our test might look like:
```lua
-- lua/tests/my_project/start_run.lua

return {
    groupName = "StartRun",
    cases = {
        {
            name = "Runs within two seconds of being called",
            async = true,
            timeout = 3, -- If it hasn't finished in 3 seconds, something went wrong and it can be marked as failed
            func = function()
                MyProject:StartRun()

                timer.Simple( 2, function()
                    expect( MyProject.didRun ).to.beTrue()
                    done()
                end )
            end
        }
    }
}
```

#### The `fail()` function
In the event that you want to fail a test manually, you can call `fail( "with a reason if you want to" )` anywhere in your test case.

This is useful if you have a callback/timer/etc that _should never run_, and indeed, fail your test if it does.

Here's an example:
```lua
-- lua/tests/my_project/async_failure.lua

return {
    groupName = "Async Failure Examples",
    cases = {
        {
            name = "HTTP Request succeeds",
            async = true,
            timeout = 5,
            func = function()
                local success = function( body )
                    -- Expect exactly 1024 bytes in the body (for example)
                    expect( #body ).to.equal( 1024 )
                    done()
                end

                local failure = function( reason )
                    -- This shouldn't ever happen! If it does, we need to fail the test instead of letting it time out.
                    fail( "HTTP Request failed with reason: " .. reason )

                    -- We don't need to call done() here because we already called fail() :)
                end

                http.Fetch( "my url", success, failure )
            end
        }
    }
}
```
</details>

<br>

### Before / After functions
You may find yourself writing a lot of repetitive setup/teardown code in each of your Test Cases.

<details>
 <summary><strong>GLuaTest has a few convenience functions for you to use.</strong></summary>

<br>

#### **`beforeEach`/`afterEach`**

Here's an example of how `beforeEach` and `afterEach` could make your life easier while working with entities:

```lua
-- lua/tests/my_project/tickle_monster.lua

return {
    groupName = "Tickle Monster",

    beforeEach = function( state )
        state.ent = ents.Create( "sent_ticklemonster" )
        state.ent:Spawn()
    end,

    afterEach = function( state )
        if IsValid( state.ent ) then
            state.ent:Remove()
        end
    end,

    cases = {
        {
            name = "Should accept the Tickle function",
            func = function( state )
                expect( state.ent.Tickle ).to.exist()
                expect( function() state.ent:Tickle() end ).to.succeed()
                expect( state.ent.wasTickled ).to.beTrue()
            end
        },
        {
            name = "Should not be tickled by default",
            func = function( state )
                expect( state.ent.wasTickled ).to.beFalse()
            end
        },
        {
            name = "Should have the correct model",
            func = function( state )
                expect( state.ent:GetModel() ).to.equal( "materials/ticklemonster/default.mdl" )
            end
        }
    }
}
```

The `beforeEach` function created a brand-new Tickle Monster before every test, and the `afterEach` function deleted it, ensuring a clean test environment for each Test Case.

You'll notice the `state` variable in that example. The `state` parameter is just a table that's shared between the before/after funcs and the Test Case function.


You also have access to `beforeAll` and `afterAll`, which are self-explanatory. Please note that these two functions **do not** take a `state` table.

<br>

---

#### **`cleanup`**

The `cleanup` function is a lot like `afterEach`, except it's used only for a specific Test Case.

One common way to use this is to make sure that your test cleans up after itself even if it errors.


<br>

For example, say I want to test my `WrapperFunc` in this file:
```lua
-- lua/my_project/wrapper.lua

GlobalFunc = function()
    return "Test"
end

WrapperFunc = function()
    return GlobalFunc()
end
```

I might write something like this:
```lua
{
    name = "Wrapper should call the original function",
    func = function()
        local ogGlobalFunc = GlobalFunc
        local wasCalled = false

        GlobalFunc = function()
            wasCalled = true
        end

        WrapperFunc()

        expect( wasCalled ).to.beTrue()

        GlobalFunc = ogGlobalFunc
    end
}
```


But consider, what would happen if `WrapperFunc` errored, or the expectation failed?

`GlobalFunc` would still be defined as our local function for all future tests, potentially causing them to fail.

Instead, we can use GLuaTest's `cleanup` function to make our test safer:
```lua
-- lua/tests/my_project/wrapper.lua

return {
    groupName = "Wrapper Functions",
    cases = {
        {
            name = "Wrapper should call the original function",

            func = function( state )
                state.GlobalFunc = GlobalFunc
                local wasCalled = false

                GlobalFunc = function()
                    wasCalled = true
                end

                WrapperFunc()

                expect( wasCalled ).to.beTrue()
            end,

            cleanup = function( state )
                GlobalFunc = state.GlobalFunc
            end
        }
    }

}
```
</details>

### Extensions
<details>
 <summary><strong>Extensions allow you to make your own test utilities or GLuaTest extensions</strong></summary>

 If you have a function or tool that you'd like to use in your tests, you can add it to the `gluatest/extensions/` directory.

 For example, if you were going to be testing a lot of entities in the same way, you could save yourself some headache by making an extension like this:
```lua
-- lua/gluatest/extensions/with_entity.lua

--- Returns a GLuaTest TestGroup that is set up for Entity Testing
--- @param classname string The class name of the entity to spawn
--- @param testGroup GLuaTest_TestGroup
WithEntityTests = function( classname, testGroup )
    testGroup.beforeEach = function( state )
        state.ents = {}

        function state.SpawnEnt()
            local ent = ents.Create( classname )
            ent:Spawn()

            table.insert( state.ents, ent )
            return ent
        end

        function state.RemoveEnt( ent )
            table.RemoveByValue( state.ents, ent )

            if IsValid( ent ) then
                ent:Remove()
            end
        end
    end

    testGroup.afterEach = function( state )
        for _, ent in ipairs( state.ents ) do
            if IsValid( ent ) then
                ent:Remove()
            end
        end
    end
end
```

And then you can set up your test like this:
```lua
-- lua/tests/my_project/entity_1.lua

return WithEntityTests( "my_special_entity", {
    groupName = "My Special Entity Tests",

    -- No need to include any special setup/cleanup logic here as it's already handled by WithEntityTests

    cases = {
        {
            name = "Spawns with default values",
            func = function( state )
                local ent = state.SpawnEnt()

                expect( ent:GetModel() ).to.equal( "models/my_special_entity.mdl" )
                expect( ent:GetColor() ).to.equal( Color( 255, 255, 255 ) )
            end
        }
    }
} )
```
</details>

<br>

---

<br>

# Now what?

At this point, you might be excited to try GLuaTest. Maybe you already have a test file set up!

But... now what?

Check out this wiki page addressing that very question:

https://github.com/CFC-Servers/GLuaTest/wiki/I-set-up-GLuaTest...-now-what

<br>

# Developers 👨‍💻
<details>
 <summary>Information about working with GLuaTest</summary>

 ### Interested in making an extension for GLuaTest?
 Check out the wiki article outlining the hooks you can use: https://github.com/CFC-Servers/GLuaTest/wiki/Developers
 </summary>
</details>
