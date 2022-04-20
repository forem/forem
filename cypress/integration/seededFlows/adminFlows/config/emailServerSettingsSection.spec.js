describe('Email Server Settings Section', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/admin/customization/config');
    });
  });

  describe('email server settings', () => {
    it('updates the smtp fields', () => {
      cy.findByTestId('emailServerSettings').as('emailServerSettings');

      cy.get('@emailServerSettings').within(() => {
        cy.findByText('Email Server Settings (SMTP)').click({ force: true });
        cy.findByLabelText('User name')
          .clear()
          .type('jane_doe', { force: true });
        cy.findByLabelText('Password')
          .clear()
          .type('abc123456', { force: true });
        cy.findByLabelText('Address')
          .clear()
          .type('smtp.gmail.com', { force: true });
        cy.findByLabelText('Authentication')
          .clear()
          .type('plain', { force: true });
        cy.findByText('Update Settings').click({ force: true });
      });

      cy.url().should('contains', '/admin/customization/config');
      cy.findByText('Successfully updated settings.').should('be.visible');
      cy.findByLabelText('User name').should('have.value', 'jane_doe');
      cy.findByLabelText('Password').should('have.value', 'abc123456');
      cy.findByLabelText('Address').should('have.value', 'smtp.gmail.com');
      cy.findByLabelText('Authentication').should('have.value', 'plain');
    });
  });
});
