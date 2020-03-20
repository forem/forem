// TODO: We should really be using the xss package by installing it in package.json
// but for now filterXSS is global because of legacy JS

function getParameterByName(name, url = window.location.href) {
  const sanitizedName = name.replace(/[[\]]/g, '\\$&');
  const regex = new RegExp(`[?&]${sanitizedName}(=([^&#]*)|&|#|$)`);
  const results = regex.exec(url);

  if (!results) {
    return null;
  }

  if (!results[2]) {
    return '';
  }

  return decodeURIComponent(results[2].replace(/\+/g, ' '));
}

function getFilterParameters(url) {
  const filters = getParameterByName('filters', url);

  if (filters) {
    return `&filters=${filters}`;
  }

  return '';
}

export const hasInstantClick = () => typeof instantClick !== 'undefined';

function fixedEncodeURIComponent(str) {
  // from https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURIComponent
  return encodeURIComponent(str).replace(
    /[!'()*]/g,
    c => `%${c.charCodeAt(0).toString(16)}`,
  );
}

export function displaySearchResults({
  searchTerm,
  location = window.location,
}) {
  const baseUrl = location.origin;
  const sanitizedQuery = fixedEncodeURIComponent(searchTerm);
  const filterParameters = getFilterParameters(location.href);

  InstantClick.display(
    `${baseUrl}/search?search_fields=${sanitizedQuery}${filterParameters}`,
  );
}

export function getInitialSearchTerm(querystring) {
  const matches = /(?:&|\?)?search_fields=([^&=]+)/.exec(querystring);
  const rawSearchTerm =
    matches !== null && matches.length === 2
      ? decodeURIComponent(matches[1].replace(/\+/g, '%20'))
      : '';
  const query = filterXSS(rawSearchTerm);
  const divForDecode = document.createElement('div');
  divForDecode.innerHTML = query;

  return divForDecode.firstChild !== null
    ? divForDecode.firstChild.nodeValue
    : query;
}

export function preloadSearchResults({
  searchTerm,
  location = window.location,
}) {
  const encodedQuery = fixedEncodeURIComponent(
    searchTerm.replace(/^[ ]+|[ ]+$/g, ''),
  );
  InstantClick.preload(
    `${
      location.origin
    }/search?search_fields=${encodedQuery}${getFilterParameters(
      location.href,
    )}`,
  );
}

/**
 * A helper method to call /search endpoints.
 *
 * @param {string} endpoint - The search endpoint you want to request (i.e. tags).
 * @param {object} dataHash - A hash with the search params that need to be included in the request.
 *
 * @returns {Promise} A promise object with response formatted as JSON.
 */
export function fetchSearch(endpoint, dataHash) {
  const searchParams = new URLSearchParams(dataHash).toString();

  return fetch(`/search/${endpoint}?${searchParams}`, {
    method: 'GET',
    headers: {
      Accept: 'application/json',
      'X-CSRF-Token': window.csrfToken,
      'Content-Type': 'application/json',
    },
    credentials: 'same-origin',
  }).then(response => response.json());
}
