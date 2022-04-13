describe('Invited users', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');
    cy.get('@user').then((user) => {
      cy.loginUser(user)
        .then(() => cy.enableFeatureFlag('member_index_view'))
        .then(() =>
          cy.inviteUser({
            name: 'Test user',
            email: 'test@test.com',
          }),
        )
        .then(() => cy.visitAndWaitForUserSideEffects('/admin/invitations'));
    });
  });

  it('searches for an invited user', () => {
    // The single invited user should be visible on the page
    cy.findByText('test@test.com').should('exist');

    // Search for a term that should match the entry
    cy.findByRole('textbox', {
      name: 'Search invited members by name, username, or email',
    }).type('test');
    cy.findByRole('button', { name: 'Search' }).click();
    cy.url().should('contain', 'search=test');
    cy.findByText('test@test.com').should('exist');

    // Search for a term that shouldn't match the entry
    cy.findByRole('textbox', {
      name: 'Search invited members by name, username, or email',
    })
      .clear()
      .type('something');
    cy.findByRole('button', { name: 'Search' }).click();
    cy.url().should('contain', 'search=something');
    cy.findByText('test@test.com').should('not.exist');
  });
});
