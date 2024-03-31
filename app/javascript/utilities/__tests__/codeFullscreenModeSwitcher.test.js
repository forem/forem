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
    global.scrollTo = jest.fn();

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
    const spyWindow = jest.spyOn(window, 'addEventListener');

    goFullScreenButtons[0].click();

    testFullScreen();
    expect(spyDoc).toHaveBeenCalledWith('keyup', onPressEscape);
    expect(spyWindow).toHaveBeenCalledWith('popstate', onPopstate);
  });

  it('exits fullscreen mode on Escape key', () => {
    const spyDocRemove = jest.spyOn(document.body, 'removeEventListener');
    const spyWindowRemove = jest.spyOn(window, 'removeEventListener');

    testFullScreen();
    document.body.dispatchEvent(new KeyboardEvent('keyup', { key: 'Escape' }));
    testNonFullScreen();

    expect(spyDocRemove).toHaveBeenCalledWith('keyup', onPressEscape);
    expect(spyWindowRemove).toHaveBeenCalledWith('popstate', onPopstate);
  });

  it('re-enters fullscreen mode on click', () => {
    const goFullScreenButtons = getEnterFullScreenButtons();
    const spyDoc = jest.spyOn(document.body, 'addEventListener');
    const spyWindow = jest.spyOn(window, 'addEventListener');

    testNonFullScreen();
    goFullScreenButtons[0].click();
    testFullScreen();

    expect(spyDoc).toHaveBeenCalledWith('keyup', onPressEscape);
    expect(spyWindow).toHaveBeenCalledWith('popstate', onPopstate);
  });

  it('exits fullscreen mode on popstate event', () => {
    const spyDocRemove = jest.spyOn(document.body, 'removeEventListener');
    const spyWindowRemove = jest.spyOn(window, 'removeEventListener');

    testFullScreen();
    window.dispatchEvent(new PopStateEvent('popstate', { state: { key: '' } }));
    testNonFullScreen();

    expect(spyDocRemove).toHaveBeenCalledWith('keyup', onPressEscape);
    expect(spyWindowRemove).toHaveBeenCalledWith('popstate', onPopstate);
  });
});
