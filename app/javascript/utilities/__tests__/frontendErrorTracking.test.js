import {
  createLazyErrorTrackingProxy,
  initializeFrontendErrorTracking,
} from '../frontendErrorTracking';

describe('frontendErrorTracking', () => {
  let originalHoneybadger;

  beforeEach(() => {
    originalHoneybadger = window.Honeybadger;
    delete window.Honeybadger;
    document.head.innerHTML = '';
    document.body.innerHTML = '';
    delete document.body.dataset.betterstackErrorsDsn;
    delete document.body.dataset.honeybadgerKey;
    delete document.body.dataset.latestCommitId;
    delete document.body.dataset.releaseFootprint;
  });

  afterEach(() => {
    if (originalHoneybadger !== undefined) {
      window.Honeybadger = originalHoneybadger;
    } else {
      delete window.Honeybadger;
    }
    document.head.innerHTML = '';
  });

  it('gives Better Stack strict precedence over Honeybadger and never loads honeybadgerClient', async () => {
    document.head.innerHTML = `
      <meta name="betterstack-errors-script" content="/assets/betterstackErrorsClient.js">
      <meta name="honeybadger-script" content="/assets/honeybadgerClient.js">
    `;
    document.body.dataset.betterstackErrorsDsn =
      'https://token@in.betterstackdata.com/2775219';
    document.body.dataset.honeybadgerKey = 'hb-key-should-be-ignored';
    document.body.dataset.latestCommitId = 'sha-999';

    initializeFrontendErrorTracking({ environment: 'production' });

    expect(window.Honeybadger.__isLazyProxy).toBe(true);
    expect(window.Honeybadger.config.dsn).toBe(
      'https://token@in.betterstackdata.com/2775219',
    );
    expect(window.Honeybadger.config.apiKey).toBeUndefined();

    // No script is loaded before an actual error occurs
    expect(document.head.querySelectorAll('script')).toHaveLength(0);

    window.Honeybadger.setContext({ section: 'feed' });
    const err = new Error('Unhandled feed failure');
    expect(window.Honeybadger.notify(err)).toBe(true);

    const scripts = document.head.querySelectorAll('script');
    expect(scripts).toHaveLength(1);
    expect(scripts[0].getAttribute('src')).toBe(
      '/assets/betterstackErrorsClient.js',
    );

    const mockBetterstackClient = {
      __provider: 'betterstack',
      configure: jest.fn(),
      beforeNotify: jest.fn(),
      setContext: jest.fn(),
      notify: jest.fn(),
    };
    window.Honeybadger = mockBetterstackClient;
    scripts[0].onload();

    await Promise.resolve();

    expect(mockBetterstackClient.configure).toHaveBeenCalledWith(
      expect.objectContaining({
        dsn: 'https://token@in.betterstackdata.com/2775219',
        environment: 'production',
        revision: 'sha-999',
      }),
    );
    expect(mockBetterstackClient.setContext).toHaveBeenCalledWith({
      section: 'feed',
    });
    expect(mockBetterstackClient.notify).toHaveBeenCalledWith(
      err,
      undefined,
      undefined,
    );
  });

  it('loads honeybadgerClient only when Better Stack is unset and HONEYBADGER_JS_API_KEY is present', () => {
    document.head.innerHTML = `
      <meta name="honeybadger-script" content="/assets/honeybadgerClient.js">
    `;
    document.body.dataset.honeybadgerKey = 'hb-only-key';
    document.body.dataset.releaseFootprint = 'rel-123';

    initializeFrontendErrorTracking({ environment: 'production' });

    expect(window.Honeybadger.config.apiKey).toBe('hb-only-key');
    expect(window.Honeybadger.config.dsn).toBeUndefined();
    expect(document.head.querySelectorAll('script')).toHaveLength(0);

    expect(window.Honeybadger.notify(new Error('HB error'))).toBe(true);

    const scripts = document.head.querySelectorAll('script');
    expect(scripts).toHaveLength(1);
    expect(scripts[0].getAttribute('src')).toBe('/assets/honeybadgerClient.js');
  });

  it('remains completely inert and attaches no listeners or scripts when neither provider is configured', () => {
    const addListenerSpy = jest.spyOn(window, 'addEventListener');

    initializeFrontendErrorTracking({ environment: 'production' });

    expect(addListenerSpy).not.toHaveBeenCalledWith(
      'error',
      expect.any(Function),
    );
    expect(addListenerSpy).not.toHaveBeenCalledWith(
      'unhandledrejection',
      expect.any(Function),
    );
    expect(window.Honeybadger.notify(new Error('Ignored'))).toBe(false);
    expect(document.head.querySelectorAll('script')).toHaveLength(0);

    addListenerSpy.mockRestore();
  });

  it('drops ignored browser noise before injecting any client script', () => {
    document.head.innerHTML = `
      <meta name="betterstack-errors-script" content="/assets/betterstackErrorsClient.js">
    `;
    document.body.dataset.betterstackErrorsDsn =
      'https://token@in.betterstackdata.com/2775219';

    initializeFrontendErrorTracking({ environment: 'production' });

    expect(
      window.Honeybadger.notify(
        new Error('ResizeObserver loop limit exceeded'),
      ),
    ).toBe(false);
    expect(
      window.Honeybadger.notify(
        new Error('ChunkLoadError: Loading chunk 2 failed'),
      ),
    ).toBe(false);
    expect(document.head.querySelectorAll('script')).toHaveLength(0);
  });

  it('removes failed script elements on error so broken tags do not linger in head', () => {
    document.head.innerHTML = `
      <meta name="betterstack-errors-script" content="/assets/betterstackErrorsClient.js">
    `;
    const proxy = createLazyErrorTrackingProxy();
    proxy.configure({ dsn: 'https://token@in.betterstackdata.com/2775219' });

    expect(proxy.notify(new Error('First error'))).toBe(true);
    const script = document.head.querySelector('script');
    expect(script).not.toBeNull();

    script.onerror();

    expect(document.head.querySelector('script')).toBeNull();
    expect(proxy.notify(new Error('Subsequent error'))).toBe(false);
  });
});
