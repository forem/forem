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
});
