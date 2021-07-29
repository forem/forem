describe('Confirm Email page', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.visit('/confirm-email?email=user%40forem.com');
  });

  it('should display the correct heading', () => {
    cy.findByText('Great! Now confirm your email address.').should(
      'be.visible',
    );
  });

  it('should display the email address on the page if provided', () => {
    cy.findByText('user@forem.com').should('be.visible');
  });

  it('should display the correct subtext', () => {
    cy.contains("We've sent an email to user@forem.com").should('be.visible');
    cy.findByText('Click the button inside to confirm your email').should(
      'be.visible',
    );
  });

  it("should display a modal when you click on 'Click here'", () => {
    cy.findAllByRole('button', { name: 'Click here' }).first().click();
    cy.findByTestId('modal-container').as('confirmationModal');

    cy.get('@confirmationModal')
      .findByText("Didn't get the email?")
      .should('exist');
    cy.get('@confirmationModal')
      .findByText(
        'Re-enter the email address below to resend the confirmation link',
      )
      .should('exist');

    cy.get('@confirmationModal')
      .get('input[name="user[email]"]')
      .last()
      .should('have.value', 'user@forem.com');

    cy.get('@confirmationModal')
      .findByRole('button', { name: /Dismiss/ })
      .click();
    cy.findByTestId('modal-container').should('not.exist');
  });
});
