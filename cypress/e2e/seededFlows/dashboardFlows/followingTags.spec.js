function openOptionsMenu(callback) {
  cy.findAllByRole('button', { name: 'Options' })
    .first()
    .should('have.attr', 'aria-haspopup', 'true')
    .should('have.attr', 'aria-expanded', 'false')
    .click()
    .then(([button]) => {
      expect(button.getAttribute('aria-expanded')).to.equal('true');
      const dropdownId = button.getAttribute('aria-controls');

      cy.get(`#${dropdownId}`).within(callback);
    });
}

describe('Dashboard: Following Tags', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/dashboard/following_tags').then(() => {
        cy.findByRole('heading', { name: 'Dashboard » Following tags' });
      });
    });
  });

  it('shows the correct number of tags on the page', () => {
    cy.get('.dashboard__tag__container').should('have.length', 5);
  });

  it('shows the appropriate buttons on the card', () => {
    cy.findByRole('button', { name: 'Following tag: tag0' });
    openOptionsMenu(() => {
      cy.findByRole('button', { name: 'Hide tag: tag0' }).click();
    });
  });

  it('unfollows a tag', () => {
    cy.get('.dashboard__tag__container').should('have.length', 5);

    cy.intercept('/follows').as('followsRequest');
    cy.findByRole('button', { name: 'Following tag: tag0' }).as(
      'followingButton',
    );

    cy.get('@followingButton').click();
    cy.wait('@followsRequest');

    // it removes the item from the 'Following tags' page
    cy.get('.dashboard__tag__container').should('have.length', 4);
    cy.findByRole('button', { name: 'Following tag: tag0' }).should(
      'not.exist',
    );

    // it decreases the count from the 'Following tags' nav item
    cy.get('.js-following-tags-link .c-indicator').as('followingTagsCount');
    cy.get('@followingTagsCount').should('contain', '4');
  });

  it('hides a tag', () => {
    cy.get('.dashboard__tag__container').should('have.length', 5);

    cy.intercept('/follows').as('followsRequest');
    openOptionsMenu(() => {
      cy.findByRole('button', { name: 'Hide tag: tag0' }).as('hideButton');
    });

    cy.get('@hideButton').click();
    cy.wait('@followsRequest');

    // it removes the item from the 'Following tags' page
    cy.get('.dashboard__tag__container').should('have.length', 4);
    cy.findByRole('button', { name: 'Following tag: tag0' }).should(
      'not.exist',
    );

    // it decreases the count from the 'Following tags' nav item
    cy.get('.js-following-tags-link .c-indicator').as('followingTagsCount');
    cy.get('@followingTagsCount').should('contain', '4');

    // it increases the count from the 'Hidden tags' nav item
    cy.get('.js-hidden-tags-link .c-indicator').as('hiddenTagsCount');
    cy.get('@hiddenTagsCount').should('contain', '6');
  });

  it('shows the number of posts published for a tag', () => {
    cy.get('.dashboard__tag__container')
      .first()
      .within(() => {
        cy.findByText('0 posts');
      });

    cy.get('.dashboard__tag__container')
      .eq(1)
      .within(() => {
        cy.findByText('1 posts');
      });
  });

  // TODO: add a test for the pagination
});
