// These assertions are currently skipped because we have the display_ad_tags Feature Flag in place right now.
// We've tried to incorporate feature flags in Cypress tests previously, but there isn't an easy way to do it via an API.
// Hence, for that reason and a couple of other db requirements we went with a separate db and script in the past.
// This is not feasible for every use case.

// Since these feature flags are temporary, I'll skip these cypress tests for now and add the tests back and remove these comments
// once the feature flags have been removed.

xdescribe('Create Display Ads', () => {
  context('when creating a new display ad', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/adminUser.json').as('user');

      cy.get('@user').then((user) => {
        cy.loginAndVisit(user, '/admin/customization/display_ads');
        cy.findByRole('link', { name: 'Make A New Display Ad' }).click({
          force: true,
        });
      });
    });

    it('should not show the tags field if the placement is not "Below the comment section"', () => {
      cy.findByRole('combobox', { name: 'Placement Area:' }).select(
        'Sidebar Right',
      );
      cy.findByRole('input', { name: 'Targeted Tag(s)' }).should('not.exist');
    });

    it('should show the tags field if the placement is "Below the comment section"', () => {
      cy.findByRole('combobox', { name: 'Placement Area:' }).select(
        'Below the comment section',
      );
      cy.findByLabelText('Targeted Tag(s)').should('exist');
    });
  });
});
