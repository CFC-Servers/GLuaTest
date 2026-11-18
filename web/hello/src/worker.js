const MAX_FIELD_LENGTH = 32;

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

function readText(searchParams, name) {
  const value = searchParams.get(name) ?? "unknown";
  return value.slice(0, MAX_FIELD_LENGTH);
}

function readCount(searchParams, name) {
  const count = Number.parseInt(searchParams.get(name), 10);
  return Number.isFinite(count) ? count : 0;
}

export default {
  async fetch(request, env) {
    const { searchParams } = new URL(request.url);

    if (searchParams.has("version")) {
      const country = request.cf?.country ?? "unknown";
      const region = request.cf?.region ?? "unknown";
      const continent = request.cf?.continent ?? "unknown";
      const asn = request.cf?.asn ?? 0;
      const cloudProvider = CLOUD_PROVIDERS_BY_ASN.get(asn) ?? "other";

      env.PINGS.writeDataPoint({
        blobs: [
          readText(searchParams, "version"),
          readText(searchParams, "branch"),
          country,
          region,
          continent,
          cloudProvider,
          readText(searchParams, "project"),
        ],
        doubles: [readCount(searchParams, "groups"), readCount(searchParams, "cases"), asn],
        indexes: [country],
      });
    }

    return new Response("Hello!");
  },
};
