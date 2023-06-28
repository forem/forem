describe('GDPR Delete Requests', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');
    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/admin/member_manager/gdpr_delete_requests');
    });
  });

  it('confirms deletion of user', () => {
    cy.findByRole('heading', { name: 'GDPR Actions' });
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

  it('displays an empty state when there are no users to be confirmed as deleted', () => {
    cy.findByRole('heading', { name: 'GDPR Actions' });
    cy.findByRole('button', {
      name: 'Confirm user gdpr_delete_user deleted',
    }).click();

    cy.findByRole('heading', {
      name: 'Are you sure you have deleted all external data for @gdpr_delete_user?',
    });

    cy.findByRole('button', { name: 'Yes, mark as deleted' }).click();

    cy.findByText('Awesome! All GDPR actions have been completed.').should(
      'exist',
    );
  });

  it('Cancels marking a user as deleted', () => {
    cy.findByRole('heading', { name: 'GDPR Actions' });
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

  it('Searches for a user', () => {
    // The user should be visible on the page
    cy.findByRole('table')
      .findByText('gdpr-delete-user@forem.local')
      .should('exist');

    // Search for a term that should match the entry
    searchForMember('delete');

    cy.url().should('contain', 'search=delete');
    cy.findByRole('table')
      .findByText('gdpr-delete-user@forem.local')
      .should('exist');

    // Search for a term that shouldn't match the entry
    searchForMember('something');
    cy.url().should('contain', 'search=something');
    cy.findByRole('table')
      .findByText('gdpr-delete-user@forem.local')
      .should('not.exist');
  });

  const searchForMember = (searchTerm) => {
    cy.findByRole('textbox', {
      name: 'Search members by email or username',
    })
      .clear()
      .type(searchTerm);
    cy.findByRole('button', { name: 'Search' }).click();
  };
});
