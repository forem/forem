describe('Logged out - tag index page', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.visit('/t/tag1');
  });

  it('shows a preview profile card for posts in the tag feed', () => {
    cy.visit('/t/tag1');
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
      });

    // Clicking a follow button while logged out should always trigger the log in to continue modal
    cy.findByTestId('modal-container').findByRole('heading', {
      name: 'Log in to continue',
    });
  });
});
