import { checkUserLoggedIn } from '@utilities/checkUserLoggedIn';

describe('CheckUserLoggedIn Utility', () => {
  it('should return false if no body', () => {
    const userLoggedIn = checkUserLoggedIn();
    expect(userLoggedIn).toEqual(false);
  });

  it('should return true if user has the logged in attribute', () => {
    document.body.setAttribute('data-user-status', 'logged-in');
    const userLoggedIn = checkUserLoggedIn();
    expect(userLoggedIn).toEqual(true);
  });
});
