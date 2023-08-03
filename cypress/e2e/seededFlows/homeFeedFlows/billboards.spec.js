describe('Home page billboards', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user);
    });
  });

  context('with location targeting', () => {
    beforeEach(() => {
      cy.intercept(`/**`, (req) => {
        req.headers['HTTP_CLIENT_GEO'] = 'US-CA'; // User in California
      });
      cy.enableFeatureFlag('billboard_location_targeting');
      cy.visitAndWaitForUserSideEffects('/');
    });

    it("shows billboards targeting a signed-in user's location", () => {
      cy.findByRole('main').within(() => {
        cy.get('.billboard')
          .should('contain', 'This is a billboard shown to people in Canada')
          .and('not.contain', 'This is a billboard shown to people in the US');
      });
    });

    it('shows billboards that do not target any location', () => {
      cy.findByLabelText('Primary sidebar').within(() => {
        cy.get('.billboard').should('contain', 'This is a regular billboard');
      });
    });
  });
});
