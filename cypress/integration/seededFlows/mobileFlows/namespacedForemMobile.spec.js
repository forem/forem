// This E2E test focuses on ensuring the mobile bridge integration
describe('Namespaced ForemMobile functions', () => {
  function waitForBaseDataLoaded() {
    cy.get('body').should('have.attr', 'data-loaded', 'true');
  }

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

  describe('within ForemWebView context', () => {
    describe('when logged in', () => {
      beforeEach(() => {
        cy.testSetup();
        cy.fixture('users/adminUser.json').as('user');
        cy.get('@user').then((user) => {
          cy.loginUser(user).then(() => {
            cy.visitAndWaitForUserSideEffects('/', runtimeStub);
            cy.get('body').should('have.attr', 'data-user-status', 'logged-in');
            waitForBaseDataLoaded();
          });
        });
      });

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

      it('should return user data when logged in', () => {
        cy.window().then((win) => {
          cy.fixture('users/adminUser.json').as('user');
          cy.get('@user').then((expected) => {
            const actual = JSON.parse(win.ForemMobile.getUserData());

            expect(actual.username).to.equal(expected.username);
          });
        });
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

    describe('when logged out', () => {
      it('should return empty user data when logged out', () => {
        cy.testSetup();
        cy.visitAndWaitForUserSideEffects('/', runtimeStub, false);
        waitForBaseDataLoaded();

        // ensures the dynamic import had time to complete before
        // referencing the attribute
        cy.window().should('have.attr', 'ForemMobile');
        cy.window().then((win) => {
          assert.isUndefined(win.ForemMobile.getUserData());
        });
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
  });

  describe('Non-mobile', () => {
    it('should not load namespaced functions on other contexts', () => {
      cy.testSetup();
      cy.visit('/');
      waitForBaseDataLoaded();

      cy.get('body')
        .invoke('attr', 'data-runtime')
        .should('contain', 'Browser-');

      cy.window().then((win) => {
        assert.isUndefined(win.ForemMobile);
      });
    });
  });
});
