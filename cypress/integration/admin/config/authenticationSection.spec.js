describe('Authentication Section', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user);
    });
  });

  // this context needs invite-only mode to be false and at least
  // email registration and Facebook auth to be enabled
  describe('invite-only mode setting', () => {
    it('should disable email registration and all authorization providers when enabled', () => {
      cy.fixture('users/adminUser.json').as('user');

      cy.updateAdminConfig().then(() => {
        cy.visit('/admin/config');
        cy.findByTestId('authSectionForm').as('authSectionForm');

        cy.get('@authSectionForm').findByText('Authentication').click();
        cy.get('@authSectionForm')
          .findByLabelText('Invite-only mode')
          .should('not.be.checked')
          .check();
        cy.get('@user').then(({ username }) => {
          cy.get('@authSectionForm')
            .findByPlaceholderText('Confirmation text')
            .type(
              `My username is ${username} and this action is 100% safe and appropriate.`,
            );
        });
        cy.get('@authSectionForm')
          .findByText('Update Site Configuration')
          .click();

        cy.url().should('contains', '/admin/config');

        // Page reloaded so need to get a new reference to the form.
        cy.findByTestId('authSectionForm').as('authSectionForm');

        cy.findByText('Site configuration was successfully updated.').should(
          'be.visible',
        );

        cy.get('@authSectionForm').findByText('Authentication').click();

        cy.get('@authSectionForm')
          .findByLabelText('Invite-only mode')
          .should('be.checked');

        // Ensure that none of the authentication providers are enabled.
        cy.findByLabelText('Email enabled').should('not.be.visible');
        cy.findByLabelText('Facebook enabled').should('not.be.visible');
        cy.findByLabelText('GitHub enabled').should('not.be.visible');
        cy.findByLabelText('Twitter enabled').should('not.be.visible');

        cy.visit('/signout_confirm');

        cy.findByText('Yes, sign out').click();
        cy.findByText('Create account').click();

        cy.findByLabelText('Sign up with Email').should('not.exist');
        cy.findByLabelText('Sign up with Facebook').should('not.exist');
        cy.findByText('DEV(local) is invite only.').should('be.visible');
      });
    });
  });

  // this context needs Facebook auth provider to be disabled and
  // its keys to be blank
  describe('authentication providers settings', () => {
    it.skip('should display warning modal if provider keys are missing', () => {
      cy.findAllByText('Authentication').first().click();
      cy.get('#facebook-auth-btn').click();
      cy.get('#authenticationBodyContainer #confirmation').type(
        'My username is @admin_mcadmin and this action is 100% safe and appropriate.',
      );
      cy.get('#authenticationBodyContainer')
        .contains('Update Site Configuration')
        .click();

      cy.contains('Setup not complete').should('be.visible');
      cy.get('.crayons-modal__box__body > ul > li')
        .contains('facebook')
        .should('be.visible');
    });

    it.skip('should not display warning modal if provider keys present', () => {
      cy.findAllByText('Authentication').first().click();
      cy.get('#facebook-auth-btn').click();
      cy.get('#site_config_facebook_key').type('randomkey');
      cy.get('#site_config_facebook_secret').type('randomsecret');
      cy.get('#authenticationBodyContainer #confirmation').type(
        'My username is @admin_mcadmin and this action is 100% safe and appropriate.',
      );
      cy.get('#authenticationBodyContainer')
        .contains('Update Site Configuration')
        .click();

      cy.url().should('contains', 'http://localhost:3000/admin/config');
      cy.get('.alert')
        .contains('Site configuration was successfully updated')
        .should('be.visible');

      cy.findAllByText('Authentication').first().click();

      cy.get('#facebook-enabled-indicator').should('be.visible');
    });
  });
});
