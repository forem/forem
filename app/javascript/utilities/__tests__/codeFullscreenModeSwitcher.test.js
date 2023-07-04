const importModule = () => import('@utilities/codeFullscreenModeSwitcher');

describe('CodeFullScreenModeSwitcher Utility', () => {
  let addFullScreenModeControl, getFullScreenModeStatus;
  let onPressEscape, resetBodyOverflow;

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
    global.scrollTo = jest.fn();

    document.body.innerHTML = `
      <div class="js-code-highlight">
        <button class="js-fullscreen-code-action">Toggle Full Screen</button>
      </div>
      <div class="js-fullscreen-code"></div>
    `;
  });

  beforeAll(async () => {
    ({ addFullScreenModeControl, getFullScreenModeStatus } =
      await importModule());
    addFullScreenModeControl(getEnterFullScreenButtons());
  });

  beforeAll(async () => {
    // eventListener functions
    ({ onPressEscape, resetBodyOverflow } = await importModule());
  });

  it('starts in non-fullscreen mode', testNonFullScreen);

  it('enters fullscreen mode on click', () => {
    const goFullScreenButtons = getEnterFullScreenButtons();
    const spyDoc = jest.spyOn(document.body, 'addEventListener');
    const spyWindow = jest.spyOn(window, 'addEventListener');

    goFullScreenButtons[0].click();

    testFullScreen();
    expect(spyDoc).toHaveBeenCalledWith('keyup', onPressEscape);
    expect(spyWindow).toHaveBeenCalledWith('popstate', resetBodyOverflow);
  });

  it('exits fullscreen mode on Escape key', () => {
    const goFullScreenButtons = getEnterFullScreenButtons();
    const spyDocRemove = jest.spyOn(document.body, 'removeEventListener');
    const spyWindowRemove = jest.spyOn(window, 'removeEventListener');

    testFullScreen();
    goFullScreenButtons[0].click();

    document.body.dispatchEvent(new KeyboardEvent('keyup', { key: 'Escape' }));

    testNonFullScreen();
    expect(spyDocRemove).toHaveBeenCalledWith('keyup', onPressEscape);
    expect(spyWindowRemove).toHaveBeenCalledWith('popstate', resetBodyOverflow);
  });

  it('re-enters fullscreen mode on click', () => {
    const goFullScreenButtons = getEnterFullScreenButtons();
    const spyDoc = jest.spyOn(document.body, 'addEventListener');
    const spyWindow = jest.spyOn(window, 'addEventListener');

    testNonFullScreen();
    goFullScreenButtons[0].click();

    testFullScreen();
    expect(spyDoc).toHaveBeenCalledWith('keyup', onPressEscape);
    expect(spyWindow).toHaveBeenCalledWith('popstate', resetBodyOverflow);
  });

  it('exits fullscreen mode on popstate event', () => {
    const goFullScreenButtons = getEnterFullScreenButtons();
    const spyDocRemove = jest.spyOn(document.body, 'removeEventListener');
    const spyWindowRemove = jest.spyOn(window, 'removeEventListener');

    testFullScreen();
    goFullScreenButtons[0].click();

    window.dispatchEvent(new PopStateEvent('popstate', { state: { key: '' } }));

    testNonFullScreen();
    expect(spyDocRemove).toHaveBeenCalledWith('keyup', onPressEscape);
    expect(spyWindowRemove).toHaveBeenCalledWith('popstate', resetBodyOverflow);
  });
});
