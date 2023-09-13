import fetch from 'jest-fetch-mock';
import '@testing-library/jest-dom';

import { asyncUserStatusCheck } from '../packs/asyncUserStatusCheck';

global.fetch = fetch;

function fakeUserIsSuspended() {
  return JSON.stringify({
    id: 123,
    username: 'user123',
    suspended: true,
  });
}

function fakeUserNotSuspended() {
  return JSON.stringify({
    id: 123,
    username: 'user123',
  });
}

describe('asyncUserStatusCheck', () => {
  beforeEach(() => {
    global.Honeybadger = { notify: jest.fn() };

    fetch.resetMocks();

    window.document.body.innerHTML = `
    <div class="profile-header__details" data-url="/users/123">
      <div class="js-username-container">
        <h1 class="crayons-title">User Hasaname</h1>
      </div>
      <p class="">Animi et qui. Voluptatum voluptas omnis. Libero voluptatem cum. Unde.</p>

      <div class="profile-header__meta">
      </div>
    </div>
    `;
  });

  describe('user is **NOT** suspended', () => {
    beforeEach(() => {
      fetch.mockResponse(fakeUserNotSuspended());
    });

    it('uses fetch to retrieve data async', async () => {
      await asyncUserStatusCheck();
      expect(fetch).toHaveBeenCalledWith('/users/123');
    });

    it('does not badge the user', async () => {
      await asyncUserStatusCheck();
      expect(document.body.innerHTML).toMatchSnapshot();
      expect(document.body.innerHTML).not.toMatch(/Suspended/);
    });
  });

  describe('user **is** suspended', () => {
    beforeEach(() => {
      fetch.mockResponse(fakeUserIsSuspended());
    });

    it('uses fetch to retrieve data async', async () => {
      await asyncUserStatusCheck();
      expect(fetch).toHaveBeenCalledWith('/users/123');
    });

    it('**does** badge the user', async () => {
      await asyncUserStatusCheck();
      expect(document.body.innerHTML).toMatchSnapshot();
      expect(document.body.innerHTML).toMatch(/Suspended/);
    });
  });
});
