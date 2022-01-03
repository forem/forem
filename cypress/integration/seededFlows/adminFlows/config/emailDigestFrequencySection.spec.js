describe('Email digest frequency Section', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user);
    });
  });

  describe('email digest frequency settings', () => {
    it('can change the frequency', () => {
      cy.get('@user').then(() => {
        cy.visit('/admin/customization/config');
        cy.findByTestId('emailDigestSectionForm').as('emailDigestSectionForm');

        cy.get('@emailDigestSectionForm')
          .findByText('Email digest frequency')
          .click();

        cy.get('@emailDigestSectionForm')
          .get('#settings_general_periodic_email_digest')
          .clear()
          .type('42');

        cy.get('@emailDigestSectionForm').findByText('Update Settings').click();

        cy.url().should('contains', '/admin/customization/config');

        cy.findByText('Successfully updated settings.').should('be.visible');

        cy.get('#settings_general_periodic_email_digest').should(
          'have.value',
          '42',
        );
      });
    });
  });
});
