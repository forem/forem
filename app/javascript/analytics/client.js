import { handleFetchAPIErrors } from '../utilities/http';

function callAnalyticsAPI(path, date, { organizationId, articleId }) {
  let url = `${path}?start=${date.toISOString().split('T')[0]}`;

  if (organizationId) {
    url = `${url}&organization_id=${organizationId}`;
  }
  if (articleId) {
    url = `${url}&article_id=${articleId}`;
  }

  return fetch(url)
    .then(handleFetchAPIErrors)
    .then((response) => response.json());
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
