import { existsSync, readFileSync, writeFileSync } from "node:fs";

const OPTIONS_FILE = "/data/options.json";
const env = process.env;

const log = (msg) => console.log(`[ha-puppet] ${msg}`);
const fail = (msg) => {
  console.error(`[ha-puppet] ${msg}`);
  process.exit(1);
};

const truthy = (value) => /^(1|true|yes|on)$/i.test(String(value).trim());

function readToken() {
  if (env.HA_TOKEN) {
    return env.HA_TOKEN.trim();
  }
  if (env.HA_TOKEN_FILE) {
    try {
      return readFileSync(env.HA_TOKEN_FILE, "utf8").trim();
    } catch (err) {
      fail(`cannot read HA_TOKEN_FILE ${env.HA_TOKEN_FILE}: ${err.message}`);
    }
  }
  return undefined;
}

log(`ha-puppet ${env.HA_PUPPET_VERSION ?? "dev"}, Puppet ${env.PUPPET_VERSION ?? "unknown"}`);

if (existsSync("./options-dev.json")) {
  fail("/app/options-dev.json exists and would take precedence over /data/options.json; remove it");
}

const hadFile = existsSync(OPTIONS_FILE);
let options = {};
if (hadFile) {
  try {
    options = JSON.parse(readFileSync(OPTIONS_FILE, "utf8"));
  } catch (err) {
    fail(`cannot parse ${OPTIONS_FILE}: ${err.message}`);
  }
}

const overrides = {};
const token = readToken();
if (token) {
  overrides.access_token = token;
}
if (env.HA_URL) {
  overrides.home_assistant_url = env.HA_URL;
}
if (env.KEEP_BROWSER_OPEN !== undefined) {
  overrides.keep_browser_open = truthy(env.KEEP_BROWSER_OPEN);
}

if (!hadFile || Object.keys(overrides).length > 0) {
  options = { ...options, ...overrides };
  try {
    writeFileSync(OPTIONS_FILE, `${JSON.stringify(options, null, 2)}\n`, { mode: 0o600 });
  } catch (err) {
    fail(`cannot write ${OPTIONS_FILE} (read-only mount?): ${err.message}`);
  }
  log(`wrote ${OPTIONS_FILE} from ${hadFile ? "existing file + environment" : "environment"}`);
} else {
  log(`using ${OPTIONS_FILE} as mounted`);
}

log(`home_assistant_url=${options.home_assistant_url ?? "(upstream default)"}`);
log(`access_token ${options.access_token ? "set" : "NOT set, the UI will show setup instructions"}`);
log(`keep_browser_open=${Boolean(options.keep_browser_open)}`);

await import("./http.js");
