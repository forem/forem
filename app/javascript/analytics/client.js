import { handleFetchAPIErrors } from '../utilities/http';

// Retry a promise-returning fn on transient network failures only.
// A `TypeError` from fetch signals a network/DNS/CORS-level failure (no HTTP
// response was received). Errors from handleFetchAPIErrors — 4xx/5xx — are
// regular `Error` instances with actionable messages and should surface
// immediately rather than being retried silently.
export function withRetry(fn, { maxRetries = 1, baseDelayMs = 300 } = {}) {
  const attempt = (n) =>
    fn().catch((err) => {
      if (n >= maxRetries || !(err instanceof TypeError)) {
        throw err;
      }
      return new Promise((resolve) => {
        setTimeout(resolve, baseDelayMs * 2 ** n);
      }).then(() => attempt(n + 1));
    });
  return attempt(0);
}

function callAnalyticsAPI(path, date, { organizationId, articleId }) {
  let url = `${path}?start=${date.toISOString().split('T')[0]}`;

  if (organizationId) {
    url = `${url}&organization_id=${organizationId}`;
  }
  if (articleId) {
    url = `${url}&article_id=${articleId}`;
  }

  return withRetry(() =>
    fetch(url)
      .then(handleFetchAPIErrors)
      .then((response) => response.json()),
  );
}

export function callHistoricalAPI(
  date,
  { organizationId, articleId },
) {
  return callAnalyticsAPI(
    '/api/analytics/historical',
    date,
    { organizationId, articleId },
  );
}

export function callReferrersAPI(
  date,
  { organizationId, articleId },
) {
  return callAnalyticsAPI(
    '/api/analytics/referrers',
    date,
    { organizationId, articleId },
  );
}

export function callTotalsAPI(
  date,
  { organizationId, articleId },
) {
  return callAnalyticsAPI(
    '/api/analytics/totals',
    date,
    { organizationId, articleId },
  );
}

export function callTopContributorsAPI(
  date,
  { organizationId, articleId },
) {
  return callAnalyticsAPI(
    '/api/analytics/top_contributors',
    date,
    { organizationId, articleId },
  );
}

export function callFollowerEngagementAPI(
  date,
  { organizationId },
) {
  return callAnalyticsAPI(
    '/api/analytics/follower_engagement',
    date,
    { organizationId },
  );
}

// Bundled endpoint that returns historical + totals + referrers +
// top_contributors + follower_engagement in a single response. Used by the
// analytics dashboard to avoid issuing 5 parallel GETs (which systematically
// tripped the Rack::Attack api_throttle of 3 requests/sec per IP and caused
// "Failed to fetch chart data" errors in production).
export function callDashboardAPI(
  date,
  { organizationId, articleId } = {},
) {
  return callAnalyticsAPI(
    '/api/analytics/dashboard',
    date,
    { organizationId, articleId },
  );
}
