import '@testing-library/jest-dom';

const mockGetUserDataAndCsrfTokenSafely = jest.fn();

jest.mock('@utilities/dropdownUtils', () => ({
  initializeDropdown: jest.fn(),
}));

jest.mock('@utilities/getUserDataAndCsrfToken', () => ({
  getUserDataAndCsrfTokenSafely: () => mockGetUserDataAndCsrfTokenSafely(),
}));

jest.mock('../profileDropdown/blockButton', () => ({
  initBlock: jest.fn(),
}));

jest.mock('../profileDropdown/flagButton', () => ({
  initFlag: jest.fn(),
}));

jest.mock('../profileDropdown/spamButton', () => ({
  initSpam: jest.fn(),
}));

describe('profile admin links', () => {
  beforeEach(() => {
    jest.resetModules();
  });

  it('shows the admin link in the user profile dropdown only for admins', async () => {
    global.userData = jest.fn(() => ({ username: 'another-user' }));
    document.body.innerHTML = `
      <div class="profile-dropdown" data-username="target-user">
        <button id="user-profile-dropdown"></button>
        <div id="user-profile-dropdownmenu">
          <span class="admin-link-wrapper" data-path="/admin/users/1" data-text="Admin"></span>
          <span class="report-abuse-link-wrapper" data-path="/report-abuse?url=/target-user"></span>
        </div>
      </div>
    `;

    mockGetUserDataAndCsrfTokenSafely.mockResolvedValueOnce({
      currentUser: { admin: true },
    });

    jest.isolateModules(() => {
      require('../packs/profileDropdown');
    });
    await Promise.resolve();

    expect(document.querySelector('.admin-link-wrapper')).toHaveTextContent('Admin');

    document.body.innerHTML = `
      <div class="profile-dropdown" data-username="target-user">
        <button id="user-profile-dropdown"></button>
        <div id="user-profile-dropdownmenu">
          <span class="admin-link-wrapper" data-path="/admin/users/1" data-text="Admin"></span>
          <span class="report-abuse-link-wrapper" data-path="/report-abuse?url=/target-user"></span>
        </div>
      </div>
    `;

    mockGetUserDataAndCsrfTokenSafely.mockResolvedValueOnce({
      currentUser: { admin: false },
    });

    jest.isolateModules(() => {
      require('../packs/profileDropdown');
    });
    await Promise.resolve();

    expect(document.querySelector('.admin-link-wrapper')).toBeEmptyDOMElement();
  });

  it('shows the admin link in the organization profile dropdown only for admins', async () => {
    document.body.innerHTML = `
      <div class="profile-dropdown">
        <button id="organization-profile-dropdown"></button>
        <div id="organization-profile-dropdownmenu">
          <span class="admin-link-wrapper" data-path="/admin/organizations/1" data-text="Admin"></span>
          <span class="report-abuse-link-wrapper" data-path="/report-abuse?url=/orgs/1"></span>
        </div>
      </div>
    `;

    mockGetUserDataAndCsrfTokenSafely.mockResolvedValueOnce({
      currentUser: { admin: true },
    });

    jest.isolateModules(() => {
      require('../packs/organizationDropdown');
    });
    await Promise.resolve();

    expect(document.querySelector('.admin-link-wrapper')).toHaveTextContent('Admin');

    document.body.innerHTML = `
      <div class="profile-dropdown">
        <button id="organization-profile-dropdown"></button>
        <div id="organization-profile-dropdownmenu">
          <span class="admin-link-wrapper" data-path="/admin/organizations/1" data-text="Admin"></span>
          <span class="report-abuse-link-wrapper" data-path="/report-abuse?url=/orgs/1"></span>
        </div>
      </div>
    `;

    mockGetUserDataAndCsrfTokenSafely.mockResolvedValueOnce({
      currentUser: { admin: false },
    });

    jest.isolateModules(() => {
      require('../packs/organizationDropdown');
    });
    await Promise.resolve();

    expect(document.querySelector('.admin-link-wrapper')).toBeEmptyDOMElement();
  });
});
