// TODO: We should really be using the xss package by installing it in package.json
// but for now filterXSS is global because of legacy JS

import { request } from '../http';

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

function getParameters(name, url) {
  const params = getParameterByName(name, url);

  if (params) {
    return `&${name}=${params}`;
  }

  return '';
}

function getFilterParameters(url) {
  return getParameters('filters', url);
}

function getSortParameters(url) {
  const sortBy = getParameters('sort_by', url);
  const sortDirection = getParameters('sort_direction', url);

  return sortBy + sortDirection;
}

export const hasInstantClick = () => typeof instantClick !== 'undefined';

function fixedEncodeURIComponent(str) {
  // from https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURIComponent
  return encodeURIComponent(str).replace(
    /[!'()*]/g,
    (c) => `%${c.charCodeAt(0).toString(16)}`,
  );
}

export function displaySearchResults({
  searchTerm,
  location = window.location,
}) {
  const baseUrl = location.origin;
  const sanitizedQuery = fixedEncodeURIComponent(searchTerm);
  const filterParameters = getFilterParameters(location.href);
  const sortParameters = getSortParameters(location.href);

  InstantClick.display(
    `${baseUrl}/search?q=${sanitizedQuery}${filterParameters}${sortParameters}`,
  );
}

export function getInitialSearchTerm(querystring) {
  const matches = /(?:&|\?)?q=([^&=]+)/.exec(querystring);
  const rawSearchTerm =
    matches !== null && matches.length === 2
      ? decodeURIComponent(matches[1].replace(/\+/g, '%20'))
      : '';
  const query = filterXSS(rawSearchTerm) || '';
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
  const searchUrl = `${
    location.origin
  }/search?q=${encodedQuery}${getFilterParameters(location.href)}`;
  InstantClick.preload(searchUrl);
}

export function createSearchUrl(dataHash) {
  const searchParams = new URLSearchParams();
  Object.keys(dataHash).forEach((key) => {
    const value = dataHash[key];
    if (Array.isArray(value)) {
      value.forEach((arrayValue) => {
        searchParams.append(`${key}[]`, arrayValue);
      });
    } else {
      searchParams.append(key, value);
    }
  });

  return searchParams.toString();
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
  const searchUrl = createSearchUrl(dataHash);

  return request(`/search/${endpoint}?${searchUrl}`).then((response) =>
    response.json(),
  );
}
