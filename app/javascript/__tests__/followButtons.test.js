import '@testing-library/jest-dom';
import {
  FOLLOW_BUTTON_STATUS_CACHE_KEY,
} from '../utilities/followButtonStatusCache';

jest.mock('../topNavigation/utilities', () => ({
  getInstantClick: jest.fn(() =>
    Promise.resolve({
      on: jest.fn(),
    }),
  ),
}));

jest.mock('../utilities/waitOnBaseData', () => ({
  waitOnBaseData: jest.fn(() => Promise.resolve()),
}));

const flushPromises = async () => {
  await Promise.resolve();
  await Promise.resolve();
  await new Promise((resolve) => setTimeout(resolve, 0));
};

const bulkFollowButton = ({ id = 42, name = 'Sloan', style = 'default' } = {}) =>
  `<div data-follow-button-container>
    <button
      class="crayons-btn whitespace-nowrap follow-action-button follow-user"
      data-info='{"id":${id},"className":"User","name":"${name}","style":"${style}"}'
    >
      Follow
    </button>
  </div>`;

describe('followButtons', () => {
  beforeEach(() => {
    jest.resetModules();
    window.localStorage.clear();
    document.head.innerHTML = '';
    document.body.innerHTML = `
      <div
        id="i18n-translations"
        data-translations='{"en":{"core":{"follow":"Follow","follow_back":"Follow back","following":"Following","edit_profile":"Edit profile"}}}'
      ></div>
      ${bulkFollowButton()}
    `;
    document.body.dataset.userStatus = 'logged-in';
    document.body.dataset.loaded = 'true';
    document.body.dataset.locale = 'en';
    document.body.removeAttribute('data-follow-handler-initialized');

    global.fetch = jest.fn();
    global.browserStoreCache = jest.fn();
    global.showLoginModal = jest.fn();
    global.showModalAfterError = jest.fn();
    global.userData = jest.fn(() => ({ followed_tags: '[]' }));
    global.getCsrfToken = jest.fn(() => Promise.resolve('csrf-token'));
    global.sendFetch = jest.fn(() => jest.fn(() => Promise.resolve({ status: 200 })));
  });

  afterEach(() => {
    delete global.browserStoreCache;
    delete global.fetch;
    delete global.getCsrfToken;
    delete global.sendFetch;
    delete global.showLoginModal;
    delete global.showModalAfterError;
    delete global.userData;
    window.localStorage.clear();
  });

  it('shows a cached non-default status immediately, then swaps to the fetched default state', async () => {
    window.localStorage.setItem(
      FOLLOW_BUTTON_STATUS_CACHE_KEY,
      JSON.stringify({
        'User:42': { status: 'mutual', updatedAt: Date.now() },
      }),
    );

    let resolveFetch;
    global.fetch.mockImplementation(
      () =>
        new Promise((resolve) => {
          resolveFetch = resolve;
        }),
    );

    require('../packs/followButtons');

    const button = document.querySelector('.follow-action-button');
    await flushPromises();
    expect(button).toHaveTextContent('Following');

    resolveFetch({
      json: () =>
        Promise.resolve({
          42: 'false',
        }),
    });

    await flushPromises();

    expect(button).toHaveTextContent('Follow');
    expect(window.localStorage.getItem(FOLLOW_BUTTON_STATUS_CACHE_KEY)).toBeNull();
  });

  it('clears the cached follow status when a follow button is clicked', async () => {
    global.fetch.mockResolvedValue({
      json: () =>
        Promise.resolve({
          42: 'false',
        }),
    });

    require('../packs/followButtons');
    const button = document.querySelector('.follow-action-button');
    await flushPromises();

    // Simulate a cache entry that might exist from a previous page load
    window.localStorage.setItem(
      FOLLOW_BUTTON_STATUS_CACHE_KEY,
      JSON.stringify({
        'User:42': { status: 'mutual', updatedAt: Date.now() },
      }),
    );

    expect(window.localStorage.getItem(FOLLOW_BUTTON_STATUS_CACHE_KEY)).not.toBeNull();

    button.click();

    // After clicking, the cache entry for this followable should have been removed
    // to prevent stale state on the next page load
    const cacheAfterClick = window.localStorage.getItem(FOLLOW_BUTTON_STATUS_CACHE_KEY);
    expect(cacheAfterClick === null || !JSON.parse(cacheAfterClick)['User:42']).toBe(true);

    await flushPromises();
  });
});
