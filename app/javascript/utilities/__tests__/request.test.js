import fetch from 'jest-fetch-mock';
import { request } from '@utilities';

/* global globalThis */
describe('request', () => {
  const csrfToken = 'this-is-a-bad-csrf-token';

  beforeAll(() => {
    globalThis.fetch = fetch;
    window.csrfToken = csrfToken;
  });
  afterAll(() => {
    delete globalThis.fetch;
    delete window.csrfToken;
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

  it('should make a POST request', async () => {});
});
