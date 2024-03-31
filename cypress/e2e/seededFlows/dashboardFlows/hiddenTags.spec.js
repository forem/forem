describe('Dashboard: Hidden Tags', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/dashboard/hidden_tags').then(() => {
        cy.findByRole('heading', { name: 'Dashboard » Hidden tags' });
      });
    });
  });

  it('shows the correct number of tags on the page', () => {
    cy.get('.dashboard__tag__container').should('have.length', 5);
  });

  it('shows the appropriate buttons on the card', () => {
    cy.findByRole('button', { name: 'Unhide tag: tag5' });
  });

  it('unhides a tag', () => {
    cy.get('.dashboard__tag__container').should('have.length', 5);

    cy.intercept('/follows').as('followsRequest');
    cy.findByRole('button', { name: 'Unhide tag: tag5' }).as('unhideButton');

    cy.get('@unhideButton').click();
    cy.wait('@followsRequest');

    // it removes the item from the 'Hidden tags' page
    cy.get('.dashboard__tag__container').should('have.length', 4);
    cy.findByRole('button', { name: 'Unhide tag: tag5' }).should('not.exist');

    // it decreases the count from the 'Hidden tags' nav item
    cy.get('.js-hidden-tags-link .c-indicator').as('hiddenTagsCount');
    cy.get('@hiddenTagsCount').should('contain', '4');
  });

  it('shows a modal when there is an error', () => {
    cy.intercept('/follows', { statusCode: 500 }).as('followsRequest');
    cy.findByRole('button', { name: 'Unhide tag: tag5' }).as('unhideButton');

    cy.get('@unhideButton').click();
    cy.wait('@followsRequest');

    cy.findByTestId('modal-container').as('confirmationModal');

    cy.get('@confirmationModal')
      .findByText(
        'Your unhide action could not be updated due to a server error',
      )
      .should('exist');
  });

  // TODO: add a test for the pagination
});
