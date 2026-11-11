import { createAssetBundleLoader } from '../loadAssetBundle';

describe('createAssetBundleLoader', () => {
  let loader;

  beforeEach(() => {
    document.head.innerHTML =
      '<meta name="test-bundle-script" content="/assets/testBundle-123.js">';
    document.body.innerHTML = '';
    delete window.__testBundleApi;
    delete window.__foremPreactLoadingPromise;

    loader = createAssetBundleLoader({
      metaName: 'test-bundle-script',
      fallbackSrc: '/assets/testBundle.js',
      dataAttribute: 'testBundle',
      getReadyValue: () => window.__testBundleApi || null,
      errorMessage: 'testBundle loaded without registering __testBundleApi',
    });
  });

  it('resolves synchronously when getReadyValue() is already available', async () => {
    const api = { run: jest.fn() };
    window.__testBundleApi = api;

    await expect(loader.load()).resolves.toBe(api);
    expect(document.querySelector('script[data-test-bundle="true"]')).toBeNull();
  });

  it('deduplicates concurrent in-flight callers and resolves when the script loads', async () => {
    const p1 = loader.load();
    const p2 = loader.load();

    const scripts = document.querySelectorAll('script[data-test-bundle="true"]');
    expect(scripts).toHaveLength(1);
    expect(scripts[0].getAttribute('src')).toBe('/assets/testBundle-123.js');

    const api = { run: jest.fn() };
    window.__testBundleApi = api;
    scripts[0].dispatchEvent(new Event('load'));

    await expect(Promise.all([p1, p2])).resolves.toEqual([api, api]);
  });

  it('removes a pre-existing eager script tag if it fails to load so subsequent retries succeed', async () => {
    const eagerScript = document.createElement('script');
    eagerScript.setAttribute('src', '/assets/testBundle-123.js');
    document.body.appendChild(eagerScript);

    const firstAttempt = loader.load();
    eagerScript.dispatchEvent(new Event('error'));

    await expect(firstAttempt).rejects.toThrow(
      'Failed to load /assets/testBundle-123.js',
    );
    expect(
      document.querySelector('script[src="/assets/testBundle-123.js"]'),
    ).toBeNull();

    const secondAttempt = loader.load();
    const retryScript = document.querySelector(
      'script[data-test-bundle="true"]',
    );
    expect(retryScript).not.toBeNull();

    const api = { run: jest.fn() };
    window.__testBundleApi = api;
    retryScript.dispatchEvent(new Event('load'));

    await expect(secondAttempt).resolves.toBe(api);
  });

  it('rejects and removes the script tag when load fires without registering the expected global', async () => {
    const attempt = loader.load();
    const script = document.querySelector('script[data-test-bundle="true"]');
    script.dispatchEvent(new Event('load'));

    await expect(attempt).rejects.toThrow(
      'testBundle loaded without registering __testBundleApi',
    );
    expect(document.querySelector('script[data-test-bundle="true"]')).toBeNull();
  });

  it('waits for window.__foremPreactLoadingPromise when a mixed-cache Preact runtime fallback is in flight', async () => {
    const attempt = loader.load();
    const script = document.querySelector('script[data-test-bundle="true"]');

    let resolveRuntime;
    window.__foremPreactLoadingPromise = new Promise((resolve) => {
      resolveRuntime = resolve;
    });

    const api = { run: jest.fn() };
    // Simulate a secondary Preact pack queuing its initialization onto __foremPreactLoadingPromise
    // before the script load event fires.
    window.__foremPreactLoadingPromise.then(() => {
      window.__testBundleApi = api;
    });

    script.dispatchEvent(new Event('load'));
    resolveRuntime({});

    await expect(attempt).resolves.toBe(api);
  });
});
