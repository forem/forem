describe('Creator Setup Page', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/creatorUser.json').as('creator');
    cy.get('@creator').then((creator) => {
      cy.loginCreator(creator);
    });
    const { baseUrl } = Cypress.config();

    cy.visit(`${baseUrl}admin/creator_settings/new?referrer=${baseUrl}`);
  });

  it('should display a welcome message', () => {
    cy.findByText("Lovely! Let's set up your Forem.").should('be.visible');
    cy.findByText('No stress, you can always change it later.').should(
      'be.visible',
    );
  });

  it('should contain a community name and update the field properly', () => {
    cy.findByRole('textbox', { name: /community name/i })
      .as('communityName')
      .invoke('attr', 'placeholder')
      .should('eq', 'Climbing Life');
    cy.get('@communityName').type('Climbing Life');
  });

  it('should contain a logo upload field and upload a logo upon click', () => {
    cy.findByText(/^Logo/).should('be.visible');
    cy.findByRole('button', { name: /logo/i }).attachFile(
      '/images/admin-image.png',
    );
  });

  it('should contain a brand color selector field', () => {
    cy.findByText(/^Brand color/).should('be.visible');
  });

  // TODO: Circle back around to testing the selection of a brand color from the color picker,
  // as this input isn't very testable at the moment. See https://github.com/cypress-io/cypress/issues/7812.

  it.skip('should allow a brand color to be selected upon click', () => {
    cy.findByRole('color', { name: 'primary_brand_color_hex' }).click();
  });

  it("should contain a 'Who can join this community?' radio selector field and allow selection upon click", () => {
    cy.findByText(/^Who can join this community/).should('be.visible');
    cy.findAllByRole('radio').first().check('0');
    cy.findAllByRole('radio').should('be.checked');
  });

  it("should contain a 'Who can view content in this community?' radio selector field and allow selection upon click", () => {
    cy.findByText(/^Who can view content in this community/).should(
      'be.visible',
    );
    cy.findAllByRole('radio').check('3');
    cy.findAllByRole('radio').should('be.checked');
  });

  it("should redirect the creator to the home page when the form is completely filled out and 'Finish' is clicked", () => {
    cy.findByRole('textbox', { name: /community name/i }).as('communityName');
    cy.get('@communityName').type('Climbing Life');
    cy.findByRole('button', { name: /logo/i }).attachFile(
      '/images/admin-image.png',
    );
    cy.findByLabelText('Brand color').invoke('attr', 'value', '#ff0000');
    cy.findAllByRole('radio').first().check('0');
    cy.findAllByRole('radio').check('3');
    cy.findByRole('button', { name: 'Finish' }).click();
    cy.url().should('equal', '/');
  });
});
