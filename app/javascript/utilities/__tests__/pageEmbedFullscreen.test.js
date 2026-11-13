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
      <a id="outside-link" href="https://example.test/outside">Outside</a>
      <div id="article-root">
        <div class="ltag__page ltag__page--article js-page-embed">
          <div class="ltag__page-card">
            <div class="ltag__page-viewport">
              <iframe src="https://example.test/alice/embed/demo?mode=embed" title="Demo" tabindex="0"></iframe>
            </div>
            <div class="ltag__page-footer">
              <div class="ltag__page-meta">
                <a href="/alice" class="ltag__page-owner-avatar-link" aria-hidden="true" tabindex="-1"></a>
                <a href="/alice" class="ltag__page-owner-link">Alice</a>
              </div>
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

  it('traps Tab and Shift+Tab keyboard focus inside the fullscreen card', () => {
    const outsideLink = document.getElementById('outside-link');

    button.click();
    expect(isPageEmbedFullscreenOpen()).toBe(true);

    button.focus();
    const forwardTab = new KeyboardEvent('keydown', {
      key: 'Tab',
      bubbles: true,
      cancelable: true,
    });
    document.dispatchEvent(forwardTab);
    expect(forwardTab.defaultPrevented).toBe(true);
    expect(document.activeElement).toBe(iframe);

    const backwardTab = new KeyboardEvent('keydown', {
      key: 'Tab',
      shiftKey: true,
      bubbles: true,
      cancelable: true,
    });
    document.dispatchEvent(backwardTab);
    expect(backwardTab.defaultPrevented).toBe(true);
    expect(document.activeElement).toBe(button);

    outsideLink.focus();
    const recoverTab = new KeyboardEvent('keydown', {
      key: 'Tab',
      bubbles: true,
      cancelable: true,
    });
    document.dispatchEvent(recoverTab);
    expect(recoverTab.defaultPrevented).toBe(true);
    expect(document.activeElement).toBe(iframe);
  });

  it('does not double-toggle when initialized on both document and a nested container', () => {
    initializePageEmbedFullscreen(document);

    button.click();
    expect(isPageEmbedFullscreenOpen()).toBe(true);

    button.click();
    expect(isPageEmbedFullscreenOpen()).toBe(false);
  });
});
