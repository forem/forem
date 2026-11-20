import { isEmbeddedBrowserContext } from '@utilities/runtime';

const TOP_WINDOW = {};
TOP_WINDOW.self = TOP_WINDOW;
TOP_WINDOW.top = TOP_WINDOW;

describe('isEmbeddedBrowserContext', () => {
  describe('embedded IDE, Electron, and native wrapper User-Agents', () => {
    it.each([
      [
        'VS Code Integrated Browser',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Code/1.109.5 Chrome/134.0.6998.179 Electron/35.1.2 Safari/537.36',
      ],
      [
        'Cursor built-in browser',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Cursor/0.49.6 Chrome/132.0.6834.210 Electron/34.3.4 Safari/537.36',
      ],
      [
        'Windsurf Preview',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Windsurf/1.6.0 Chrome/132.0.0.0 Electron/34.0.0 Safari/537.36',
      ],
      [
        'Antigravity desktop/IDE webview',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Antigravity/2.0.0 Chrome/136.0.0.0 Electron/36.0.0 Safari/537.36',
      ],
      [
        'Claude Desktop preview',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Claude/1.2.0 Chrome/134.0.0.0 Electron/35.0.0 Safari/537.36',
      ],
      [
        'OpenAI Codex Desktop app',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Codex/1.0.0 Chrome/135.0.0.0 Electron/35.1.0 Safari/537.36',
      ],
      [
        'IDE wrapper that stripped Electron/ token',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Cursor/0.50.0 Chrome/134.0.0.0 Safari/537.36',
      ],
      [
        'Generic Electron desktop app (e.g. Slack/Discord/Obsidian)',
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Obsidian/1.8.9 Chrome/132.0.6834.83 Electron/34.0.1 Safari/537.36',
      ],
      ['ForemWebView mobile wrapper', 'ForemWebView/1'],
      ['DEV-Native-ios wrapper', 'DEV-Native-ios'],
      ['DEV-Native-android wrapper', 'DEV-Native-android'],
      [
        'macOS native WKWebView (no Safari token)',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko)',
      ],
      [
        'iOS native WKWebView in-app browser (no Safari token)',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 18_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148',
      ],
      [
        'Android WebView (; wv)',
        'Mozilla/5.0 (Linux; Android 15; Pixel 9 Build/AP3A; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/134.0.0.0 Mobile Safari/537.36',
      ],
    ])('detects %s as embedded', (_label, userAgent) => {
      expect(
        isEmbeddedBrowserContext({
          userAgent,
          userAgentData: undefined,
          win: TOP_WINDOW,
        }),
      ).toBe(true);
    });
  });

  describe('User-Agent Client Hints (navigator.userAgentData)', () => {
    it('detects Microsoft Edge WebView2 even when UA looks like desktop Edge', () => {
      expect(
        isEmbeddedBrowserContext({
          userAgent:
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36 Edg/134.0.0.0',
          userAgentData: {
            platform: 'Windows',
            brands: [
              { brand: 'Not:A-Brand', version: '99' },
              { brand: 'Microsoft Edge', version: '134' },
              { brand: 'Chromium', version: '134' },
              { brand: 'Microsoft Edge WebView2', version: '134' },
            ],
          },
          win: TOP_WINDOW,
        }),
      ).toBe(true);
    });

    it('detects unbranded Chromium on macOS/Windows (stripped-UA Electron or JCEF)', () => {
      expect(
        isEmbeddedBrowserContext({
          userAgent:
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36',
          userAgentData: {
            platform: 'macOS',
            brands: [
              { brand: 'Not:A-Brand', version: '99' },
              { brand: 'Chromium', version: '134' },
            ],
          },
          win: TOP_WINDOW,
        }),
      ).toBe(true);
    });

    it('does not flag unbranded distro Chromium on Linux', () => {
      expect(
        isEmbeddedBrowserContext({
          userAgent:
            'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36',
          userAgentData: {
            platform: 'Linux',
            brands: [
              { brand: 'Not:A-Brand', version: '99' },
              { brand: 'Chromium', version: '134' },
            ],
          },
          win: TOP_WINDOW,
        }),
      ).toBe(false);
    });
  });

  describe('iframe framing', () => {
    it('detects iframe-hosted IDE previews (window.self !== window.top)', () => {
      const framedWin = { self: {}, top: {} };
      expect(
        isEmbeddedBrowserContext({
          userAgent:
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36',
          userAgentData: undefined,
          win: framedWin,
        }),
      ).toBe(true);
    });

    it('treats cross-origin SecurityError on window.top access as framed', () => {
      const crossOriginWin = { self: {} };
      Object.defineProperty(crossOriginWin, 'top', {
        get() {
          throw new DOMException(
            'Blocked a frame from accessing a cross-origin frame.',
          );
        },
      });

      expect(
        isEmbeddedBrowserContext({
          userAgent:
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36',
          userAgentData: undefined,
          win: crossOriginWin,
        }),
      ).toBe(true);
    });
  });

  describe('standalone browsers are not flagged', () => {
    it.each([
      [
        'Google Chrome on macOS',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36',
        {
          platform: 'macOS',
          brands: [
            { brand: 'Google Chrome', version: '135' },
            { brand: 'Chromium', version: '135' },
            { brand: 'Not-A.Brand', version: '99' },
          ],
        },
      ],
      [
        'Microsoft Edge on Windows',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36 Edg/135.0.0.0',
        {
          platform: 'Windows',
          brands: [
            { brand: 'Microsoft Edge', version: '135' },
            { brand: 'Chromium', version: '135' },
            { brand: 'Not-A.Brand', version: '99' },
          ],
        },
      ],
      [
        'Brave on macOS',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36',
        {
          platform: 'macOS',
          brands: [
            { brand: 'Brave', version: '135' },
            { brand: 'Chromium', version: '135' },
            { brand: 'Not-A.Brand', version: '99' },
          ],
        },
      ],
      [
        'Safari on macOS',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.3 Safari/605.1.15',
        undefined,
      ],
      [
        'Firefox on macOS',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:136.0) Gecko/20100101 Firefox/136.0',
        undefined,
      ],
      [
        'Safari on iOS',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 18_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.3 Mobile/15E148 Safari/604.1',
        undefined,
      ],
      [
        'Chrome on iOS (CriOS)',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 18_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.53 Mobile/15E148 Safari/604.1',
        undefined,
      ],
      [
        'Firefox on iOS (FxiOS)',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 18_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) FxiOS/136.0 Mobile/15E148 Safari/605.1.15',
        undefined,
      ],
    ])('does not flag %s', (_label, userAgent, userAgentData) => {
      expect(
        isEmbeddedBrowserContext({
          userAgent,
          userAgentData,
          win: TOP_WINDOW,
        }),
      ).toBe(false);
    });
  });
});
