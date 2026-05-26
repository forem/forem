import { observeBillboards } from '../packs/billboardAfterRenderActions';

// Behavioral test of the bot gate: drives the real impression code path
// (observeBillboards -> IntersectionObserver -> trackAdImpression) and asserts
// the /bb_tabulations POST is suppressed for crawlers and sent for humans.
// This fails if the `isBot` guard is removed — unlike a bare regex assertion.
describe('billboard impression tracking — bot gate', () => {
  let originalFetch;
  let originalUserAgent;
  let intersectionCallback;

  const setUserAgent = (ua) => {
    Object.defineProperty(window.navigator, 'userAgent', {
      value: ua,
      configurable: true,
    });
  };

  const renderBillboard = () => {
    document.body.replaceChildren();
    document
      .querySelectorAll('meta[name="csrf-token"]')
      .forEach((node) => node.remove());

    const meta = document.createElement('meta');
    meta.setAttribute('name', 'csrf-token');
    meta.setAttribute('content', 'test-token');
    document.head.appendChild(meta);

    const ad = document.createElement('div');
    ad.setAttribute('data-display-unit', '');
    ad.dataset.id = '42';
    ad.dataset.contextType = 'home';
    ad.dataset.categoryImpression = 'impression';
    ad.dataset.articleId = '7';
    document.body.appendChild(ad);
  };

  const scrollAdIntoView = () => {
    const ad = document.querySelector('[data-display-unit]');
    intersectionCallback([
      { isIntersecting: true, intersectionRatio: 0.25, target: ad },
    ]);
    jest.advanceTimersByTime(200); // trackAdImpression fires on a 200ms timer
  };

  beforeEach(() => {
    jest.useFakeTimers();
    originalFetch = global.fetch;
    originalUserAgent = window.navigator.userAgent;
    global.fetch = jest.fn(() => Promise.resolve({}));
    global.IntersectionObserver = class {
      constructor(callback) {
        intersectionCallback = callback;
      }
      observe() {}
      unobserve() {}
      disconnect() {}
    };
    renderBillboard();
  });

  afterEach(() => {
    global.fetch = originalFetch;
    setUserAgent(originalUserAgent);
    jest.useRealTimers();
  });

  it('suppresses the impression POST for a crawler whose UA lacks "bot" (Bytespider)', () => {
    setUserAgent(
      'Mozilla/5.0 (compatible; Bytespider; spider-feedback@bytedance.com)',
    );

    observeBillboards();
    scrollAdIntoView();

    expect(global.fetch).not.toHaveBeenCalled();
  });

  it('sends the impression POST to /bb_tabulations for a human browser UA', () => {
    setUserAgent(
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 ' +
        '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    );

    observeBillboards();
    scrollAdIntoView();

    expect(global.fetch).toHaveBeenCalledWith(
      '/bb_tabulations',
      expect.objectContaining({ method: 'POST' }),
    );
  });
});
