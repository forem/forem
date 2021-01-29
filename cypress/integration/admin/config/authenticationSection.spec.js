describe('Authentication Section', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        cy.visit('/admin/config');
      });
    });
  });

  // this context needs invite-only mode to be false and at least
  // email registration and Facebook auth to be enabled
  context('invite-only mode setting', () => {
    it('should disable email registration and all authorization providers when enabled', () => {
      cy.findAllByText('Authentication').first().click();
      cy.get('#site_config_invite_only_mode').click();
      cy.get('#authenticationBodyContainer #confirmation').type(
        'My username is @admin_mcadmin and this action is 100% safe and appropriate.',
      );
      cy.get('#authenticationBodyContainer')
        .contains('Update Site Configuration')
        .click();

      cy.url().should('contains', '/admin/config');
      cy.get('.alert')
        .contains('Site configuration was successfully updated')
        .should('be.visible');

      cy.findAllByText('Authentication').first().click();

      cy.get('#site_config_invite_only_mode').should('be.checked');
      cy.get('.enabled-indicator.visible').should('have.length', 0);

      cy.visit('/signout_confirm');

      cy.findAllByText('Yes, sign out').first().click();
      cy.findAllByText('Create account').first().click();

      cy.contains('Sign up with Email').should('not.exist');
      cy.contains('Sign up with Facebook').should('not.exist');
      cy.contains('is invite only').should('be.visible');
    });
  });

  // this context needs Facebook auth provider to be disabled and
  // its keys to be blank
  context('authentication providers settings', () => {
    it('should display warning modal if provider keys are missing', () => {
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

    it('should not display warning modal if provider keys present', () => {
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
