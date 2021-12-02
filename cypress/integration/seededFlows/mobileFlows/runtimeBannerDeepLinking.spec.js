describe('Runtime Banner Deep Linking', () => {
  const runtimeStub = {
    onBeforeLoad: (win) => {
      Object.defineProperty(win.navigator, 'userAgent', {
        value:
          'Mozilla/5.0 (iPhone; CPU iPhone OS 14_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.3 Mobile/15E148 Safari/604.1',
      });
      Object.defineProperty(win.navigator, 'platform', { value: 'iPhone' });
    },
  };
  beforeEach(() => {
    cy.testSetup();
    cy.visit(`/`, runtimeStub);
  });

  it('should include the correct deep_link param in the banner link', () => {
    // When visiting the root path the banner should deep link into it
    cy.get('.runtime-banner > a')
      .should('have.attr', 'href')
      .and('contains', `deep_link%3D%2F`);
    // NOTE: %3D%2F -> '=/' (URL Encoded)

    // When visiting `/tags` the banner should deep link into `/tags`
    cy.visit('/tags', runtimeStub).then(() => {
      cy.get('.runtime-banner > a')
        .should('have.attr', 'href')
        .and('contains', `deep_link%3D%2Ftags`);
      // NOTE: %3D%2Ftags -> '=/tags' (URL Encoded)
    });
  });

  it('should show a loading spinner and then the fallback page', () => {
    const deepLinkPath = '/custom_path2';
    cy.visit(`/r/mobile?deep_link=${deepLinkPath}`).then(() => {
      // The loading spinner appears with the following text
      cy.get('p').contains('Opening the mobile app...').should('be.visible');
      cy.get('p')
        .contains('Whoops! Did you get stuck trying to open the mobile app?')
        .should('be.visible');
      cy.get('a').contains('Take me back').should('be.visible');
      cy.get('a').contains('Try again').should('be.visible');
      cy.get('a').contains('Install the app').should('be.visible');

      // Also the loading text should not exist anymore
      cy.get('p').contains('Opening the mobile app...').should('not.exist');
    });
  });
});
