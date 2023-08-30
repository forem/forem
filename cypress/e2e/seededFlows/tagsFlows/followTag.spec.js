describe('Follow tag', () => {
  describe('Tag index page', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/articleEditorV1User.json').as('user');

      cy.get('@user').then((user) => {
        cy.loginAndVisit(user, '/tags').then(() => {
          cy.findByRole('heading', { name: 'Tags' });
        });
      });
    });

    it('Follows and unfollows a tag from the tag index page', () => {
      cy.intercept('/follows').as('followsRequest');
      cy.findByRole('button', { name: 'Follow tag: tag0' }).as('followButton');

      cy.get('@followButton').click();
      cy.wait('@followsRequest');

      cy.get('@followButton').should('have.text', 'Following');
      cy.get('@followButton').should('have.attr', 'aria-pressed', 'true');

      cy.get('@followButton').click();
      cy.wait('@followsRequest');

      cy.get('@followButton').should('have.text', 'Follow');
      cy.get('@followButton').should('have.attr', 'aria-pressed', 'false');
    });

    it('hides and unhides a tag', () => {
      cy.intercept('/follows').as('followsRequest');
      cy.findByRole('button', { name: 'Follow tag: tag0' }).as('followButton');
      cy.findByRole('button', { name: 'Hide tag: tag0' }).as('hideButton');

      cy.get('@hideButton').click();
      cy.wait('@followsRequest');

      // clicking on 'Hide' should change it to an 'Unhide'
      // and remove the Follow button
      cy.get('@hideButton').should('have.text', 'Unhide');
      cy.get('@followButton').should('not.exist');

      // clicking on 'Unhide' should change it back to 'Hide'
      // and show a 'Following' button
      cy.get('@hideButton').click();
      cy.wait('@followsRequest');

      cy.get('@hideButton').should('have.text', 'Hide');
      cy.get('@followButton').should('not.exist');
      cy.findByRole('button', { name: 'Following tag: tag0' }).as(
        'followingButton',
      );
      cy.get('@followingButton').should('exist');
      cy.get('@followingButton').should('have.text', 'Following');
      cy.get('@followingButton').should('have.attr', 'aria-pressed', 'true');
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
