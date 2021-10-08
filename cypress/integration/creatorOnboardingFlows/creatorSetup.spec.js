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

  it('should properly load and fill out the creator setup form', () => {
    cy.findByRole('textbox', { name: /community name/i })
      .as('communityName')
      .invoke('attr', 'placeholder')
      .should('eq', 'Climbing Life');
    cy.get('@communityName').invoke('attr', 'value', 'Climbing Life');
    // .click()
    // .should('have.focus')
    // .type('Climbing Life'); // Does not finish typing community name -- need to revisit this!

    cy.findByRole('button', { name: /logo/i }).attachFile(
      '/images/admin-image.png',
    );

    cy.findByLabelText('Brand color').invoke('attr', 'value', '#ff0000');
  });

  // it('should display a welcome message', () => {
  //   cy.findByText("Lovely! Let's set up your Forem.").should('be.visible');
  //   cy.findByText('No stress, you can always change it later.').should(
  //     'be.visible',
  //   );
  // });

  // it('should contain a community name label and field', () => {
  //   cy.findByTestId('creator-setup-form').as('creatorSetupForm');
  //   cy.get('@creatorSetupForm')
  //     .findByText(/^Community name/)
  //     .should('be.visible');
  // });

  // it('should contain a logo upload field', () => {
  //   cy.findByTestId('creator-setup-form').findByText(/^Logo/).should('be.visible');
  // });

  // it('should allow a logo to be uploaded upon click', () => {
  //   cy.findByTestId('creator-setup-form').as('creatorSetupForm');
  //   cy.get('@creatorSetupForm')
  //     .findByRole('button', { name: 'logo_svg' })
  //     .click();
  // });

  // it('should contain a brand color selector field', () => {
  //   cy.findByTestId('creator-setup-form').as('creatorSetupForm');
  //   cy.get('@creatorSetupForm')
  //     .findByText(/^Brand color/)
  //     .should('be.visible');
  // });

  // it('should allow a brand color to be selected upon click', () => {
  //   cy.findByTestId('creator-setup-form').as('creatorSetupForm');
  //   cy.get('@creatorSetupForm')
  //     .findByRole('color', { name: 'primary_brand_color_hex' })
  //     .click();
  // });

  // it("should contain a 'Who can join this community?' radio selector field", () => {
  //   cy.findByTestId('creator-setup-form').as('creatorSetupForm');
  //   cy.get('@creatorSetupForm')
  //     .findByText(/^Who can join this community/)
  //     .should('be.visible');
  // });

  // it('should allow the selection of who can join the community upon click', () => {
  //   cy.findByTestId('creator-setup-form').as('creatorSetupForm');
  //   cy.get('@creatorSetupForm')
  //     .findByRole('radio', { name: 'invite_only_mode_0' })
  //     .check('Everyone');
  //   cy.findByRole('radio', { name: 'invite_only_mode_0' }).should.should(
  //     'be.checked',
  //   );
  // });

  // it("should contain a 'Who can view content in this community?' radio selector field", () => {
  //   cy.findByTestId('creator-setup-form').as('creatorSetupForm');
  //   cy.get('@creatorSetupForm')
  //     .findByText(/^Who can view content in this community/)
  //     .should('be.visible');
  // });

  // it('should allow the selection of who can join the community upon click', () => {
  //   cy.findByTestId('creator-setup-form').as('creatorSetupForm');
  //   cy.get('@creatorSetupForm')
  //     .findByRole('radio', { name: 'public_0' })
  //     .check('Everyone');
  //   cy.findByRole('radio', { name: 'public_0' }).should.should('be.checked');
  // });

  // it("should sign the user in when 'Finish' is clicked", () => {
  //   cy.findByTestId('creator-signup-form').as('creatorSignupForm');
  //   cy.get('@creatorSignupForm')
  //     .findByRole('button', { name: 'Finish' })
  //     .click();

  //   cy.url().should('equal', '/');
  // });
});
