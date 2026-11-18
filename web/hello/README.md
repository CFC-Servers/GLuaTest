# hello.gluatest.com

The Cloudflare Worker that receives GLuaTest's [usage ping](../../README.md#usage-ping).

It stores one row for each request to `/ping` in the `pings` table of the `gluatest-hello` D1 database and replies `Hello!`. Requests to other paths, or without a `version` parameter, are not stored.

| Column           | Value                                                        |
|------------------|--------------------------------------------------------------|
| `received_at`    | UTC time the ping arrived                                    |
| `version`        | GLuaTest version                                             |
| `branch`         | GMod branch                                                  |
| `country`        | Country code                                                 |
| `region`         | Region                                                       |
| `continent`      | Continent code                                               |
| `cloud_provider` | Cloud provider (`microsoft`, `amazon`, ..., or `other`)      |
| `project`        | Project name, or `unknown` when the project did not set one  |
| `test_groups`    | Number of test groups                                        |
| `test_cases`     | Number of test cases                                         |
| `asn`            | AS number of the network the request came from               |

The table is defined in [`migrations`](migrations). After adding a migration, apply it by hand before the Worker change that needs it reaches `main`:

```
npx wrangler d1 migrations apply gluatest-hello --remote
```

## Routing

The Worker only runs for the route `hello.gluatest.com/ping*`. A route needs a proxied DNS record for `hello` in the `gluatest.com` zone, and that record is managed in the Cloudflare dashboard.

## Deploying

Changes under `web/hello` deploy automatically when they reach `main`, through the [Deploy hello Worker](../../.github/workflows/deploy_hello.yml) workflow.

To deploy by hand, run this from this directory, logged in to the Cloudflare account that owns `gluatest.com`:

```
npx wrangler deploy
```
