describe('Follow tag', () => {
  describe('Tag index page', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/articleEditorV1User.json').as('user');

      cy.get('@user').then((user) => {
        cy.loginAndVisit(user, '/tags').then(() => {
          cy.findByRole('heading', { name: 'Top tags' });
          cy.get('[data-follow-clicks-initialized]');
        });
      });
    });

    it('Follows and unfollows a tag from the tag index page', () => {
      cy.intercept('/follows').as('followsRequest');
      cy.findByRole('button', { name: 'Follow tag: tag1' }).as('followButton');

      cy.get('@followButton').click();
      cy.wait('@followsRequest');

      cy.get('@followButton').should('have.text', 'Following');

      cy.get('@followButton').click();
      cy.wait('@followsRequest');

      cy.get('@followButton').should('have.text', 'Follow');
    });
  });

  describe('Tag feed page', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/articleEditorV1User.json').as('user');

      cy.get('@user').then((user) => {
        cy.loginAndVisit(user, '/t/tag1').then(() => {
          cy.findByRole('heading', { name: '# tag1' });
          cy.get('[data-follow-clicks-initialized]');
        });
      });
    });

    it('Follows and unfollows a tag from the tag feed page', () => {
      cy.intercept('/follows').as('followsRequest');
      cy.findByRole('button', { name: 'Follow tag: tag1' }).as('followButton');

      cy.get('@followButton').click();
      cy.wait('@followsRequest');

      cy.get('@followButton').should('have.text', 'Following');

      cy.get('@followButton').click();
      cy.wait('@followsRequest');

      cy.get('@followButton').should('have.text', 'Follow');
    });
  });
});
