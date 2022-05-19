describe('User experience Section', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/admin/customization/config');
    });
  });

  it('can change the default font', () => {
    cy.get('#new_settings_user_experience').as('userExperienceSectionForm');

    cy.get('#new_settings_user_experience').within(() => {
      cy.findByText('User Experience and Brand').click();

      cy.findByRole('combobox', { name: 'Default font' }).select(
        'open-dyslexic',
      );

      cy.findByText('Update Settings').click();
    });

    cy.findByTestId('snackbar').within(() => {
      cy.findByRole('alert').should(
        'have.text',
        'Successfully updated settings.',
      );
    });

    // Page reloaded so need to get a new reference to the form.
    cy.get('#new_settings_user_experience').within(() => {
      cy.findByText('User Experience and Brand').click();
      cy.get('#settings_user_experience_default_font').should(
        'have.value',
        'open_dyslexic',
      );
    });
  });

  it('Should change the primary brand color hex if contrast is sufficient', () => {
    cy.get('#new_settings_user_experience').within(() => {
      cy.findByText('User Experience and Brand').click();

      // Both a button and an input should exist for the brand color
      cy.findByRole('button', { name: 'Primary brand color hex' });
      cy.findByRole('textbox', {
        name: 'Primary brand color hex',
      }).enterIntoColorInput('#591803');

      cy.findByText('Update Settings').click();
    });

    cy.findByTestId('snackbar').within(() => {
      cy.findByRole('alert').should(
        'have.text',
        'Successfully updated settings.',
      );
    });
  });

  it('should not update brand color if contrast is insufficient', () => {
    cy.get('#new_settings_user_experience').within(() => {
      cy.findByText('User Experience and Brand').click();

      // Both a button and an input should exist for the brand color
      cy.findByRole('button', { name: 'Primary brand color hex' });
      cy.findByRole('textbox', {
        name: 'Primary brand color hex',
      }).enterIntoColorInput('#ababab');

      cy.findByText('Update Settings').click();
    });

    cy.findByTestId('snackbar').within(() => {
      cy.findByRole('alert').should(
        'have.text',
        'Validation failed: Primary brand color hex must be darker for accessibility',
      );
    });
  });
});
