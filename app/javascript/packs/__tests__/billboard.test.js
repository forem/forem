import { getBillboard } from '../billboard';

describe('getBillboard', () => {
  beforeEach(() => {
    global.Honeybadger = { notify: jest.fn() };
    document.body.innerHTML = `
      <div>
        <div class="js-display-ad-container" data-async-url="/billboards/sidebar_left"></div>
        <div class="js-display-ad-container" data-async-url="/billboards/sidebar_left_2"></div>
      </div>
    `;
  });

  test('should make a call to the correct placement url', async () => {
    const fetchPromise = Promise.resolve('fetch response');
    window.fetch = jest.fn(fetchPromise);

    await getBillboard();

    expect(window.fetch).toHaveBeenCalledWith('/billboards/sidebar_left');
    expect(window.fetch).toHaveBeenCalledWith('/billboards/sidebar_left_2');
  });
});
