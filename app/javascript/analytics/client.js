import handleFetchAPIErrors from '../src/utils/errors';

function callAnalyticsAPI(path, date, { organizationId, articleId }, callback) {
  let url = `${path}?start=${date.toISOString().split('T')[0]}`;

  if (organizationId) {
    url = `${url}&organization_id=${organizationId}`;
  }
  if (articleId) {
    url = `${url}&article_id=${articleId}`;
  }

  fetch(url)
    .then(handleFetchAPIErrors)
    .then(response => response.json())
    .then(callback)
    // eslint-disable-next-line no-console
    .catch(error => console.error(error)); // we should come up with better error handling
}

export function callHistoricalAPI(
  date,
  { organizationId, articleId },
  callback,
) {
  callAnalyticsAPI(
    '/api/analytics/historical',
    date,
    { organizationId, articleId },
    callback,
  );
}

export function callReferrersAPI(
  date,
  { organizationId, articleId },
  callback,
) {
  callAnalyticsAPI(
    '/api/analytics/referrers',
    date,
    { organizationId, articleId },
    callback,
  );
}
