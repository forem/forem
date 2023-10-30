import { getBillboard } from '../packs/billboard';
import { executeBBScripts } from '../packs/billboardAfterRenderActions';

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

  test('should clone and re-insert script tags in fetched content', async () => {
    // Setup fetch to return a script tag
    global.fetch = jest.fn(() =>
      Promise.resolve({
        text: () =>
          Promise.resolve(
            '<script type="text/javascript">console.log("test")</script>',
          ),
      }),
    );

    await getBillboard();

    // Find the new script tags in the document
    const scriptElements = document.querySelectorAll(
      '.js-billboard-container script',
    );

    // Assert that the script tags are properly cloned and re-inserted
    expect(scriptElements.length).toBe(2); // You have two .js-billboard-container in your setup, so expect two script tags
    scriptElements.forEach((script) => {
      expect(script.type).toEqual('text/javascript'); // Should retain attributes
      expect(script.innerHTML).toEqual('console.log("test")'); // Should retain content
    });
  });
});

describe('executeBBScripts', () => {
  let container;

  beforeEach(() => {
    container = document.createElement('div');
    document.body.appendChild(container);
  });

  afterEach(() => {
    document.body.removeChild(container);
  });

  test('should execute script when script tag is present', () => {
    container.innerHTML = '<script>window.someGlobalVar = "executed";</script>';

    executeBBScripts(container);

    expect(window.someGlobalVar).toBe('executed');
  });

  test('should skip null or undefined script elements', () => {
    container.innerHTML = '<script>window.someGlobalVar = "executed";</script>';
    // Simulating an inconsistency in the returned HTMLCollection
    const spiedGetElementsByTagName = jest
      .spyOn(container, 'getElementsByTagName')
      .mockReturnValue([null, undefined]);

    executeBBScripts(container);

    expect(spiedGetElementsByTagName).toBeCalled();
  });

  test('should copy attributes of original script element', () => {
    container.innerHTML =
      '<script type="text/javascript" async>window.someGlobalVar = "executed";</script>';

    executeBBScripts(container);

    const newScript = container.querySelector('script');
    expect(newScript.type).toBe('text/javascript');
  });

  test('should remove the original script element', () => {
    container.innerHTML = '<script>window.someGlobalVar = "executed";</script>';

    executeBBScripts(container);

    const allScripts = container.getElementsByTagName('script');
    expect(allScripts.length).toBe(1);
  });

  test('should insert the new script element at the same position as the original', () => {
    container.innerHTML =
      '<div></div><script>window.someGlobalVar = "executed";</script><div></div>';

    executeBBScripts(container);

    const middleChild = container.children[1];
    expect(middleChild.tagName).toBe('SCRIPT');
    expect(middleChild.textContent).toBe('window.someGlobalVar = "executed";');
  });
});
