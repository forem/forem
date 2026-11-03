describe('Turnstile form action binding', () => {
  beforeEach(() => {
    jest.resetModules();
    document.body.innerHTML = '';
    window.turnstile = { render: jest.fn(() => 'widget'), remove: jest.fn() };
  });

  afterEach(() => {
    delete window.turnstile;
    document.body.innerHTML = '';
  });

  it.each(['signup', 'abuse_report'])(
    'passes the %s action to the SDK',
    async (action) => {
      const { initializeTurnstile } = require('../initializeTurnstile');
      const container = document.createElement('div');
      container.className = 'cf-turnstile';
      container.dataset.sitekey = 'site-key';
      container.dataset.action = action;
      document.body.appendChild(container);

      await initializeTurnstile();

      expect(window.turnstile.render).toHaveBeenCalledWith(container, {
        sitekey: 'site-key',
        action,
      });
    },
  );
});
