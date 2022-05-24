# Quickstart

Okay, okay, I get it. You're a big strong engineer and you don't need a README.

Here's the bare minimum you need to get started


## Setup

1. Create a new branch on your project
2. Create a new directory in your project, `lua/tests/project_name/`
3. Open your first test file, `lua/tests/project_name/main.lua`

Create the basic test structure:
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
        },
        {
            name = "Should not load modules automatically",
            func = function()
                expect( MyProject.Modules ).to.beNil()
            end
        }
    }
}
```

_Sidenote: There are a lot of ways to structure the test file. Ultimately it just needs to return a table of tables. Play around with some different methods to see what works for you!_

4. Add the GitHub Workflow to `.github/workflows/gluatest.yml`:
```yml
name: GLuaTest Runner

on:
  pull_request:

jobs:
  run-tests:
    uses: CFC-Servers/GLuaTest/.github/workflows/run_tests.yml@main
```

5. Commit your changes, push your branch, and open a new PR



That's it! You have a working automated test runner for your project.

Check out the README for more details about [what expectations you can use](https://github.com/CFC-Servers/GLuaTest#expectations) and [how to make async tests](https://github.com/CFC-Servers/GLuaTest#the-done-function).