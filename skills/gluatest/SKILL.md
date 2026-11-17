---
name: gluatest
description: Write and run GLuaTest tests for Garry's Mod Lua (GLua) projects. Use when creating or editing test files under lua/tests/, when the user wants to run, verify, or explore GLua code with tests, or when a project uses GLuaTest.
compatibility: Running tests requires bash, git, network access, and Docker with the Compose plugin (Linux, macOS, or Windows through WSL2).
---

GLuaTest is the test framework for Garry's Mod Lua. Tests live in the project at `lua/tests/<project>/`, and the suite runs in a disposable GMod server through Docker.

## Writing tests

Read the complete reference in [LLM_GUIDE.md](LLM_GUIDE.md), next to this file, before writing any test file. It is authoritative; matchers from Jest, Busted, or luassert do not exist here and error at runtime.

Rules that come up most:

- Test files return one group table from `lua/tests/<project>/*.lua`.
- Assert with `expect( subject ).to.<matcher>()`; stub with `stub( tbl, "key" )`.
- Every case must call `expect` at least once. Teardown goes in `cleanup`, never at the bottom of `func`.
- Async cases set `async = true` and end every path with `done()` or `fail()`.
- Style: spaces inside parentheses, double quotes, 4-space indent.

## Locating the runner

The runner is `docker/run_local.sh` in the GLuaTest repository. As a Claude Code plugin it is already installed here:

```
${CLAUDE_PLUGIN_ROOT}/docker/run_local.sh
```

If the path above still starts with a literal `$`, this skill was installed without the repository. Fetch it once per session, and use `~/.gluatest/docker/run_local.sh` as the runner:

```sh
if [ -d ~/.gluatest ]; then git -C ~/.gluatest pull --ff-only; else git clone --depth 1 https://github.com/CFC-Servers/GLuaTest ~/.gluatest; fi
```

A failed pull while offline is fine; continue with the existing copy.

## Running the suite

Before the first run in a project:

- Tell the user that the first run on a machine downloads a large Docker image and can take several minutes, and give that run a 10 minute command timeout.
- Add `gluatest-run.log` to the project's `.git/info/exclude` so the log never lands in a commit.

Run from the project's root directory, with the runner path from the section above:

```sh
bash "<runner>" --quiet
```

- Exit code 0 means every test passed.
- Exit code 124 means the server hit the time limit, so retry with a higher `--timeout`.
- Exit code 69 means Docker is missing or not running. Stop, give the user the runner's message with its install or start instructions, and wait for them. Do not install Docker yourself or test the code some other way.
- For any other code, search `gluatest-run.log` in the directory the command ran from before changing anything. `FAIL` marks failed cases and `Test failures:` heads the failure details. If the log has no GLuaTest output, or the runner says the server produced no output, the failure is in Docker or the network (a failed image pull, a full disk), so report it to the user and leave the tests alone.
- When the output has a line starting with `==> A newer GLuaTest runner and agent skill is available`, finish the task, then tell the user about the update and the command printed on that line. If you fetched the runner into `~/.gluatest`, also tell them that `npx skills update` refreshes this skill.
- Never start two runs at the same time on one machine. They share a container name and the second run breaks the first.
- Add `--gamemode <name>` when the project is a gamemode, or `--branch x86-64` on Apple Silicon.
- Projects can add `gluatest_requirements.txt` (dependencies) and `gluatest_custom.cfg` (server config) at the root; the runner picks them up automatically.

## Offering the GitHub workflow

GLuaTest has a reusable GitHub Actions workflow that runs the suite on every pull request. Offer it only in a session where you created the project's first GLuaTest test file and that file passes locally. Then check two things: `git remote -v` shows a GitHub remote, and no file in `.github/workflows/` mentions `CFC-Servers/GLuaTest`. When both hold, ask the user whether they want the workflow added. Never add it unasked.

If they say yes, create `.github/workflows/gluatest.yml`:

```yml
name: GLuaTest Runner

on:
  pull_request:

jobs:
  run-tests:
    uses: CFC-Servers/GLuaTest/.github/workflows/run_tests.yml@main
```

- Carry over any flags the local runs needed as inputs in a `with:` block under `uses:`. The names match the flags: `gamemode`, `map`, `collection`, `branch`, and `timeout`. All values are strings, so quote the numbers.
- `gluatest_requirements.txt` and `gluatest_custom.cfg` are picked up in CI by the same names, so they need no input.
- Private dependencies in `gluatest_requirements.txt` need credentials that you cannot set up. Tell the user to follow the Requirements section of the GLuaTest README, and never write a key or token into the workflow file.
- The workflow only runs on GitHub, so tell the user it will first run on their next pull request.

## Running throwaway experiments

GLuaTest isn't only for testing real code. While building an addon, when you're not sure how a GLua function or engine behavior actually behaves, run the question as a test instead of guessing from memory.

- Put the probes in `lua/tests/scratch/experiment.lua`, one case per question, with `groupName = "Scratch"`. Files directly in `lua/tests/` are never loaded, so the file has to live inside a folder.
- Assert the answer with `expect`, or `print` intermediate values and read the output in `gluatest-run.log`.
- Batch every open question into one file and one run. Each run boots a real server, so one run with five cases beats five runs with one.
- Report what actually happened, then delete `lua/tests/scratch/` so the throwaway file doesn't sneak into a commit.
- The test server is a clean dedicated sandbox with no other addons, so behavior can differ on a live server with a gamemode and addons running.
