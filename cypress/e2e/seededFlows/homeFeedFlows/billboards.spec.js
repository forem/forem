describe('Home page billboards', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');
  });

  context('with location targeting', () => {
    beforeEach(() => {
      cy.intercept(`/**`, (req) => {
        // User in Ontario, Canada
        req.headers['X-Client-Geo'] = 'CA-ON';
        req.headers['X-Cacheable-Client-Geo'] = 'CA';
      });
      cy.enableFeatureFlag('billboard_location_targeting');
    });

    context('when a user is signed in', () => {
      beforeEach(() => {
        cy.get('@user').then((user) => {
          cy.loginAndVisit(user, '/');
        });
      });

      it('shows billboards targeting their location', () => {
        cy.findByRole('main').within(() => {
          cy.get('.bb-placement')
            .should('contain', 'This is a billboard shown to people in Ontario')
            .and(
              'not.contain',
              'This is a billboard shown to people in the US',
            );
        });
      });

      it('shows billboards that do not target any location', () => {
        cy.findByLabelText('Primary sidebar').within(() => {
          cy.get('.bb-placement').should('contain', 'This is a regular billboard');
        });
      });
    });

    context('when a user is not signed in', () => {
      beforeEach(() => {
        cy.visit('/');
      });

      it('only shows billboards with a cacheable target geolocation', () => {
        cy.findByRole('main').within(() => {
          cy.get('.bb-placement').should('not.exist');
        });
      });

      it('shows billboards that do not target any location', () => {
        cy.findByLabelText('Primary sidebar').within(() => {
          cy.get('.bb-placement').should('contain', 'This is a regular billboard');
        });
      });
    });
  });
});
