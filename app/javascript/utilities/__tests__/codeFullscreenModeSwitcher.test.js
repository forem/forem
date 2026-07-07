import {
  addFullScreenModeControl,
  getFullScreenModeStatus,
  onPressEscape,
  onPopstate,
} from '@utilities/codeFullscreenModeSwitcher';

describe('CodeFullScreenModeSwitcher Utility', () => {
  const getFullScreenElements = () =>
    ['.js-fullscreen-code.is-open', '.js-code-highlight.is-fullscreen'].map(
      (selector) => document.body.querySelector(selector),
    );

  const testFullScreenElements = ({ exists }) => {
    for (const element of getFullScreenElements()) {
      if (exists) expect(element).not.toBeNull();
      else expect(element).toBeNull();
    }
  };

  const testNonFullScreen = () => {
    expect(getFullScreenModeStatus()).toBe(false);
    testFullScreenElements({ exists: false });
    expect(document.body.style.overflow).toBe('');
  };

  const testFullScreen = () => {
    expect(getFullScreenModeStatus()).toBe(true);
    testFullScreenElements({ exists: true });
    expect(document.body.style.overflow).toBe('hidden');
  };

  const getEnterFullScreenButtons = () =>
    document.getElementsByClassName('js-fullscreen-code-action');

  beforeAll(() => {
    globalThis.scrollTo = jest.fn();

    document.body.innerHTML = `
      <div class="js-code-highlight">
        <div class="js-fullscreen-code-action"><div>
      </div>
      <div class="js-fullscreen-code"></div>
    `;
    addFullScreenModeControl(getEnterFullScreenButtons());
  });

  // Assertions are called within the `testNonFullScreen` function.
  // eslint-disable-next-line jest/expect-expect
  it('starts in non-fullscreen mode', testNonFullScreen);

  it('enters fullscreen mode on click', () => {
    const goFullScreenButtons = getEnterFullScreenButtons();
    const spyDoc = jest.spyOn(document.body, 'addEventListener');
    const spyWindow = jest.spyOn(globalThis, 'addEventListener');

    goFullScreenButtons[0].click();

    testFullScreen();
    expect(spyDoc).toHaveBeenCalledWith('keyup', onPressEscape);
    expect(spyWindow).toHaveBeenCalledWith('popstate', onPopstate);
  });

  it('exits fullscreen mode on Escape key', () => {
    const spyDocRemove = jest.spyOn(document.body, 'removeEventListener');
    const spyWindowRemove = jest.spyOn(globalThis, 'removeEventListener');

    testFullScreen();
    document.body.dispatchEvent(new KeyboardEvent('keyup', { key: 'Escape' }));
    testNonFullScreen();

    expect(spyDocRemove).toHaveBeenCalledWith('keyup', onPressEscape);
    expect(spyWindowRemove).toHaveBeenCalledWith('popstate', onPopstate);
  });

  it('re-enters fullscreen mode on click', () => {
    const goFullScreenButtons = getEnterFullScreenButtons();
    const spyDoc = jest.spyOn(document.body, 'addEventListener');
    const spyWindow = jest.spyOn(globalThis, 'addEventListener');

    testNonFullScreen();
    goFullScreenButtons[0].click();
    testFullScreen();

    expect(spyDoc).toHaveBeenCalledWith('keyup', onPressEscape);
    expect(spyWindow).toHaveBeenCalledWith('popstate', onPopstate);
  });

  it('exits fullscreen mode on popstate event', () => {
    const spyDocRemove = jest.spyOn(document.body, 'removeEventListener');
    const spyWindowRemove = jest.spyOn(globalThis, 'removeEventListener');

    testFullScreen();
    globalThis.dispatchEvent(
      new PopStateEvent('popstate', { state: { key: '' } }),
    );
    testNonFullScreen();

    expect(spyDocRemove).toHaveBeenCalledWith('keyup', onPressEscape);
    expect(spyWindowRemove).toHaveBeenCalledWith('popstate', onPopstate);
  });
});

describe('CodeFullScreenModeSwitcher edge cases', () => {
  const getButtons = () =>
    document.getElementsByClassName('js-fullscreen-code-action');

  const setupDom = () => {
    document.body.innerHTML = `
      <div class="js-code-highlight">
        <div class="js-fullscreen-code-action"></div>
      </div>
      <div class="js-fullscreen-code"></div>
    `;
    addFullScreenModeControl(getButtons());
  };

  beforeEach(() => {
    globalThis.scrollTo = jest.fn();
    setupDom();
  });

  afterEach(() => {
    // close any session a test left open so its listeners don't leak forward
    if (getFullScreenModeStatus()) {
      globalThis.dispatchEvent(new PopStateEvent('popstate'));
    }
    jest.restoreAllMocks();
  });

  it('ignores non-Escape key presses while fullscreen', () => {
    getButtons()[0].click();
    expect(getFullScreenModeStatus()).toBe(true);

    onPressEscape(new KeyboardEvent('keyup', { key: 'a' }));
    expect(getFullScreenModeStatus()).toBe(true);
  });

  it('does not throw or open on popstate when not in fullscreen', () => {
    expect(getFullScreenModeStatus()).toBe(false);
    expect(() =>
      globalThis.dispatchEvent(new PopStateEvent('popstate')),
    ).not.toThrow();
    expect(getFullScreenModeStatus()).toBe(false);
  });

  it('restores the page when the container is gone before popstate', () => {
    getButtons()[0].click();
    expect(getFullScreenModeStatus()).toBe(true);
    expect(document.body.style.overflow).toBe('hidden');

    const spyBodyRemove = jest.spyOn(document.body, 'removeEventListener');
    const spyWindowRemove = jest.spyOn(globalThis, 'removeEventListener');

    // simulate a soft navigation swapping out the page body
    document.body.innerHTML = '';

    expect(() =>
      globalThis.dispatchEvent(new PopStateEvent('popstate')),
    ).not.toThrow();

    expect(getFullScreenModeStatus()).toBe(false);
    // the interrupted session must release the scroll lock and its listeners
    expect(document.body.style.overflow).toBe('');
    expect(spyBodyRemove).toHaveBeenCalledWith('keyup', onPressEscape);
    expect(spyWindowRemove).toHaveBeenCalledWith('popstate', onPopstate);
  });

  it('restores the pre-fullscreen scroll position on exit', () => {
    Object.defineProperty(globalThis, 'scrollY', {
      value: 250,
      writable: true,
      configurable: true,
    });

    getButtons()[0].click();
    document.body.dispatchEvent(new KeyboardEvent('keyup', { key: 'Escape' }));

    expect(globalThis.scrollTo).toHaveBeenCalledWith(0, 250);
  });

  it('re-enters fullscreen and Escape still works after a back > forward sequence', () => {
    getButtons()[0].click();
    document.body.innerHTML = ''; // back: soft nav drops the container
    globalThis.dispatchEvent(new PopStateEvent('popstate'));
    expect(getFullScreenModeStatus()).toBe(false);

    setupDom(); // forward: article DOM restored

    getButtons()[0].click();
    expect(getFullScreenModeStatus()).toBe(true);

    document.body.dispatchEvent(new KeyboardEvent('keyup', { key: 'Escape' }));
    expect(getFullScreenModeStatus()).toBe(false);
  });

  it('still opens with a single click after the pack re-binds controls', () => {
    // InstantClick re-runs the pack on soft navigation, re-calling this bind.
    addFullScreenModeControl(getButtons());
    addFullScreenModeControl(getButtons());

    getButtons()[0].click();
    expect(getFullScreenModeStatus()).toBe(true);
  });

  it('derives open/closed from the DOM, so a click always matches the overlay', () => {
    // The old module tracked state in a boolean that could stick "open" after an
    // interrupted navigation, inverting the next click into a no-op collapse.
    getButtons()[0].click();
    expect(getFullScreenModeStatus()).toBe(true);
    getButtons()[0].click();
    expect(getFullScreenModeStatus()).toBe(false);
    getButtons()[0].click();
    expect(getFullScreenModeStatus()).toBe(true);
  });
});
