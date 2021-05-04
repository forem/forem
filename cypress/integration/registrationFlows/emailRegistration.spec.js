describe('Sign up with email', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.visit('/enter?state=new-user');
  });

  // Regression test for #11099
  it('should preserve the form data on unsuccesful submissions', () => {
    cy.findByRole('link', { name: /Sign up with Email/ }).click();

    cy.findByLabelText('Profile image').attachFile('images/admin-image.png');
    cy.findByLabelText('Name').type('Sloan');
    cy.findByLabelText('Username').type('s');
    cy.findByLabelText('Email').type('sloan@example.com');
    cy.findByLabelText('Password').type('password');
    cy.findByLabelText('Password confirmation').type('password');
    cy.findByRole('button', { name: 'Sign up' }).click();

    // The validation failed but the user's data is not lost
    cy.get('li')
      .contains('Username is too short (minimum is 2 characters)')
      .should('be.visible');
    cy.findByLabelText('Name').should('have.value', 'Sloan');
    cy.findByLabelText('Username').should('have.value', 's');
    cy.findByLabelText('Email').should('have.value', 'sloan@example.com');
  });
});
