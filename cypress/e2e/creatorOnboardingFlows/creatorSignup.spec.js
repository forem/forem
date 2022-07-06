describe('Creator Signup Page', () => {
  beforeEach(() => {
    cy.testSetup();
    // NOTE: The "New Forem Owner" field is displayed based on a rails env variable
    // which is set on Travis already. It cannot be dynamically updated for the
    // Cypress tests, hence we have chosen the route of passing the forem_owner_secret
    // as a param. This sends us down the path with least resistance.
    cy.visit('/enter?state=new-user&forem_owner_secret=secret');
  });

  it('should display a welcome message', () => {
    cy.findByText("Let's start your Forem journey!").should('be.visible');
  });

  it('should display instructions', () => {
    cy.findByText('Create your admin account first.').should('be.visible');
    cy.findByText("Then we'll walk you through your Forem setup.").should(
      'be.visible',
    );
  });

  it('should display a validated username hint that correlates to the name entered', () => {
    cy.findByTestId('creator-signup-form').as('creatorSignupForm');
    cy.get('@creatorSignupForm')
      .findByText(/^Name$/)
      .type('1 Forem creator name! Also test a maximum length string');

    // restricts the string to 20 characters, lowercased,
    // replaces spaces and special_characters with an underscore
    cy.contains('1_forem_creator_name__also_tes');
  });

  it('should show and focus on the username field when clicking on the edit icon', () => {
    cy.findByTestId('creator-signup-form').as('creatorSignupForm');
    cy.get('@creatorSignupForm')
      .findByText(/^Name$/)
      .type('Forem creator name');

    cy.findByRole('button', { name: 'Edit username' }).click();
    cy.get('@creatorSignupForm')
      .findByText(/^Username/)
      .should('exist');

    cy.findByLabelText('Username').should('have.value', 'forem_creator_name');
  });

  it('should contain an email label and field', () => {
    cy.findByTestId('creator-signup-form').as('creatorSignupForm');
    cy.get('@creatorSignupForm')
      .findByText(/^Email/)
      .should('be.visible');
  });

  it('should contain a password', () => {
    cy.findByTestId('creator-signup-form').as('creatorSignupForm');
    cy.get('@creatorSignupForm')
      .findByText(/^Password/)
      .should('be.visible');
  });

  it('should toggle the password when the eye icon is clicked', () => {
    cy.findByTestId('creator-signup-form').as('creatorSignupForm');
    cy.get('@creatorSignupForm')
      .findByText(/^Password$/)
      .type('abc123456');

    cy.findByLabelText('Password').should('have.attr', 'type', 'password');
    cy.findByTestId('mask-icon').should('be.visible');
    cy.findByTestId('unmask-icon').should('not.be.visible');

    cy.findByRole('button', { name: 'Show password' }).click();
    cy.findByRole('button', { name: 'Show password' }).should(
      'have.attr',
      'aria-pressed',
      'true',
    );
    cy.findByLabelText('Password').should('have.attr', 'type', 'text');
    cy.findByTestId('unmask-icon').should('be.visible');
    cy.findByTestId('mask-icon').should('not.be.visible');
  });

  it("should sign the user in when 'Create my account' is clicked", () => {
    cy.findByTestId('creator-signup-form').as('creatorSignupForm');
    cy.get('@creatorSignupForm').findByText(/^Name/).type('Forem Creator');

    cy.get('@creatorSignupForm')
      .findByText(/^Email/)
      .type('forem_creator@gmail.com');

    cy.get('@creatorSignupForm')
      .findByText(/^Password/)
      .type('abc123456');

    cy.get('@creatorSignupForm')
      .findByRole('button', { name: 'Create my account' })
      .click();

    const { baseUrl } = Cypress.config();
    cy.url().should('equal', `${baseUrl}admin/creator_settings/new`);
  });
});
