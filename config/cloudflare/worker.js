/**
 * Forem Portable Cloudflare Edge Worker
 *
 * Provides 1:1 behavioral parity with the Fastly VCL snippets in `config/fastly/snippets/`:
 *   1. `bad_bot_detection.vcl`
 *   2. `safe_params_list.vcl`
 *   3. `client_geolocation.vcl`
 *   4. `check_for_remember_user_token_in_cookie_to_set_header.vcl`
 *   5. `stale_while_revalidate_controls.vcl`
 *
 * Also bridges Forem's Surrogate headers (`Surrogate-Control` -> `CDN-Cache-Control`,
 * `Surrogate-Key` -> `Cache-Tag`) and client IP/geo headers (`CF-Connecting-IP` ->
 * `Fastly-Client-IP`, `cf.regionCode` -> `Fastly-Client-Geo-Region`) so the Rails
 * origin behaves identically behind Cloudflare or Fastly.
 */

export const DEFAULT_ACTIVE_GEOFENCING_REGIONS = Object.freeze({
  CA: "CA", // Canada
  US: "US", // USA
  AU: "AU", // Australia
  BR: "BR", // Brazil
  CN: "CN", // China
  FR: "FR", // France
  DE: "DE", // Germany
  IN: "IN", // India
  ID: "ID", // Indonesia
  MY: "MY", // Malaysia
  NZ: "NZ", // New Zealand
  PH: "PH", // Philippines
  RU: "RU", // Russia
  SG: "SG", // Singapore
  GB: "GB", // United Kingdom
});

export const SAFE_PARAMS = Object.freeze([
  "a_id",
  "args",
  "article_id",
  "article_ids",
  "articles",
  "asc",
  "callback_url",
  "category",
  "client_id",
  "code",
  "collection_id",
  "commentable_id",
  "commentable_type",
  "confirmation_token",
  "continuation",
  "created_at",
  "end",
  "email",
  "filter",
  "followable_id",
  "followable_type",
  "forem_owner_secret",
  "fork_id",
  "form_ids",
  "i",
  "key",
  "message_offset",
  "name",
  "oauth_token",
  "oauth_verifier",
  "offset",
  "onboarding",
  "org_id",
  "organization_id",
  "p",
  "page",
  "per_page",
  "p_id",
  "placement_area",
  "prefill",
  "preview",
  "purchaser",
  "q",
  "reactable_ids",
  "redirect_uri",
  "reported_url",
  "reporter_username",
  "response_type",
  "scope",
  "search",
  "signature",
  "sort",
  "source_id",
  "source_type",
  "start",
  "state",
  "status",
  "tag",
  "tag_list",
  "top",
  "type_of",
  "url",
  "username",
  "invitation_token",
  "reset_password_token",
  "ut",
  "verb",
  "invitation_slug",
  "period",
  "comments_sort",
  "billboard",
  "controller_action",
  "bb_test_placement_area",
  "cookies_allowed",
  "members",
  "bb_test_id",
  "item",
  "mode",
  "month",
  "page_id",
  "token",
  "passed_domain",
]);

const SAFE_PARAMS_SET = new Set(SAFE_PARAMS);

const BAD_BOT_REGEXES = [
  /^Java/,
  /^Jakarta/,
  /IDBot/,
  /id-search/,
  /User-Agent/,
  /compatible ;/,
  /ConveraCrawler/,
  /^Mozilla$/,
  /libwww/,
  /lwp-trivial/,
  /urllib/,
  /GT:WWW/,
  /Snoopy/,
  /MFC_Tear_Sample/,
  /HTTP::Lite/,
  /PHPCrawl/,
  /URI::Fetch/,
  /Zend_Http_Client/,
  /http client/,
  /PECL::HTTP/,
  /panscient\.com/,
  /IBM EVV/,
  /Bork-edition/,
  /Fetch API Request/,
  /PleaseCrawl/,
  /[A-Z][a-z]{3,} [a-z]{4,} [a-z]{4,}/,
  /layeredtech\.com/,
  /WEP Search/,
  /Wells Search II/,
  /Missigua Locator/,
  /ISC Systems iRc Search 2\.1/,
  /Microsoft URL Control/,
  /Indy Library/,
  /Fuzz Faster/,
  /AhrefsBot/,
  /bytespider/,
  /amazonbot/,
];

export const BAD_BOT_EXACT_USER_AGENTS = Object.freeze([
  "8484 Boston Project v 1.0",
  "Atomic_Email_Hunter/4.0",
  "atSpider/1.0",
  "autoemailspider",
  "China Local Browse 2.6",
  "ContactBot/0.2",
  "ContentSmartz",
  "DataCha0s/2.0",
  "DBrowse 1.4b",
  "DBrowse 1.4d",
  "Demo Bot DOT 16b",
  "Demo Bot Z 16b",
  "DSurf15a 01",
  "DSurf15a 71",
  "DSurf15a 81",
  "DSurf15a VA",
  "EBrowse 1.4b",
  "Educate Search VxB",
  "EmailSiphon",
  "EmailWolf 1.00",
  "ESurf15a 15",
  "ExtractorPro",
  "Franklin Locator 1.8",
  "FSurf15a 01",
  "Full Web Bot 0416B",
  "Full Web Bot 0516B",
  "Full Web Bot 2816B",
  "Guestbook Auto Submitter",
  "Industry Program 1.0.x",
  "ISC Systems iRc Search 2.1",
  "IUPUI Research Bot v 1.9a",
  "LARBIN-EXPERIMENTAL (efp\u0040gmx.net)",
  "LetsCrawl.com/1.0 +http://letscrawl.com/",
  "Lincoln State Web Browser",
  "LMQueueBot/0.2",
  "LWP::Simple/5.803",
  "Mac Finder 1.0.xx",
  "MFC Foundation Class Library 4.0",
  "Microsoft URL Control - 6.00.8xxx",
  "Missauga Locate 1.0.0",
  "Missigua Locator 1.9",
  "Missouri College Browse",
  "Mizzu Labs 2.2",
  "Mo College 1.9",
  "Mozilla/2.0 (compatible; NEWT ActiveX; Win32)",
  "Mozilla/3.0 (compatible; Indy Library)",
  "Mozilla/4.0 (compatible; Advanced Email Extractor v2.xx)",
  "Mozilla/4.0 (compatible; Iplexx Spider/1.0 http://www.iplexx.at)",
  "Mozilla/4.0 (compatible; MSIE 5.0; Windows NT; DigExt; DTS Agent",
  "Mozilla/4.0 efp\u0040gmx.net",
  "Mozilla/5.0 (Version: xxxx Type:xx)",
  "MVAClient",
  "NameOfAgent (CMS Spider)",
  "NASA Search 1.0",
  "Nsauditor/1.x",
  "PBrowse 1.4b",
  "PEval 1.4b",
  "Poirot",
  "Port Huron Labs",
  "Production Bot 0116B",
  "Production Bot 2016B",
  "Production Bot DOT 3016B",
  "Program Shareware 1.0.2",
  "PSurf15a 11",
  "PSurf15a 51",
  "PSurf15a VA",
  "psycheclone",
  "RSurf15a 41",
  "RSurf15a 51",
  "RSurf15a 81",
  "searchbot admin\u0040google.com",
  "ShablastBot 1.0",
  "snap.com beta crawler v0",
  "Snapbot/1.0",
  "sogou develop spider",
  "Sogou Orion spider/3.0(+http://www.sogou.com/docs/help/webmasters.htm#07)",
  "sogou spider",
  "Sogou web spider/3.0(+http://www.sogou.com/docs/help/webmasters.htm#07)",
  "sohu agent",
  "SSurf15a 11",
  "TSurf15a 11",
  "Under the Rainbow 2.2",
  "User-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)",
  "VadixBot",
  "WebVulnCrawl.blogspot.com/1.0 libwww-perl/5.803",
  "Wells Search II",
  "WEP Search 00",
]);

const BAD_BOT_EXACT_SET = new Set(BAD_BOT_EXACT_USER_AGENTS);
const VALID_HOSTNAME_REGEX = /^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$/;
const INVALID_GEO_COUNTRIES = new Set(["**", "XX", "T1"]);
const INVALID_GEO_REGIONS = new Set(["NO REGION", "AOL", "?", "***"]);

/**
 * Constant-time string comparison equivalent to Fastly VCL `digest.secure_is_equal`.
 */
export function secureIsEqual(a, b) {
  if (typeof a !== "string" || typeof b !== "string") {
    return false;
  }
  const encoder = new TextEncoder();
  const aBytes = encoder.encode(a);
  const bBytes = encoder.encode(b);
  if (aBytes.length !== bBytes.length || aBytes.length === 0) {
    return false;
  }
  let diff = 0;
  for (let i = 0; i < aBytes.length; i += 1) {
    diff |= aBytes[i] ^ bBytes[i];
  }
  return diff === 0;
}

/**
 * Mirrors `config/fastly/snippets/bad_bot_detection.vcl`.
 */
export function isBadBot(userAgent, pathname = "/") {
  if (typeof userAgent !== "string" || userAgent.length === 0 || !/./.test(userAgent)) {
    return true;
  }
  if (BAD_BOT_EXACT_SET.has(userAgent)) {
    return true;
  }
  if (userAgent === "Ruby" && !pathname.startsWith("/api")) {
    return true;
  }
  if (userAgent.includes("Firefox/62.0") && userAgent.includes("Win64")) {
    return true;
  }
  for (let i = 0; i < BAD_BOT_REGEXES.length; i += 1) {
    if (BAD_BOT_REGEXES[i].test(userAgent)) {
      return true;
    }
  }
  return false;
}

/**
 * Mirrors `config/fastly/snippets/safe_params_list.vcl`.
 */
export function filterSafeParams(inputUrl, headers) {
  const url = new URL(inputUrl.toString());
  const fullPathAndQuery = `${url.pathname}${url.search}`;
  const hasApiKey = Boolean(headers && typeof headers.get === "function" && headers.get("api-key"));

  const bypassFilter =
    fullPathAndQuery.includes("/ahoy/") ||
    fullPathAndQuery.includes("/admin/") ||
    fullPathAndQuery.includes("/search/") ||
    fullPathAndQuery.includes("/bulk_show") ||
    (fullPathAndQuery.startsWith("/api") && hasApiKey);

  if (bypassFilter || !url.search) {
    return url;
  }

  const filteredParams = new URLSearchParams();
  for (const [key, value] of url.searchParams.entries()) {
    if (SAFE_PARAMS_SET.has(key)) {
      filteredParams.append(key, value);
    }
  }

  const queryString = filteredParams.toString();
  url.search = queryString ? `?${queryString}` : "";
  return url;
}

/**
 * Mirrors `config/fastly/snippets/client_geolocation.vcl`.
 */
export function resolveGeolocation(cf = {}, activeRegions = DEFAULT_ACTIVE_GEOFENCING_REGIONS) {
  const country = cf && typeof cf.country === "string" ? cf.country.toUpperCase() : "";
  if (!country || INVALID_GEO_COUNTRIES.has(country)) {
    return { clientGeo: null, cacheableClientGeo: null };
  }

  const rawRegion = cf && typeof cf.regionCode === "string" ? cf.regionCode.toUpperCase() : "";
  let code = country;
  if (rawRegion && !INVALID_GEO_REGIONS.has(rawRegion)) {
    code = `${country}-${rawRegion}`;
  }

  const hasSpecific = Object.prototype.hasOwnProperty.call(activeRegions, code);
  const cacheableLookupKey = hasSpecific ? code : country;
  const cacheableClientGeo = Object.prototype.hasOwnProperty.call(activeRegions, cacheableLookupKey)
    ? activeRegions[cacheableLookupKey]
    : "";

  return { clientGeo: code, cacheableClientGeo };
}

function parsePrimaryHosts(env = {}) {
  if (env && typeof env.PRIMARY_HOSTS === "string" && env.PRIMARY_HOSTS.trim().length > 0) {
    return new Set(
      env.PRIMARY_HOSTS.split(",")
        .map((h) => h.trim().toLowerCase())
        .filter(Boolean),
    );
  }
  return new Set(["dev.to", "www.dev.to"]);
}

/**
 * Mirrors `vcl_recv` in `config/fastly/snippets/check_for_remember_user_token_in_cookie_to_set_header.vcl`.
 */
export function resolveHostAndAuthHeaders(requestUrl, incomingHeaders, env = {}) {
  const cookie = incomingHeaders.get("Cookie") || "";
  const xLoggedIn = cookie.includes("remember_user_token") ? "logged-in" : "logged-out";

  const candidateOrigHost = (incomingHeaders.get("X-Forem-Original-Host") || "").toLowerCase();
  const edgeSecret = incomingHeaders.get("X-Forem-Edge-Secret") || "";
  const configuredSecret = (env && env.CLOUDFLARE_SECRET) || "";

  const incomingHost = incomingHeaders.get("Host") || new URL(requestUrl.toString()).host;

  let reqHost = incomingHost;
  if (
    edgeSecret.length > 0 &&
    configuredSecret.length > 0 &&
    secureIsEqual(edgeSecret, configuredSecret) &&
    candidateOrigHost.length > 0 &&
    candidateOrigHost.length <= 253 &&
    VALID_HOSTNAME_REGEX.test(candidateOrigHost)
  ) {
    reqHost = candidateOrigHost;
  }

  const primaryHosts = parsePrimaryHosts(env);
  const originHost = (env && env.ORIGIN_HOST) || "practicaldev.herokuapp.com";
  let upstreamHost = incomingHost;

  if (
    !primaryHosts.has(incomingHost.toLowerCase()) &&
    incomingHost.toLowerCase() !== originHost.toLowerCase()
  ) {
    upstreamHost = originHost;
  }

  return {
    xLoggedIn,
    reqHost,
    upstreamHost,
    isPrimaryHost: primaryHosts.has(reqHost.toLowerCase()),
  };
}

function appendVaryValue(existingVary, headerName) {
  if (!existingVary) {
    return headerName;
  }
  const tokens = existingVary.split(",").map((t) => t.trim().toLowerCase());
  if (tokens.includes(headerName.toLowerCase())) {
    return existingVary;
  }
  return `${existingVary}, ${headerName}`;
}

function removeVaryValue(existingVary, headerName) {
  if (!existingVary) {
    return null;
  }
  const filtered = existingVary
    .split(",")
    .map((t) => t.trim())
    .filter((t) => t.length > 0 && t.toLowerCase() !== headerName.toLowerCase());
  return filtered.length > 0 ? filtered.join(", ") : null;
}

/**
 * Mirrors `vcl_fetch` across `check_for_remember_user_token_in_cookie_to_set_header.vcl`
 * and `stale_while_revalidate_controls.vcl`, plus translates Surrogate headers for Cloudflare.
 */
export function applyEdgeResponseHeaders(responseHeaders, options = {}) {
  const {
    reqHost = "dev.to",
    isPrimaryHost = true,
    pathname = "/",
    search = "",
    status = 200,
    stripSurrogateHeaders = true,
  } = options;

  const headers = new Headers(responseHeaders);

  // 1. Always vary on X-Loggedin
  headers.set("Vary", appendVaryValue(headers.get("Vary"), "X-Loggedin"));

  // 2. Vary on X-Req-Host only for non-primary (custom/subforem) domains
  if (isPrimaryHost || reqHost === "dev.to" || reqHost === "www.dev.to") {
    const updatedVary = removeVaryValue(headers.get("Vary"), "X-Req-Host");
    if (updatedVary) {
      headers.set("Vary", updatedVary);
    } else {
      headers.delete("Vary");
    }
  } else {
    headers.set("Vary", appendVaryValue(headers.get("Vary"), "X-Req-Host"));
  }

  // 3. Translate Surrogate-Key (space-delimited) -> Cache-Tag (comma-delimited)
  const surrogateKey = headers.get("Surrogate-Key");
  if (surrogateKey && !headers.has("Cache-Tag")) {
    const tags = surrogateKey.trim().split(/\s+/).filter(Boolean);
    if (tags.length > 0) {
      headers.set("Cache-Tag", tags.join(","));
    }
  }

  // 4. Translate Surrogate-Control -> CDN-Cache-Control & apply SWR / error caching rules
  let edgeCacheControl = headers.get("CDN-Cache-Control") || headers.get("Surrogate-Control");
  const isHomepage = pathname === "/" && (search === "" || search === "?i=i");

  if (isHomepage && edgeCacheControl && !edgeCacheControl.includes("no-store")) {
    if (/stale-while-revalidate=\d+/.test(edgeCacheControl)) {
      edgeCacheControl = edgeCacheControl.replace(
        /stale-while-revalidate=\d+/,
        "stale-while-revalidate=60",
      );
    } else {
      edgeCacheControl = `${edgeCacheControl}, stale-while-revalidate=60`;
    }
  }

  const browserCacheControl = headers.get("Cache-Control") || "";
  const explicitlyUncacheable =
    browserCacheControl.includes("no-store") ||
    browserCacheControl.includes("private") ||
    (edgeCacheControl && edgeCacheControl.includes("no-store"));

  if (status >= 400 && !pathname.startsWith("/api") && !explicitlyUncacheable) {
    edgeCacheControl = "max-age=30";
  }

  if (edgeCacheControl) {
    headers.set("CDN-Cache-Control", edgeCacheControl);
  }

  if (stripSurrogateHeaders) {
    headers.delete("Surrogate-Control");
    headers.delete("Surrogate-Key");
  }

  return headers;
}

/**
 * Builds the synthetic cache key URL used with Cloudflare's Cache API so that
 * `X-Loggedin`, `X-Req-Host`, `X-Cacheable-Client-Geo`, and `Accept` never collide
 * even on non-Enterprise Cloudflare plans where `Vary` headers are ignored by default.
 *
 * Signed-out HTML requests on the canonical host keep their exact URL so standard
 * URL purges (`EdgeCache::Bust::Cloudflare`) match directly without extra parameters.
 */
export function buildCacheKeyUrl(filteredUrl, { reqHost, xLoggedIn, cacheableClientGeo, accept }) {
  const keyUrl = new URL(filteredUrl.toString());
  keyUrl.hostname = reqHost.split(":")[0] || keyUrl.hostname;

  if (xLoggedIn === "logged-in") {
    keyUrl.searchParams.set("__cf_loggedin", "1");
  }
  if (cacheableClientGeo && keyUrl.pathname.startsWith("/billboards")) {
    keyUrl.searchParams.set("__cf_geo", cacheableClientGeo);
  }
  if (accept && accept.includes("application/json")) {
    keyUrl.searchParams.set("__cf_format", "json");
  }

  return keyUrl.toString();
}

function parseActiveGeofencingRegions(env = {}) {
  if (!env || !env.ACTIVE_GEOFENCING_REGIONS) {
    return DEFAULT_ACTIVE_GEOFENCING_REGIONS;
  }
  if (typeof env.ACTIVE_GEOFENCING_REGIONS === "object") {
    return env.ACTIVE_GEOFENCING_REGIONS;
  }
  try {
    return JSON.parse(env.ACTIVE_GEOFENCING_REGIONS);
  } catch (_err) {
    const map = {};
    String(env.ACTIVE_GEOFENCING_REGIONS)
      .split(",")
      .map((s) => s.trim().toUpperCase())
      .filter(Boolean)
      .forEach((code) => {
        map[code] = code;
      });
    return map;
  }
}

export default {
  async fetch(request, env = {}, ctx = {}) {
    const originalUrl = new URL(request.url);
    const userAgent = request.headers.get("User-Agent") || "";

    // 1. Bad bot detection (`bad_bot_detection.vcl`)
    if (isBadBot(userAgent, originalUrl.pathname)) {
      return new Response("", {
        status: 403,
        statusText: "Forbidden Bots",
      });
    }

    // 2. Query parameter allowlist (`safe_params_list.vcl`)
    const filteredUrl = filterSafeParams(originalUrl, request.headers);

    // 3. Client geolocation (`client_geolocation.vcl`)
    const activeRegions = parseActiveGeofencingRegions(env);
    const { clientGeo, cacheableClientGeo } = resolveGeolocation(request.cf, activeRegions);

    // 4. Auth state (`X-Loggedin`) and custom domain host headers
    const { xLoggedIn, reqHost, upstreamHost, isPrimaryHost } = resolveHostAndAuthHeaders(
      filteredUrl,
      request.headers,
      env,
    );

    const upstreamHeaders = new Headers(request.headers);
    upstreamHeaders.set("X-Loggedin", xLoggedIn);
    upstreamHeaders.set("X-Req-Host", reqHost);
    upstreamHeaders.set("Fastly-Orig-Host", reqHost);
    upstreamHeaders.set("X-Forwarded-Host", reqHost);
    upstreamHeaders.set("X-Forem-Original-Host", reqHost);
    upstreamHeaders.delete("X-Forem-Edge-Secret");

    if (clientGeo !== null) {
      upstreamHeaders.set("X-Client-Geo", clientGeo);
      upstreamHeaders.set("X-Cacheable-Client-Geo", cacheableClientGeo || "");
    }

    const cfConnectingIp = request.headers.get("CF-Connecting-IP");
    if (cfConnectingIp && !upstreamHeaders.has("Fastly-Client-IP")) {
      upstreamHeaders.set("Fastly-Client-IP", cfConnectingIp);
    }

    const cfRegionCode = request.cf && request.cf.regionCode;
    if (cfRegionCode && !upstreamHeaders.has("Fastly-Client-Geo-Region")) {
      upstreamHeaders.set("Fastly-Client-Geo-Region", String(cfRegionCode));
    }

    if (upstreamHost) {
      upstreamHeaders.set("Host", upstreamHost);
    }

    const cacheKeyUrl = buildCacheKeyUrl(filteredUrl, {
      reqHost,
      xLoggedIn,
      cacheableClientGeo,
      accept: request.headers.get("Accept") || "",
    });

    const isCacheableMethod = request.method === "GET" || request.method === "HEAD";
    const cache = typeof caches !== "undefined" && caches ? caches.default : null;
    const cacheKeyRequest = isCacheableMethod ? new Request(cacheKeyUrl, { method: "GET" }) : null;

    if (cache && cacheKeyRequest && request.method === "GET") {
      const cachedResponse = await cache.match(cacheKeyRequest);
      if (cachedResponse) {
        return cachedResponse;
      }
    }

    const upstreamRequest = new Request(filteredUrl.toString(), {
      method: request.method,
      headers: upstreamHeaders,
      body: isCacheableMethod ? null : request.body,
      redirect: "manual",
      cf: {
        cacheKey: cacheKeyUrl,
      },
    });

    const originResponse = await fetch(upstreamRequest);
    const transformedHeaders = applyEdgeResponseHeaders(originResponse.headers, {
      reqHost,
      isPrimaryHost,
      pathname: filteredUrl.pathname,
      search: filteredUrl.search,
      status: originResponse.status,
      stripSurrogateHeaders: env.KEEP_SURROGATE_HEADERS !== "true",
    });

    const finalResponse = new Response(originResponse.body, {
      status: originResponse.status,
      statusText: originResponse.statusText,
      headers: transformedHeaders,
    });

    const cdnCacheControl = transformedHeaders.get("CDN-Cache-Control") || "";
    const shouldStoreInWorkerCache =
      cache &&
      cacheKeyRequest &&
      request.method === "GET" &&
      cdnCacheControl.includes("max-age=") &&
      !cdnCacheControl.includes("max-age=0") &&
      !cdnCacheControl.includes("no-store");

    if (shouldStoreInWorkerCache) {
      const cacheCopy = finalResponse.clone();
      cacheCopy.headers.set("Cache-Control", cdnCacheControl);
      const putPromise = cache.put(cacheKeyRequest, cacheCopy);
      if (ctx && typeof ctx.waitUntil === "function") {
        ctx.waitUntil(putPromise);
      }
    }

    return finalResponse;
  },
};
