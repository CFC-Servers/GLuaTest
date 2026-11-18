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

## Routing

The Worker only runs for the route `hello.gluatest.com/ping*`. A route needs a proxied DNS record for `hello` in the `gluatest.com` zone, and that record is managed in the Cloudflare dashboard.

## Deploying

Changes under `web/hello` deploy automatically when they reach `main`, through the [Deploy hello Worker](../../.github/workflows/deploy_hello.yml) workflow.

To deploy by hand, run this from this directory, logged in to the Cloudflare account that owns `gluatest.com`:

```
npx wrangler deploy
```
