import fetch from 'jest-fetch-mock';
import { request } from '@utilities/http';

const csrfToken = 'this-is-a-csrf-token';
jest.mock('../csrfToken', () => ({
  getCSRFToken: jest.fn(() => Promise.resolve(csrfToken)),
}));

// NOTE: Everything that native fetch in the browser does, e.g. CREATE, DELETE etc. could be tested here, but that is pointless.
// The tests below are really just to check the functionality that request offers on top of native fetch.

/* global globalThis */
describe('request', () => {
  beforeAll(() => {
    globalThis.fetch = fetch;
  });

  afterAll(() => {
    delete globalThis.fetch;
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('should make a GET request', async () => {
    const url = '/listings/forsale';

    await request(url);

    expect(fetch).toHaveBeenCalledWith(url, {
      credentials: 'same-origin',
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
      },
      method: 'GET',
    });
  });

  it('should make a GET request with query string parameters', async () => {
    const url = '/listings/mentees?t=help';

    await request(url);

    expect(fetch).toHaveBeenCalledWith(url, {
      credentials: 'same-origin',
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
      },
      method: 'GET',
    });
  });

  it('should make a POST request', async () => {
    const url = '/notification_subscriptions/Article/26';
    const jsonifiedBody = JSON.stringify({ config: 'all_comments' });
    await request(url, {
      method: 'POST',
      body: jsonifiedBody,
    });

    expect(fetch).toHaveBeenCalledWith(url, {
      credentials: 'same-origin',
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
      },
      method: 'POST',
      body: jsonifiedBody,
    });
  });

  it('should convert body property in options to JSON if it is a JavaScript object', async () => {
    const url = '/notification_subscriptions/Article/26';
    const body = { config: 'all_comments' };
    const jsonifiedBody = JSON.stringify(body);
    await request(url, {
      method: 'POST',
      body,
    });

    expect(fetch).toHaveBeenCalledWith(url, {
      credentials: 'same-origin',
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
      },
      method: 'POST',
      body: jsonifiedBody,
    });
  });

  it('should override application headers if they are passed in as part of the headers property of request options', async () => {
    const defaultHeaderOverrides = {
      Accept: 'text/html',
      'Content-Type':
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'X-CSRF-Token': 'a-different-csrf-token',
    };

    const url = '/notification_subscriptions/Article/26';
    const body = { config: 'all_comments' };
    const jsonifiedBody = JSON.stringify(body);
    await request(url, {
      method: 'POST',
      body,
      headers: defaultHeaderOverrides,
    });

    expect(fetch).toHaveBeenCalledWith(url, {
      credentials: 'same-origin',
      headers: defaultHeaderOverrides,
      method: 'POST',
      body: jsonifiedBody,
    });
  });

  it('should add additional options that are present in the default options', async () => {
    const url = '/notification_subscriptions/Article/26';
    const body = { config: 'all_comments' };
    const jsonifiedBody = JSON.stringify(body);
    await request(url, {
      method: 'POST',
      body,
      headers: {
        'keep-alive': true,
      },
    });

    expect(fetch).toHaveBeenCalledWith(url, {
      credentials: 'same-origin',
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
        'keep-alive': true,
      },
      method: 'POST',
      body: jsonifiedBody,
    });
  });
});
