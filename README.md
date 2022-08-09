# GLuaTest

🎉 **The missing test framework for GMod** 🎉

**GLuaTest is a testing framework built for Garry's Mod.**
**Its job is to make writing automated tests for Garry's Mod projects easy and tolerable.**

**It offers an approachable (albeit strange) syntax that makes writing tests intuitive.**

GLuaTest takes a lot of inspiration from both Ruby's [RSpec](https://rspec.info/) and Javascript's [Jest](https://jestjs.io/)

**Glossary**
 - [Additional reading](#some-additional-reading)
 - [Usage](#usage)
 - [Writing Tests](#writing-tests-%EF%B8%8F)
 - [Troubleshooting](#troubleshooting-)
 - [Developers](#developers-)
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

To set up automated test runs, we'll use Github Workflows.

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

---

### Gamemodes
<details>
 <summary><strong>If you're testing a non-sandbox project, you need to tell the test server which gamemode to run</strong></summary>
<br>

Simply specify the desired gamemode in your workflow's `with` section.

```yml
name: GLuaTest Runner

on:
  pull_request:

jobs:
  run-tests:
    uses: CFC-Servers/GLuaTest/.github/workflows/run_tests.yml@main
    with:
      gamemode: darkrp
```

</summary>
</details>

---

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

---


### Speed 🏃
Running tests in a GitHub Runner is surprisingly fast.

Even with hundreds of tests, you can expect the entire check to take **under 30 seconds!**

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

Just put GLuaTest into your `addons/` directory, set `gluatest_enable 1` on the server, and restart!


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
| **`cases`**      |   `table`  | A table of Test Cases                                                               |     ✔️    |
| **`groupName`**  |  `string`  | The name of the module/function this Test Group is testing                          |     ❌    |
| **`beforeAll`**  | `function` | A function to run once before running your Test Group                               |     ❌    |
| **`beforeEach`** | `function` | A function to run before each Test Case in your Test Group. Takes a `state` table   |     ❌    |
| **`afterAll`**   | `function` | A function to run after all Test Cases in your Test Group                           |     ❌    |
| **`afterEach`**  | `function` | A function to run after each Test Case in your Test Group. Takes a `state` table    |     ❌    |


<br>


### The Test Case
Each Test Case is a table with the following keys:

| Key              | Type       | Description                                                                    | Required | Default |
|------------------|:----------:|--------------------------------------------------------------------------------|:--------:|:-------:|
| **`name`**       | `string`   | Name of the Test Case (for reference later)                                    |  ✔️     |         |
| **`func`**       | `function` | The actual test function. Takes a `state` table                                |  ✔️     |         |
| **`async`**      | `bool`     | If your test relies on timers, hooks, or callbacks, it must run asynchronously |  ❌     | `false` |
| **`timeout`**    | `int`      | How long to wait for your async test before marking it as having timed out     |  ❌     | 60      |
| **`cleanup`**    | `function` | The function to run after running your test. Takes a `state` table             |  ❌     |         |

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

Kinda cool, right?

<br>

There are a number of different expectations you can use.

#### Expectations
| Expectation          | Description                                           | Example                                                         |
|----------------------|-------------------------------------------------------|-----------------------------------------------------------------|
| **`equal`**/**`eq`** | Basic `==` equality check                             | `expect( a ).to.equal( b )`                                     |
| **`beLessThan`**     | Basic `<` comparison                                  | `expect( 5 ).to.beLessThan( 6 )`                                |
| **`beGreaterThan`**  | Basic `>` comparison                                  | `expect( 10 ).to.beGreaterThan( 1 )`                            |
| **`beTrue`**         | Expects the subject to literally be `true`            | `expect( Entity( 1 ):IsPlayer() ).to.beTrue()`                  |
| **`beFalse`**        | Expects the subject to literally be `false`           | `expect( istable( "test" ) ).to.beFalse()`                      |
| **`beValid`**        | Expects `IsValid( value )` to return `true`           | `expect( ply ).to.beValid()`                                    |
| **`beInvalid`**      | Expects `IsValid( value )` to return `false`          | `expect( nil ).to.beInvalid()`                                   |
| **`beNil`**          | Expects the subject to literally be `nil`             | `expect( player.GetAll()[2] ).to.beNil()`                       |
| **`exist`**          | Expects the subject to not be `nil`                   | `expect( MyProject ).to.exist()`                                |
| **`beA`**/**`beAn`** | Expects the subject to have the given `type`          | `expect( "test" ).to.beA( "string" )`                           |
| **`succeed`**        | Expects the subject function to run without error     | `expect( func, param ).to.succeed()`                            |
| **`err`**            | Expects the subject function to throw an error        | `expect( error ).to.err()`                                      |
| **`errWith`**        | Expects the subject function to throw the given error | `expect( badFunc, param ).to.errWith( "error message" )`        |
| **`haveBeenCalled`** | Expects the subject Stub have been called             | `expect( myStub ).to.haveBeenCalled()`                          |

<br>

#### Expecation Negation
You can invert an Expectation by using `.toNot` or `.notTo` in place of your `.to`

i.e.:
```lua
expect( ply ).toNot.beInvalid()
expect( "test" ).notTo.beA( "table" )
```

<br>

### The `stub` function
<details>
 <summary><strong>Isolating your tests is important. Stubs are a powerful way of controling which parts of your code your tests invoke.</strong></summary>

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
 - The user's name is not emtpy

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

</details>


<br>

### Async tests and the `done` function
<details>
 <summary><strong>If your test relies on timers, hooks, callbacks, etc., then you need to run your test Asynchronously.</strong></summary>

The test is otherwise completely normal, but it's your job to tell GLuaTest when the test is done by calling `done()` anywhere in your test.


If your test fails for some reason before it can call `done()`, it'll be marked as having failed after timing out.

If you know the maximum amount of time your test will take, you can include the `timeout` key on the test with the number of seconds to wait until failing the test.

If you don't include a `timeout` on your Test Case, you'll have to wait for the defaut 60-second timer before the test can complete. So if speed is important to you, consider setting a conservative `timeout` value for your async tests.


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
            name = "Should run within two seconds of being called",
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

---

<br>

# Now what?

At this point, you might be excited to try GLuaTest. Maybe you already have a test file set up!

But... now what?

Check out this wiki page addressing that very question:

https://github.com/CFC-Servers/GLuaTest/wiki/I-set-up-GLuaTest...-now-what

<br>

# Troubleshooting 🤔
<details>
 <summary>Solutions to common problems</summary>

 ### Does your test output look completely unreadable?
 ![image](https://user-images.githubusercontent.com/7936439/170231750-e59f880f-138a-485d-be47-8b81f60c9cad.png)

 **Try setting the `gluatest_use_ansi` convar to `0`**
</details>

# Developers 👨‍💻
<details>
 <summary>Information about working with GLuaTest</summary>
 
 ### Interested in making an extension for GLuaTest?
 Check out the wiki article outlining the hooks you can use: https://github.com/CFC-Servers/GLuaTest/wiki/Developers
 </summary>
</details>
