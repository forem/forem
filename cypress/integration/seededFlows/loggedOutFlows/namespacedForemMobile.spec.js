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

  beforeEach(() => cy.testSetup());

  describe('within ForemWebView context', () => {
    beforeEach(() => cy.visit('/', runtimeStub));

    it('should load the ForemMobile namespaced functions', () => {
      cy.window().then((win) => {
        assert.isNumber(win.ForemMobile.retryDelayMs);
        assert.isFunction(win.ForemMobile.getUserData);
        assert.isFunction(win.ForemMobile.getInstanceMetadata);
        assert.isFunction(win.ForemMobile.registerDeviceToken);
        assert.isFunction(win.ForemMobile.unregisterDeviceToken);
      });
    });

    it('should return the instance metadata JSON when requested', () => {
      cy.window().then((win) => {
        var res = JSON.parse(win.ForemMobile.getInstanceMetadata());
        assert.isObject(res);
        assert.equal(res.domain, 'localhost:3000');
        assert.isString(res.logo);
        assert.isString(res.name);
      });
    });

    it('should return empty user data when logged out', () => {
      cy.window().then((win) => {
        assert.isUndefined(win.ForemMobile.getUserData());
      });
    });

    it('should return user data JSON when logged in', () => {
      // Attempt to login user and fetch its data
      cy.fixture('users/adminUser.json').as('user');
      cy.get('@user').then((user) => {
        cy.loginUser(user).then(() => {
          cy.visit('/settings', runtimeStub)
            .then(() => cy.window())
            .then((win) => {
              var res = JSON.parse(win.ForemMobile.getUserData());
              assert.isObject(res);
            });
        });
      });
    });
  });

  it('should not load namespaced functions on other contexts', () => {
    cy.visit('/');
    cy.window().then((win) => assert.isUndefined(win.ForemMobile));
  });
});
