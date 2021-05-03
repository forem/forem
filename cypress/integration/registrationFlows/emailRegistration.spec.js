describe('Sign up with email', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.visit('/enter?state=new-user');
  });

  // Regression test for #11099
  it('should preserve the form data on unsuccesful submissions', () => {
    cy.get('a').contains('Sign up with Email').click();

    cy.get('input[type="file"]').attachFile('images/admin-image.png');
    cy.getInputByLabel('Name').type('Sloan');
    cy.getInputByLabel('Username').type('s');
    cy.getInputByLabel('Email').type('sloan@example.com');
    cy.getInputByLabel('Password').type('password');
    cy.getInputByLabel('Password confirmation').type('password');
    cy.get('input').contains('Sign up').click();

    // The validation failed but the user's data is not lost
    cy.get('li')
      .contains('Username is too short (minimum is 2 characters)')
      .should('be.visible');
    cy.getInputByLabel('Name').should('have.value', 'Sloan');
    cy.getInputByLabel('Username').should('have.value', 's');
    cy.getInputByLabel('Email').should('have.value', 'sloan@example.com');
  });
});
