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
        // cy.get('[data-follow-clicks-initialized]');
      });
    });
  });

  // shows the correct number of tags on the page
  // for each tag it shows a following button and a hide button
  // When you click on 'following'
  // it removes the item from the 'Following tags' page
  // it decreases the count from the 'Following tags' item
  // When you click on 'hide tags'
  // it removes the item from the 'Following tags' page
  // it decreases the count from the 'Following tags' item
  // it increases the count from the 'Hidden tags' item
  // paginates the following tags page
  // shows the number of posts published

  it('shows the correct number of tags on the page', () => {
    cy.get('.dashboard__tag__container').should('have.length', 5);
  });

  it('shows the appropriate buttons on the card', () => {
    cy.findByRole('button', { name: 'Following tag: tag0' });
    openOptionsMenu(() => {
      cy.findByRole('button', { name: 'Hide tag: tag0' }).click();
    });
  });

  it('unfollows a tag', () => {});
});
