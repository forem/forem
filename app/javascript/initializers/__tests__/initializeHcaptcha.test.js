describe('initializeHcaptcha', () => {
  let initializeHcaptcha;
  let api;

  function addContainer() {
    const container = document.createElement('div');
    container.className = 'h-captcha';
    container.dataset.sitekey = 'public-site-key';
    document.body.appendChild(container);
    return container;
  }

  beforeEach(() => {
    jest.resetModules();
    ({ initializeHcaptcha } = require('../initializeHcaptcha'));
    document.head.innerHTML = '';
    document.body.innerHTML = '';
    delete window.hcaptcha;
    api = { render: jest.fn(() => 'widget'), remove: jest.fn() };
  });

  afterEach(() => {
    document.head.innerHTML = '';
    document.body.innerHTML = '';
    delete window.hcaptcha;
    delete window.onForemHcaptchaLoad;
    jest.restoreAllMocks();
  });

  it('does not load the SDK on pages without hCaptcha', async () => {
    await initializeHcaptcha();
    expect(document.head.querySelector('script')).toBeNull();
  });

  it('loads once, waits for onload, and explicitly renders a normal visible widget', async () => {
    const container = addContainer();
    const first = initializeHcaptcha();
    const second = initializeHcaptcha();
    const script = document.head.querySelector('script');
    expect(document.head.querySelectorAll('script')).toHaveLength(1);
    expect(script.src).toBe(
      'https://js.hcaptcha.com/1/api.js?render=explicit&onload=onForemHcaptchaLoad&recaptchacompat=off',
    );
    window.hcaptcha = api;
    script.dispatchEvent(new Event('load'));
    expect(api.render).not.toHaveBeenCalled();
    window.onForemHcaptchaLoad();
    await Promise.all([first, second]);
    await initializeHcaptcha();
    expect(api.render).toHaveBeenCalledTimes(1);
    expect(api.render).toHaveBeenCalledWith(container, {
      sitekey: 'public-site-key',
      size: 'normal',
    });
  });

  it('removes old widgets and clears spent tokens on navigation and restoration', async () => {
    const container = addContainer();
    window.hcaptcha = api;
    await initializeHcaptcha();
    container.innerHTML = '<input name="h-captcha-response" value="spent">';
    container.remove();
    await initializeHcaptcha();
    expect(api.remove).toHaveBeenCalledWith('widget');
    expect(container.childNodes).toHaveLength(0);
    document.body.appendChild(container);
    await initializeHcaptcha();
    expect(api.render).toHaveBeenCalledTimes(2);
  });

  it('does not initialize a container removed while the SDK loads', async () => {
    const container = addContainer();
    const initialization = initializeHcaptcha();
    container.remove();
    window.hcaptcha = api;
    window.onForemHcaptchaLoad();
    await initialization;
    expect(api.render).not.toHaveBeenCalled();
  });

  it('retries a failed SDK load without allowing an unverified submission', async () => {
    addContainer();
    jest.spyOn(console, 'error').mockImplementation(() => {});
    const first = initializeHcaptcha();
    const failedScript = document.head.querySelector('script');
    failedScript.dispatchEvent(new Event('error'));
    await first;
    expect(failedScript.isConnected).toBe(false);
    const retry = initializeHcaptcha();
    window.hcaptcha = api;
    window.onForemHcaptchaLoad();
    await retry;
    expect(api.render).toHaveBeenCalledTimes(1);
  });
});
