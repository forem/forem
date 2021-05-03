describe('Authentication Section', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        cy.updateAdminAuthConfig(user.username);
      });
    });
  });

  describe('invite-only mode setting', () => {
    it('should disable email registration and all authorization providers when enabled', () => {
      cy.fixture('users/adminUser.json').as('user');

      cy.get('@user').then(({ username }) => {
        cy.updateAdminAuthConfig(username, {
          authProvidersToEnable: 'facebook',
          facebookKey: 'somekey',
          facebookSecret: 'somesecret',
        }).then(() => {
          cy.visit('/admin/config');
          cy.findByTestId('authSectionForm').as('authSectionForm');

          cy.get('@authSectionForm').findByText('Authentication').click();
          cy.get('@authSectionForm')
            .findByLabelText('Invite-only mode')
            .should('not.be.checked')
            .check();

          cy.get('@authSectionForm')
            .findByPlaceholderText('Confirmation text')
            .type(
              `My username is @${username} and this action is 100% safe and appropriate.`,
            );
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

          cy.findByRole('button', { name: 'Yes, sign out' }).click();
          cy.findByRole('link', { name: 'Create account' }).click();

          cy.findByLabelText('Sign up with Email').should('not.exist');
          cy.findByLabelText('Sign up with Facebook').should('not.exist');
          cy.contains('invite only').should('be.visible');
        });
      });
    });
  });

  describe('authentication providers settings', () => {
    it('should display warning modal if provider keys are missing', () => {
      cy.fixture('users/adminUser.json').as('user');
      cy.get('@user').then(() => {
        cy.visit('/admin/config');
        cy.findByTestId('authSectionForm').as('authSectionForm');

        cy.get('@authSectionForm').findByText('Authentication').click();
        cy.get('#facebook-auth-btn').click();
        cy.get('@user').then(({ username }) => {
          cy.get('@authSectionForm')
            .findByPlaceholderText('Confirmation text')
            .type(
              `My username is @${username} and this action is 100% safe and appropriate.`,
            );
        });
        cy.get('@authSectionForm')
          .findByText('Update Site Configuration')
          .click();

        cy.get('.crayons-modal__box__body > ul > li')
          .contains('facebook')
          .should('be.visible');
      });
    });

    it('should not display warning modal if provider keys present', () => {
      cy.fixture('users/adminUser.json').as('user');

      cy.get('@user').then(() => {
        cy.visit('/admin/config');
        cy.findByTestId('authSectionForm').as('authSectionForm');

        cy.get('@authSectionForm').findByText('Authentication').click();
        cy.get('#facebook-auth-btn').click();
        cy.get('#settings_authentication_facebook_key').type('randomkey');
        cy.get('#settings_authentication_facebook_secret').type('randomsecret');
        cy.get('@user').then(({ username }) => {
          cy.get('@authSectionForm')
            .findByPlaceholderText('Confirmation text')
            .type(
              `My username is @${username} and this action is 100% safe and appropriate.`,
            );
        });
        cy.get('@authSectionForm')
          .findByText('Update Site Configuration')
          .click();

        cy.url().should('contains', '/admin/config');

        cy.findByText('Site configuration was successfully updated.').should(
          'be.visible',
        );

        // Page reloaded so need to get a new reference to the form.
        cy.findByTestId('authSectionForm').as('authSectionForm');
        cy.get('@authSectionForm').findByText('Authentication').click();

        cy.findByLabelText('Facebook enabled').should('be.visible');
      });
    });
  });
});
