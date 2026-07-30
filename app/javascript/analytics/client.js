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

function formatDateParam(val) {
  if (!val) return null;
  if (val instanceof Date) {
    return val.toISOString().split('T')[0];
  }
  return String(val);
}

function callAnalyticsAPI(path, dateOrOpts, endDateOrCtx, contextOpts = {}) {
  let startDate = null;
  let endDate = null;
  let context = {};

  if (dateOrOpts && typeof dateOrOpts === 'object' && !(dateOrOpts instanceof Date)) {
    startDate = dateOrOpts.start || dateOrOpts.startDate;
    endDate = dateOrOpts.end || dateOrOpts.endDate;
    context = dateOrOpts;
  } else {
    startDate = dateOrOpts;
    if (endDateOrCtx instanceof Date || typeof endDateOrCtx === 'string') {
      endDate = endDateOrCtx;
      context = contextOpts || {};
    } else if (endDateOrCtx && typeof endDateOrCtx === 'object') {
      context = endDateOrCtx;
    }
  }

  const formattedStart = formatDateParam(startDate);
  let url = `${path}?start=${formattedStart}`;

  const formattedEnd = formatDateParam(endDate);
  if (formattedEnd) {
    url = `${url}&end=${formattedEnd}`;
  }

  if (context.organizationId) {
    url = `${url}&organization_id=${context.organizationId}`;
  }
  if (context.articleId) {
    url = `${url}&article_id=${context.articleId}`;
  }

  return withRetry(() =>
    fetch(url)
      .then(handleFetchAPIErrors)
      .then((response) => response.json()),
  );
}

export function callHistoricalAPI(
  date,
  { organizationId, articleId } = {},
) {
  return callAnalyticsAPI(
    '/api/analytics/historical',
    date,
    { organizationId, articleId },
  );
}

export function callReferrersAPI(
  date,
  { organizationId, articleId } = {},
) {
  return callAnalyticsAPI(
    '/api/analytics/referrers',
    date,
    { organizationId, articleId },
  );
}

export function callTotalsAPI(
  date,
  { organizationId, articleId } = {},
) {
  return callAnalyticsAPI(
    '/api/analytics/totals',
    date,
    { organizationId, articleId },
  );
}

export function callTopContributorsAPI(
  date,
  { organizationId, articleId } = {},
) {
  return callAnalyticsAPI(
    '/api/analytics/top_contributors',
    date,
    { organizationId, articleId },
  );
}

export function callFollowerEngagementAPI(
  date,
  { organizationId } = {},
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
  dateOrOpts,
  endDateOrCtx,
  contextOpts,
) {
  return callAnalyticsAPI(
    '/api/analytics/dashboard',
    dateOrOpts,
    endDateOrCtx,
    contextOpts,
  );
}
