import { initEmbedInnerGuard } from '@utilities/embedInnerGuard';

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

describe('embedInnerGuard', () => {
  let controller;
  let originalFetch;
  let originalWorker;
  let originalRTCPeerConnection;
  let originalPrint;
  let originalOpen;
  let originalAudioContext;
  let originalClipboard;
  let originalMessageChannel;
  let originalHTMLElementFocus;
  let nativeFocusSpy;
  let printSpy;
  let openSpy;
  let capturedBootPorts;
  let parentPostMessageSpy;
  let hostPort;

  function mountGuard(overrideConfig = {}) {
    controller?.destroy();
    capturedBootPorts = [];

    controller = initEmbedInnerGuard(
      {
        blockedHosts: ['dev.to', 'sub.dev.to'],
        allowLocalHttp: false,
        limits: {
          maxActiveTimers: 5,
          maxPendingRaf: 4,
          minIntervalMs: 16,
          minTimeoutMs: 4,
          maxConcurrentFetches: 2,
          maxFetchesPerWindow: 4,
          fetchWindowMs: 10000,
          maxPopupsPerGesture: 1,
          popupCooldownMs: 1000,
          maxConsolePerSec: 3,
          maxConsecutiveErrors: 3,
          maxDomNodes: 50,
          userActivationWindowMs: 5000,
        },
        ...overrideConfig,
      },
      window,
      document,
    );
    hostPort = capturedBootPorts[capturedBootPorts.length - 1];
  }

  beforeEach(() => {
    jest.restoreAllMocks();
    capturedBootPorts = [];

    document.head.innerHTML = '';
    document.body.innerHTML =
      '<div id="app"><a id="ext" href="https://example.com">Go</a><a id="bad" href="javascript:alert(1)">Bad</a><form id="f"><button type="submit">Send</button></form><input id="inp" /><video id="vid"></video></div>';
    document.body.getBoundingClientRect = () => ({ height: 240 });

    originalFetch = global.fetch;
    originalWorker = global.Worker;
    originalRTCPeerConnection = global.RTCPeerConnection;
    originalPrint = window.print;
    originalOpen = window.open;
    originalAudioContext = global.AudioContext;
    originalClipboard = navigator.clipboard;
    originalMessageChannel = global.MessageChannel;
    originalHTMLElementFocus = window.HTMLElement.prototype.focus;

    global.MessageChannel = MockMessageChannel;
    global.fetch = jest.fn(() => Promise.resolve({ ok: true }));
    global.Worker = jest.fn();
    global.RTCPeerConnection = jest.fn();
    printSpy = jest.fn();
    openSpy = jest.fn();
    window.print = printSpy;
    window.open = openSpy;
    window.Element.prototype.requestFullscreen = jest.fn(() => Promise.resolve());
    nativeFocusSpy = jest.fn();
    window.HTMLElement.prototype.focus = nativeFocusSpy;
    window.HTMLMediaElement.prototype.play = jest.fn(() => Promise.resolve());
    window.HTMLMediaElement.prototype.pause = jest.fn();

    const fakeAudioCtx = {
      state: 'running',
      suspend: jest.fn(() => {
        fakeAudioCtx.state = 'suspended';
        return Promise.resolve();
      }),
      resume: jest.fn(() => {
        fakeAudioCtx.state = 'running';
        return Promise.resolve();
      }),
    };
    global.AudioContext = jest.fn(() => fakeAudioCtx);

    Object.defineProperty(navigator, 'clipboard', {
      configurable: true,
      value: {
        writeText: jest.fn(() => Promise.resolve()),
        write: jest.fn(() => Promise.resolve()),
      },
    });

    parentPostMessageSpy = jest.fn((data, _targetOrigin, transfer) => {
      if (data && data.__foremEmbed === 'boot' && transfer?.[0]) {
        capturedBootPorts.push(transfer[0]);
      }
    });

    Object.defineProperty(window, 'parent', {
      configurable: true,
      value: { postMessage: parentPostMessageSpy, close: jest.fn() },
    });

    mountGuard();
  });

  afterEach(() => {
    controller?.destroy();
    controller = null;
    jest.useRealTimers();
    global.fetch = originalFetch;
    global.Worker = originalWorker;
    global.RTCPeerConnection = originalRTCPeerConnection;
    window.print = originalPrint;
    window.open = originalOpen;
    global.AudioContext = originalAudioContext;
    global.MessageChannel = originalMessageChannel;
    window.HTMLElement.prototype.focus = originalHTMLElementFocus;
    Object.defineProperty(navigator, 'clipboard', {
      configurable: true,
      value: originalClipboard,
    });
    document.head.innerHTML = '';
    document.body.innerHTML = '';
  });

  it('connects a private MessageChannel on boot and responds to discover pings only from parent', async () => {
    expect(capturedBootPorts.length).toBe(1);

    const hostMessages = [];
    hostPort.onmessage = (e) => hostMessages.push(e.data);
    hostPort.postMessage({ type: 'ping', seq: 7 });
    await flushMicrotasks();

    expect(hostMessages.some((m) => m.type === 'pong' && m.seq === 7)).toBe(true);

    const authorListener = jest.fn();
    window.addEventListener('message', authorListener);

    // Non-parent source discover should be ignored and NOT hidden from author listeners
    window.dispatchEvent(
      new MessageEvent('message', {
        data: { __foremEmbedHost: 'discover' },
        source: window,
      }),
    );
    expect(capturedBootPorts.length).toBe(1);
    expect(authorListener).toHaveBeenCalledTimes(1);

    // Real parent discover should reconnect cleanly and stop propagation from author scripts
    window.dispatchEvent(
      new MessageEvent('message', {
        data: { __foremEmbedHost: 'discover' },
        source: window.parent,
      }),
    );
    expect(capturedBootPorts.length).toBe(2);
    expect(authorListener).toHaveBeenCalledTimes(1);
  });

  it('pauses and resumes rAF, intervals, timeouts, CSS state, and AudioContext on visibility changes', async () => {
    controller?.destroy();
    jest.useFakeTimers();
    mountGuard();

    const rafCb = jest.fn();
    const intervalCb = jest.fn();
    const timeoutCb = jest.fn();

    const audio = new window.AudioContext();
    window.requestAnimationFrame(rafCb);
    window.setInterval(intervalCb, 20);
    window.setTimeout(timeoutCb, 50);

    // Pause via host state over MessagePort
    hostPort.postMessage({
      type: 'state',
      active: false,
      theme: 'dark',
      fullscreen: true,
    });
    await flushMicrotasks();

    expect(document.documentElement.dataset.foremPaused).toBe('true');
    expect(document.documentElement.dataset.foremTheme).toBe('dark');
    expect(document.documentElement.dataset.foremFullscreen).toBe('true');
    expect(audio.suspend).toHaveBeenCalled();

    jest.advanceTimersByTime(500);
    expect(rafCb).not.toHaveBeenCalled();
    expect(intervalCb).not.toHaveBeenCalled();
    expect(timeoutCb).not.toHaveBeenCalled();

    // Resume via host state
    hostPort.postMessage({ type: 'state', active: true });
    await flushMicrotasks();

    expect(document.documentElement.dataset.foremPaused).toBe('false');
    expect(audio.resume).toHaveBeenCalled();

    jest.advanceTimersByTime(100);
    expect(rafCb).toHaveBeenCalled();
    expect(intervalCb).toHaveBeenCalled();
    expect(timeoutCb).toHaveBeenCalledTimes(1);
    controller?.destroy();
    controller = null;
    jest.useRealTimers();
  });

  it('blocks SSRF, Forem-host fetches, non-HTTPS URLs, sync XHR, WebRTC, and Web Workers', async () => {
    await expect(window.fetch('https://dev.to/api/articles')).rejects.toThrow(
      /blocked/i,
    );
    await expect(window.fetch('https://127.0.0.1:3000/secret')).rejects.toThrow(
      /blocked/i,
    );
    await expect(
      window.fetch('http://169.254.169.254/latest/meta-data'),
    ).rejects.toThrow(/blocked/i);
    await expect(window.fetch('https://10.0.0.5/internal')).rejects.toThrow(
      /blocked/i,
    );
    await expect(window.fetch('http://example.com/insecure')).rejects.toThrow(
      /blocked/i,
    );
    await expect(
      window.fetch('https://[::ffff:127.0.0.1]/secret'),
    ).rejects.toThrow(/blocked/i);
    await expect(
      window.fetch('https://[::ffff:169.254.169.254]/latest/meta-data'),
    ).rejects.toThrow(/blocked/i);

    await expect(window.fetch('https://api.github.com/zen')).resolves.toEqual({
      ok: true,
    });
    await expect(window.fetch('blob:null/123')).resolves.toEqual({ ok: true });

    // Validate canonical URL string check.url is passed rather than mutable { toString } / { url } objects
    const rawFetchSpy = jest.fn(() => Promise.resolve({ ok: true }));
    controller.destroy();
    global.fetch = rawFetchSpy;
    mountGuard();

    const spoofObj = {
      url: 'https://api.github.com/zen',
      toString() {
        return 'https://dev.to/api/articles';
      },
    };
    await expect(window.fetch(spoofObj)).rejects.toThrow(/blocked/i);
    expect(rawFetchSpy).not.toHaveBeenCalled();

    let swaps = 0;
    const toctouUrl = {
      toString() {
        swaps += 1;
        return swaps === 1
          ? 'https://api.github.com/zen'
          : 'https://dev.to/api/articles';
      },
    };
    await expect(window.fetch(toctouUrl)).resolves.toEqual({ ok: true });
    expect(rawFetchSpy).toHaveBeenCalledWith(
      'https://api.github.com/zen',
      undefined,
    );

    const xhr = new window.XMLHttpRequest();
    expect(() => xhr.open('GET', 'https://api.github.com/zen', false)).toThrow(
      /disabled/i,
    );

    expect(() => new window.RTCPeerConnection()).toThrow(/disabled/i);
    expect(() => new window.Worker('blob:test')).toThrow(/disabled/i);
  });

  it('enforces fetch rate limits and timer/rAF caps plus error-storm circuit breaking', async () => {
    for (let i = 0; i < 4; i += 1) {
      await window.fetch('https://api.github.com/zen');
    }
    await expect(window.fetch('https://api.github.com/zen')).rejects.toThrow(
      /rate-limited/i,
    );

    // Timer cap = 5
    const ids = [];
    for (let i = 0; i < 6; i += 1) {
      ids.push(window.setTimeout(() => {}, 1000));
    }
    expect(ids[5]).toBe(0);

    // Error loop breaker (maxConsecutiveErrors = 3)
    controller?.destroy();
    controller = null;
    jest.useFakeTimers();
    mountGuard();
    const hostMessages = [];
    hostPort.onmessage = (e) => hostMessages.push(e.data);
    let runs = 0;
    window.setInterval(() => {
      runs += 1;
      throw new Error('boom');
    }, 20);

    for (let i = 0; i < 5; i += 1) {
      try {
        jest.advanceTimersByTime(25);
      } catch (_err) {
        // expected rethrow on first 3 runs
      }
    }
    expect(runs).toBe(3);
    await flushMicrotasks();
    expect(
      hostMessages.some((m) => m.type === 'guard' && m.reason === 'error-loop'),
    ).toBe(true);

    // Heavy-frame streak resets after throttling so subsequent reports require another full streak
    controller?.destroy();
    controller = null;
    jest.useFakeTimers();
    let nowMs = 1000;
    const origPerfNow = window.performance.now;
    window.performance.now = () => nowMs;
    mountGuard({ limits: { maxLongTaskMs: 100, maxConsecutiveHeavyFrames: 2 } });
    const heavyMsgs = [];
    hostPort.onmessage = (e) => heavyMsgs.push(e.data);
    window.setInterval(() => {
      nowMs += 150;
    }, 20);
    jest.advanceTimersByTime(25);
    jest.advanceTimersByTime(25);
    await flushMicrotasks();
    expect(
      heavyMsgs.filter((m) => m.type === 'guard' && m.reason === 'heavy-frame'),
    ).toHaveLength(1);
    jest.advanceTimersByTime(520);
    await flushMicrotasks();
    // Only 1 more heavy frame ran since delay increased -> streak is 1 < 2, no duplicate report
    expect(
      heavyMsgs.filter((m) => m.type === 'guard' && m.reason === 'heavy-frame'),
    ).toHaveLength(1);
    window.performance.now = origPerfNow;
    controller?.destroy();
    controller = null;
    jest.useRealTimers();
  });

  it('prevents focus stealing, print, native fullscreen, document wipe, and unactivated popups/clipboard', async () => {
    const input = document.getElementById('inp');
    input.focus();
    expect(nativeFocusSpy).not.toHaveBeenCalled();

    window.print();
    expect(printSpy).not.toHaveBeenCalled();
    await expect(document.body.requestFullscreen()).rejects.toThrow();
    await expect(navigator.clipboard.writeText('hi')).rejects.toThrow();
    expect(window.open('https://example.com')).toBeNull();
    expect(openSpy).not.toHaveBeenCalled();

    // Document.open / post-load write blocked
    expect(document.open()).toBe(document);
    document.write('<p>wiped</p>');
    expect(document.body.innerHTML).not.toContain('wiped');

    // Simulate genuine user interaction inside iframe
    document.dispatchEvent(new Event('pointerdown', { bubbles: true }));
    input.focus();
    expect(nativeFocusSpy).toHaveBeenCalledTimes(1);
    await expect(
      navigator.clipboard.writeText('allowed'),
    ).resolves.toBeUndefined();

    window.open('javascript:alert(1)');
    expect(openSpy).not.toHaveBeenCalled();

    // Allowed HTTPS popup once per cooldown
    window.open('https://example.com/docs');
    expect(openSpy).toHaveBeenCalledTimes(1);
    window.open('https://example.com/second-blocked');
    expect(openSpy).toHaveBeenCalledTimes(1);
  });

  it('forwards Escape key to exit fullscreen and enforces safe link & form behaviors', async () => {
    const hostMessages = [];
    hostPort.onmessage = (e) => hostMessages.push(e.data);

    hostPort.postMessage({ type: 'state', fullscreen: true });
    await flushMicrotasks();

    document.dispatchEvent(
      new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }),
    );
    await flushMicrotasks();
    expect(hostMessages.some((m) => m.type === 'exit-fullscreen')).toBe(true);

    // Unsafe javascript: link click is prevented
    const badLink = document.getElementById('bad');
    const badClick = new MouseEvent('click', {
      bubbles: true,
      cancelable: true,
    });
    badLink.dispatchEvent(badClick);
    expect(badClick.defaultPrevented).toBe(true);

    // Safe link gets target="_blank" rel="noopener noreferrer"
    const extLink = document.getElementById('ext');
    extLink.dispatchEvent(
      new MouseEvent('click', { bubbles: true, cancelable: true }),
    );
    expect(extLink.getAttribute('target')).toBe('_blank');
    expect(extLink.getAttribute('rel')).toContain('noopener');
    expect(extLink.getAttribute('rel')).toContain('noreferrer');

    // Unhandled form submission is prevented so it doesn't navigate the iframe
    const form = document.getElementById('f');
    const submitEvent = new Event('submit', {
      bubbles: true,
      cancelable: true,
    });
    form.dispatchEvent(submitEvent);
    expect(submitEvent.defaultPrevented).toBe(true);
  });

  it('blocks child iframe realms synchronously before insertion and strips injected dangerous tags', async () => {
    const badIframe = document.createElement('iframe');
    badIframe.src = 'https://evil.com';
    document.body.appendChild(badIframe);
    // Blocked synchronously before MutationObserver microtasks run
    expect(document.querySelector('iframe')).toBeNull();
    expect(badIframe.contentWindow).toBeNull();

    const container = document.createElement('div');
    container.innerHTML = '<iframe src="about:blank"></iframe><p>safe</p>';
    expect(container.querySelector('iframe')).toBeNull();
    expect(container.querySelector('p')?.textContent).toBe('safe');

    const badMeta = document.createElement('meta');
    badMeta.setAttribute('http-equiv', 'refresh');
    badMeta.setAttribute('content', '0;url=https://evil.com');
    document.head.appendChild(badMeta);

    const autoInput = document.createElement('input');
    autoInput.setAttribute('autofocus', 'autofocus');
    document.body.appendChild(autoInput);

    await new Promise((resolve) => setTimeout(resolve, 10));

    expect(document.querySelector('iframe')).toBeNull();
    expect(document.querySelector('meta[http-equiv="refresh"]')).toBeNull();
    expect(autoInput.hasAttribute('autofocus')).toBe(false);
  });
});
