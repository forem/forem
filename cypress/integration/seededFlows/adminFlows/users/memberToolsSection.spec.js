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
        cy.findByRole('link', { name: username }).click();

        cy.findByRole('main').within(() => {
          cy.findByRole('link', { name: /Emails/ }).should('be.visible');
          cy.findByRole('link', { name: /Notes/ }).should('be.visible');
          cy.findByRole('link', { name: /Credits/ }).should('be.visible');
          cy.findByRole('link', { name: /Organizations/ }).should('be.visible');
          cy.findByRole('link', { name: /Reports/ }).should('be.visible');
          cy.findByRole('link', { name: /Reactions/ }).should('be.visible');
        });
      });
    });
  });

  describe('Emails', () => {
    it('Verifies the email', () => {
      cy.get('@user').then(({ username }) => {
        cy.visitAndWaitForUserSideEffects('/admin/users');
        cy.findByRole('link', { name: username }).click();
        cy.findByRole('link', { name: /Emails/ }).click();

        cy.findByRole('button', { name: 'Verify Email Ownership' }).as(
          'verifyEmailOwnership',
        );
        cy.get('@verifyEmailOwnership').within((button) => {
          button.click();
        });
        cy.findByTestId('snackbar').should(
          'have.text',
          'Verification email sent!',
        );
      });
    });

    it('Sends an email to the user and checks its presence in the history', () => {
      cy.get('@user').then(({ username }) => {
        cy.visitAndWaitForUserSideEffects('/admin/users');
        cy.findByRole('link', { name: username }).click();
        cy.findByRole('link', { name: /Emails/ }).click();

        // Send email
        cy.findByRole('textbox', { name: 'Subject' }).type('Hello!');
        cy.findByRole('textbox', { name: 'Body' }).type('This is an email');
        cy.findByRole('button', { name: 'Send Email' }).click();

        // Check message coming from the server
        cy.findByTestId('snackbar').should('have.text', 'Email sent!');

        // Go back to check its presence in the history
        cy.visitAndWaitForUserSideEffects('/admin/users');
        cy.findByRole('link', { name: username }).click();
        cy.findByRole('link', { name: /Emails/ }).click();

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

  describe('Notes', () => {
    it('Creates a note and checks its presence in the history', () => {
      cy.get('@user').then(({ username }) => {
        cy.visitAndWaitForUserSideEffects('/admin/users');
        cy.findByRole('link', { name: username }).click();
        cy.findByRole('link', { name: /Notes/ }).click();

        cy.findByRole('textbox', { name: 'Add a new note' }).type(
          'Hello, this is a note about them',
        );
        cy.findByRole('button', { name: 'Create Note' }).click();

        cy.findByTestId('snackbar').should('have.text', 'Note created!');

        // Go back to check its presence in the history
        cy.visitAndWaitForUserSideEffects('/admin/users');
        cy.findByRole('link', { name: username }).click();
        cy.findByRole('link', { name: /Notes/ }).click();

        cy.findAllByText(/Recent Notes/)
          .first()
          .within((details) => {
            details.click(); // open the details
          });

        cy.findAllByText(/a note about them/).should('exist');
      });
    });
  });

  describe('Credits', () => {
    it('Add credits for the user', () => {
      cy.get('@user').then(({ username }) => {
        cy.visitAndWaitForUserSideEffects('/admin/users');
        cy.findByRole('link', { name: username }).click();
        cy.findByRole('link', { name: /Credits/ }).click();

        cy.findAllByLabelText('Add credits').first().type(1).trigger('change');
        cy.findByRole('textbox', { name: 'Add credits' }).type(
          'Increasing credits',
        );
        cy.findAllByRole('button', { name: 'Add' }).first().click();

        cy.findByTestId('snackbar').should('have.text', 'Added 1 credit!');
      });
    });

    it('Removes credits for the user', () => {
      cy.get('@user').then(({ username }) => {
        cy.visitAndWaitForUserSideEffects('/admin/users');
        cy.findByRole('link', { name: username }).click();
        cy.findByRole('link', { name: /Credits/ }).click();

        cy.findAllByLabelText('Remove credits')
          .first()
          .type(1)
          .trigger('change');
        cy.findByRole('textbox', { name: 'Remove credits' }).type(
          'Decreasing credits',
        );
        cy.findAllByRole('button', { name: 'Remove' }).first().click();

        cy.findByTestId('snackbar').should('have.text', 'Removed 1 credit!');
      });
    });

    it('Add credits to the organization', () => {
      cy.get('@user').then(({ username }) => {
        cy.visitAndWaitForUserSideEffects('/admin/users');
        cy.findByRole('link', { name: username }).click();
        cy.findByRole('link', { name: /Credits/ }).click();

        cy.findAllByLabelText('Add credits to organizations')
          .first()
          .type(1)
          .trigger('change');
        cy.findByRole('textbox', { name: 'Add credits to organizations' }).type(
          'Increasing credits',
        );
        cy.findAllByRole('button', { name: 'Add' }).last().click();

        cy.findByTestId('snackbar').should('have.text', 'Added 1 credit!');
      });
    });

    it('Removes credits from the organization', () => {
      cy.get('@user').then(({ username }) => {
        cy.visitAndWaitForUserSideEffects('/admin/users');
        cy.findByRole('link', { name: username }).click();
        cy.findByRole('link', { name: /Credits/ }).click();

        cy.findAllByLabelText('Remove credits from organizations')
          .first()
          .type(1)
          .trigger('change');
        cy.findByRole('textbox', {
          name: 'Remove credits from organizations',
        }).type('Decreasing credits');
        cy.findAllByRole('button', { name: 'Remove' }).last().click();

        cy.findByTestId('snackbar').should('have.text', 'Removed 1 credit!');
      });
    });
  });

  describe('Organizations', () => {
    it('Changes a user membership level within an organization', () => {
      cy.get('@user').then(({ username }) => {
        cy.visitAndWaitForUserSideEffects('/admin/users');
        cy.findByRole('link', { name: username }).click();
        cy.findByRole('link', { name: /Organizations/ }).click();

        cy.findAllByText(/Manage memberships/)
          .first()
          .within((details) => {
            details.click();
          });

        // Change role
        cy.findAllByRole('combobox', { name: /Membership Level/ })
          .last()
          .select('Member');
        cy.findAllByRole('button', { name: 'Update Permissions' })
          .first()
          .click();

        cy.findByTestId('snackbar').contains(
          /User was successfully updated to member/i,
        );
      });
    });

    it('Removes a user from an organization', () => {
      cy.get('@user').then(({ username }) => {
        cy.visitAndWaitForUserSideEffects('/admin/users');
        cy.findByRole('link', { name: username }).click();
        cy.findByRole('link', { name: /Organizations/ }).click();

        cy.findAllByText(/Manage memberships/)
          .first()
          .within((details) => {
            details.click();
          });

        cy.findAllByRole('button', { name: /Remove from organization/i })
          .first()
          .click();

        cy.findByTestId('snackbar').contains(/User was successfully removed/i);
      });
    });
  });
});
