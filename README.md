# GLuaTest 
🎉 **An endearing testing framework for GMod** 🎉
---

GLuaTest is a testing framework built for Garry's Mod.
Its job is to make writing tests for Garry's Mod projects easy.


It offers an approachable (albeit strange) syntax that lets you get started quickly.


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

**Some additional reading:**
<details>
 <summary><strong>Foreward about automated testing in GMod</strong></summary>
<br>
Automated testing is a crucial part of any software workflow.
Your automated tests define a contract that give you and your would-be users confidence that the project will behave properly.


Without tests, you may find yourself spending large amounts of time debugging obscure issues.
Automated tests require more work up front, but will save you time and frustration in the future when more people start using your project.

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

 - [I want to run my tests on my Pull Requests](#automated-testing-on-pull-requests)
 - [I want to run my tests locally or on a dev server](#running-locally)
 - [I want to run my tests without setting up a local or dev server](#running-locally-without-a-server)

<br>

## Automated testing on Pull Requests

<details>
<summary><strong>GitHub Actions Automation</strong></summary>
<br>

To set up automated test runs, we'll use Github Workflows.

It's actually really simple to set up the workflow. Simply add the following file to your project:
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
 - The Lua branch CFC's Logging Library ( github.com/CFC-Servers/gm_logger )


Make a new file somewhere in your project (`lua/tests/my_project/requirements.txt` maybe?) with the following:
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
<summary><strong>Running Locally</strong></summary>
<br>

It's actually extremely simple to run GLuaTest locally.

Just put GLuaTest into your `addons/` directory, set `gluatest_enable 1` on the server, and restart!


All of your tests will run when the server starts up and you can view the output in the server console/logs.
</details>


## Running locally without a server
<details>
<summary><strong>Running Locally without a server</strong></summary>
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

The test file itself is quite simple. It needs to return a table of test cases.


For example:
```lua
-- lua/tests/my_clock/get_time.lua

return {
    {
        name = "It should return the correct time",
        func = function()
            local myClock = Clock.New()
            local realTime = os.time()

            expect( myClock:GetTime() ).to.equal( realTime )
        end
    }
}
```
 
<br>

### The Test Case
Each Test Case is a table with the following keys:

| Key              | Type       | Description                                                                    | Required | Default |
|------------------|------------|--------------------------------------------------------------------------------|----------|---------|
| **`name`**       | `string`   | Name of the test case (for reference later)                                    | `true`   |         |
| **`func`**       | `function` | The test function                                                              | `true`   |         |
| **`async`**      | `bool`     | If your test relies on timers, hooks, or callbacks, it must run asynchronously | `false`  | `false` |
| **`timeout`**    | `int`      | How long to wait for your async test before marking it as having timed out     | `false`  | 60      |
| **`clientside`** | `bool`     | Should run clientside-only                                                     | `false`  | `false` |
| **`shared`**     | `bool`     | Should run clientside and serverside                                           | `false`  | `false` |

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
| **`equal`**/**`eq`**     | Basic `==` equality check                             | `expect( a ).to.eq( b )`                                        |
| **`beLessThan`**     | Basic `<` comparison                                  | `expect( 5 ).to.beLessThan( 6 )`                                |
| **`beGreaterThan`**  | Basic `>` comparison                                  | `expect( 10 ).to.beGreaterThan( 1 )`                            |
| **`beTrue`**         | Expects the subject to literally be `true`            | `expect( Entity( 1 ):IsPlayer() ).to.beTrue()`                  |
| **`beFalse`**        | Expects the subject to literally be `false`           | `expect( istable( "test" ) ).to.beFalse()`                      |
| **`beValid`**        | Expects `IsValid( value )` to return `true`           | `expect( ply ).to.beValid()`                                    |
| **`beNil`**          | Expects the subject to literally be `nil`             | `expect( player.GetAll()[2] ).to.beNil()`                       |
| **`exist`**          | Expects the subject to not be `nil`                   | `expect( MyProject ).to.exist()`                                |
| **`beA`**/**`beAn`**     | Expects the subject to have the given `type`          | `expect( "test" ).to.beA( "string" )`                           |
| **`succeed`**        | Expects the subject function to run without error     | `expect( CurTime ).to.succeed()`                                |
| **`err`**            | Expects the subject function to throw an error        | `expect( error ).to.err()`                                      |
| **`errWith`**        | Expects the subject function to throw the given error | `expect( function() error( "oops" ) end ).to.errWith( "oops" )` |

<br>

### The `done` function
Some tests can't run synchronously. Sometimes you need to wait for something else to happen.

In those cases, you need to mark your test as `async` and tell GLuaTest when you're done.

You can do this with the `done()` function. As soon as an async test calls `done()`, it's marked as complete.


If your test fails for some reason before it can call `done()`, GLuaTest has no way of knowing what happened.

GLuaTest has a 60 second timer for each file's async functions to complete. If it hasn't heard back from any of them by then, it will mark them as Timed Out.

If you know the maximum amount of time your test will take, you can include the `timeout` key on the test with the number of seconds to wait until failing the test.


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
    {
        name = "It should run within 2 seconds of calling StartRun",
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
```
