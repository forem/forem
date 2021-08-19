describe('Preview profile from series', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/articleEditorV1User.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/series_user/series');
    });
  });

  it('shows a preview on a series article card', () => {
    // Go to an individual series listing
    cy.findByRole('link', { name: 'seriestest (1 Part Series)' }).click();
    cy.findByRole('heading', { name: "seriestest Series' Articles" });

    // Find the preview button and check it functions as expected
    cy.findByRole('button', { name: 'Series User profile details' }).as(
      'previewButton',
    );
    cy.get('@previewButton').should('have.attr', 'data-initialized');
    cy.get('@previewButton').should('have.attr', 'aria-expanded', 'false');
    cy.get('@previewButton').click();

    cy.findByTestId('profile-preview-card').within(() => {
      cy.findByRole('link', {
        name: 'Series User',
      }).should('have.focus');

      // Check all the expected user data sections are present
      cy.findByText('Series user summary');
      cy.findByText('Software developer at Company');
      cy.findByText('Edinburgh');
      cy.findByText('University of Life');

      cy.findByRole('button', { name: 'Follow' }).click();

      // Check that the follow button has updated as expected
      cy.findByRole('button', { name: 'Follow' }).should('not.exist');
      cy.findByRole('button', { name: 'Following' });
    });
  });
});
