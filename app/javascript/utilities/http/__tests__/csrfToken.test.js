import { getCSRFToken } from '@utilities/http/csrfToken';

document.head.innerHTML = `<meta name="csrf-token" content="this-is-a-csrf-token"></head>`;

describe('getCSRFToken', () => {
  it('should return a resolved Promise with the CSRF token', async () => {
    const data = await getCSRFToken();
    expect(data).toBe('this-is-a-csrf-token');
  });
});
