import {
  getUserDataAndCsrfToken,
  getUserDataAndCsrfTokenSafely,
} from '../getUserDataAndCsrfToken';

const ERROR_MESSAGE = "Couldn't find user data on page.";
const BASE_OPTIONS = { maxWaitTime: 0 };

const buildCurrentUser = () => ({
  id: 41,
  name: 'Guy Fieri',
  username: 'guyfieri',
  profile_image_90:
    '/uploads/user/profile_image/41/0841dbe2-208c-4daa-b498-b2f01f3d37b2.png',
  followed_tag_names: [],
  followed_tags: '[]',
  reading_list_ids: [48, 49, 34, 51, 64, 56],
  saw_onboarding: true,
  checked_code_of_conduct: false,
  display_sponsors: true,
  trusted: false,
});

const encodeCookieUser = (user) => {
  const serialized = typeof user === 'string' ? user : JSON.stringify(user);
  const encoded = btoa(
    encodeURIComponent(serialized).replace(/%([0-9A-F]{2})/g, (_, p1) =>
      String.fromCharCode(`0x${p1}`),
    ),
  );

  return encodeURIComponent(encoded);
};

const resetEnvironment = () => {
  document.head.innerHTML = '';
  document.body.removeAttribute('data-user');
  window.localStorage.clear();
  document.cookie =
    'current_user=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/';
};

describe('getUserDataAndCsrfToken', () => {
  beforeEach(() => {
    resetEnvironment();
  });

  afterEach(() => {
    resetEnvironment();
  });

  test('rejects if no user or csrf token found', async () => {
    await expect(getUserDataAndCsrfToken(BASE_OPTIONS)).rejects.toThrow(
      ERROR_MESSAGE,
    );
  });

  test('rejects if csrf token found but no user data', async () => {
    document.head.innerHTML =
      '<meta name="csrf-token" content="some-csrf-token" />';

    await expect(getUserDataAndCsrfToken(BASE_OPTIONS)).rejects.toThrow(
      ERROR_MESSAGE,
    );
  });

  test('rejects if user found but no csrf token found', async () => {
    document.body.setAttribute('data-user', '{}');

    await expect(getUserDataAndCsrfToken(BASE_OPTIONS)).rejects.toThrow(
      ERROR_MESSAGE,
    );
  });

  test('resolves if user and csrf token found', async () => {
    const csrfToken = 'some-csrf-token';
    const currentUser = buildCurrentUser();
    document.head.innerHTML = `<meta name="csrf-token" content="${csrfToken}" />`;
    document.body.setAttribute('data-user', JSON.stringify(currentUser));

    await expect(getUserDataAndCsrfToken(BASE_OPTIONS)).resolves.toEqual({
      currentUser,
      csrfToken,
    });
  });

  test('uses cached localStorage user data when dataset is missing', async () => {
    const csrfToken = 'cached-csrf';
    const currentUser = buildCurrentUser();
    document.head.innerHTML = `<meta name="csrf-token" content="${csrfToken}" />`;
    window.localStorage.setItem('current_user', JSON.stringify(currentUser));

    await expect(getUserDataAndCsrfToken(BASE_OPTIONS)).resolves.toEqual({
      currentUser,
      csrfToken,
    });
    expect(document.body.dataset.user).toEqual(JSON.stringify(currentUser));
  });

  test('uses cached cookie user data when dataset is missing', async () => {
    const csrfToken = 'cached-cookie-csrf';
    const currentUser = buildCurrentUser();
    document.head.innerHTML = `<meta name="csrf-token" content="${csrfToken}" />`;
    document.cookie = `current_user=${encodeCookieUser(
      JSON.stringify(currentUser),
    )}; path=/`;

    await expect(getUserDataAndCsrfToken(BASE_OPTIONS)).resolves.toEqual({
      currentUser,
      csrfToken,
    });
    expect(document.body.dataset.user).toEqual(JSON.stringify(currentUser));
  });
});

describe('getUserDataAndCsrfTokenSafely', () => {
  beforeEach(() => {
    resetEnvironment();
  });

  afterEach(() => {
    resetEnvironment();
  });

  test('resolves with null currentUser if no user or csrf token found', async () => {
    await expect(
      getUserDataAndCsrfTokenSafely(BASE_OPTIONS),
    ).resolves.toEqual({
      currentUser: null,
      csrfToken: undefined,
    });
  });
});
