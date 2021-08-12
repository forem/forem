describe('Creator Signup Page', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.visit('/enter?state=new-user');
  });

  it('should display a welcome message', () => {
    cy.findByText("Let's start your Forem journey!").should('be.visible');
  });

  it('should display some subtext', () => {
    cy.findByText('Create your admin account first.').should('be.visible');
    cy.findByText("Then we'll walk you through your Forem setup.").should(
      'be.visible',
    );
  });

  it('should display a validated username hint that maps to the name', () => {
    cy.findByTestId('creator-signup-form').as('creatorSignupForm');
    cy.get('@creatorSignupForm')
      .findByText(/^Name$/)
      .type('1 Forem creator name! Also test a maximum length string');

    cy.contains('1_forem_creator_name__also_tes');
  });

  it('should show and focus on the username field when clicking on the edit icon', () => {
    cy.findByTestId('creator-signup-form').as('creatorSignupForm');
    cy.get('@creatorSignupForm')
      .findByText(/^Name$/)
      .type('Forem creator name');

    cy.get('.js-creator-edit-username').click();
    cy.get('@creatorSignupForm')
      .findByText(/^Username/)
      .should('exist');

    cy.get('input[name="user[username]"]').should(
      'have.value',
      'forem_creator_name',
    );
  });

  it('should contain an email label and field', () => {
    cy.findByTestId('creator-signup-form').as('creatorSignupForm');
    cy.get('@creatorSignupForm').findByText(/^Email/);
    // test for email input
  });

  it('should contain an password', () => {
    cy.findByTestId('creator-signup-form').as('creatorSignupForm');
    cy.get('@creatorSignupForm').findByText(/^Password/);
    // test for password input
  });

  //
  // it("should toggle the password when the eye icon is clicked", () => {
  //
  // });
  //
  // it("should allow sign the user in when 'Create my account' is clicked", () => {
  //
  // });

  // it("should catch any errors", ()=> {
  //
  // });
});
