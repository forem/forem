import { getCSRFToken } from '@utilities/http/csrfToken';

describe('getCSRFToken', () => {
  it('should resolve with the CSRF token when there is a meta tag', async () => {
    document.head.innerHTML = `<meta name="csrf-token" content="this-is-a-csrf-token"></head>`;

    const data = await getCSRFToken();
    expect(data).toBe('this-is-a-csrf-token');
  });

  // [@ridhwana] It was proving to be really difficult to test the error case
  // since there are timers and max retries on setInterval, and I was
  // struggling to achieve the scenario with jest timers.
});
