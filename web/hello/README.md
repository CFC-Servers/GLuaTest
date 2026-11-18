# hello.gluatest.com

The Cloudflare Worker that receives GLuaTest's [usage ping](../../README.md#usage-ping).

It stores one row for each request to `/ping` in the `gluatest_pings` Analytics Engine dataset and replies `Hello!`. Requests to other paths, or without a `version` parameter, are not stored.

| Column    | Value                                                        |
|-----------|--------------------------------------------------------------|
| `blob1`   | GLuaTest version                                             |
| `blob2`   | GMod branch                                                  |
| `blob3`   | Country code                                                 |
| `blob4`   | Region                                                       |
| `blob5`   | Continent code                                               |
| `blob6`   | Cloud provider (`microsoft`, `amazon`, ..., or `other`)      |
| `blob7`   | Project name, or `unknown` when the project did not set one  |
| `double1` | Number of test groups                                        |
| `double2` | Number of test cases                                         |
| `double3` | AS number of the network the request came from               |

## Deploying

From this directory, logged in to the Cloudflare account that owns `gluatest.com`:

```
npx wrangler deploy
```
