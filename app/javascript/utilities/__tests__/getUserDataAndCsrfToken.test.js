import {
  getUserDataAndCsrfToken,
  getUserDataAndCsrfTokenSafely,
} from '../getUserDataAndCsrfToken';

const ERROR_MESSAGE = "Couldn't find user data on page.";

describe('getUserDataAndCsrfToken', () => {
  afterEach(() => {
    document.head.innerHTML = '';
    document.body.removeAttribute('data-user');
  });

  test('should reject if no user or csrf token found.', async () => {
    await expect(getUserDataAndCsrfToken(document)).rejects.toThrow(
      ERROR_MESSAGE,
    );
  });

  test('should reject if csrf token found but no user.', async () => {
    document.head.innerHTML =
      '<meta name="csrf-token" content="some-csrf-token" />';
    await expect(getUserDataAndCsrfToken(document)).rejects.toThrow(
      ERROR_MESSAGE,
    );
  });

  test('should reject if user found but no csrf token found.', async () => {
    document.body.setAttribute('data-user', '{}');
    await expect(getUserDataAndCsrfToken(document)).rejects.toThrow(
      ERROR_MESSAGE,
    );
  });

  test('should resolve if user and csrf token found.', async () => {
    const csrfToken = 'some-csrf-token';
    const currentUser = {
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
    };
    document.head.innerHTML = `<meta name="csrf-token" content="${csrfToken}" />`;
    document.body.setAttribute('data-user', JSON.stringify(currentUser));

    expect(await getUserDataAndCsrfToken(document)).toEqual({
      currentUser,
      csrfToken,
    });
  });
});

describe('getUserDataAndCsrfTokenSafely', () => {
  afterEach(() => {
    document.head.innerHTML = '';
    document.body.removeAttribute('data-user');
  });

  test('should not reject if no user or csrf token found.', async () => {
    await expect(getUserDataAndCsrfTokenSafely(document)).resolves.toEqual(
      expect.anything(),
    );
  });
});
