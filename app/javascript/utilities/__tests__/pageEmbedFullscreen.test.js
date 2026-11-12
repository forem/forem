import {
  initializePageEmbedFullscreen,
  isPageEmbedFullscreenOpen,
  exitPageEmbedFullscreen,
} from '@utilities/pageEmbedFullscreen';

describe('pageEmbedFullscreen utility', () => {
  let root;
  let embed;
  let iframe;
  let button;

  beforeEach(() => {
    globalThis.scrollTo = jest.fn();
    Object.defineProperty(globalThis, 'scrollY', {
      value: 320,
      writable: true,
      configurable: true,
    });

    document.body.style.overflow = '';
    document.body.innerHTML = `
      <div id="article-root">
        <div class="ltag__page ltag__page--article js-page-embed">
          <div class="ltag__page-card">
            <div class="ltag__page-viewport">
              <iframe src="https://example.test/alice/embed/demo?mode=embed" title="Demo"></iframe>
            </div>
            <div class="ltag__page-footer">
              <button
                type="button"
                class="ltag__page-fullscreen-btn js-fullscreen-page-action"
                aria-expanded="false"
                aria-label="Enter fullscreen mode"
                title="Enter fullscreen mode"
                data-enter-label="Enter fullscreen mode"
                data-exit-label="Exit fullscreen mode"
              ></button>
            </div>
          </div>
        </div>
      </div>
    `;

    root = document.getElementById('article-root');
    embed = root.querySelector('.js-page-embed');
    iframe = root.querySelector('iframe');
    button = root.querySelector('.js-fullscreen-page-action');

    embed.getBoundingClientRect = () => ({ height: 642 });
    initializePageEmbedFullscreen(root);
    // Calling initialize twice on the same root should be idempotent
    initializePageEmbedFullscreen(root);
  });

  afterEach(() => {
    exitPageEmbedFullscreen({ restoreScroll: false, restoreFocus: false });
  });

  it('toggles fullscreen in-place without replacing or reloading the iframe element', () => {
    expect(isPageEmbedFullscreenOpen()).toBe(false);

    button.click();

    expect(isPageEmbedFullscreenOpen()).toBe(true);
    expect(embed.classList.contains('is-fullscreen')).toBe(true);
    expect(embed.style.minHeight).toBe('642px');
    expect(document.body.style.overflow).toBe('hidden');
    expect(button.getAttribute('aria-expanded')).toBe('true');
    expect(button.getAttribute('aria-label')).toBe('Exit fullscreen mode');
    expect(button.getAttribute('title')).toBe('Exit fullscreen mode');
    expect(root.querySelector('iframe')).toBe(iframe);

    button.click();

    expect(isPageEmbedFullscreenOpen()).toBe(false);
    expect(embed.classList.contains('is-fullscreen')).toBe(false);
    expect(embed.style.minHeight).toBe('');
    expect(document.body.style.overflow).toBe('');
    expect(button.getAttribute('aria-expanded')).toBe('false');
    expect(button.getAttribute('aria-label')).toBe('Enter fullscreen mode');
    expect(globalThis.scrollTo).toHaveBeenCalledWith(0, 320);
    expect(root.querySelector('iframe')).toBe(iframe);
  });

  it('exits fullscreen when Escape is pressed', () => {
    button.click();
    expect(isPageEmbedFullscreenOpen()).toBe(true);

    document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }));

    expect(isPageEmbedFullscreenOpen()).toBe(false);
    expect(document.body.style.overflow).toBe('');
    expect(button.getAttribute('aria-expanded')).toBe('false');
  });

  it('exits fullscreen on browser popstate navigation', () => {
    button.click();
    expect(isPageEmbedFullscreenOpen()).toBe(true);

    globalThis.dispatchEvent(new PopStateEvent('popstate'));

    expect(isPageEmbedFullscreenOpen()).toBe(false);
    expect(document.body.style.overflow).toBe('');
  });
});
