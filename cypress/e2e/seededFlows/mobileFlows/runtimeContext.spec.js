describe('Runtime Context', () => {
  beforeEach(() => {
    cy.testSetup();
  });

  it('should detect the context and set the corresponding runtime attr', () => {
    const supportedPlatforms = [
      {
        // Windows 10 Chrome 89.0
        userAgent:
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.90 Safari/537.36',
        platform: 'Win32',
        expectedContext: 'Browser-Windows',
      },
      {
        // Linux Firefox
        userAgent:
          'Mozilla/5.0 (X11; Linux x86_64; rv:87.0) Gecko/20100101 Firefox/87.0',
        platform: 'Linux x86_64',
        expectedContext: 'Browser-Linux',
      },
      {
        // macOS Big Sur 11.2.2 (Intel processor) Chrome 89.0
        userAgent:
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 11_2_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.90 Safari/537.36',
        platform: 'MacIntel',
        expectedContext: 'Browser-macOS',
      },
      {
        // macOS Big Sur (M1 processor) Safari
        userAgent:
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.3 Safari/605.1.15',
        platform: 'MacIntel',
        expectedContext: 'Browser-macOS',
      },
      {
        // Android 10 Chrome 88
        userAgent:
          'Mozilla/5.0 (Linux; Android 10; SM-A217M) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.181 Mobile Safari/537.36',
        platform: 'Linux armv8l',
        expectedContext: 'Browser-Android',
      },
      {
        // iOS 14.4.1 Safari
        userAgent:
          'Mozilla/5.0 (iPhone; CPU iPhone OS 14_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.3 Mobile/15E148 Safari/604.1',
        platform: 'iPhone',
        expectedContext: 'Browser-iOS',
      },
      {
        // ForemWebView (Forem iOS app)
        userAgent:
          'Mozilla/5.0 (iPhone; CPU iPhone OS 14_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 ForemWebView/1.0',
        platform: 'iPhone',
        expectedContext: 'ForemWebView-iOS',
      },
    ];

    supportedPlatforms.forEach((platform) => {
      // Visit the site
      cy.visit('/', {
        onBeforeLoad: (win) => {
          Object.defineProperty(win.navigator, 'userAgent', {
            value: platform.userAgent,
          });
          Object.defineProperty(win.navigator, 'platform', {
            value: platform.platform,
          });
        },
      });

      // Check the body's data-runtime attribute
      cy.get('body')
        .should('have.attr', 'data-runtime')
        .and('equal', platform.expectedContext);
    });
  });
});
