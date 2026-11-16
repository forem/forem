jest.mock('../../utilities/billboardInteractivity', () => ({
  setupBillboardInteractivity: jest.fn(),
}));

jest.mock('../../utilities/gist', () => ({
  embedGists: jest.fn(),
}));

const EMBED_HTML = `
  <div class="ltag__page ltag__page--article js-page-embed">
    <div class="ltag__page-card">
      <div class="ltag__page-viewport"><iframe title="Embed"></iframe></div>
      <div class="ltag__page-footer">
        <button
          type="button"
          class="js-fullscreen-page-action"
          aria-expanded="false"
          data-enter-label="Enter fullscreen mode"
          data-exit-label="Exit fullscreen mode"
        ></button>
      </div>
    </div>
  </div>
`;

describe('articlePage pack', () => {
  beforeEach(() => {
    jest.resetModules();
    delete document.documentElement.dataset.pageEmbedFullscreenBound;
    delete document.documentElement.dataset.imageLightboxInit;
    document.body.style.overflow = '';
    window.scrollTo = jest.fn();
    global.IntersectionObserver = jest.fn(() => ({
      observe: jest.fn(),
      unobserve: jest.fn(),
    }));
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  // Draft previews render no share button, comments section or bottom content.
  it('loads without throwing when article chrome is missing', () => {
    document.body.innerHTML = `${EMBED_HTML}${EMBED_HTML}`;

    expect(() => {
      jest.isolateModules(() => {
        require('../articlePage');
      });
    }).not.toThrow();
  });

  it('wires up fullscreen for every page embed when article chrome is missing', () => {
    document.body.innerHTML = `${EMBED_HTML}${EMBED_HTML}`;

    jest.isolateModules(() => {
      require('../articlePage');
    });

    const embeds = document.querySelectorAll('.js-page-embed');
    const buttons = document.querySelectorAll('.js-fullscreen-page-action');

    buttons[1].click();
    expect(embeds[1].classList.contains('is-fullscreen')).toBe(true);
    expect(embeds[0].classList.contains('is-fullscreen')).toBe(false);

    buttons[1].click();
    expect(embeds[1].classList.contains('is-fullscreen')).toBe(false);

    buttons[0].click();
    expect(embeds[0].classList.contains('is-fullscreen')).toBe(true);
  });
});
