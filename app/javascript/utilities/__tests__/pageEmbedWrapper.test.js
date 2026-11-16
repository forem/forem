import {
  initializeSandboxedEmbeds,
  destroyAllPageEmbedWrappers,
  getSandboxedEmbedState,
} from '@utilities/pageEmbedWrapper';
import {
  initializePageEmbedFullscreen,
  isPageEmbedFullscreenOpen,
  exitPageEmbedFullscreen,
} from '@utilities/pageEmbedFullscreen';

class MockMessageChannel {
  constructor() {
    this.port1 = {
      onmessage: null,
      start: jest.fn(),
      close: jest.fn(),
      postMessage: (data) => {
        if (typeof this.port2.onmessage === 'function') {
          Promise.resolve().then(() => this.port2.onmessage({ data }));
        }
      },
    };
    this.port2 = {
      onmessage: null,
      start: jest.fn(),
      close: jest.fn(),
      postMessage: (data) => {
        if (typeof this.port1.onmessage === 'function') {
          Promise.resolve().then(() => this.port1.onmessage({ data }));
        }
      },
    };
  }
}

function flushMicrotasks() {
  return Promise.resolve().then(() => Promise.resolve());
}

describe('pageEmbedWrapper host coordination', () => {
  let intersectionCallback;
  let originalMessageChannel;

  beforeEach(() => {
    jest.restoreAllMocks();
    destroyAllPageEmbedWrappers();
    exitPageEmbedFullscreen({ restoreScroll: false, restoreFocus: false });
    document.body.className = '';
    document.body.innerHTML = '';
    delete document.documentElement.dataset.pageEmbedFullscreenBound;

    originalMessageChannel = global.MessageChannel;
    global.MessageChannel = MockMessageChannel;
    global.scrollTo = jest.fn();

    global.IntersectionObserver = jest.fn((cb) => {
      intersectionCallback = cb;
      return {
        observe: jest.fn(),
        unobserve: jest.fn(),
        disconnect: jest.fn(),
      };
    });
  });

  afterEach(() => {
    destroyAllPageEmbedWrappers();
    exitPageEmbedFullscreen({ restoreScroll: false, restoreFocus: false });
    document.body.innerHTML = '';
    global.MessageChannel = originalMessageChannel;
    jest.useRealTimers();
  });

  function buildEmbedMarkup(id, { autoHeight = false } = {}) {
    return `
      <div id="${id}" class="ltag__page ltag__page--article js-sandboxed-embed js-page-embed" data-sandboxed-embed="true"${autoHeight ? ' data-auto-height="true"' : ''}>
        <div class="ltag__page-card">
          <div class="ltag__page-viewport">
            <iframe
              src="https://example.test/alice/embed/${id}?mode=embed"
              title="${id}"
              height="360px"
              data-embed-src="https://example.test/alice/embed/${id}?mode=embed"
              ${autoHeight ? 'data-auto-height="true"' : ''}
            ></iframe>
          </div>
          <div class="ltag__page-footer">
            <div class="ltag__page-actions">
              <button type="button" class="js-reload-page-action">Reload</button>
              <button type="button" class="js-fullscreen-page-action" aria-expanded="false">Fullscreen</button>
            </div>
          </div>
        </div>
      </div>
    `;
  }

  function mockContentWindow(iframe) {
    const fakeWin = { postMessage: jest.fn(), close: jest.fn() };
    Object.defineProperty(iframe, 'contentWindow', {
      configurable: true,
      value: fakeWin,
    });
    return fakeWin;
  }

  it('authenticates MessageChannel exclusively by matching iframe.contentWindow and syncs visibility, theme, and auto-height', async () => {
    document.body.innerHTML = buildEmbedMarkup('widget-1', { autoHeight: true });
    const embedEl = document.getElementById('widget-1');
    const iframe = embedEl.querySelector('iframe');
    const fakeWin = mockContentWindow(iframe);

    initializeSandboxedEmbeds(document);
    expect(fakeWin.postMessage).toHaveBeenCalledWith(
      { __foremEmbedHost: 'discover' },
      '*',
    );

    // Spoofed message from unrelated source must be ignored
    const spoofChannel = new MockMessageChannel();
    const spoofMessages = [];
    spoofChannel.port1.onmessage = (e) => spoofMessages.push(e.data);
    window.dispatchEvent(
      new MessageEvent('message', {
        data: { __foremEmbed: 'boot', protocol: 1 },
        source: window,
        ports: [spoofChannel.port2],
      }),
    );
    await flushMicrotasks();
    expect(spoofMessages).toHaveLength(0);

    // Genuine boot message from matching contentWindow connects private port
    const realChannel = new MockMessageChannel();
    const innerMessages = [];
    realChannel.port1.onmessage = (e) => innerMessages.push(e.data);
    window.dispatchEvent(
      new MessageEvent('message', {
        data: { __foremEmbed: 'boot', protocol: 1 },
        source: fakeWin,
        ports: [realChannel.port2],
      }),
    );
    await flushMicrotasks();

    expect(
      innerMessages.some(
        (m) => m.type === 'state' && m.active === true && m.theme === 'light',
      ),
    ).toBe(true);

    // Auto-height resize message updates iframe height clamped to [150, 2000]
    realChannel.port1.postMessage({ type: 'resize', height: 512 });
    await flushMicrotasks();
    expect(iframe.style.height).toBe('512px');

    realChannel.port1.postMessage({ type: 'resize', height: 9999 });
    await flushMicrotasks();
    expect(iframe.style.height).toBe('2000px');

    // Off-screen intersection pauses embed
    intersectionCallback([{ target: embedEl, isIntersecting: false }]);
    await flushMicrotasks();
    expect(
      innerMessages.some((m) => m.type === 'state' && m.active === false),
    ).toBe(true);

    // Theme change broadcasts updated theme
    document.body.classList.add('dark-theme');
    await flushMicrotasks();
    expect(
      innerMessages.some((m) => m.type === 'state' && m.theme === 'dark'),
    ).toBe(true);
  });

  it('defers embeds beyond maxConcurrent and lets users load them on demand', () => {
    document.body.innerHTML = `${buildEmbedMarkup('e1')}${buildEmbedMarkup('e2')}${buildEmbedMarkup('e3')}`;
    const e3 = document.getElementById('e3');
    const e3Iframe = e3.querySelector('iframe');

    initializeSandboxedEmbeds(document, { maxConcurrent: 2 });

    expect(
      getSandboxedEmbedState(document.getElementById('e1')).suspended,
    ).toBe(false);
    expect(
      getSandboxedEmbedState(document.getElementById('e2')).suspended,
    ).toBe(false);
    expect(getSandboxedEmbedState(e3).suspended).toBe(true);
    expect(e3Iframe.getAttribute('src')).toBeNull();
    expect(e3Iframe.dataset.deferredSrc).toContain('/alice/embed/e3');

    const loadBtn = e3.querySelector('.ltag__page-overlay button');
    expect(loadBtn).not.toBeNull();
    loadBtn.click();

    expect(getSandboxedEmbedState(e3).suspended).toBe(false);
    expect(e3Iframe.getAttribute('src')).toContain('/alice/embed/e3');
  });

  it('detects unresponsive embeds via heartbeat watchdog and auto-suspends prolonged freezes', () => {
    jest.useFakeTimers();
    document.body.innerHTML = buildEmbedMarkup('frozen');
    const embedEl = document.getElementById('frozen');
    const iframe = embedEl.querySelector('iframe');
    const fakeWin = mockContentWindow(iframe);

    initializeSandboxedEmbeds(document);

    const fakePort = {
      postMessage: jest.fn(),
      start: jest.fn(),
      close: jest.fn(),
      onmessage: null,
    };

    window.dispatchEvent(
      new MessageEvent('message', {
        data: { __foremEmbed: 'boot', protocol: 1 },
        source: fakeWin,
        ports: [fakePort],
      }),
    );

    // Advance past UNRESPONSIVE_TIMEOUT_MS (6s) at the 10s heartbeat tick
    jest.advanceTimersByTime(10500);
    expect(embedEl.classList.contains('is-unresponsive')).toBe(true);
    expect(embedEl.querySelector('.ltag__page-overlay')).not.toBeNull();

    // Advance past AUTO_SUSPEND_TIMEOUT_MS (15s)
    jest.advanceTimersByTime(10000);
    expect(embedEl.classList.contains('is-suspended')).toBe(true);
    expect(iframe.getAttribute('src')).toBe('about:blank');
  });

  it('blocks unexpected post-load navigation inside the iframe', () => {
    document.body.innerHTML = buildEmbedMarkup('nav-guard');
    const embedEl = document.getElementById('nav-guard');
    const iframe = embedEl.querySelector('iframe');

    initializeSandboxedEmbeds(document);

    // First load is initial boot
    iframe.dispatchEvent(new Event('load'));
    expect(getSandboxedEmbedState(embedEl).suspended).toBe(false);

    // Second unexpected load triggers quarantine
    iframe.dispatchEvent(new Event('load'));
    expect(getSandboxedEmbedState(embedEl).suspended).toBe(true);
    expect(iframe.getAttribute('src')).toBe('about:blank');
    expect(
      embedEl.querySelector('.ltag__page-overlay-message')?.textContent,
    ).toMatch(/navigation/i);
  });

  it('coordinates fullscreen pauses across embeds and exits fullscreen on iframe Escape message', async () => {
    document.body.innerHTML = `${buildEmbedMarkup('fs-a')}${buildEmbedMarkup('fs-b')}`;
    const fsA = document.getElementById('fs-a');
    const fsB = document.getElementById('fs-b');
    const winA = mockContentWindow(fsA.querySelector('iframe'));
    const winB = mockContentWindow(fsB.querySelector('iframe'));

    initializePageEmbedFullscreen(document);

    const chA = new MockMessageChannel();
    const chB = new MockMessageChannel();
    const msgsA = [];
    const msgsB = [];
    chA.port1.onmessage = (e) => msgsA.push(e.data);
    chB.port1.onmessage = (e) => msgsB.push(e.data);

    window.dispatchEvent(
      new MessageEvent('message', {
        data: { __foremEmbed: 'boot', protocol: 1 },
        source: winA,
        ports: [chA.port2],
      }),
    );
    window.dispatchEvent(
      new MessageEvent('message', {
        data: { __foremEmbed: 'boot', protocol: 1 },
        source: winB,
        ports: [chB.port2],
      }),
    );
    await flushMicrotasks();

    fsA.querySelector('.js-fullscreen-page-action').click();
    await flushMicrotasks();

    expect(isPageEmbedFullscreenOpen()).toBe(true);
    expect(
      msgsA.some(
        (m) =>
          m.type === 'state' && m.fullscreen === true && m.active === true,
      ),
    ).toBe(true);
    expect(
      msgsB.some(
        (m) =>
          m.type === 'state' && m.fullscreen === false && m.active === false,
      ),
    ).toBe(true);

    // Escape forwarded from inside iframe A cleanly exits fullscreen
    chA.port1.postMessage({ type: 'exit-fullscreen' });
    await flushMicrotasks();
    expect(isPageEmbedFullscreenOpen()).toBe(false);
  });
});
