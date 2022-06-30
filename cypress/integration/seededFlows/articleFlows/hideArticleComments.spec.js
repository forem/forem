describe('Hiding/unhiding comments on an article', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/admin_mcadmin/test-article-slug');
    });
  });

  describe('Admin visits the article authored by them', () => {
    it('Allows a user to hide/unhide a comment', () => {
      cy.findByRole('button', { name: 'Toggle dropdown menu' }).click();
      cy.findByRole('button', { name: "Hide Admin McAdmin's comment" }).click();

      // Check we also expose the link to report abuse
      cy.findByRole('link', { name: 'reporting abuse' })
        .should('have.attr', 'href')
        .and('contains', `/admin_mcadmin/comment/`);

      cy.findByRole('button', { name: 'Confirm' }).click();

      // Page reloads after confirm click - we check the new page references the hidden comment
      cy.findByText(
        /Some comments have been hidden by the post's author/,
      ).should('exist');

      cy.findByRole('img', { name: 'Expand' }).click();
      cy.findByRole('button', { name: 'Toggle dropdown menu' }).click();
      cy.findByRole('link', {
        name: "Unhide Admin McAdmin's comment",
      }).click();

      // Page reloads with no hidden comments
      cy.findByText(
        /Some comments have been hidden by the post's author/,
      ).should('not.exist');

      cy.findByRole('img', { name: 'Expand' }).should('not.exist');
    });
  });
});
