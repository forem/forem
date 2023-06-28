import { getCSRFToken } from './csrfToken';

/**
 * Generic request with all the default headers required by the application.
 *
 * @example
 * import { request } from '@utilities/http';
 *
 * const response = await request('/notification_subscriptions/Article/26')
 *
 * Note:
 * The body option will typically be passed in as a JavaScript object.
 * A check is performed for this and automatically convert it to JSON if necessary.
 *
 * Requests send JSON by default but this can be easily overridden by adding
 * the Accept and Content-Type headers to the request options.
 *
 * The default method is GET.
 *
 * @param {string} url The URL to make the request to.
 * @param {RequestInit} [options={}] The request options.
 *
 * @return {Promise<Response>} the response
 */
export async function request(url, options = {}) {
  const {
    headers,
    body,
    method = 'GET',
    csrfToken = await getCSRFToken(),
    // These are any other options that might be passed in e.g. keepalive
    ...restOfOptions
  } = options;

  // There should never be a scenario where null is passed as the body,
  // but if ever there is, this logic should change.
  const jsonifiedBody = {
    body: body && typeof body !== 'string' ? JSON.stringify(body) : body,
  };

  const fetchOptions = {
    method,
    headers: {
      Accept: 'application/json',
      'X-CSRF-Token': csrfToken,
      'Content-Type': 'application/json',
      ...headers,
    },
    credentials: 'same-origin',
    ...jsonifiedBody,
    ...restOfOptions,
  };

  return fetch(url, fetchOptions);
}
