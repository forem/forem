describe('Follow author from article sidebar', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.viewport('macbook-16');
    cy.fixture('users/articleEditorV1User.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/').then(() => {
        cy.findAllByRole('link', { name: 'Test article' })
          .first()
          .click({ force: true });

        cy.get('[data-follow-clicks-initialized]');
        cy.findByRole('heading', { name: 'Test article' });
      });
    });
  });

  it('Follows and unfollows an author from the sidebar', () => {
    cy.intercept('/follows').as('followRequest');

    cy.findByRole('complementary', { name: 'Author details' }).within(() => {
      cy.findByRole('button', { name: 'Follow' }).as('followButton');
      cy.get('@followButton').click();

      cy.wait('@followRequest');
      cy.get('@followButton').should('have.text', 'Following');

      cy.get('@followButton').click();
      cy.wait('@followRequest');
      cy.get('@followButton').should('have.text', 'Follow');
    });
  });
});
