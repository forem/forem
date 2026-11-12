import { getBillboard, cleanupStaleLiveStreamIntervals } from '../billboard';
import { setupBillboardInteractivity, ensurePersistentMinimizedBillboardContainer } from '../../utilities/billboardInteractivity';
import {
  observeBillboards,
  executeBBScripts,
} from '../billboardAfterRenderActions';

jest.mock('../../utilities/billboardInteractivity', () => ({
  setupBillboardInteractivity: jest.fn(),
  ensurePersistentMinimizedBillboardContainer: jest.fn(),
}));

jest.mock('../billboardAfterRenderActions', () => ({
  observeBillboards: jest.fn(),
  executeBBScripts: jest.fn(),
  implementSpecialBehavior: jest.fn(),
}));

describe('billboard.js - internal navigation behavior', () => {
  let mockFetch;
  let originalFetch;
  let originalHoneybadger;

  beforeEach(() => {
    // Reset mocks
    jest.clearAllMocks();
    
    // Set up dummy elements and environment variables
    document.body.innerHTML = '';
    originalHoneybadger = global.Honeybadger;
    global.Honeybadger = { notify: jest.fn() };
    
    // Mock window.fetch
    originalFetch = global.fetch;
    mockFetch = jest.fn();
    global.fetch = mockFetch;
  });

  afterEach(() => {
    global.fetch = originalFetch;
    global.Honeybadger = originalHoneybadger;
  });

  it('renders billboard normally when isInternalNav is false', async () => {
    // Setup DOM
    document.body.innerHTML = `
      <div id="page-content-inner" data-internal-nav="false"></div>
      <div class="js-billboard-container" data-async-url="/billboards/post_fixed_bottom"></div>
    `;

    mockFetch.mockResolvedValue({
      text: () => Promise.resolve(`
        <div class="js-billboard" data-special="standard" data-dismissal-sku="TEST_SKU">
          <div class="content">Normal Billboard Content</div>
        </div>
      `),
    });

    const element = document.querySelector('.js-billboard-container');
    await getBillboard();

    // Verify it fetched the billboard
    expect(mockFetch).toHaveBeenCalledWith('/billboards/post_fixed_bottom');
    
    // Verify it was appended to the container
    expect(element.innerHTML).toContain('Normal Billboard Content');
    expect(element.style.display).not.toBe('none');
    expect(setupBillboardInteractivity).toHaveBeenCalled();
  });

  it('shows minimized version and hides main container when isInternalNav is true and billboard is persistent', async () => {
    // Setup DOM
    document.body.innerHTML = `
      <div id="page-content-inner" data-internal-nav="true"></div>
      <div id="persistent-minimized-billboard-container" class="hidden"></div>
      <div class="js-billboard-container" data-async-url="/billboards/post_fixed_bottom"></div>
    `;

    const mockContainer = document.getElementById('persistent-minimized-billboard-container');
    ensurePersistentMinimizedBillboardContainer.mockReturnValue(mockContainer);

    mockFetch.mockResolvedValue({
      text: () => Promise.resolve(`
        <div class="js-billboard" data-special="persistent" data-dismissal-sku="PERSISTENT_TEST_SKU">
          <template class="js-minimized-template">
            <div class="minimized-content">Minimized text!</div>
          </template>
        </div>
      `),
    });

    const element = document.querySelector('.js-billboard-container');
    await getBillboard();

    // Verify it fetched the billboard
    expect(mockFetch).toHaveBeenCalledWith('/billboards/post_fixed_bottom');

    // Verify minimized container was populated and shown
    expect(mockContainer.innerHTML).toContain('Minimized text!');
    expect(mockContainer.classList.contains('hidden')).toBe(false);

    // Verify main container is cleared and hidden
    expect(element.style.display).toBe('none');
    expect(element.innerHTML).toBe('');

    // Verify appropriate rendering callbacks
    expect(executeBBScripts).toHaveBeenCalledWith(mockContainer);
    expect(observeBillboards).toHaveBeenCalled();
    expect(setupBillboardInteractivity).toHaveBeenCalled();
  });

  it('hides main container and does not show minimized when isInternalNav is true and billboard is NOT persistent', async () => {
    // Setup DOM
    document.body.innerHTML = `
      <div id="page-content-inner" data-internal-nav="true"></div>
      <div id="persistent-minimized-billboard-container" class="hidden"></div>
      <div class="js-billboard-container" data-async-url="/billboards/post_fixed_bottom"></div>
    `;

    const mockContainer = document.getElementById('persistent-minimized-billboard-container');

    mockFetch.mockResolvedValue({
      text: () => Promise.resolve(`
        <div class="js-billboard" data-special="standard" data-dismissal-sku="TEST_SKU">
          <div class="content">Normal Billboard Content</div>
        </div>
      `),
    });

    const element = document.querySelector('.js-billboard-container');
    await getBillboard();

    // Verify it fetched the billboard
    expect(mockFetch).toHaveBeenCalledWith('/billboards/post_fixed_bottom');

    // Verify minimized container was NOT populated
    expect(mockContainer.innerHTML).toBe('');
    expect(mockContainer.classList.contains('hidden')).toBe(true);

    // Verify main container is cleared and hidden
    expect(element.style.display).toBe('none');
    expect(element.innerHTML).toBe('');

    // Verify helper callbacks were not called for the minimized container
    expect(executeBBScripts).not.toHaveBeenCalledWith(mockContainer);
  });

  describe('embedded browser context suppression for post_fixed_bottom', () => {
    let originalUserAgent;
    let originalUserAgentData;

    beforeEach(() => {
      originalUserAgent = window.navigator.userAgent;
      originalUserAgentData = window.navigator.userAgentData;
    });

    afterEach(() => {
      Object.defineProperty(window.navigator, 'userAgent', {
        value: originalUserAgent,
        configurable: true,
      });
      Object.defineProperty(window.navigator, 'userAgentData', {
        value: originalUserAgentData,
        configurable: true,
      });
    });

    it.each([
      ['Forem mobile app', 'ForemWebView/1'],
      [
        'Cursor built-in browser',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Cursor/0.49.6 Chrome/132.0.0.0 Electron/34.3.4 Safari/537.36',
      ],
      [
        'VS Code Integrated Browser',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Code/1.109.5 Chrome/134.0.0.0 Electron/35.1.2 Safari/537.36',
      ],
      [
        'Antigravity webview',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Antigravity/2.0.0 Chrome/136.0.0.0 Electron/36.0.0 Safari/537.36',
      ],
      [
        'Claude Desktop preview',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Claude/1.2.0 Chrome/134.0.0.0 Electron/35.0.0 Safari/537.36',
      ],
      [
        'Codex Desktop preview',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Codex/1.0.0 Chrome/135.0.0.0 Electron/35.1.0 Safari/537.36',
      ],
      [
        'macOS native WKWebView wrapper',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko)',
      ],
    ])(
      'skips fetching post_fixed_bottom in %s while still loading other placements',
      async (_label, ua) => {
        Object.defineProperty(window.navigator, 'userAgent', {
          value: ua,
          configurable: true,
        });

        document.body.innerHTML = `
          <div id="page-content-inner" data-internal-nav="false"></div>
          <div class="js-billboard-container" data-async-url="/billboards/post_fixed_bottom"></div>
          <div class="js-billboard-container" data-async-url="/billboards/post_sidebar"></div>
        `;

        mockFetch.mockResolvedValue({
          text: () =>
            Promise.resolve(
              '<div class="js-billboard"><div class="content">Sidebar Ad</div></div>',
            ),
        });

        await getBillboard();

        expect(mockFetch).not.toHaveBeenCalledWith('/billboards/post_fixed_bottom');
        expect(mockFetch).toHaveBeenCalledWith('/billboards/post_sidebar');
      },
    );
  });

  describe('cleanupStaleLiveStreamIntervals', () => {
    it('preserves intervals for overlays still present in the DOM and clears intervals for detached overlays', () => {
      document.body.innerHTML = '<div id="overlay-feed-42"></div>';
      const activeInterval = setInterval(() => {}, 10000);
      const staleInterval = setInterval(() => {}, 10000);

      window.liveStreamIntervals = {
        42: activeInterval,
        99: staleInterval,
      };

      cleanupStaleLiveStreamIntervals();

      expect(window.liveStreamIntervals['42']).toBe(activeInterval);
      expect(window.liveStreamIntervals['99']).toBeUndefined();

      clearInterval(activeInterval);
      clearInterval(staleInterval);
    });
  });
});
