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
        assert.isFunction(win.ForemMobile.injectJSMessage);
        assert.isFunction(win.ForemMobile.injectNativeMessage);
        assert.isFunction(win.ForemMobile.userSessionBroadcast);
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

      // Manual attempt (?)
      cy.contains('.crayons-btn', 'Log in').click();
      cy.get('#user_email').type('admin@forem.local');
      cy.get('#user_password').type('password');
      cy.get('input[type="submit"]').click();
      cy.window().then((win) => {
        var res = JSON.parse(win.ForemMobile.getUserData());
        assert.isObject(res);
      });

      // Previous attempt with cy.loginUser():
      //
      // cy.fixture('users/adminUser.json').as('user');
      // cy.get('@user').then((user) => {
      //   return cy.loginUser(user);
      // }).then(() => {
      //   return cy.visit('/settings', runtimeStub);
      // }).then(() => cy.window()).then((win) => {
      //   var res = JSON.parse(win.ForemMobile.getUserData());
      //   assert.isObject(res);
      // });
    });

    it('should inject messages using CustomEvent', () => {
      cy.document()
        .then((doc) => {
          doc.addEventListener('ForemMobile', cy.stub().as('bridgeEvent'));
        })
        .then(() => cy.window())
        .then((win) => {
          win.ForemMobile.injectJSMessage({ action: 'test' });
        });

      // on load the app should have sent an event
      cy.get('@bridgeEvent')
        .should('have.been.calledOnce')
        .its('firstCall.args.0.detail')
        .should('deep.equal', { action: 'test' });
    });
  });

  it('should not load namespaced functions on other contexts', () => {
    cy.visit('/');
    cy.window().then((win) => assert.isUndefined(win.ForemMobile));
  });
});
