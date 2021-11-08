describe('Namespaced ForemMobile functions', () => {
  // Make the runtime act as ForemWebView context
  const runtimeStub = {
    onBeforeLoad: (win) => {
      Object.defineProperty(win.navigator, 'userAgent', {
        value:
          'Mozilla/5.0 (iPhone; CPU iPhone OS 14_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 ForemWebView/1.0',
      });
      Object.defineProperty(win.navigator, 'platform', { value: 'iPhone' });
    },
  };
  beforeEach(() => {
    cy.testSetup();
  });

  it('should load namespaced functions within ForemWebView context', () => {
    cy.visit('/', runtimeStub);
    cy.window().then((win) => {
      assert.isNumber(win.ForemMobile.retryDelayMs);
      assert.isFunction(win.ForemMobile.getUserData);
      assert.isFunction(win.ForemMobile.getInstanceMetadata);
      assert.isFunction(win.ForemMobile.registerDeviceToken);
      assert.isFunction(win.ForemMobile.unregisterDeviceToken);
    });
  });

  it('should not load namespaced functions on other contexts', () => {
    cy.visit('/');
    cy.window().then((win) => assert.isUndefined(win.ForemMobile));
  });
});
