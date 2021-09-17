describe('Preview profile from post search results', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/articleEditorV1User.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/search?q=test');
    });
  });

  it('shows profile preview cards on posts in search results', () => {
    cy.findAllByRole('button', { name: 'Admin McAdmin profile details' })
      .first()
      .as('previewButton');
    cy.get('@previewButton').should('have.attr', 'data-initialized');
    cy.get('@previewButton').click();

    cy.findAllByTestId('profile-preview-card')
      .first()
      .within(() => {
        cy.findByRole('link', {
          name: 'Admin McAdmin',
        }).should('have.focus');

        // Check all the expected user data sections are present
        cy.findByText('Admin user summary');
        cy.findByText('Software developer at Company');
        cy.findByText('Edinburgh');
        cy.findByText('University of Life');

        cy.findByRole('button', { name: 'Follow user: Admin McAdmin' }).click();

        // Check that following status has been updated
        cy.findByRole('button', { name: 'Follow user: Admin McAdmin' }).should(
          'not.exist',
        );
        cy.findByRole('button', { name: 'Unfollow user: Admin McAdmin' });
      });
  });
});
