describe('GDPR Delete Requests', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');
    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/admin/gdpr_delete_requests');
    });
  });

  it('confirms deletion of user', () => {
    cy.findByRole('heading', { name: 'Members (GDPR Delete Requests)' });
    cy.findByRole('button', {
      name: 'Confirm user gdpr_delete_user deleted',
    }).click();

    cy.findByRole('heading', {
      name: 'Are you sure you have deleted all external data for @gdpr_delete_user?',
    });

    cy.findByRole('button', { name: 'Yes, mark as deleted' }).click();

    // Flash message should confirm success
    cy.findByText('Successfully marked as deleted').should('exist');
    // User should no longer be in the list for deletion
    cy.findByRole('button', {
      name: 'Confirm user gdpr_delete_user deleted',
    }).should('not.exist');
  });

  it('Cancels marking a user as deleted', () => {
    cy.findByRole('heading', { name: 'Members (GDPR Delete Requests)' });
    cy.findByRole('button', {
      name: 'Confirm user gdpr_delete_user deleted',
    })
      .as('confirmButton')
      .click();

    cy.findByRole('heading', {
      name: 'Are you sure you have deleted all external data for @gdpr_delete_user?',
    });
    cy.findByRole('button', { name: 'Cancel' }).click();

    cy.findByRole('heading', {
      name: 'Are you sure you have deleted all external data for @gdpr_delete_user?',
    }).should('not.exist');
    cy.get('@confirmButton').should('exist').should('have.focus');
  });
});
