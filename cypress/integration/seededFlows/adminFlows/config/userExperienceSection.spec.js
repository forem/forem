describe('User experience Section', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user);
    });
  });

  describe('default font', () => {
    it('can change the default font', () => {
      cy.get('@user').then(() => {
        cy.visit('/admin/customization/config');
        cy.get('#new_settings_user_experience').as('userExperienceSectionForm');

        cy.get('@userExperienceSectionForm')
          .findByText('User Experience and Brand')
          .click();
        cy.get('@userExperienceSectionForm')
          .get('#settings_user_experience_default_font')
          // We need to use force here because the select is covered by another element.
          .select('open-dyslexic', { force: true });

        cy.get('@userExperienceSectionForm')
          .findByText('Update Settings')
          .click();

        cy.url().should('contains', '/admin/customization/config');

        cy.findByTestId('snackbar').within(() => {
          cy.findByRole('alert').should(
            'have.text',
            'Successfully updated settings.',
          );
        });

        // Page reloaded so need to get a new reference to the form.
        cy.get('#new_settings_user_experience').as('userExperienceSectionForm');
        cy.get('@userExperienceSectionForm')
          .findByText('User Experience and Brand')
          .click();
        cy.get('#settings_user_experience_default_font').should(
          'have.value',
          'open_dyslexic',
        );
      });
    });
  });
});
