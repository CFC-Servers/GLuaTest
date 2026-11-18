const GREETING = "Hello!";
const MAX_FIELD_LENGTH = 32;
const MAX_PROJECT_NAME_LENGTH = 140;

const INSERT_PING = `
  INSERT INTO pings (version, branch, country, region, continent, cloud_provider, project, test_groups, test_cases, asn, runner, agent)
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
`;

const CLOUD_PROVIDERS_BY_ASN = new Map([
  [8075, "microsoft"],
  [16509, "amazon"],
  [14618, "amazon"],
  [15169, "google"],
  [396982, "google"],
  [14061, "digitalocean"],
  [24940, "hetzner"],
  [16276, "ovh"],
  [63949, "linode"],
  [20473, "vultr"],
]);

function readText(searchParams, name, maxLength = MAX_FIELD_LENGTH) {
  const value = searchParams.get(name) ?? "unknown";
  return value.slice(0, maxLength);
}

function readCount(searchParams, name) {
  const count = Number.parseInt(searchParams.get(name), 10);
  return Number.isFinite(count) ? count : 0;
}

export default {
  async fetch(request, env) {
    const { pathname, searchParams } = new URL(request.url);

    if (pathname !== "/ping") return new Response(GREETING);
    if (!searchParams.has("version")) return new Response(GREETING);

    const country = request.cf?.country ?? "unknown";
    const region = request.cf?.region ?? "unknown";
    const continent = request.cf?.continent ?? "unknown";
    const asn = request.cf?.asn ?? 0;
    const cloudProvider = CLOUD_PROVIDERS_BY_ASN.get(asn) ?? "other";

    // "agent/claude-code" -> "agent", "claude-code"
    const [runner, agent = ""] = readText(searchParams, "runner").split("/");

    const insertPing = env.DB.prepare(INSERT_PING).bind(
      readText(searchParams, "version"),
      readText(searchParams, "branch"),
      country,
      region,
      continent,
      cloudProvider,
      readText(searchParams, "project", MAX_PROJECT_NAME_LENGTH),
      readCount(searchParams, "groups"),
      readCount(searchParams, "cases"),
      asn,
      runner,
      agent,
    );

    try {
      await insertPing.run();
    } catch (error) {
      console.error("Failed to store ping", error);
    }

    return new Response(GREETING);
  },
};
