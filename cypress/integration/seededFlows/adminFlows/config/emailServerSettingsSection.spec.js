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
      cy.get('@user').then(() => {
        cy.visit('/admin/customization/config');
        cy.findByTestId('emailServerSettings').as('emailServerSettings');

        cy.get('@emailServerSettings')
          .findByText('Email Server Settings (SMTP)')
          .click();

        cy.get('@emailServerSettings')
          .get('#settings_smtp_user_name')
          .clear()
          .type('jane_doe');

        cy.get('@emailServerSettings')
          .get('#settings_smtp_password')
          .clear()
          .type('abc123456');

        cy.get('@emailServerSettings')
          .get('#settings_smtp_address')
          .clear()
          .type('smtp.gmail.com');

        cy.get('@emailServerSettings')
          .get('#settings_smtp_authentication')
          .clear()
          .type('plain');

        cy.get('@emailServerSettings').findByText('Update Settings').click();

        cy.url().should('contains', '/admin/customization/config');

        cy.findByText('Successfully updated settings.').should('be.visible');

        cy.get('#settings_smtp_user_name').should('have.value', 'jane_doe');

        cy.get('#settings_smtp_password').should('have.value', 'abc123456');

        cy.get('#settings_smtp_address').should('have.value', 'smtp.gmail.com');

        cy.get('#settings_smtp_authentication').should('have.value', 'plain');
      });
    });
  });
});
