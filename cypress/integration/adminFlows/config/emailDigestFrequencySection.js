describe('Email digest frequency Section', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user);
    });
  });

  describe('email digency frequency settings', () => {
    it('cam change the frequency', () => {
      cy.get('@user').then(({ username }) => {
        cy.visit('/admin/config');
        cy.findByTestId('emailDigestSectionForm').as('emailDigestSectionForm');

        cy.get('@emailDigestSectionForm')
          .findByText('Email digest frequency')
          .click();

        cy.get('@emailDigestSectionForm')
          .get('#site_config_periodic_email_digest')
          .clear()
          .type('42');

        cy.get('@emailDigestSectionForm')
          .findByPlaceholderText('Confirmation text')
          .type(
            `My username is @${username} and this action is 100% safe and appropriate.`,
          );

        cy.get('@emailDigestSectionForm')
          .findByText('Update Site Configuration')
          .click();

        cy.url().should('contains', '/admin/config');

        cy.findByText('Site configuration was successfully updated.').should(
          'be.visible',
        );

        cy.get('#site_config_periodic_email_digest').should('have.value', '42');
      });
    });
  });
});
