describe('initializeTurnstile', () => {
  let initializeTurnstile;
  let api;

  function addContainer() {
    const container = document.createElement('div');
    container.className = 'cf-turnstile';
    container.dataset.sitekey = 'public-site-key';
    container.dataset.action = 'signup';
    document.body.appendChild(container);
    return container;
  }

  function loadApi() {
    window.turnstile = api;
    const script = document.head.querySelector('script');
    script.dispatchEvent(new Event('load'));
    const callback = new URL(script.src).searchParams.get('onload');
    window[callback]();
  }

  beforeEach(() => {
    jest.resetModules();
    ({ initializeTurnstile } = require('../initializeTurnstile'));
    document.head.innerHTML = '';
    document.body.innerHTML = '';
    delete window.turnstile;
    api = {
      ready: jest.fn(() => {
        throw new Error('Remove async/defer before using turnstile.ready()');
      }),
      render: jest.fn((container) => {
        container.innerHTML =
          '<iframe></iframe><input name="cf-turnstile-response" value="old-token">';
        return `widget-${api.render.mock.calls.length}`;
      }),
      remove: jest.fn(),
    };
  });

  afterEach(() => {
    expect(api.ready).not.toHaveBeenCalled();
    document.head.innerHTML = '';
    document.body.innerHTML = '';
    delete window.turnstile;
    delete window.onForemTurnstileLoad;
    jest.restoreAllMocks();
  });

  it('does not load the API on pages without a widget', async () => {
    await initializeTurnstile();

    expect(document.head.querySelector('script')).toBeNull();
    expect(api.render).not.toHaveBeenCalled();
  });

  it('waits for the SDK onload callback without calling ready on the async API', async () => {
    const container = addContainer();
    const initialization = initializeTurnstile();
    const script = document.head.querySelector('script');

    expect(script.src).toBe(
      'https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit&onload=onForemTurnstileLoad',
    );
    expect(script.async).toBe(true);
    expect(script.defer).toBe(true);
    expect(api.render).not.toHaveBeenCalled();

    window.turnstile = api;
    script.dispatchEvent(new Event('load'));
    expect(api.render).not.toHaveBeenCalled();
    window.onForemTurnstileLoad();
    await initialization;

    expect(window.onForemTurnstileLoad).toBeUndefined();
    expect(api.render).toHaveBeenCalledWith(container, {
      sitekey: 'public-site-key',
      action: 'signup',
    });
  });

  it('reuses an already loaded API', async () => {
    addContainer();
    window.turnstile = api;

    await initializeTurnstile();

    expect(document.head.querySelector('script')).toBeNull();
    expect(api.render).toHaveBeenCalledTimes(1);
  });

  it('loads once and avoids duplicate widgets during concurrent initialization', async () => {
    addContainer();
    const first = initializeTurnstile();
    const second = initializeTurnstile();

    expect(document.head.querySelectorAll('script')).toHaveLength(1);
    loadApi();
    await Promise.all([first, second]);
    await initializeTurnstile();

    expect(document.head.querySelectorAll('script')).toHaveLength(1);
    expect(api.render).toHaveBeenCalledTimes(1);
    expect(api.remove).not.toHaveBeenCalled();
  });

  it('removes detached widgets and renders replacement containers', async () => {
    const oldContainer = addContainer();
    const first = initializeTurnstile();
    loadApi();
    await first;

    oldContainer.remove();
    const replacement = addContainer();
    await initializeTurnstile();

    expect(api.remove).toHaveBeenCalledWith('widget-1');
    expect(oldContainer.childNodes).toHaveLength(0);
    expect(api.render).toHaveBeenLastCalledWith(replacement, {
      sitekey: 'public-site-key',
      action: 'signup',
    });
    expect(api.render).toHaveBeenCalledTimes(2);
  });

  it('cleans up on navigation away and renders restored nodes with fresh tokens', async () => {
    const container = addContainer();
    const first = initializeTurnstile();
    loadApi();
    await first;

    container.remove();
    await initializeTurnstile();

    expect(api.remove).toHaveBeenCalledWith('widget-1');
    expect(
      container.querySelector('[name="cf-turnstile-response"]'),
    ).toBeNull();

    document.body.appendChild(container);
    await initializeTurnstile();

    expect(api.render).toHaveBeenCalledTimes(2);
    expect(document.head.querySelectorAll('script')).toHaveLength(1);
  });

  it('clears cached widget markup before rendering a restored clone', async () => {
    const container = addContainer();
    const first = initializeTurnstile();
    loadApi();
    await first;
    const cached = container.cloneNode(true);
    container.replaceWith(cached);
    api.render.mockImplementation((node) => {
      expect(node.childNodes).toHaveLength(0);
      return 'fresh-widget';
    });

    await initializeTurnstile();

    expect(api.remove).toHaveBeenCalledWith('widget-1');
    expect(api.render).toHaveBeenLastCalledWith(cached, {
      sitekey: 'public-site-key',
      action: 'signup',
    });
  });

  it('does not render a container removed while the API was loading', async () => {
    const container = addContainer();
    const first = initializeTurnstile();
    container.remove();
    await initializeTurnstile();
    loadApi();
    await first;

    expect(api.render).not.toHaveBeenCalled();
  });

  it('renders the current page after navigating while the API was loading', async () => {
    const container = addContainer();
    const first = initializeTurnstile();
    container.remove();
    const replacement = addContainer();
    const second = initializeTurnstile();
    loadApi();
    await Promise.all([first, second]);

    expect(api.render).toHaveBeenCalledTimes(1);
    expect(api.render).toHaveBeenCalledWith(replacement, {
      sitekey: 'public-site-key',
      action: 'signup',
    });
  });

  it('retries loading after a script error', async () => {
    addContainer();
    jest.spyOn(console, 'error').mockImplementation(() => {});
    const first = initializeTurnstile();
    const failedScript = document.head.querySelector('script');
    failedScript.dispatchEvent(new Event('error'));
    await first;

    expect(failedScript.isConnected).toBe(false);
    expect(window.onForemTurnstileLoad).toBeUndefined();
    expect(api.render).not.toHaveBeenCalled();

    const retry = initializeTurnstile();
    expect(document.head.querySelector('script')).not.toBe(failedScript);
    loadApi();
    await retry;

    expect(api.render).toHaveBeenCalledTimes(1);
    expect(console.error).toHaveBeenCalledTimes(1);
  });
});
