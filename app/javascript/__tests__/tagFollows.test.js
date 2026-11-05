import '@testing-library/jest-dom';
import { mountTagButtons } from '../packs/tagFollows';

describe('tagFollows mountTagButtons', () => {
  beforeEach(() => {
    document.body.innerHTML = `
      <div id="snack-zone"></div>
      <div id="tag-buttons-7" class="mt-auto flex items-end justify-between">
        <div class="flex gap-2">
          <button class="c-btn c-btn--primary js-follow-tag-button">Follow</button>
          <button class="c-btn js-hide-tag-button">Hide</button>
        </div>
        <img src="/badge.png" class="tag-card__badge" alt="" />
      </div>
    `;
    window.csrfToken = 'test-csrf';
    global.browserStoreCache = jest.fn();
    global.fetch = jest.fn(() => Promise.resolve({ ok: true }));
  });

  afterEach(() => {
    delete global.browserStoreCache;
    delete global.fetch;
  });

  it('preserves the sibling tag badge image on initial render and after toggling follow/hide', async () => {
    const container = document.getElementById('tag-buttons-7');

    mountTagButtons(container, {
      id: '7',
      name: 'javascript',
      isFollowing: false,
      isHidden: false,
    });

    expect(container.querySelector('.tag-card__badge')).toBeInTheDocument();
    const followBtn = container.querySelector(
      'button[aria-label="Follow tag: javascript"]',
    );
    expect(followBtn).toHaveTextContent('Follow');

    followBtn.click();
    await Promise.resolve();
    await Promise.resolve();

    expect(container.querySelector('.tag-card__badge')).toBeInTheDocument();
    expect(
      container.querySelector('button[aria-label="Following tag: javascript"]'),
    ).toHaveTextContent('Following');
    expect(document.getElementById('snack-zone')).toHaveTextContent(
      'You have followed javascript.',
    );
  });
});
