describe('Moderation Tools for Posts', () => {
  beforeEach(() => {
    cy.testSetup();
  });

  it('should load moderation tools on a post for a trusted user', () => {
    cy.fixture('users/trustedUser.json').as('user');
    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/').then(() => {
        cy.findAllByRole('link', { name: 'Test article' })
          .first()
          .click({ force: true });
        cy.findByRole('button', { name: 'Moderation' }).should('exist');
      });
    });
  });

  it('should not load moderation tools for a post when the logged on user is not a trusted user', () => {
    cy.fixture('users/articleEditorV1User.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/').then(() => {
        cy.findAllByRole('link', { name: 'Test article' })
          .first()
          .click({ force: true });

        cy.findByRole('button', { name: 'Moderation' }).should('not.exist');
      });
    });
  });

  it('should not load moderation tools for a post when not logged in', () => {
    cy.fixture('users/articleEditorV1User.json').as('user');

    cy.visit('/').then(() => {
      cy.findAllByRole('link', { name: 'Test article' })
        .first()
        .click({ force: true });

      cy.findByRole('button', { name: 'Moderation' }).should('not.exist');
    });
  });

  it('should not alter tags from a post if a reason is not specified', () => {
    cy.fixture('users/adminUser.json').as('user');
    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/admin_mcadmin/tag-test-article').then(() => {
        cy.findByRole('button', { name: 'Moderation' }).click();

        cy.getIframeBody('[title="Moderation panel actions"]').within(() => {
          cy.findByRole('button', { name: 'Open adjust tags section' }).click({
            force: true,
          });

          cy.findByRole('button', { name: '#tag1 Remove tag' }).click();
          cy.findByRole('button', { name: 'Submit' }).click();
        });

        cy.findByTestId('snackbar').should('not.exist');
      });
    });
  });
});
