describe('Community Content Section', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user);
    });
  });

  describe('member label setting', () => {
    it('accepts valid input', () => {
      cy.get('@user').then(() => {
        cy.visit('/admin/customization/config');
        cy.get('#new_settings_community').as('communitySectionForm');

        cy.get('@communitySectionForm').findByText('Community Content').click();
        cy.get('@communitySectionForm')
          .get('#settings_community_member_label')
          .clear()
          .type('devs');

        cy.get('@communitySectionForm').findByText('Update Settings').click();

        cy.url().should('contains', '/admin/customization/config');

        cy.findByTestId('snackbar').within(() => {
          cy.findByRole('alert').should(
            'have.text',
            'Successfully updated settings.',
          );
        });

        // Page reloaded so need to get a new reference to the form.
        cy.get('#new_settings_community').as('communitySectionForm');
        cy.get('#settings_community_member_label').should('have.value', 'devs');
      });
    });
  });
});
