describe('Creator Setup Page', () => {
  const { baseUrl } = Cypress.config();

  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/creatorUser.json').as('creator');
    cy.get('@creator').then((creator) => {
      cy.loginCreator(creator);
    });

    cy.visit(`${baseUrl}admin/creator_settings/new?referrer=${baseUrl}`);
  });

  it('should submit the creator settings form', () => {
    // should display a welcome message
    cy.findByText("Lovely! Let's set up your Forem.").should('be.visible');
    cy.findByText('No stress, you can always change it later.').should(
      'be.visible',
    );

    // should contain a community name and update the field properly
    cy.findByRole('textbox', { name: /community name/i })
      .as('communityName')
      .invoke('attr', 'placeholder')
      .should('eq', 'Climbing Life');
    cy.get('@communityName').type('Climbing Life');

    // should contain a logo upload field and upload a logo upon click
    cy.findByText(/^Logo/).should('be.visible');
    cy.findByRole('button', { name: /logo/i }).attachFile(
      '/images/admin-image.png',
    );

    // should contain a brand color field
    cy.findByText(/^Brand color/).should('be.visible');
    cy.findByText(/^Brand color/).invoke('attr', 'value', '#ff0000');

    // should contain a 'Who can join this community?' radio selector field and allow selection upon click
    cy.findByRole('group', { name: /^Who can join this community/i }).should(
      'be.visible',
    );
    cy.findAllByRole('radio', { name: /everyone/i }).check();
    cy.findAllByRole('radio').should('be.checked');

    // should contain a 'Who can view content in this community?' radio selector field and allow selection upon click
    cy.findByRole('group', {
      name: /^Who can view content in this community/i,
    }).should('be.visible');
    cy.findAllByRole('radio', { name: /members only/i }).check();
    cy.findAllByRole('radio').should('be.checked');

    // should redirect the creator to the home page when the form is completely filled out and 'Finish' is clicked
    cy.findByRole('button', { name: 'Finish' }).click();
    cy.url().should('equal', baseUrl);
  });

  it('should not submit the creator settings form if any of the fields are not filled out', () => {
    // TODO: Circle back around to testing this once the styling for the form is complete
    cy.findByRole('textbox', { name: /community name/i }).should(
      'have.attr',
      'required',
    );
    cy.findByRole('button', { name: /logo/i }).should('have.attr', 'required');
    // should not redirect the creator to the home page when the form is not completely filled out and 'Finish' is clicked
    cy.findByRole('button', { name: 'Finish' }).click();
    cy.url().should(
      'equal',
      `${baseUrl}admin/creator_settings/new?referrer=${baseUrl}`,
    );
  });
});
