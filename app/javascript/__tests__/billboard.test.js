import { getBillboard } from '../packs/billboard';

describe('getBillboard', () => {
  let originalFetch;
  beforeEach(() => {
    originalFetch = global.fetch;
    global.Honeybadger = { notify: jest.fn() };
    document.body.innerHTML = `
      <div>
        <div class="js-billboard-container" data-async-url="/billboards/sidebar_left"></div>
        <div class="js-billboard-container" data-async-url="/billboards/sidebar_left_2"></div>
      </div>
    `;
  });

  afterEach(() => {
    global.fetch = originalFetch;
  });

  test('should make a call to the correct placement url', async () => {
    global.fetch = jest.fn(() =>
      Promise.resolve({
        text: () => Promise.resolve('<div>Some HTML content</div>'),
      }),
    );

    await getBillboard();

    expect(global.fetch).toHaveBeenCalledWith('/billboards/sidebar_left');
    expect(global.fetch).toHaveBeenCalledWith('/billboards/sidebar_left_2');
  });

  test('should execute scripts in the fetched content', async () => {
    global.fetch = jest.fn(() =>
      Promise.resolve({
        text: () =>
          Promise.resolve(
            '<script>window.someGlobalVar = "test";</script><script>window.someOtherGlobalVar = "test2";</script>',
          ),
      }),
    );

    await getBillboard();

    expect(window.someGlobalVar).toBe('test');
    expect(window.someOtherGlobalVar).toBe('test2');
  });

  test('should handle fetch errors gracefully', async () => {
    global.fetch = jest.fn(() => Promise.reject(new Error('NetworkError')));

    await getBillboard();

    expect(global.Honeybadger.notify).not.toHaveBeenCalled();
  });

  test('should report non-network errors to Honeybadger', async () => {
    global.fetch = jest.fn(() => Promise.reject(new Error('Some other error')));

    await getBillboard();

    expect(global.Honeybadger.notify).toHaveBeenCalledWith(
      new Error('Some other error'),
    );
  });
});
