import { getBillboard } from '../billboard';
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

  beforeEach(() => {
    // Reset mocks
    jest.clearAllMocks();
    
    // Set up dummy elements and environment variables
    document.body.innerHTML = '';
    global.Honeybadger = { notify: jest.fn() };
    
    // Mock window.fetch
    mockFetch = jest.fn();
    global.fetch = mockFetch;
  });

  afterEach(() => {
    delete global.fetch;
    delete global.Honeybadger;
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
});
