# GLuaTest

🎉 **The missing test framework for GMod** 🎉

**Glossary**
 - [Additional reading](#some-additional-reading)
 - [Usage](#usage)
 - [Writing Tests](#writing-tests-%EF%B8%8F)
 - [Troubleshooting]
---

GLuaTest is a testing framework built for Garry's Mod.
Its job is to make writing tests for Garry's Mod projects easy.


It offers an approachable (albeit strange) syntax that makes writing tests intuitive.


### It also has some pretty rad test output:

#### **In the terminal:**
![image](https://user-images.githubusercontent.com/7936439/169948915-c75e07a3-563a-43ee-825c-12ee76149b05.png)


<br>

#### **In GCompute:**
![image](https://user-images.githubusercontent.com/7936439/169943331-fd280fe0-57e9-4f38-993e-b99763e3b86e.png)


<br>

#### **In a Pull Request:**
![image](https://user-images.githubusercontent.com/7936439/169943290-e531d722-cc36-4191-b882-2cb74f820f20.png)



<br>

_**Are you an impatient software developer? Check out the [quickstart](https://github.com/CFC-Servers/GLuaTest/blob/main/QUICKSTART.md) guide to go fast**_

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

_Just looking for a taste of what GLuaTest has to offer? Check out the [Writing tests](#writing-tests-%EF%B8%8F) section._

_Interested in giving it a shot on your own project? Take a look at the [Usage](#usage) section to find out how to get started._

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
If your project depends on an external project, GLuaTest can automatically grab them for you.

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

---

### Server Configs
**Sometimes your project requires specific convars to be set.**

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
```

You can skip the `REQUIREMENTS` and `CUSTOM_SERVER_CONFIG` if you don't need them, but you must set the `PROJECT_DIR` variable.


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
| **`setup`**      | `function` | The function to run before running your test. Takes a `state` table            |  ❌     |         |
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
| **`equal`**/**`eq`**     | Basic `==` equality check                             | `expect( a ).to.equal( b )`                                 |
| **`beLessThan`**     | Basic `<` comparison                                  | `expect( 5 ).to.beLessThan( 6 )`                                |
| **`beGreaterThan`**  | Basic `>` comparison                                  | `expect( 10 ).to.beGreaterThan( 1 )`                            |
| **`beTrue`**         | Expects the subject to literally be `true`            | `expect( Entity( 1 ):IsPlayer() ).to.beTrue()`                  |
| **`beFalse`**        | Expects the subject to literally be `false`           | `expect( istable( "test" ) ).to.beFalse()`                      |
| **`beValid`**        | Expects `IsValid( value )` to return `true`           | `expect( ply ).to.beValid()`                                    |
| **`beInvalid`**      | Expects `IsValid( value )` to return `false`          | `expect( nil ).to.beInalid()`                                   |
| **`beNil`**          | Expects the subject to literally be `nil`             | `expect( player.GetAll()[2] ).to.beNil()`                       |
| **`exist`**          | Expects the subject to not be `nil`                   | `expect( MyProject ).to.exist()`                                |
| **`beA`**/**`beAn`**     | Expects the subject to have the given `type`          | `expect( "test" ).to.beA( "string" )`                       |
| **`succeed`**        | Expects the subject function to run without error     | `expect( CurTime ).to.succeed()`                                |
| **`err`**            | Expects the subject function to throw an error        | `expect( error ).to.err()`                                      |
| **`errWith`**        | Expects the subject function to throw the given error | `expect( badFunc ).to.errWith( "error message" )`               |

<br>

#### Expecation Negation
You can invert an Expectation by using `.toNot` or `.notTo` in place of your `.to`

i.e.:
```lua
expect( ply ).toNot.beInvalid()
expect( "test" ).notTo.beA( "table" )
```

<br>

### Async tests and the `done` function
If your test relies on timers, hooks, callbacks, etc., then you need to run your test Asynchronously.

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

<br>

### Before / After functions
You may find yourself writing a lot of repetitive setup/teardown code in each of your Test Cases.

GLuaTest has a few convenience functions for you to use.

<br>

---

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

#### **`setup`/`cleanup`**

The `setup` and `cleanup` functions are a lot like `beforeEach` and `afterEach`, except they're used only for a specific Test Case.

One common way to use these is to make sure that your test cleans up after itself even if it errors.


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
    end,
}
```
 
 
But consider, what would happen if `WrapperFunc` errored, or the expectation failed?

`GlobalFunc` would still be defined as our local function for all future tests, potentially causing them to fail.

Instead, we can use GLuaTest's `setup` and `cleanup` functions to make our test safer:
```lua
-- lua/tests/my_project/wrapper.lua

return {
    groupName = "Wrapper Functions",
    cases = {
        {
            name = "Wrapper should call the original function",
            setup = function( state )
                state.GlobalFunc = GlobalFunc
            end,

            func = function()
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

# Troubleshooting 🤔
<details>
 <summary>Solutions to common problems</summary>
 
 ### Does your test output look completely unreadable?
 ![image](https://user-images.githubusercontent.com/7936439/170231750-e59f880f-138a-485d-be47-8b81f60c9cad.png)

 **Try setting the `gluatest_use_ansi` convar to `0`**
</details>
