describe('Tools Section', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/admin/users');
    });
  });

  describe('Show section', () => {
    it('shows the boxes', () => {
      cy.get('@user').then(({ username }) => {
        cy.visitAndWaitForUserSideEffects('/admin/users');

        cy.findAllByText(username).first().click();

        cy.findByRole('main').within(() => {
          cy.findAllByText('Emails').should('be.visible');
          cy.findAllByText('Notes').should('be.visible');
          cy.findAllByText('Credits').should('be.visible');
          cy.findAllByText('Organizations').should('be.visible');
          cy.findAllByText('Reports').should('be.visible');
          cy.findAllByText('Reactions').should('be.visible');
        });
      });
    });
  });

  describe('Emails', () => {
    it('Verifies the email', () => {
      cy.get('@user').then(({ username }) => {
        cy.visitAndWaitForUserSideEffects('/admin/users');

        cy.findAllByText(username).first().click();

        cy.findAllByText('Emails').first().click();

        cy.findAllByText('Verify Email Ownership')
          .first()
          .as('verifyEmailOwnership');
        cy.get('@verifyEmailOwnership').within((button) => {
          button.click();
        });
        cy.findByTestId('snackbar').should(
          'have.text',
          'Verification email sent!',
        );
      });
    });

    it('Sends an email to the user and check its presence in the history', () => {
      cy.get('@user').then(({ username }) => {
        cy.visitAndWaitForUserSideEffects('/admin/users');

        cy.findAllByText(username).first().click();

        cy.findAllByText('Emails').first().click();

        // Send email
        cy.findByRole('textbox', { name: 'Subject' }).type('Hello!');
        cy.findByRole('textbox', { name: 'Body' }).type('This is an email');
        cy.findByRole('button', { name: 'Send Email' }).click();

        // Check message coming from the server
        cy.findByTestId('snackbar').should('have.text', 'Email sent!');

        // Go back to check its presence in the history
        cy.visitAndWaitForUserSideEffects('/admin/users');
        cy.findAllByText(username).first().click();
        cy.findAllByText('Emails').first().click();

        cy.findAllByText(/Emails history/)
          .first()
          .within((details) => {
            details.click(); // open the details
          });

        // Check the email is present in the details
        cy.findByRole('link', { name: /Hello!/ }).should('exist');
      });
    });
  });
});
