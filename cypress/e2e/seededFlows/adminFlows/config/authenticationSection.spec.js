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
          cy.visit('/admin/customization/config');
          cy.findByTestId('authSectionForm').as('authSectionForm');

          cy.get('@authSectionForm').findByText('Authentication').click();

          cy.get('@authSectionForm')
            .findByRole('checkbox', { name: 'Invite-only mode' })
            .should('not.be.checked')
            .check();

          cy.get('@authSectionForm')
            .findByRole('button', { name: 'Update Settings' })
            .click();

          cy.findByTestId('snackbar').within(() => {
            cy.findByRole('alert').should(
              'have.text',
              'Successfully updated settings.',
            );
          });

          // The page doesn't automatically reload on submission,
          // so we reload manually to check the settings have been persisted
          cy.reload();

          // Page reloaded so need to get a new reference to the form.
          cy.findByTestId('authSectionForm').as('authSectionForm');

          cy.get('@authSectionForm').findByText('Authentication').click();
          cy.get('@authSectionForm')
            .findByRole('checkbox', { name: 'Invite-only mode' })
            .should('be.checked');

          // Ensure that none of the authentication providers are enabled.
          cy.findByLabelText('Email enabled').should('not.be.visible');
          cy.findByLabelText('Facebook enabled').should('not.be.visible');
          cy.findByLabelText('GitHub enabled').should('not.be.visible');
          cy.findByLabelText('Twitter enabled').should('not.be.visible');

          cy.signOutUser().then(() => {
            cy.findByRole('link', { name: 'Create account' }).click();

            cy.findByLabelText('Sign up with Email').should('not.exist');
            cy.findByLabelText('Sign up with Facebook').should('not.exist');
            cy.contains('invite only').should('be.visible');
          });
        });
      });
    });
  });

  describe('authentication providers settings', () => {
    it('should display warning modal if provider keys are missing', () => {
      cy.fixture('users/adminUser.json').as('user');
      cy.get('@user').then(() => {
        cy.visit('/admin/customization/config');
        cy.findByTestId('authSectionForm').as('authSectionForm');

        cy.get('@authSectionForm').findByText('Authentication').click();
        cy.get('#facebook-auth-btn').click();

        cy.get('@authSectionForm').findByText('Update Settings').click();

        cy.findByTestId('modal-container').as('modal');

        cy.get('@modal')
          .get('.admin-modal-content > ul > li')
          .contains('facebook')
          .should('be.visible');
      });
    });

    it('should display warning modal with multiple providers if keys are missing', () => {
      cy.fixture('users/adminUser.json').as('user');
      cy.get('@user').then(() => {
        cy.visit('/admin/customization/config');
        cy.findByTestId('authSectionForm').as('authSectionForm');

        cy.get('@authSectionForm').findByText('Authentication').click();
        cy.get('#apple-auth-btn').click();
        cy.get('#facebook-auth-btn').click();

        cy.get('@authSectionForm').findByText('Update Settings').click();

        cy.findByTestId('modal-container').as('modal');

        cy.get('@modal')
          .get('.admin-modal-content > ul > li')
          .contains('facebook')
          .should('be.visible');

        cy.get('@modal')
          .get('.admin-modal-content > ul > li')
          .contains('apple')
          .should('be.visible');
      });
    });

    it('closing warning modal should keep provider enabled', () => {
      cy.fixture('users/adminUser.json').as('user');
      cy.get('@user').then(() => {
        cy.visit('/admin/customization/config');
        cy.findByTestId('authSectionForm').as('authSectionForm');

        cy.get('@authSectionForm').findByText('Authentication').click();
        cy.get('#facebook-auth-btn').click();

        cy.get('@authSectionForm').findByText('Update Settings').click();

        cy.findByTestId('modal-container').as('modal');
        cy.get('@modal').findByRole('button', { name: /Close/ }).click();

        cy.get('@modal').should('not.exist');
        cy.get('@authSectionForm').findByText('Facebook key').should('exist');
      });
    });

    it('continue editing button of modal should keep provider enabled', () => {
      cy.fixture('users/adminUser.json').as('user');
      cy.get('@user').then(() => {
        cy.visit('/admin/customization/config');
        cy.findByTestId('authSectionForm').as('authSectionForm');

        cy.get('@authSectionForm').findByText('Authentication').click();
        cy.get('#facebook-auth-btn').click();

        cy.get('@authSectionForm').findByText('Update Settings').click();

        cy.findByTestId('modal-container').as('modal');
        cy.get('@modal').findByText('Continue editing').click();

        cy.get('@modal').should('not.exist');
        cy.get('@authSectionForm').findByText('Facebook key').should('exist');
      });
    });

    it('cancelling modal should reset providers', () => {
      cy.fixture('users/adminUser.json').as('user');
      cy.get('@user').then(() => {
        cy.visit('/admin/customization/config');
        cy.findByTestId('authSectionForm').as('authSectionForm');

        cy.get('@authSectionForm').findByText('Authentication').click();
        cy.get('#facebook-auth-btn').click();

        cy.get('@authSectionForm').findByText('Update Settings').click();

        cy.findByTestId('modal-container').as('modal');
        cy.get('@modal').findByText('Cancel').click();

        cy.get('@modal').should('not.exist');
        cy.get('@authSectionForm')
          .findAllByRole('button', { name: 'Enable' })
          .should('have.length', 6);
      });
    });

    it('should not display warning modal if provider keys present', () => {
      cy.fixture('users/adminUser.json').as('user');

      cy.get('@user').then(() => {
        cy.visit('/admin/customization/config');
        cy.findByTestId('authSectionForm').as('authSectionForm');

        cy.get('@authSectionForm').findByText('Authentication').click();
        cy.get('#facebook-auth-btn').click();
        cy.get('#settings_authentication_facebook_key').type('randomkey');
        cy.get('#settings_authentication_facebook_secret').type('randomsecret');

        cy.get('@authSectionForm').findByText('Update Settings').click();

        cy.url().should('contains', '/admin/customization/config');

        cy.findByText('Successfully updated settings.').should('be.visible');
        cy.findByLabelText('Facebook enabled').should('be.visible');
      });
    });

    it('generates error message when update fails', () => {
      cy.intercept('POST', 'admin/settings/authentications', {
        error: 'some error msg',
      });
      cy.get('@user').then(() => {
        cy.visit('/admin/customization/config');
        cy.findByTestId('authSectionForm').as('authSectionForm');

        cy.get('@authSectionForm').findByText('Authentication').click();
        cy.get('#facebook-auth-btn').click();
        cy.get('#settings_authentication_facebook_key').type('randomkey');
        cy.get('#settings_authentication_facebook_secret').type('randomsecret');

        cy.get('@authSectionForm').findByText('Update Settings').click();

        cy.url().should('contains', '/admin/customization/config');

        cy.findByTestId('snackbar').within(() => {
          cy.findByRole('alert').should('have.text', 'some error msg');
        });
      });
    });

    it('should display warning modal when disabling a provider', () => {
      cy.fixture('users/adminUser.json').as('user');

      cy.get('@user').then(() => {
        cy.visit('/admin/customization/config');
        cy.findByTestId('authSectionForm').as('authSectionForm');

        cy.get('@authSectionForm').findByText('Authentication').click();
        cy.get('#email-auth-enable-edit-btn').click();
        cy.get('@authSectionForm').findByText('Disable').click();

        cy.findByTestId('modal-container').as('modal');
        cy.get('@modal').should('exist');
      });
    });

    it('email-auth disable modal has correct header', () => {
      cy.fixture('users/adminUser.json').as('user');

      cy.get('@user').then(() => {
        cy.visit('/admin/customization/config');
        cy.findByTestId('authSectionForm').as('authSectionForm');

        cy.get('@authSectionForm').findByText('Authentication').click();
        cy.get('#email-auth-enable-edit-btn').click();
        cy.get('@authSectionForm').findByText('Disable').click();

        cy.findByTestId('modal-container').as('modal');
        cy.get('@modal')
          .findByText('Disable Email address registration')
          .should('exist');
      });
    });

    it('cancelling email-auth disable modal should close the modal', () => {
      cy.fixture('users/adminUser.json').as('user');
      cy.get('@user').then(() => {
        cy.visit('/admin/customization/config');
        cy.findByTestId('authSectionForm').as('authSectionForm');

        cy.get('@authSectionForm').findByText('Authentication').click();
        cy.get('#email-auth-enable-edit-btn').click();
        cy.get('@authSectionForm').findByText('Disable').click();

        cy.findByTestId('modal-container').as('modal');
        cy.get('@modal').findByText('Cancel').click();

        cy.get('@modal').should('not.exist');
        cy.get('@authSectionForm').findByText('Disable').should('exist');
      });
    });

    it('confirm disable button of email-auth disable modal should disable the auth', () => {
      cy.fixture('users/adminUser.json').as('user');
      cy.get('@user').then(() => {
        cy.visit('/admin/customization/config');
        cy.findByTestId('authSectionForm').as('authSectionForm');

        cy.get('@authSectionForm').findByText('Authentication').click();
        cy.get('#email-auth-enable-edit-btn').click();
        cy.get('@authSectionForm').findByText('Disable').click();

        cy.findByTestId('modal-container').as('modal');
        cy.get('@modal').findByText('Confirm disable').click();

        cy.get('@modal').should('not.exist');
        cy.get('@authSectionForm')
          .findAllByRole('button', { name: 'Enable' })
          .should('have.length', 7);
      });
    });
  });
});
