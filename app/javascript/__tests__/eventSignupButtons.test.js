import '@testing-library/jest-dom';

jest.mock('../topNavigation/utilities', () => ({
  getInstantClick: jest.fn(() =>
    Promise.resolve({
      on: jest.fn(),
    }),
  ),
}));

const flushPromises = async () => {
  await Promise.resolve();
  await Promise.resolve();
  await new Promise((resolve) => setTimeout(resolve, 0));
};

const mockEventButton = ({
  name = 'test-event',
  variation = 'test-var',
  confirm = 'Are you sure?',
  signedUp = 'false',
} = {}) => `
  <button data-event-signup-button="true"
          data-event-name-slug="${name}"
          data-event-variation-slug="${variation}"
          data-signup-confirm-message="${confirm}"
          data-signed-up-class="btn-signed-up"
          data-unsigned-up-class="btn-unsigned-up"
          class="btn btn-unsigned-up"
          data-signed-up="${signedUp}">
    <template data-signed-up-html>
      <span>Signed Up!</span>
    </template>
    <template data-unsigned-up-html>
      <span>Sign Up</span>
    </template>
    <span>Sign Up</span>
  </button>
`;

describe('eventSignupButtons', () => {
  beforeEach(() => {
    if (window.eventSignupCleanup) {
      window.eventSignupCleanup();
    }
    jest.resetModules();
    document.body.innerHTML = `
      <meta name="csrf-token" content="mock-csrf-token" />
      ${mockEventButton()}
    `;
    document.body.dataset.userStatus = 'logged-in';
    document.body.removeAttribute('data-event-signup-handler-initialized');

    global.fetch = jest.fn().mockImplementation(() =>
      Promise.resolve({
        ok: true,
        json: () => Promise.resolve({ signed_up: false }),
      })
    );
    global.showLoginModal = jest.fn();
    window.confirm = jest.fn(() => true);
  });

  afterEach(() => {
    if (window.eventSignupCleanup) {
      window.eventSignupCleanup();
    }
    delete global.fetch;
    delete global.showLoginModal;
    delete window.confirm;
  });

  it('sets state to unsigned up without fetching if user is logged out', async () => {
    document.body.dataset.userStatus = 'logged-out';

    require('../packs/eventSignupButtons');
    await flushPromises();

    expect(global.fetch).not.toHaveBeenCalled();
    const button = document.querySelector('[data-event-signup-button]');
    expect(button.getAttribute('data-signed-up')).toBe('false');
    expect(button).toHaveTextContent('Sign Up');
  });

  it('fetches status and updates UI if user is logged in', async () => {
    global.fetch.mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve({ signed_up: true }),
    });

    require('../packs/eventSignupButtons');
    await flushPromises();

    expect(global.fetch).toHaveBeenCalledWith('/events/test-event/test-var/signup_status', expect.any(Object));
    const button = document.querySelector('[data-event-signup-button]');
    expect(button.getAttribute('data-signed-up')).toBe('true');
    expect(button.classList.contains('btn-signed-up')).toBe(true);
    expect(button.classList.contains('btn-unsigned-up')).toBe(false);
    expect(button.querySelector('span')).toHaveTextContent('Signed Up!');
  });

  it('handles click to sign up when user is logged in', async () => {
    // Initial load fetch
    global.fetch.mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve({ signed_up: false }),
    });

    require('../packs/eventSignupButtons');
    await flushPromises();

    const button = document.querySelector('[data-event-signup-button]');
    expect(button.getAttribute('data-signed-up')).toBe('false');

    // Click handler POST call
    global.fetch.mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve({ signed_up: true }),
    });

    button.click();
    expect(button.disabled).toBe(true);
    await flushPromises();

    expect(global.fetch).toHaveBeenLastCalledWith(
      '/events/test-event/test-var/signup.json',
      expect.objectContaining({
        method: 'POST',
        headers: expect.objectContaining({
          'X-CSRF-Token': 'mock-csrf-token',
        }),
      }),
    );
    expect(button.disabled).toBe(false);
    expect(button.getAttribute('data-signed-up')).toBe('true');
    expect(button.querySelector('span')).toHaveTextContent('Signed Up!');
  });

  it('handles click to unregister (with confirmation) when user is logged in', async () => {
    // Initial load fetch returns signed_up: true
    global.fetch.mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve({ signed_up: true }),
    });

    require('../packs/eventSignupButtons');
    await flushPromises();

    const button = document.querySelector('[data-event-signup-button]');
    expect(button.getAttribute('data-signed-up')).toBe('true');

    // Click handler DELETE call
    global.fetch.mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve({ signed_up: false }),
    });

    button.click();
    expect(window.confirm).toHaveBeenCalledWith('Are you sure?');
    await flushPromises();

    expect(global.fetch).toHaveBeenLastCalledWith(
      '/events/test-event/test-var/signup.json',
      expect.objectContaining({
        method: 'DELETE',
      }),
    );
    expect(button.getAttribute('data-signed-up')).toBe('false');
  });

  it('aborts unregistering if confirmation is declined', async () => {
    window.confirm = jest.fn(() => false);

    global.fetch.mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve({ signed_up: true }),
    });

    require('../packs/eventSignupButtons');
    await flushPromises();

    const button = document.querySelector('[data-event-signup-button]');
    button.click();

    expect(window.confirm).toHaveBeenCalledWith('Are you sure?');
    expect(global.fetch).not.toHaveBeenCalledTimes(2); // Only the initial load fetch
    expect(button.getAttribute('data-signed-up')).toBe('true');
  });

  it('calls showLoginModal on click if user is logged out', async () => {
    document.body.dataset.userStatus = 'logged-out';

    require('../packs/eventSignupButtons');
    await flushPromises();

    const button = document.querySelector('[data-event-signup-button]');
    button.click();

    expect(global.showLoginModal).toHaveBeenCalledWith({ trigger: 'event_signup_button' });
    expect(global.fetch).not.toHaveBeenCalled();
  });
});
