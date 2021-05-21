describe('Campaign Section', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user);
    });
  });

  describe('rate limit settings', () => {
    it('can change for how many days a user is considered new', () => {
      cy.get('@user').then(({ username }) => {
        cy.visit('/admin/customization/config');
        cy.get('#new_settings_rate_limit').as('rateLimitSectionForm');

        cy.get('@rateLimitSectionForm')
          .findByText('Rate limits and anti-spam')
          .click();

        cy.get('@rateLimitSectionForm')
          .get('#settings_rate_limit_user_considered_new_days')
          .clear()
          .type('42');

        cy.get('@rateLimitSectionForm')
          .findByPlaceholderText('Confirmation text')
          .type(
            `My username is @${username} and this action is 100% safe and appropriate.`,
          );

        cy.get('@rateLimitSectionForm')
          .findByText('Update Site Configuration')
          .click();

        cy.url().should('contains', '/admin/customization/config');

        cy.findByText('Site configuration was successfully updated.').should(
          'be.visible',
        );

        cy.get('#settings_rate_limit_user_considered_new_days').should(
          'have.value',
          '42',
        );
      });
    });
  });
});
