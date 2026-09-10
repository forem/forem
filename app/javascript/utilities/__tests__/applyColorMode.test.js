import '../../../assets/javascripts/utilities/applyColorMode';

/* global globalThis applyColorMode darkColorModeEnabled watchColorModeChanges */

function mockPrefersDark(matches) {
  const listeners = [];

  window.matchMedia = jest.fn().mockImplementation((media) => ({
    matches,
    media,
    addEventListener: (_eventName, handler) => listeners.push(handler),
    removeEventListener: jest.fn(),
  }));

  return listeners;
}

function renderThemeStyleTags() {
  document.body.innerHTML = `
    <div id="dark-mode-style">:root { --base: dark; }</div>
    <div id="light-mode-style">:root { --base: light; }</div>
    <div id="body-styles"><style>:root { --base: initial; }</style></div>
  `;
}

describe('applyColorMode', () => {
  beforeEach(() => {
    delete window.colorModeWatcherStarted;
    document.body.className = '';
    renderThemeStyleTags();
    mockPrefersDark(false);
  });

  afterAll(() => {
    delete globalThis.applyColorMode;
    delete globalThis.darkColorModeEnabled;
    delete globalThis.watchColorModeChanges;
  });

  describe('darkColorModeEnabled', () => {
    it('is false when no body class is available', () => {
      expect(darkColorModeEnabled(null)).toBe(false);
      expect(darkColorModeEnabled('')).toBe(false);
    });

    it('is false for an explicit light theme even when the OS prefers dark', () => {
      mockPrefersDark(true);

      expect(darkColorModeEnabled('light-theme default-header')).toBe(false);
    });

    it('is true for an explicit dark theme even when the OS prefers light', () => {
      mockPrefersDark(false);

      expect(darkColorModeEnabled('dark-theme default-header')).toBe(true);
    });

    it('follows the OS preference for the system theme', () => {
      mockPrefersDark(true);
      expect(darkColorModeEnabled('system-theme default-header')).toBe(true);

      mockPrefersDark(false);
      expect(darkColorModeEnabled('system-theme default-header')).toBe(false);
    });

    it('is false for the system theme when matchMedia is unavailable', () => {
      window.matchMedia = undefined;

      expect(darkColorModeEnabled('system-theme default-header')).toBe(false);
    });
  });

  describe('applyColorMode', () => {
    it('applies the dark styles when the system theme resolves to dark', () => {
      mockPrefersDark(true);

      expect(applyColorMode('system-theme default-header')).toBe(true);
      expect(document.body.classList.contains('dark-theme')).toBe(true);
      expect(document.body.classList.contains('ten-x-hacker-theme')).toBe(true);
      expect(document.getElementById('body-styles').innerHTML).toContain(
        '--base: dark;',
      );
    });

    it('applies the light styles when the system theme resolves to light', () => {
      document.body.className = 'system-theme dark-theme ten-x-hacker-theme';

      expect(applyColorMode(document.body.className)).toBe(false);

      const { classList } = document.body;

      expect(classList.contains('dark-theme')).toBe(false);
      expect(classList.contains('ten-x-hacker-theme')).toBe(false);
      expect(document.getElementById('body-styles').innerHTML).toContain(
        '--base: light;',
      );
    });

    it('leaves an explicit dark choice untouched when the OS prefers light', () => {
      expect(applyColorMode('dark-theme ten-x-hacker-theme')).toBe(true);
      expect(document.body.classList.contains('dark-theme')).toBe(true);
      expect(document.getElementById('body-styles').innerHTML).toContain(
        '--base: dark;',
      );
    });

    it('leaves an explicit light choice untouched when the OS prefers dark', () => {
      mockPrefersDark(true);

      expect(applyColorMode('light-theme')).toBe(false);
      expect(document.body.classList.contains('dark-theme')).toBe(false);
      expect(document.getElementById('body-styles').innerHTML).toContain(
        '--base: light;',
      );
    });
  });

  describe('watchColorModeChanges', () => {
    it('reapplies the color mode when the OS preference flips', () => {
      const listeners = mockPrefersDark(false);
      document.body.className = 'system-theme default-header';

      watchColorModeChanges();
      applyColorMode(document.body.className);

      expect(document.body.classList.contains('dark-theme')).toBe(false);

      mockPrefersDark(true);
      listeners.forEach((handler) => handler());

      expect(document.body.classList.contains('dark-theme')).toBe(true);
      expect(document.getElementById('body-styles').innerHTML).toContain(
        '--base: dark;',
      );
    });

    it('only registers a single listener', () => {
      const listeners = mockPrefersDark(false);

      watchColorModeChanges();
      watchColorModeChanges();

      expect(listeners).toHaveLength(1);
    });
  });
});
