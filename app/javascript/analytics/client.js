import handleFetchAPIErrors from '../src/utils/errors';

export function callHistoricalAPI(
  date,
  { organizationId, articleId },
  callback,
) {
  let url = `/api/analytics/historical?start=${
    date.toISOString().split('T')[0]
  }`;

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

export function callReferrersAPI(
  date,
  { organizationId, articleId },
  callback,
) {
  let url = `/api/analytics/referrers?start=${
    date.toISOString().split('T')[0]
  }`;

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
